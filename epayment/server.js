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

// Xendit credentials (set these in your environment variables)
const XENDIT_SECRET_KEY = process.env.XENDIT_SECRET_KEY; // API Secret Key for making API calls
const XENDIT_WEBHOOK_TOKEN = process.env.XENDIT_WEBHOOK_TOKEN; // Webhook Verification Token

// Function to verify Xendit webhook signature
function verifyXenditSignature(req, body) {
  const signature = req.headers['x-callback-token'];
  if (!signature) {
    return false;
  }

  const expectedSignature = crypto
    .createHmac('sha256', XENDIT_WEBHOOK_TOKEN)
    .update(body)
    .digest('hex');

  return signature === expectedSignature;
}

// Webhook endpoint for Xendit
app.post('/webhook/xendit', async (req, res) => {
  console.log('\n=== Xendit Webhook Received ===');
  console.log('Payload:', JSON.stringify(req.body, null, 2));

  // Process the webhook payload
  const event = req.body;

  // Handle different webhook formats
  if (event.status === 'PAID' || event.status === 'SETTLED') {
    console.log('✅ Payment successful! Processing...');
    await handlePaymentSuccess(event);
  } else if (event.event === 'invoice.paid') {
    console.log('✅ Invoice paid! Processing...');
    await handlePaymentSuccess(event);
  } else {
    console.log('ℹ️ Other webhook event:', event.event || event.status);
  }

  // Always respond with 200 OK
  res.status(200).send('OK');
});

// Function to handle successful payment
async function handlePaymentSuccess(paymentData) {
  console.log('\n🔄 Processing successful payment...');
  console.log('External ID:', paymentData.external_id);

  try {
    // Extract appointment ID from metadata
    const metadata = paymentData.metadata || {};
    console.log('Metadata:', JSON.stringify(metadata, null, 2));
    
    const appointmentData = metadata.appointmentData || {};
    const appointmentId = appointmentData.appointmentId;

    if (!appointmentId) {
      console.error('❌ No appointment ID found in payment metadata');
      console.error('Available metadata:', metadata);
      return;
    }

    console.log('📝 Updating appointment:', appointmentId);

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

    console.log(`✅ Successfully updated appointment ${appointmentId} to Paid status`);
  } catch (error) {
    console.error('❌ Error updating appointment:', error);
    console.error('Error details:', error.message);
  }
}

