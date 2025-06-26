import 'package:flutter/material.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});
  static const String routeName = '/about-us';

  @override
  Widget build(BuildContext context) {
    final teamMembers = [
      {
        'name': 'Muneer Raja',
        'role': 'Project Lead & Sustainability Expert',
        'bio':
            'A passionate advocate for sustainable living, Ayesha brings over a decade of experience in environmental education and project management.',
      },
    ];

    return Scaffold(
      drawer: BookstoreHeader.buildDrawer(context), // Add the drawer here
      body: Column(
        children: [
          const BookstoreHeader(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'About Sustainable Living Guide',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                           'Sustainable Living Guide is your all-in-one platform for adopting eco-friendly habits and making a positive impact on the planet. Our mission is to simplify sustainable living by providing tools to track your carbon footprint, discover green products, and connect with a like-minded community.',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Meet Our Team',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...teamMembers.map(
                            (m) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(m['name']![0]),
                                ),
                                title: Text(m['name']!),
                                subtitle: Text('${m['role']}\n${m['bio']}'),
                                isThreeLine: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const BookstoreFooter(),
        ],
      ),
    );
  }
}
