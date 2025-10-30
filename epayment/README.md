# E-Payment Webhook Server

A Node.js webhook server for handling Xendit payment notifications and processing GCash payments for the wmobile Flutter app.

## Features

- ✅ **Xendit Payment Integration** - Supports GCash, QR PH, Cards, and Bank Transfers
- ✅ **Webhook Handler** - Automatic appointment status updates on successful payment
- ✅ **Firebase Integration** - Updates Firestore when payments complete
- ✅ **Security** - Webhook signature verification
- ✅ **CORS Enabled** - Works with Flutter mobile app

## Setup Instructions

### 1. Install Dependencies
```bash
cd c:\Users\monde\Documents\wmobile\epayment
npm install
```

### 2. Get Xendit API Credentials

1. Sign up at [Xendit Dashboard](https://dashboard.xendit.co/)
2. Go to **Settings** → **API Keys**
3. Copy your **Secret Key** (starts with `xnd_...`)
4. Copy your **Webhook Verification Token**

### 3. Setup Firebase Admin SDK

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project → **Project Settings** → **Service Accounts**
3. Click **Generate New Private Key**
4. Save the JSON file as `serviceAccountKey.json` in the `epayment` folder

### 4. Configure Environment Variables

Create/update `.env` file:
```env
XENDIT_WEBHOOK_SECRET=your_xendit_secret_key_here
PORT=3000
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
```

### 5. Start the Server
```bash
npm start
```

Server will run on `http://localhost:3000`

### 6. Update Flutter App

Update the API URL in `payment_screen.dart`:
```dart
String _paymentApiUrl = 'http://YOUR_IP_ADDRESS:3000';
```

For testing on physical device, use your computer's local IP (e.g., `http://192.168.1.100:3000`)

### 7. Configure Xendit Webhooks

1. Go to Xendit Dashboard → **Settings** → **Webhooks**
2. Add webhook URL: `https://your-domain.com/webhook/xendit`
3. Enable events: `invoice.paid`, `payment.succeeded`, `payment.failed`

## API Endpoints

### POST `/create-appointment-payment`
Creates a Xendit payment invoice for appointment

**Request Body:**
```json
{
  "service": "Hair Styling",
  "amount": 500,
  "userId": "firebase_user_id",
  "appointmentData": {
    "appointmentId": "appointment_doc_id",
    "service": "Hair Styling",
    "price": 500
  }
}
```

**Response:**
```json
{
  "success": true,
  "invoiceUrl": "https://checkout.xendit.co/web/...",
  "externalId": "appointment-user123-1234567890"
}
```

### POST `/webhook/xendit`
Receives Xendit webhook notifications (secured with signature verification)

### GET `/health`
Health check endpoint

## Payment Flow

1. User clicks **Pay Now** in Flutter app
2. App calls `/create-appointment-payment` API
3. Server creates Xendit invoice
4. User redirected to Xendit payment page (GCash/Card/etc.)
5. User completes payment
6. Xendit sends webhook to `/webhook/xendit`
7. Server updates appointment status to "Paid" in Firebase
8. User sees updated status in app

## Deployment (Production)

For production deployment:

1. Deploy to a cloud service (Heroku, Railway, Google Cloud Run, etc.)
2. Update Xendit webhook URL to your production domain
3. Update Flutter app `_paymentApiUrl` to production URL
4. Use environment variables for all sensitive data

## Testing

Test payment creation:
```bash
npm run create-payment
```

## Troubleshooting

**Error: Firebase Admin initialization failed**
- Make sure `serviceAccountKey.json` exists
- Check `GOOGLE_APPLICATION_CREDENTIALS` path in `.env`

**Error: Payment creation failed**
- Verify Xendit API key in `.env`
- Check Xendit dashboard for API errors

**Webhook not updating Firebase**
- Check webhook signature is correct
- Verify Firebase Admin SDK is initialized
- Check server logs for errors