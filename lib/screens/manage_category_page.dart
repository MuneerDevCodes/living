import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/product_model.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../widgets/loader.dart';

class ManageCategoryPage extends StatefulWidget {
  const ManageCategoryPage({super.key});
  static const String routeName = '/manage-categories';

  @override
  State<ManageCategoryPage> createState() => _ManageCategoryPageState();
}

class _ManageCategoryPageState extends State<ManageCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  String? _editingId;

  void _submit([String? id]) async {
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
    await FirebaseDatabase.instance.ref('categories/$id').remove();
  }

  void _edit(Category cat) {
    _nameCtrl.text = cat.name;
    setState(() => _editingId = cat.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: BookstoreHeader.buildDrawer(context), // Add the drawer here
      body: Column(
        children: [
          const BookstoreHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Category Name',
                            ),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? 'Enter name'
                                        : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _submit(_editingId),
                          child: Text(_editingId == null ? 'Add' : 'Save'),
                        ),
                        if (_editingId != null)
                          TextButton(
                            onPressed: () {
                              _nameCtrl.clear();
                              setState(() => _editingId = null);
                            },
                            child: const Text('Cancel'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder(
                      stream:
                          FirebaseDatabase.instance.ref('categories').onValue,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Loader();
                        }
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Error loading categories'),
                          );
                        }
                        final data = snapshot.data?.snapshot.value;
                        if (data == null) {
                          return const Center(
                            child: Text('No categories found.'),
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
                            return ListTile(
                              title: Text(cat.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _edit(cat),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _delete(cat.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const BookstoreFooter(),
        ],
      ),
    );
  }
}
