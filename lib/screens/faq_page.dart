import 'package:flutter/material.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});
  static const String routeName = '/faq';

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'Question': 'How do I track my carbon footprint?',
        'Answer':
            'Go to the Carbon Footprint Tracker module and input your daily activities such as transportation, energy usage, and food consumption. The app will calculate your carbon footprint and provide insights.',
      },
      {
        'Question': 'How can I find eco-friendly product suggestions?',
        'Answer':
            'Navigate to the Eco-Friendly Product Suggestions section. Based on your preferences and lifestyle, the app will recommend sustainable products like reusable bottles, organic food, and energy-efficient appliances.',
      },
      {
        'Question': 'What are Sustainable Living Challenges?',
        'Answer':
            'These are weekly or monthly challenges designed to help you adopt specific sustainable habits, such as a "Plastic-Free Week". Participate to improve your eco-friendly lifestyle.',
      },
      {
        'Question': 'How do I use the Waste Reduction Tracker?',
        'Answer':
            'Use the Waste Reduction Tracker to log your recycling, composting, and plastic reduction efforts. The app will provide tips and statistics to help you improve.',
      },
      {
        'Question': 'Can I get tips for energy conservation?',
        'Answer':
            'Yes! The Energy Conservation Tips module offers personalized suggestions for saving energy at home, such as turning off unused appliances and using renewable sources.',
      },
      {
        'Question': 'How do I join the community forum?',
        'Answer':
            'Access the Community Forum from the main menu to share your sustainability efforts, ask questions, and connect with other users.',
      },
      {
        'Question': 'Is my data secure in this app?',
        'Answer':
            'Yes, your data is securely stored and only accessible to you. Certain features require authentication to protect your privacy.',
      },
      {
        'Question': 'How can I contact support or give feedback?',
        'Answer':
            'Use the Contact Us page to send your queries or feedback. Fill in your name, email, and message, and our team will respond promptly.',
      },
    ];

    return Scaffold(
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...faqs.map(
                      (faq) => Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        child: ExpansionTile(
                          title: Text(
                            faq['Question']!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(faq['Answer']!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }
}
