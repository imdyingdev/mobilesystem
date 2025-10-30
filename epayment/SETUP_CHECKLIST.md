# Payment Integration Setup Checklist

## ✅ Prerequisites
- [ ] Node.js installed (v14 or higher)
- [ ] Flutter app connected to Firebase
- [ ] Xendit account created

## 📋 Step-by-Step Setup

### 1. Backend Setup (Node.js Server)

- [ ] Navigate to epayment folder
  ```bash
  cd c:\Users\monde\Documents\wmobile\epayment
  ```

- [ ] Install dependencies
  ```bash
  npm install
  ```

- [ ] Get Xendit credentials
  - [ ] Login to [Xendit Dashboard](https://dashboard.xendit.co/)
  - [ ] Copy Secret Key from Settings → API Keys
  - [ ] Copy Webhook Verification Token

- [ ] Setup Firebase Admin SDK
  - [ ] Go to Firebase Console → Project Settings → Service Accounts
  - [ ] Click "Generate New Private Key"
  - [ ] Save as `serviceAccountKey.json` in epayment folder

- [ ] Create `.env` file with:
  ```env
  XENDIT_WEBHOOK_SECRET=xnd_development_YOUR_KEY_HERE
  PORT=3000
  GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
  ```

- [ ] Test server startup
  ```bash
  npm start
  ```
  Should see: "Server listening on port 3000" and "Firebase Admin initialized"

### 2. Flutter App Setup

- [ ] Install new dependencies
  ```bash
  cd c:\Users\monde\Documents\wmobile\flutter_application
  flutter pub get
  ```

- [ ] Update API URL in `payment_screen.dart` (line 26)
  - For emulator: `http://10.0.2.2:3000` (Android)
  - For physical device: `http://YOUR_COMPUTER_IP:3000` (e.g., `http://192.168.1.100:3000`)
  - To find your IP: Run `ipconfig` in terminal, look for "IPv4 Address"

- [ ] Rebuild the app
  ```bash
  flutter run
  ```

### 3. Testing Payment Flow

- [ ] Create a test appointment in the app
- [ ] Click "Pay Now" button
- [ ] Verify:
  - [ ] Payment screen shows correct amount
  - [ ] Clicking "Proceed to Payment" opens browser
  - [ ] Xendit payment page loads
  - [ ] Can select GCash payment method

### 4. Webhook Configuration (For Production Only)

- [ ] Deploy server to cloud (Heroku, Railway, etc.)
- [ ] Configure Xendit webhook
  - [ ] Go to Xendit Dashboard → Settings → Webhooks
  - [ ] Add URL: `https://your-domain.com/webhook/xendit`
  - [ ] Enable events: invoice.paid, payment.succeeded, payment.failed
- [ ] Update Flutter app with production URL

## 🔍 Verification

### Backend Health Check
Visit: `http://localhost:3000/health`
Should return: "Server is running"

### Test Payment Creation
```bash
npm run create-payment
```
Should create a Xendit invoice and show the URL

### Test Appointment Status Update
1. Make test payment
2. Complete payment in Xendit
3. Check appointment in Firebase Console
4. Status should update from "Pending" to "Paid"

## 🚨 Common Issues

**Issue: Cannot connect to payment server**
- Check if server is running (`npm start`)
- Verify IP address in Flutter app matches your computer
- Disable firewall temporarily for testing

**Issue: Firebase Admin error**
- Verify `serviceAccountKey.json` exists in epayment folder
- Check file path in `.env` is correct
- Ensure Firebase project matches your app

**Issue: Payment doesn't update appointment**
- Check server console logs
- Verify webhook signature in Xendit dashboard
- Ensure appointmentId is passed correctly

## 📝 Next Steps After Setup

1. Test with Xendit test mode first
2. Configure success/failure redirect URLs
3. Add user email to payment metadata
4. Setup email notifications
5. Deploy to production
6. Switch to live Xendit credentials
7. Configure production webhooks

## 🎯 Production Checklist

- [ ] Server deployed to cloud platform
- [ ] Environment variables set in production
- [ ] Xendit webhook URL configured
- [ ] Flutter app updated with production API URL
- [ ] SSL certificate configured (HTTPS)
- [ ] Webhook signature verification enabled
- [ ] Error logging setup
- [ ] Testing completed with real payments
