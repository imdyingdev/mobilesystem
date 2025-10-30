require('dotenv').config();
const express = require('express');
const crypto = require('crypto');
const cors = require('cors');
const admin = require('firebase-admin');
const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Firebase Admin SDK
// Make sure to set GOOGLE_APPLICATION_CREDENTIALS env variable
// or provide serviceAccountKey.json
try {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
  console.log('Firebase Admin initialized');
} catch (error) {
  console.warn('Firebase Admin initialization failed:', error.message);
  console.warn('Webhook will log events but cannot update Firebase');
}

// Middleware to parse JSON
app.use(express.json());

// Enable CORS for all routes
app.use(cors({
  origin: true, // Allow all origins
  credentials: true
}));

// Xendit webhook secret (set this in your environment variables)
const XENDIT_WEBHOOK_SECRET = process.env.XENDIT_WEBHOOK_SECRET;

// Function to verify Xendit webhook signature
function verifyXenditSignature(req, body) {
  const signature = req.headers['x-callback-token'];
  if (!signature) {
    return false;
  }

  const expectedSignature = crypto
    .createHmac('sha256', XENDIT_WEBHOOK_SECRET)
    .update(body)
    .digest('hex');

  return signature === expectedSignature;
}

// Webhook endpoint for Xendit
app.post('/webhook/xendit', (req, res) => {
  const body = JSON.stringify(req.body);

  // Verify the webhook signature
  if (!verifyXenditSignature(req, body)) {
    console.log('Invalid signature');
    return res.status(401).send('Unauthorized');
  }

  // Process the webhook payload
  const event = req.body;

  console.log('Received Xendit webhook:', event);

  // Handle different event types
  switch (event.event) {
    case 'payment.succeeded':
      console.log('Payment succeeded:', event.data);
      // TODO: Update your database, send notifications, etc.
      break;
    case 'payment.failed':
      console.log('Payment failed:', event.data);
      // TODO: Handle failed payment
      break;
    case 'invoice.paid':
      console.log('Invoice paid:', event.data);
      // Move appointment from pending to confirmed
      handlePaymentSuccess(event.data);
      break;
    default:
      console.log('Unhandled event type:', event.event);
  }

  // Respond to Xendit
  res.status(200).send('OK');
});

// Function to handle successful payment
async function handlePaymentSuccess(paymentData) {
  console.log('Processing successful payment for appointment:', paymentData.external_id);

  try {
    // Extract appointment ID from metadata
    const metadata = paymentData.metadata || {};
    const appointmentData = metadata.appointmentData || {};
    const appointmentId = appointmentData.appointmentId;

    if (!appointmentId) {
      console.error('No appointment ID found in payment metadata');
      return;
    }

    // Update appointment status in Firebase
    const db = admin.firestore();
    await db.collection('appointments').doc(appointmentId).update({
      status: 'Paid',
      paymentMethod: 'Xendit',
      paymentId: paymentData.id,
      externalId: paymentData.external_id,
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      paidAmount: paymentData.amount,
    });

    console.log(`Successfully updated appointment ${appointmentId} to Paid status`);
  } catch (error) {
    console.error('Error updating appointment:', error);
  }
}

// Endpoint to create payment for appointment
app.post('/create-appointment-payment', async (req, res) => {
  try {
    const { service, amount, userId, appointmentData } = req.body;

    // Create invoice with Xendit
    const Xendit = require('xendit-node');
    const xendit = new Xendit({
      secretKey: process.env.XENDIT_WEBHOOK_SECRET,
    });

    const { Invoice } = xendit;
    const invoice = new Invoice();

    const newInvoice = await invoice.createInvoice({
      externalID: `appointment-${userId}-${Date.now()}`,
      payerEmail: 'customer@example.com', // Would come from user data
      description: `Payment for ${service} appointment`,
      amount: amount || 10000, // Default 100 PHP
      currency: 'PHP',
      successRedirectURL: 'http://localhost:3000/payment-success',
      failureRedirectURL: 'http://localhost:3000/payment-failed',
      paymentMethods: ['GCASH', 'QRPH', 'CARD', 'BANK_TRANSFER'],
      metadata: {
        type: 'appointment',
        userId: userId,
        appointmentData: appointmentData
      }
    });

    res.json({
      success: true,
      invoiceUrl: newInvoice.invoice_url,
      externalId: newInvoice.external_id
    });

  } catch (error) {
    console.error('Error creating payment:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('Server is running');
});

// Start the server
app.listen(PORT, () => {
  console.log(`Webhook server listening on port ${PORT}`);
});