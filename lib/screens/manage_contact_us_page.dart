import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../models/enums.dart';
import '../services/contact_dao.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../widgets/loader.dart';
import '../style/responsive_helper.dart';
import '../style/theme.dart';

class ManageContactUsPage extends StatefulWidget {
  const ManageContactUsPage({super.key});
  static const String routeName = '/manage-contact-us';

  @override
  State<ManageContactUsPage> createState() => _ManageContactUsPageState();
}

class _ManageContactUsPageState extends State<ManageContactUsPage> {
  final ContactDao _contactDao = ContactDao();
  List<Contact> contacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final query = _contactDao.getContactList();
    query.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final List<Contact> loadedContacts = [];

        data.forEach((key, value) {
          final contact = Contact.fromJson(value as Map<dynamic, dynamic>);
          loadedContacts.add(contact);
        });

        setState(() {
          contacts = loadedContacts;
          isLoading = false;
        });
      } else {
        setState(() {
          contacts = [];
          isLoading = false;
        });
      }
    });
  }

  Future<void> _replyToContact(Contact contact) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: contact.email,
      queryParameters: {
        'subject': 'Re: ${contact.subject}',
        'body':
            'Dear ${contact.name},\n\nThank you for contacting us.\n\nBest regards,\nAdmin Team',
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
        // Update status to inProgress after sending email
        _updateContactStatus(contact, ContactStatus.inProgress);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch email client')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _updateContactStatus(
    Contact contact,
    ContactStatus newStatus,
  ) async {
    final updatedContact = Contact(
      name: contact.name,
      email: contact.email,
      subject: contact.subject,
      message: contact.message,
      createdAt: contact.createdAt,
      status: newStatus,
      responseMessage: contact.responseMessage,
      respondedAt: contact.respondedAt,
      responseBy: contact.responseBy,
    );

    // Find the contact key in Firebase
    final query = _contactDao.getContactList();
    final snapshot = await query.get();
    if (snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final currentContact = Contact.fromJson(value as Map<dynamic, dynamic>);
        if (currentContact.email == contact.email &&
            currentContact.createdAt == contact.createdAt) {
          _contactDao.updateContact(key.toString(), updatedContact);
        }
      });
    }
  }

  void _showStatusUpdateDialog(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Status',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ContactStatus.values.map((status) {
            return ListTile(
              title: Text(
                status.name,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
              selected: contact.status == status,
              onTap: () {
                _updateContactStatus(contact, status);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: isLoading
                ? const Center(child: Loader())
                : contacts.isEmpty
                    ? Center(
                        child: Text(
                          'No contact submissions yet',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: ResponsiveHelper.getAdaptivePadding(context),
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          return _buildContactCard(contact);
                        },
                      ),
          ),
          Footer(),
        ],
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          contact.subject,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'From: ${contact.name} (${contact.email})',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
            Text(
              'Status: ${contact.status.name}',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                color: contact.status == ContactStatus.new_
                    ? AppColors.error
                    : contact.status == ContactStatus.responded
                        ? AppColors.success
                        : AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: ResponsiveHelper.getAdaptivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message:',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Text(
                  contact.message,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _replyToContact(contact),
                        icon: Icon(
                          Icons.email,
                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                        ),
                        label: Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showStatusUpdateDialog(contact),
                        icon: Icon(
                          Icons.update,
                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                        ),
                        label: Text(
                          'Update Status',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
