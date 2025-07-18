import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/product_model.dart';
import '../services/admin_service.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../widgets/loader.dart';
import '../style/responsive_helper.dart';
import '../style/theme.dart';
import 'package:living/services/validate.dart';

/// ManageCategoryPage allows admins to manage product categories, using responsive and theme-driven design.
class ManageCategoryPage extends StatefulWidget {
  const ManageCategoryPage({super.key});
  static const String routeName = '/manage-categories';

  @override
  State<ManageCategoryPage> createState() => _ManageCategoryPageState();
}

class _ManageCategoryPageState extends State<ManageCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final AdminService adminService = AdminService();
  String? _editingId;
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await adminService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isLoading = false;
    });
  }

  void _submit([String? id]) async {
    if (!_isAdmin) return;
    if (!_formKey.currentState!.validate()) return;
    final ref = FirebaseDatabase.instance.ref('categories');
    if (id == null) {
      final newRef = ref.push();
      await newRef.set({'id': newRef.key, 'name': _nameCtrl.text.trim()});
    } else {
      await ref.child(id).set({'id': id, 'name': _nameCtrl.text.trim()});
    }
    _nameCtrl.clear();
    setState(() => _editingId = null);
  }

  void _delete(String id) async {
    if (!_isAdmin) return;
    await FirebaseDatabase.instance.ref('categories/$id').remove();
  }

  void _edit(Category cat) {
    if (!_isAdmin) return;
    _nameCtrl.text = cat.name;
    setState(() => _editingId = cat.id);
  }

  /// Build method for the manage category page, using only ResponsiveHelper and AppTheme/AppColors.
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: Loader()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Padding(
              padding: ResponsiveHelper.getAdaptivePadding(context),
              child: Column(
                children: [
                  // Only show form section for admin users
                  if (_isAdmin) ...[
                    _buildFormSection(),
                    SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  ],
                  Expanded(
                    child: _buildCategoriesList(),
                  ),
                ],
              ),
            ),
          ),
          Footer(),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Card(
      elevation: 2,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editingId == null ? 'Add New Category' : 'Edit Category',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Category Name',
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
                      validator: validateName,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                  ElevatedButton(
                    onPressed: () => _submit(_editingId),
                    style: ElevatedButton.styleFrom(
                      padding: ResponsiveHelper.getAdaptivePadding(context),
                    ),
                    child: Text(
                      _editingId == null ? 'Add' : 'Save',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      ),
                    ),
                  ),
                  if (_editingId != null) ...[
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                    TextButton(
                      onPressed: () {
                        _nameCtrl.clear();
                        setState(() => _editingId = null);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('categories').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Loader();
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading categories',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
              ),
            ),
          );
        }
        final data = snapshot.data?.snapshot.value;
        if (data == null) {
          return Center(
            child: Text(
              'No categories found.',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
              ),
            ),
          );
        }
        final cats = <Category>[];
        final map = Map<String, dynamic>.from(data as dynamic);
        map.forEach((key, value) {
          cats.add(
            Category.fromJson(Map<String, dynamic>.from(value)),
          );
        });
        return ListView.builder(
          itemCount: cats.length,
          itemBuilder: (context, i) {
            final cat = cats[i];
            return Card(
              margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getAdaptiveBorderRadius(context),
                ),
              ),
              child: ListTile(
                title: Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: _isAdmin ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: AppColors.info,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                      ),
                      onPressed: () => _edit(cat),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: AppColors.error,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                      ),
                      onPressed: () => _delete(cat.id),
                    ),
                  ],
                ) : null,
              ),
            );
          },
        );
      },
    );
  }
}
