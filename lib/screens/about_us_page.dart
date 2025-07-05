import 'package:flutter/material.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';

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
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.getAdaptivePadding(context),
                child: Container(
                  constraints: ResponsiveHelper.getFlexibleConstraints(context),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context),
                      ),
                    ),
                    child: Padding(
                      padding: ResponsiveHelper.getCardPadding(context),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'About Sustainable Living Guide',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 22),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                          Text(
                           'Sustainable Living Guide is your all-in-one platform for adopting eco-friendly habits and making a positive impact on the planet. Our mission is to simplify sustainable living by providing tools to track your carbon footprint, discover green products, and connect with a like-minded community.',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 1.5),
                          Text(
                            'Meet Our Team',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.6),
                          ...teamMembers.map(
                            (m) => Padding(
                              padding: ResponsiveHelper.getVerticalPadding(context),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: ResponsiveHelper.getAdaptiveIconSize(context),
                                  child: Text(
                                    m['name']![0],
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  m['name']!,
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${m['role']}\n${m['bio']}',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                  ),
                                ),
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
          const Footer(),
        ],
      ),
    );
  }
}
