import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool isLoading = true;
  bool editName = false;
  bool editContact = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['full_name'] ?? '';
        _contactController.text = data['contact'] ?? '';
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _updateField(String field) async {
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user!.uid);

    if (field == 'name') {
      await userDoc.update({'full_name': _nameController.text.trim()});
      setState(() {
        editName = false;
      });
    } else if (field == 'contact') {
      await userDoc.update({'contact': _contactController.text.trim()});
      setState(() {
        editContact = false;
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  void _cancelEdit(String field) {
    _loadUserData(); // Reload original values
    setState(() {
      if (field == 'name') editName = false;
      if (field == 'contact') editContact = false;
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false, // Removes all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.pink,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 100,
                      height: 100,
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
                    const Text(
                      "User Information",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Full Name
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            readOnly: !editName,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (!editName)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.pink),
                            onPressed: () {
                              setState(() => editName = true);
                            },
                          )
                        else
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _updateField('name'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _cancelEdit('name'),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Contact
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _contactController,
                            readOnly: !editContact,
                            decoration: const InputDecoration(
                              labelText: 'Contact Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (!editContact)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.pink),
                            onPressed: () {
                              setState(() => editContact = true);
                            },
                          )
                        else
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _updateField('contact'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _cancelEdit('contact'),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Email (read-only)
                    Text(
                      "Email: ${user?.email ?? 'Not set'}",
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Sign out button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _signOut,
                        child: const Text(
                          "Sign Out",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
