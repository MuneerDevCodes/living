import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:living/models/product_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class ProductModal extends StatefulWidget {
  final Product? product;
  final Future<void> Function(Product product) onSubmit;

  const ProductModal({super.key, this.product, required this.onSubmit});

  @override
  State<ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends State<ProductModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _ecoRatingCtrl;
  late TextEditingController _imageUrlCtrl;
  late TextEditingController _priceCtrl;

  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  Uint8List? _webImage;
  String? _imageBase64;

  late Category? _selectedCategory;
  List<Category> _categories = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _ecoRatingCtrl = TextEditingController(text: p?.ecoRating.toString() ?? '');
    _imageUrlCtrl = TextEditingController(text: p?.imageUrl ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _selectedCategory = p?.category;
    _fetchCategories();
    if (p != null && p.imageUrl.isNotEmpty) {
      _imageBase64 = p.imageUrl;
      try {
        _webImage = base64Decode(p.imageUrl);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _ecoRatingCtrl.dispose();
    _imageUrlCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imageBase64 = base64Encode(bytes);
          _imageUrlCtrl.text = _imageBase64!;
        });
      } else {
        setState(() {
          _selectedImage = File(picked.path);
          _imageBase64 = base64Encode(_selectedImage!.readAsBytesSync());
          _imageUrlCtrl.text = _imageBase64!;
        });
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final ref = FirebaseDatabase.instance.ref('categories');
      final snapshot = await ref.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final categories = data.values.map((v) => Category.fromJson(Map<String, dynamic>.from(v))).toList();
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Widget _imagePreview() {
    if (_webImage != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(_webImage!, fit: BoxFit.cover),
        ),
      );
    } else if (_selectedImage != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_selectedImage!, fit: BoxFit.cover),
        ),
      );
    } else {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              color: AppColors.mutedText,
              size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.5,
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
            Text(
              'Add Photo',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
    Widget? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
              vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.6,
            ),
          ),
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
          ),
          validator: validator,
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category *',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        DropdownButtonFormField<Category>(
          value: _selectedCategory,
          items: _categories.map((cat) => DropdownMenuItem(
            value: cat,
            child: Row(
              children: [
                Icon(Icons.category, color: AppColors.primary, size: 20),
                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
              ],
            ),
          )).toList(),
          onChanged: (cat) {
            setState(() => _selectedCategory = cat);
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8,
              vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.6,
            ),
          ),
          validator: (v) => v == null ? 'Please select a category' : null,
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
      ],
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        final product = Product(
          name: _nameCtrl.text.trim(),
          category: _selectedCategory!,
          description: _descCtrl.text.trim(),
          price: double.tryParse(_priceCtrl.text) ?? 0.0,
          ecoRating: double.tryParse(_ecoRatingCtrl.text) ?? 0.0,
          imageUrl: _imageBase64 ?? '',
          ratings: widget.product?.ratings ?? Ratings(average: 0.0, count: 0),
          reviews: widget.product?.reviews ?? {},
        );
        
        await widget.onSubmit(product);
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null ? 'Product added successfully!' : 'Product updated successfully!',
              style: TextStyle(color: AppColors.white),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: ResponsiveHelper.getScreenWidth(context) * 0.9,
        constraints: BoxConstraints(
          maxHeight: ResponsiveHelper.getScreenHeight(context) * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context)),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.product == null ? Icons.add_shopping_cart : Icons.edit,
                    color: AppColors.white,
                    size: ResponsiveHelper.getAdaptiveIconSize(context) * 1.2,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                  Expanded(
                    child: Text(
                      widget.product == null ? 'Add New Product' : 'Edit Product',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppColors.white),
                  ),
                ],
              ),
            ),
            
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: _imagePreview(),
                            ),
                            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                            Text(
                              'Tap to add product image',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                      
                      // Form Fields
                      _buildFormField(
                        controller: _nameCtrl,
                        label: 'Product Name *',
                        hintText: 'Enter product name',
                        prefixIcon: Icon(Icons.shopping_bag, color: AppColors.primary),
                        validator: (v) => v?.trim().isEmpty == true ? 'Product name is required' : null,
                      ),
                      
                      _buildCategoryDropdown(),
                      
                      _buildFormField(
                        controller: _descCtrl,
                        label: 'Description *',
                        hintText: 'Describe the product and its eco-friendly features',
                        maxLines: 4,
                        prefixIcon: Icon(Icons.description, color: AppColors.primary),
                        validator: (v) => v?.trim().isEmpty == true ? 'Description is required' : null,
                      ),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: _priceCtrl,
                              label: 'Price (\$) *',
                              hintText: '0.00',
                              keyboardType: TextInputType.number,
                              prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
                              validator: (v) {
                                if (v?.trim().isEmpty == true) return 'Price is required';
                                final price = double.tryParse(v!);
                                if (price == null || price < 0) return 'Enter a valid price';
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                          Expanded(
                            child: _buildFormField(
                              controller: _ecoRatingCtrl,
                              label: 'Eco Rating (1-5) *',
                              hintText: '4.5',
                              keyboardType: TextInputType.number,
                              prefixIcon: Icon(Icons.eco, color: AppColors.success),
                              validator: (v) {
                                if (v?.trim().isEmpty == true) return 'Eco rating is required';
                                final rating = double.tryParse(v!);
                                if (rating == null || rating < 1 || rating > 5) {
                                  return 'Enter rating between 1-5';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context)),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: AppColors.borderLight),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.product == null ? Icons.add : Icons.save,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                                SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                                Text(
                                  widget.product == null ? 'Add Product' : 'Save Changes',
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}