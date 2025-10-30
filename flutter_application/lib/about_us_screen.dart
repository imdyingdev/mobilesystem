import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text("About Us"),
        backgroundColor: Colors.pink,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Square logo at the top
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

            // About Us Content
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Our Family Business Journey:\n\nFrom RMR to Aloha R.M.R Hair & Nails Salon",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Our story began in 2003 in Laguna, where RMR Salon was born out of passion, dedication, and a dream to help people look and feel their best. "
                    "In 2011, we moved to Montalban, Rizal, expanding our services. "
                    "By 2024, we opened Aloha R.M.R Hair & Nails Salon, led by Ms. Rhona O.\n\n"
                    "For over 20 years, we’ve served countless clients with affordable, high-quality salon services, proving that beauty doesn’t have to be expensive.",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Team Members:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Salon Manager / Supervisor: Alma & Rhona\n"
                    "Senior Hair Stylist: Alma\n"
                    "Junior Hair Stylist / Assistant: Jennifer\n"
                    "Receptionist / Front Desk: Wendy & Alma\n"
                    "Nail Technician: Wendy\n"
                    "Makeup Artist / Lash Technician: Alma & Jennifer\n"
                    "Salon Assistant / Housekeeper: Marelyn\n"
                    "Cashier / Inventory Clerk: Alma & Wendy",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Business Operation Numbers:\n📲 09485999115 - Lewelyn O.\n📲 09983266746 - Maria Alma O.",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