// Endpoint to create payment for appointment
app.post('/create-appointment-payment', async (req, res) => {
  try {
    const { service, amount, userId, appointmentData } = req.body;

    // Create invoice with Xendit
    const Xendit = require('xendit-node');
    const xendit = new Xendit({
      secretKey: XENDIT_SECRET_KEY,
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

// GET fallback for create-appointment-payment (for browser visits)
app.get('/create-appointment-payment', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Payment API Endpoint</title>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        body {
          font-family: Arial, sans-serif;
          display: flex;
          justify-content: center;
          align-items: center;
          min-height: 100vh;
          margin: 0;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 20px;
        }
        .container {
          background: rgba(255, 255, 255, 0.1);
          border-radius: 20px;
          padding: 40px;
          backdrop-filter: blur(10px);
          box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
          max-width: 500px;
          text-align: center;
        }
        .icon {
          font-size: 80px;
          margin-bottom: 20px;
        }
        h1 { 
          margin: 20px 0; 
          font-size: 24px;
        }
        .info-box {
          background: rgba(255, 255, 255, 0.2);
          border-radius: 10px;
          padding: 20px;
          margin: 20px 0;
          text-align: left;
        }
        .info-box h3 {
          margin-top: 0;
          color: #ffd700;
        }
        code {
          background: rgba(0, 0, 0, 0.3);
          padding: 2px 6px;
          border-radius: 4px;
          font-size: 14px;
        }
        .status {
          display: inline-block;
          background: #4caf50;
          padding: 8px 16px;
          border-radius: 20px;
          font-weight: bold;
          margin-top: 10px;
        }
        ul {
          text-align: left;
          line-height: 1.8;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="icon">🔌</div>
        <h1>Payment API Endpoint</h1>
        <div class="status">✅ Server Running</div>
        
        <div class="info-box">
          <h3>ℹ️ API Information</h3>
          <p><strong>Endpoint:</strong> <code>/create-appointment-payment</code></p>
          <p><strong>Method:</strong> <code>POST</code> only</p>
          <p><strong>Purpose:</strong> Create Xendit payment invoices</p>
        </div>

        <div class="info-box">
          <h3>📋 Required POST Data</h3>
          <ul>
            <li><code>service</code> - Service name</li>
            <li><code>amount</code> - Amount in PHP</li>
            <li><code>userId</code> - User ID</li>
            <li><code>appointmentData</code> - Appointment details</li>
          </ul>
        </div>

        <p style="margin-top: 30px; font-size: 14px; opacity: 0.8;">
          This endpoint cannot be accessed directly via browser.<br>
          It's designed to be called from the mobile app.
        </p>
      </div>
    </body>
    </html>
  `);
});

// Success redirect endpoint
app.get('/payment-success', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Payment Successful</title>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        body {
          font-family: Arial, sans-serif;
          display: flex;
          justify-content: center;
          align-items: center;
          min-height: 100vh;
          margin: 0;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          text-align: center;
          padding: 20px;
        }
        .container {
          background: rgba(255, 255, 255, 0.1);
          border-radius: 20px;
          padding: 40px;
          backdrop-filter: blur(10px);
          box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        .checkmark {
          font-size: 80px;
          animation: scale 0.5s ease-in-out;
        }
        @keyframes scale {
          0% { transform: scale(0); }
          50% { transform: scale(1.2); }
          100% { transform: scale(1); }
        }
        h1 { margin: 20px 0; }
        p { font-size: 18px; margin: 10px 0; }
        .info { margin-top: 30px; font-size: 14px; opacity: 0.8; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="checkmark">✅</div>
        <h1>Payment Successful!</h1>
        <p>Your appointment has been confirmed.</p>
        <p>Check your appointment status in the app.</p>
        <div class="info">
          <p>You can close this window and return to the app.</p>
        </div>
      </div>
    </body>
    </html>
  `);
});

// Failure redirect endpoint
app.get('/payment-failed', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Payment Failed</title>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        body {
          font-family: Arial, sans-serif;
          display: flex;
          justify-content: center;
          align-items: center;
          min-height: 100vh;
          margin: 0;
          background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
          color: white;
          text-align: center;
          padding: 20px;
        }
        .container {
          background: rgba(255, 255, 255, 0.1);
          border-radius: 20px;
          padding: 40px;
          backdrop-filter: blur(10px);
          box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        .cross {
          font-size: 80px;
          animation: shake 0.5s ease-in-out;
        }
        @keyframes shake {
          0%, 100% { transform: translateX(0); }
          25% { transform: translateX(-10px); }
          75% { transform: translateX(10px); }
        }
        h1 { margin: 20px 0; }
        p { font-size: 18px; margin: 10px 0; }
        .info { margin-top: 30px; font-size: 14px; opacity: 0.8; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="cross">❌</div>
        <h1>Payment Failed</h1>
        <p>Your payment could not be processed.</p>
        <p>Please try again or contact support.</p>
        <div class="info">
          <p>You can close this window and return to the app.</p>
        </div>
      </div>
    </body>
    </html>
  `);
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('Server is running');
});

// Manual test endpoint for updating appointment to Paid
app.post('/test-payment-success', async (req, res) => {
  const { appointmentId } = req.body;
  
  if (!appointmentId) {
    return res.status(400).json({ error: 'appointmentId required' });
  }

  try {
    const db = admin.firestore();
    await db.collection('appointments').doc(appointmentId).update({
      status: 'Paid',
      paymentMethod: 'Test',
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log(`✅ Test: Updated appointment ${appointmentId} to Paid`);
    res.json({ success: true, message: 'Appointment updated to Paid' });
  } catch (error) {
    console.error('❌ Test failed:', error);
    res.status(500).json({ error: error.message });
  }
});

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🚀 Webhook server listening on port ${PORT}`);
  console.log(`📱 Local access: http://localhost:${PORT}`);
  console.log(`🌐 Network access: http://192.168.1.6:${PORT}`);
  console.log(`✅ Health check: http://192.168.1.6:${PORT}/health\n`);
});