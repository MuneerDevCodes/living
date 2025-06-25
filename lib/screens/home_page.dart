import 'package:flutter/material.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: BookstoreHeader.buildDrawer(context),
      body: Column(
        children: [
          const BookstoreHeader(),
          Expanded(
            child: Stack(
              children: [
                ListView(
                  children: [
                    ListTile(
                      title: const Text('Introduction to Sustainable Living'),
                      subtitle: const Text(
                        'Learn the basics of sustainable living.',
                      ),
                    ),
                    ListTile(
                      title: const Text('Eco-Friendly Practices'),
                      subtitle: const Text(
                        'Discover eco-friendly practices for daily life.',
                      ),
                    ),
                    ListTile(
                      title: const Text('Sustainable Products'),
                      subtitle: const Text(
                        'Find sustainable products for your home.',
                      ),
                    ),
                    ListTile(
                      title: const Text('Community Initiatives'),
                      subtitle: const Text(
                        'Get involved in local sustainability initiatives.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const BookstoreFooter(),
        ],
      ),
    );
  }
}
