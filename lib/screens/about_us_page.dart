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
        'name': 'xxx',
        'role': 'Chief Booklover',
        'bio':
            'A lifelong book enthusiast and visionary entrepreneur with over 15 years of experience in the book industry, dedicated to connecting readers with stories that inspire.',
      },
      {
        'name': 'xxx',
        'role': 'Lead Developer',
        'bio':
            'Tech innovator passionate about crafting smooth, intuitive digital experiences that make browsing and buying books a joy.',
      },
      {
        'name': 'xxx',
        'role': 'Customer Success Manager',
        'bio':
            'Committed to creating exceptional customer journeys and helping every reader discover their next favorite book with ease and satisfaction.',
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
                            'About BookNook',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'BookNook is your friendly neighborhood online bookstore. '
                            'We are passionate about connecting readers with their next great read. '
                            'Our mission is to provide a wide selection of books, excellent customer service, '
                            'and a welcoming community for book lovers everywhere.',
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
