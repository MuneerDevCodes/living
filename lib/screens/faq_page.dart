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
        'Question': 'How do I place an order?',
        'Answer':
            'Browse our collection, add items to your cart, and proceed to checkout. Follow the simple steps to complete your purchase.',
      },
      {
        'Question': 'What payment methods do you accept?',
        'Answer':
            'We accept all major credit cards, PayPal, and other secure payment methods.',
      },
      {
        'Question': 'How long does shipping take?',
        'Answer':
            'Standard shipping typically takes 3-5 business days. Express shipping is available for faster delivery.',
      },
      {
        'Question': 'Do you offer international shipping?',
        'Answer':
            'Yes, we offer international shipping to many countries. Shipping times and fees may vary based on location.',
      },
      {
        'Question': 'What is your return policy?',
        'Answer':
            'We offer a 30-day return policy on most items. Products must be in original condition. Please contact support to initiate a return.',
      },
      {
        'Question': 'How can I contact customer support?',
        'Answer':
            'You can reach our customer support via the Contact Us page, email, or by calling our support hotline.',
      },
      {
        'Question': 'Can I cancel or modify my order after placing it?',
        'Answer':
            'Orders can be modified or canceled within 1 hour of placement. Please contact our support team immediately for assistance.',
      },
      {
        'Question': 'Do you offer gift wrapping?',
        'Answer':
            'Yes, gift wrapping options are available at checkout for an additional fee.',
      },
    ];

    return Scaffold(
      drawer: BookstoreHeader.buildDrawer(context), // Add the drawer here
      body: Column(
        children: [
          const BookstoreHeader(),
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
          const BookstoreFooter(),
        ],
      ),
    );
  }
}
