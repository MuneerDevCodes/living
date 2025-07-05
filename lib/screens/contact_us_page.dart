import 'package:flutter/material.dart';
import 'package:living/models/contact_us_model.dart';
import 'package:living/services/contact_dao.dart';
import 'package:living/models/enums.dart';
import 'package:living/widgets/alert_success.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

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
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Center(
              child: _isSubmitting
                  ? const Loader()
                  : SingleChildScrollView(
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
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Get in Touch',
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 22),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                                  Text(
                                    'We\'d love to hear from you!',
                                    style: TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
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
                                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                                  _buildFormFields(),
                                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                                  _buildSubmitButton(),
                                ],
                              ),
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

  Widget _buildFormFields() {
    final fields = [
      {
        'ctrl': _nameController,
        'label': 'Name',
        'icon': Icons.person,
        'validator': (String? v) =>
            v == null || v.isEmpty ? 'Please enter your name' : null,
      },
      {
        'ctrl': _emailController,
        'label': 'Email',
        'icon': Icons.email,
        'validator': (String? v) {
          if (v == null || v.isEmpty) {
            return 'Please enter your email';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
            return 'Please enter a valid email address';
          }
          return null;
        },
      },
      {
        'ctrl': _subjectController,
        'label': 'Subject',
        'icon': Icons.subject,
        'validator': (String? v) =>
            v == null || v.isEmpty ? 'Please enter a subject' : null,
      },
    ];

    return Column(
      children: [
        ...fields.map((f) => Padding(
          padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.6),
          child: TextFormField(
            controller: f['ctrl'] as TextEditingController,
            decoration: InputDecoration(
              labelText: f['label'] as String,
              prefixIcon: Icon(
                f['icon'] as IconData,
                size: ResponsiveHelper.getAdaptiveIconSize(context),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                ),
              ),
              labelStyle: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            ),
            validator: f['validator'] as String? Function(String?)?,
          ),
        )).toList(),
        Padding(
          padding: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.6),
          child: TextFormField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(top: ResponsiveHelper.getAdaptiveSpacing(context)),
                child: Icon(
                  Icons.message,
                  size: ResponsiveHelper.getAdaptiveIconSize(context),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
                ),
              ),
              labelStyle: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            ),
            maxLines: 4,
            validator: (v) =>
                v == null || v.isEmpty ? 'Please enter your message' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          padding: ResponsiveHelper.getAdaptivePadding(context),
        ),
        child: _isSubmitting
            ? SizedBox(
                width: ResponsiveHelper.getAdaptiveIconSize(context),
                height: ResponsiveHelper.getAdaptiveIconSize(context),
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Send Message',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
