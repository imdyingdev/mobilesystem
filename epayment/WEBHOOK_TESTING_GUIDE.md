# 🧪 Webhook Testing Guide

## Problem Fixed

✅ **Added `/payment-success` and `/payment-failed` endpoints**
✅ **Enhanced webhook logging for debugging**
✅ **Made webhook automatically update appointment status**

## How It Works Now

```
User pays → Xendit processes → Webhook called → Appointment updated to "Paid" → User sees status change
```

## Testing Options

### Option 1: Test Manually Without Real Payment

**Step 1:** Get your appointment ID from Firebase Console

**Step 2:** Call the test endpoint:
```bash
curl -X POST http://localhost:3000/test-payment-success \
  -H "Content-Type: application/json" \
  -d "{\"appointmentId\": \"YOUR_APPOINTMENT_ID_HERE\"}"
```

Or use PowerShell:
```powershell
$body = @{
    appointmentId = "YOUR_APPOINTMENT_ID_HERE"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/test-payment-success" -Method POST -Body $body -ContentType "application/json"
```

**Expected Result:**
- Appointment status changes from "Pending" to "Paid"
- You see success message in app

### Option 2: Test With Real Xendit Payment (Test Mode)

**Requirements:**
- Xendit account in test mode
- Ngrok or similar for webhook URL

**Step 1:** Install ngrok
```bash
# Download from https://ngrok.com/download
ngrok http 3000
```

**Step 2:** Copy the ngrok URL (e.g., `https://abc123.ngrok.io`)

**Step 3:** Configure Xendit webhook
- Go to Xendit Dashboard → Settings → Webhooks
- Add webhook URL: `https://abc123.ngrok.io/webhook/xendit`
- Enable: `invoice.paid`, `payment.succeeded`

**Step 4:** Make a test payment from your app
- Use Xendit test cards or test GCash credentials
- Complete payment
- Watch server console for webhook logs

### Option 3: Simulate Webhook Manually

Create a file `test-webhook.json`:
```json
{
  "id": "test-payment-123",
  "external_id": "appointment-test-1234567890",
  "status": "PAID",
  "amount": 500,
  "metadata": {
    "type": "appointment",
    "userId": "test-user",
    "appointmentData": {
      "appointmentId": "YOUR_APPOINTMENT_ID",
      "service": "Test Service",
      "price": 500
    }
  }
}
```

Send it:
```bash
curl -X POST http://localhost:3000/webhook/xendit \
  -H "Content-Type: application/json" \
  -d @test-webhook.json
```

## Checking if Webhook Works

### 1. Check Server Logs

After payment, you should see:
```
=== Xendit Webhook Received ===
Payload: {...}
✅ Payment successful! Processing...
🔄 Processing successful payment...
External ID: appointment-user123-1234567890
Metadata: {...}
📝 Updating appointment: abc123
✅ Successfully updated appointment abc123 to Paid status
```

### 2. Check Firebase Console

1. Open Firebase Console
2. Go to Firestore Database
3. Find the appointment document
4. Check if `status` field changed to "Paid"
5. Check if `paidAt` timestamp was added

### 3. Check App

1. Open the app
2. Go to Appointments tab
3. Appointment status should show "Paid" (green)
4. "Pay Now" button should disappear
5. "Mark as Complete" button should appear

## Common Issues & Solutions

### Issue: "Cannot GET /payment-success"
**Status:** ✅ FIXED
**Solution:** Added the endpoint in server.js

### Issue: Webhook not updating appointment
**Check:**
1. Is server running? (`npm start`)
2. Is Firebase Admin initialized? (Check server logs)
3. Is appointment ID in metadata? (Check webhook logs)
4. Does server have access to Firebase? (Check serviceAccountKey.json)

**Debug:**
```bash
# Watch server logs in real-time
npm start

# In webhook logs, verify:
# - Metadata contains appointmentData
# - appointmentData has appointmentId
# - No Firebase errors
```

### Issue: Status not updating in app
**Cause:** App caching old data
**Solution:** 
- Pull down to refresh in app
- Close and reopen app
- Check if using StreamBuilder (should auto-update)

### Issue: Webhook called but no update
**Check server logs for:**
```
❌ No appointment ID found in payment metadata
```

**Fix:** Ensure metadata is passed correctly in payment creation:
```javascript
metadata: {
  type: 'appointment',
  userId: userId,
  appointmentData: {
    appointmentId: appointmentId,  // ← Must be present
    service: service,
    price: price
  }
}
```

## Production Checklist

Before going live:

- [ ] Deploy server to cloud (Heroku, Railway, etc.)
- [ ] Configure production webhook URL in Xendit
- [ ] Switch Xendit to live mode (not test mode)
- [ ] Update success/failure URLs to production domain
- [ ] Enable webhook signature verification
- [ ] Test with small real payment
- [ ] Monitor logs for errors
- [ ] Setup error alerts

## Webhook URL Examples

**Development:**
- Local: `http://localhost:3000/webhook/xendit`
- Ngrok: `https://abc123.ngrok.io/webhook/xendit`

**Production:**
- Heroku: `https://your-app.herokuapp.com/webhook/xendit`
- Railway: `https://your-app.railway.app/webhook/xendit`
- Custom: `https://api.yourdomain.com/webhook/xendit`

## Testing Checklist

- [ ] Server starts without errors
- [ ] `/health` endpoint returns "Server is running"
- [ ] `/payment-success` shows success page
- [ ] `/payment-failed` shows error page
- [ ] Manual test endpoint works
- [ ] Real payment updates status
- [ ] App shows updated status
- [ ] Webhook logs show success

## Need Help?

1. Check server console logs
2. Check Firebase Console for updates
3. Check Xendit dashboard for webhook delivery status
4. Use `/test-payment-success` endpoint to bypass Xendit
5. Check this guide's troubleshooting section
