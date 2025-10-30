import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  String? _selectedService;
  int _price = 0;
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadServices();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (!mounted) return;
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _contactController.text = data['contact'] ?? '';
        });
      }
    }
  }

  Future<void> _loadServices() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('services').get();
    final list = snapshot.docs
        .map((doc) => {'name': doc['name'], 'price': doc['price']})
        .toList();
    if (!mounted) return;
    setState(() {
      _services = list;
      _isLoading = false;
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      selectableDayPredicate: (date) {
        return date.weekday >= 1 && date.weekday <= 5;
      },
    );

    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    if (pickedTime.hour < 9 || pickedTime.hour > 18) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time between 9 AM and 6 PM.')),
      );
      return;
    }

    final selected = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (!mounted) return;
    setState(() {
      _selectedDateTime = selected;
    });
  }

  Future<void> _submitBooking() async {
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service.')),
      );
      return;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('appointments').add({
      'userId': user.uid,
      'name': _nameController.text,
      'contact': _contactController.text,
      'service': _selectedService,
      'price': _price,
      'status': 'Pending',
      'date': _selectedDateTime,
      'createdAt': DateTime.now(),
    });

    if (!mounted) return;
    setState(() {
      _selectedService = null;
      _selectedDateTime = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment confirmed!')),
    );
    // ✅ Do NOT switch tab automatically
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Book an Appointment'),
        backgroundColor: Colors.pink,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.pink, width: 2),
                      borderRadius: BorderRadius.circular(10),
                      image: const DecorationImage(
                        image: AssetImage('assets/logo.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _contactController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Select Service',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.room_service),
                            ),
                            initialValue: _selectedService,
                            items: _services
                                .map((service) => DropdownMenuItem<String>(
                                      value: service['name'],
                                      child: Text(
                                          '${service['name']} - ₱${service['price']}'),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (!mounted) return;
                              setState(() {
                                _selectedService = value;
                                _price = _services
                                        .firstWhere((s) => s['name'] == value)['price'] ??
                                    0;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: _pickDateTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Select Date & Time',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _selectedDateTime == null
                                    ? 'Tap to select'
                                    : DateFormat('MMMM dd, yyyy - hh:mm a')
                                        .format(_selectedDateTime!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _submitBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Book Appointment',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'Store Hours: Mon-Fri, 9:00 AM - 6:00 PM',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
