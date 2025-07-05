import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../models/enums.dart';
import '../services/contact_dao.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';

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
      builder:
          (context) => AlertDialog(
            title: const Text('Update Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  ContactStatus.values.map((status) {
                    return ListTile(
                      title: Text(status.name),
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
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : contacts.isEmpty
                    ? const Center(child: Text('No contact submissions yet'))
                    : ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ExpansionTile(
                            title: Text(
                              contact.subject,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'From: ${contact.name} (${contact.email})',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  'Status: ${contact.status.name}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        contact.status == ContactStatus.new_
                                            ? Colors.red
                                            : contact.status ==
                                                ContactStatus.responded
                                            ? Colors.green
                                            : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Message:',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      contact.message,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Submitted: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(contact.createdAt))}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed:
                                              () => _showStatusUpdateDialog(
                                                contact,
                                              ),
                                          icon: const Icon(Icons.update),
                                          label: const Text('Update Status'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed:
                                              () => _replyToContact(contact),
                                          icon: const Icon(Icons.reply),
                                          label: const Text('Reply'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
          const Footer(),
        ],
      ),
    );
  }
}
