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
  final void Function(Product product) onSubmit;

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

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _ecoRatingCtrl = TextEditingController(text: p?.ecoRating.toString() ?? '');
    _imageUrlCtrl = TextEditingController(text: p?.imageUrl ?? '');
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
    final snap = await FirebaseDatabase.instance.ref('categories').get();
    final data = snap.value;
    if (data != null) {
      final map = Map<String, dynamic>.from(data as dynamic);
      setState(() {
        _categories =
            map.values
                .map((v) => Category.fromJson(Map<String, dynamic>.from(v)))
                .toList();
        if (_selectedCategory == null && _categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      });
    }
  }

  Widget _imagePreview() {
    return FormField<String>(
      validator: (value) {
        if (_imageBase64 == null || _imageBase64!.isEmpty) {
          return 'Please select an image';
        }
        return null;
      },
      builder: (field) {
        final imageSize = ResponsiveHelper.getAdaptiveImageSize(context) * 3;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: SizedBox(
                width: imageSize,
                height: imageSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getAdaptiveBorderRadius(context),
                  ),
                  child: Container(
                    color: AppColors.borderLight,
                    child: _webImage != null
                        ? Semantics(
                            label: 'Product image',
                            image: true,
                            child: Image.memory(_webImage!, fit: BoxFit.cover),
                          )
                        : _selectedImage != null
                            ? Semantics(
                                label: 'Product image',
                                image: true,
                                child: Image.file(_selectedImage!, fit: BoxFit.cover),
                              )
                            : Icon(
                                Icons.camera_alt,
                                size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                                color: AppColors.mutedText,
                              ),
                  ),
                ),
              ),
            ),
            if (field.hasError)
              Padding(
                padding: EdgeInsets.only(top: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 13),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        name: _nameCtrl.text,
        category: _selectedCategory!,
        description: _descCtrl.text,
        price: double.tryParse(_priceCtrl.text) ?? 0.0,
        ecoRating: double.tryParse(_ecoRatingCtrl.text) ?? 0.0,
        imageUrl: _imageBase64!,
      );
      widget.onSubmit(product);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.product == null ? 'Add Product' : 'Edit Product',
        style: TextStyle(
          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: ResponsiveHelper.getScreenWidth(context) * 0.8,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: _imagePreview(),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                _buildFormFields(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            ),
          ),
        ),
        Semantics(
          label: 'Submit product',
          button: true,
          child: ElevatedButton(
            onPressed: _submit,
            child: Text(
              widget.product == null ? 'Add' : 'Save',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: 'Product Name',
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
          validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        DropdownButtonFormField<Category>(
          value: _selectedCategory,
          items: _categories
              .map(
                (cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (cat) => setState(() => _selectedCategory = cat),
          decoration: InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.6,
              ),
            ),
            labelStyle: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
            ),
          ),
          validator: (v) => v == null ? 'Select category' : null,
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        TextFormField(
          controller: _descCtrl,
          decoration: InputDecoration(
            labelText: 'Description',
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
          maxLines: 3,
          validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        TextFormField(
          controller: _ecoRatingCtrl,
          decoration: InputDecoration(
            labelText: 'Eco Rating (0.0 - 5.0)',
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
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter eco rating';
            final rating = double.tryParse(v);
            if (rating == null || rating < 0 || rating > 5) {
              return 'Enter a valid rating between 0.0 and 5.0';
            }
            return null;
          },
        ),
      ],
    );
  }
}