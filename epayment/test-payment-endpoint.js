// Test script for payment endpoint
const axios = require('axios');

const baseUrl = 'http://192.168.1.6:3000';

async function testPaymentEndpoint() {
  console.log('Testing payment endpoint...\n');

  try {
    const response = await axios.post(`${baseUrl}/create-appointment-payment`, {
      service: 'Waxing',
      amount: 19900, // 199 PHP in cents
      userId: 'test-user-123',
      appointmentData: {
        appointmentId: 'test-appointment-456',
        service: 'Waxing',
        price: 19900
      }
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    console.log('✅ Success!');
    console.log('Response:', JSON.stringify(response.data, null, 2));
    console.log('\nInvoice URL:', response.data.invoiceUrl);
    
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

testPaymentEndpoint();
