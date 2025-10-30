require('dotenv').config();
const Xendit = require('xendit-node');

const xendit = new Xendit({
  secretKey: process.env.XENDIT_WEBHOOK_SECRET,
});

const { Invoice } = xendit;
const invoice = new Invoice();

// Create payment invoice with GCash and QR PH options
async function createGCashInvoice() {
  try {
    const newInvoice = await invoice.createInvoice({
      externalID: `gcash-invoice-${Date.now()}`,
      payerEmail: 'test@example.com',
      description: 'Payment with GCash or QR PH',
      amount: 10000, // 100.00 IDR (will be converted to PHP for GCash)
      currency: 'PHP', // Specify PHP currency for GCash
      successRedirectURL: 'http://localhost:3000/success',
      failureRedirectURL: 'http://localhost:3000/failure',
      paymentMethods: ['GCASH', 'QRPH'], // Allow GCash and QR PH
    });

    console.log('GCash invoice created:');
    console.log('Invoice URL:', newInvoice.invoice_url);
    console.log('Amount:', newInvoice.amount, newInvoice.currency);
    console.log('External ID:', newInvoice.external_id);
    console.log('Status:', newInvoice.status);

    // Visit invoice_url in browser to pay with GCash
    // Webhook will be triggered when payment succeeds

  } catch (error) {
    console.error('Error creating GCash invoice:', error);
  }
}

createGCashInvoice();