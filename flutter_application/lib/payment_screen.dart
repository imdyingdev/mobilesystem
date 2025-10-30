import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'config.dart';

class PaymentScreen extends StatefulWidget {
  final String appointmentId;
  final String service;
  final int price;

  const PaymentScreen({
    super.key,
    required this.appointmentId,
    required this.service,
    required this.price,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;

  Future<void> _initiatePayment() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Call the payment API
      print('🔄 Calling payment API: ${ApiConfig.createPaymentEndpoint}');
      print('Request data: service=${widget.service}, amount=${widget.price}');
      
      final response = await http.post(
        Uri.parse(ApiConfig.createPaymentEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service': widget.service,
          'amount': widget.price,
          'userId': user.uid,
          'appointmentData': {
            'appointmentId': widget.appointmentId,
            'service': widget.service,
            'price': widget.price,
          }
        }),
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final invoiceUrl = data['invoiceUrl'];
        
        print('✅ Payment API Success!');
        print('Invoice URL: $invoiceUrl');
        
        if (invoiceUrl != null) {
          // Open Xendit payment page in browser
          final uri = Uri.parse(invoiceUrl);
          print('Parsed URI: $uri');
          print('Attempting to launch URL...');
          
          // Try launching without checking first (more reliable on some devices)
          try {
            final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
            print('Launch result: $launched');
            
            if (!launched) {
              throw Exception('launchUrl returned false');
            }
            
            if (!mounted) return;
            
            // Show confirmation dialog after payment
            final confirmed = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Payment Complete?'),
                content: const Text(
                  'Did you complete the payment successfully?\n\n'
                  'Note: This is temporary. Normally the system auto-updates via webhook.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Not Yet'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Yes, Completed'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              // Manually update status to Paid
              await FirebaseFirestore.instance
                  .collection('appointments')
                  .doc(widget.appointmentId)
                  .update({
                'status': 'Paid',
                'paymentMethod': 'Xendit (Manual Confirm)',
                'paidAt': FieldValue.serverTimestamp(),
              });

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Payment confirmed! Status updated to Paid.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            
            if (!mounted) return;
            Navigator.pop(context);
          } catch (launchError) {
            print('❌ Launch error: $launchError');
            throw Exception('Could not launch payment URL: $launchError');
          }
        } else {
          throw Exception('No invoice URL received');
        }
      } else {
        throw Exception('Failed to create payment: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
        backgroundColor: Colors.pink,
      ),
      backgroundColor: Colors.pink.shade50,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.payment,
              size: 80,
              color: Colors.pink,
            ),
            const SizedBox(height: 30),
            Text(
              "Service: ${widget.service}",
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text("Amount to Pay: ₱${widget.price}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink)),
            const SizedBox(height: 10),
            const Text(
              "Payment via Xendit",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Text(
              "Supports: GCash, QR PH, Card, Bank Transfer",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _initiatePayment,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text("Proceed to Payment"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            const Text(
              "You will be redirected to complete payment.\nReturn to the app to check your appointment status.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
