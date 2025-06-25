import 'package:flutter/material.dart';
import 'package:living/models/contact.dart';
import 'package:living/services/contact_dao.dart';
import 'package:living/models/enums.dart';
import 'package:living/widgets/alert_success.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/loader.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});
  static const String routeName = '/contact-us';

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _submitted = false;

  final contactDao = ContactDao();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
        _submitted = false;
      });
      try {
        final contact = Contact(
          name: _nameController.text,
          email: _emailController.text,
          subject: _subjectController.text,
          message: _messageController.text,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          status: ContactStatus.new_,
          responseMessage: null,
          respondedAt: null,
          responseBy: null,
        );

        contactDao.saveContact(contact);

        setState(() {
          _isSubmitting = false;
          _submitted = true;
        });

        _nameController.clear();
        _emailController.clear();
        _subjectController.clear();
        _messageController.clear();
      } catch (e) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to submit: ${e.toString()}';
          _submitted = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: BookstoreHeader.buildDrawer(context), // Add the drawer here
      body: Column(
        children: [
          const BookstoreHeader(),
          Expanded(
            child: Center(
              child:
                  _isSubmitting
                      ? const Loader()
                      : SingleChildScrollView(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 22,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Get in Touch',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'We\'d love to hear from you!',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (_errorMessage != null)
                                      AlertError(
                                        _errorMessage!,
                                        onClose: () {
                                          setState(() => _errorMessage = null);
                                        },
                                      ),
                                    if (_submitted)
                                      AlertSuccess(
                                        'Thank you for contacting us. We will respond shortly.',
                                        onClose: () {
                                          setState(() => _submitted = false);
                                        },
                                      ),
                                    ...[
                                      {
                                        'ctrl': _nameController,
                                        'label': 'Name',
                                        'icon': Icons.person,
                                        'validator':
                                            (String? v) =>
                                                v == null || v.isEmpty
                                                    ? 'Please enter your name'
                                                    : null,
                                      },
                                      {
                                        'ctrl': _emailController,
                                        'label': 'Email',
                                        'icon': Icons.email,
                                        'validator': (String? v) {
                                          if (v == null || v.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                          ).hasMatch(v)) {
                                            return 'Please enter a valid email address';
                                          }
                                          return null;
                                        },
                                      },
                                      {
                                        'ctrl': _subjectController,
                                        'label': 'Subject',
                                        'icon': Icons.subject,
                                        'validator':
                                            (String? v) =>
                                                v == null || v.isEmpty
                                                    ? 'Please enter a subject'
                                                    : null,
                                      },
                                    ].map(
                                      (f) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: TextFormField(
                                          controller:
                                              f['ctrl']
                                                  as TextEditingController,
                                          decoration: InputDecoration(
                                            labelText: f['label'] as String,
                                            prefixIcon: Icon(
                                              f['icon'] as IconData,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            isDense: true,
                                          ),
                                          validator:
                                              f['validator']
                                                  as String? Function(String?),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 18,
                                      ),
                                      child: TextFormField(
                                        controller: _messageController,
                                        decoration: InputDecoration(
                                          labelText: 'Message',
                                          alignLabelWithHint: true,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          isDense: true,
                                          prefixIcon: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 16,
                                            ),
                                            child: Icon(Icons.message),
                                          ),
                                        ),
                                        maxLines: 4,
                                        validator:
                                            (v) =>
                                                v == null || v.isEmpty
                                                    ? 'Please enter your message'
                                                    : null,
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon:
                                            _isSubmitting
                                                ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: Loader(),
                                                )
                                                : const Icon(Icons.send),
                                        label: Text(
                                          _isSubmitting
                                              ? 'Sending...'
                                              : 'Send Message',
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                        onPressed:
                                            _isSubmitting ? null : _submitForm,
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
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
          ),
          const BookstoreFooter(),
        ],
      ),
    );
  }
}
