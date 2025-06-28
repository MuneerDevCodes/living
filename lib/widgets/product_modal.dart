import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:living/models/product_model.dart';
import 'package:firebase_database/firebase_database.dart';

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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: SizedBox(
                width: 150,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    color: Colors.grey[200],
                    child: _webImage != null
                        ? Image.memory(_webImage!, fit: BoxFit.fill)
                        : _selectedImage != null
                            ? Image.file(_selectedImage!, fit: BoxFit.fill)
                            : const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey,
                              ),
                  ),
                ),
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
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
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      content: SizedBox(
        width: 400,
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
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                ),
                DropdownButtonFormField<Category>(
                  value: _selectedCategory,
                  items: _categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.name),
                        ),
                      )
                      .toList(),
                  onChanged: (cat) => setState(() => _selectedCategory = cat),
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (v) => v == null ? 'Select category' : null,
                ),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                  validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
                ),
                TextFormField(
                  controller: _ecoRatingCtrl,
                  decoration: const InputDecoration(labelText: 'Eco Rating'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Enter eco rating' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.product == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}