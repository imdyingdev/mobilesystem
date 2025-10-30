const crypto = require('crypto');
const http = require('http'); // use http for local server

// Mock webhook payload
const mockPayload = {
  event: 'payment.succeeded',
  data: {
    id: 'test_payment_123',
    amount: 10000,
    currency: 'IDR',
    status: 'PAID'
  }
};

// Your webhook secret from .env
const XENDIT_WEBHOOK_SECRET = 'xnd_development_DyVYdYsDwt0IDlI7DBFfsIlZZIzaxjrZXgPSQMsDy7aW48G8oUfjEmeVA2vWjQ4';

// Generate signature
const bodyString = JSON.stringify(mockPayload);
const signature = crypto
  .createHmac('sha256', XENDIT_WEBHOOK_SECRET)
  .update(bodyString)
  .digest('hex');

// Send POST request to local server
const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/webhook/xendit',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'x-callback-token': signature,
    'Content-Length': Buffer.byteLength(bodyString)
  }
};

const req = http.request(options, (res) => {
  console.log(`Status: ${res.statusCode}`);
  res.on('data', (d) => {
    process.stdout.write(d);
  });
});

req.on('error', (e) => {
  console.error(e);
});

req.write(bodyString);
req.end();