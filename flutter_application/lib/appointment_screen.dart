import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'payment_screen.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final User? user = FirebaseAuth.instance.currentUser;


  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final currentUser = user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Appointments"),
        backgroundColor: Colors.pink,
      ),
      backgroundColor: Colors.pink.shade50,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No appointments found."));
          }

          final userAppointments = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['userId'] == currentUser.uid;
          }).toList();

          if (userAppointments.isEmpty) {
            return const Center(child: Text("No appointments found."));
          }

          return ListView.builder(
            itemCount: userAppointments.length,
            itemBuilder: (context, index) {
              final doc = userAppointments[index];
              final data = doc.data() as Map<String, dynamic>;

              final date = data['date'] != null
                  ? (data['date'] as Timestamp).toDate()
                  : DateTime.now();

              final formattedDate =
                  DateFormat('MMMM dd, yyyy - hh:mm a').format(date);
              final status = data['status']?.toString().toLowerCase() ?? 'pending';

              // Show Pay button only for pending appointments
              bool showPayButton = status == 'pending';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.pink, width: 2),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Name: ${data['name']}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Contact: ${data['contact']}"),
                    Text("Service: ${data['service']}"),
                    Text("Price: ₱${data['price']}"),
                    Text("Date: $formattedDate"),
                    Text("Status: ${data['status']}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _statusColor(status))),
                    const SizedBox(height: 12),
                    // Show Complete button for Paid appointments
                    if (status == 'paid')
                      ElevatedButton.icon(
                        onPressed: () => _completeAppointment(doc.id),
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Mark as Complete"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade400,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    // Show action buttons for Pending appointments
                    if (status != 'cancelled' &&
                        status != 'paid' &&
                        status != 'completed' &&
                        status != 'approved')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _rescheduleAppointment(doc.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink.shade300,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text("Reschedule"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _cancelAppointment(doc.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text("Cancel"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (showPayButton)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentScreen(
                                        appointmentId: doc.id,
                                        service: data['service'],
                                        price: data['price'],
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade400,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text("Pay Now"),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'approved':
        return Colors.blue;
      case 'completed':
      case 'paid':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelAppointment(String id) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(id)
        .update({'status': 'Cancelled'});
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Appointment cancelled.")));
  }

  Future<void> _completeAppointment(String id) async {
    // Confirm before marking as complete
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Appointment'),
        content: const Text(
            'Mark this appointment as complete? This means the service has been provided.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(id)
        .update({
      'status': 'Completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Appointment marked as complete!")),
    );
  }

  Future<void> _rescheduleAppointment(String id) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      selectableDayPredicate: (date) => date.weekday >= 1 && date.weekday <= 5,
    );

    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (!mounted || pickedTime == null) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(id)
        .update({'date': newDateTime, 'status': 'Rescheduled'});

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Appointment rescheduled.")));
  }
}
