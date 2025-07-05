import 'package:flutter/material.dart';
import 'package:living/models/educational_content_model.dart';
import 'package:living/services/educational_content_dao.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/alert_success.dart';

class ManageEducationalContentPage extends StatefulWidget {
  const ManageEducationalContentPage({super.key});

  @override
  State<ManageEducationalContentPage> createState() => _ManageEducationalContentPageState();
}

class _ManageEducationalContentPageState extends State<ManageEducationalContentPage> {
  List<EducationalContent> content = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      content = await EducationalContentDAO.getPublishedContent();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to load educational content: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Educational Content'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Loader()
          : _buildContentList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContentDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContentList() {
    if (content.isEmpty) {
      return const Center(
        child: Text(
          'No educational content available. Add your first article!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: content.length,
      itemBuilder: (context, index) {
        final item = content[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getContentTypeColor(item.contentType),
              child: Icon(
                _getContentTypeIcon(item.contentType),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${item.contentType}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'By ${item.author}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditContentDialog(item);
                } else if (value == 'delete') {
                  _deleteContent(item);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Color _getContentTypeColor(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'article':
        return Colors.blue;
      case 'video':
        return Colors.red;
      case 'infographic':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getContentTypeIcon(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'article':
        return Icons.article;
      case 'video':
        return Icons.play_circle;
      case 'infographic':
        return Icons.image;
      default:
        return Icons.description;
    }
  }

  void _showAddContentDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final contentController = TextEditingController();
    final authorController = TextEditingController();
    final imageUrlController = TextEditingController();
    final videoUrlController = TextEditingController();
    final tagsController = TextEditingController();
    String selectedCategory = 'Climate Change';
    String selectedContentType = 'Article';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Educational Content'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                value: selectedCategory,
                items: [
                  'Climate Change',
                  'Sustainable Living',
                  'Renewable Energy',
                  'Waste Management',
                  'Biodiversity',
                  'Water Conservation',
                  'Sustainable Agriculture',
                ].map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) => selectedCategory = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Content Type'),
                value: selectedContentType,
                items: ['Article', 'Video', 'Infographic'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => selectedContentType = value!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL (optional)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: videoUrlController,
                decoration: const InputDecoration(labelText: 'Video URL (optional)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  hintText: 'sustainability, climate, eco-friendly',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 6,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  contentController.text.isNotEmpty &&
                  authorController.text.isNotEmpty) {
                final tags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();

                final educationalContent = EducationalContent(
                  key: '',
                  title: titleController.text,
                  description: descriptionController.text,
                  category: selectedCategory,
                  content: contentController.text,
                  author: authorController.text,
                  publishDate: DateTime.now(),
                  tags: tags,
                  imageUrl: imageUrlController.text,
                  contentType: selectedContentType.toLowerCase(),
                  videoUrl: videoUrlController.text.isEmpty ? null : videoUrlController.text,
                );

                try {
                  await EducationalContentDAO.addEducationalContent(educationalContent);
                  Navigator.pop(context);
                  _loadData();
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => const AlertSuccess('Content added successfully!'),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertError('Failed to add content: $e'),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditContentDialog(EducationalContent item) {
    final titleController = TextEditingController(text: item.title);
    final descriptionController = TextEditingController(text: item.description);
    final contentController = TextEditingController(text: item.content);
    final authorController = TextEditingController(text: item.author);
    final imageUrlController = TextEditingController(text: item.imageUrl);
    final videoUrlController = TextEditingController(text: item.videoUrl ?? '');
    final tagsController = TextEditingController(text: item.tags.join(', '));
    String selectedCategory = item.category;
    String selectedContentType = item.contentType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Educational Content'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category'),
                value: selectedCategory,
                items: [
                  'Climate Change',
                  'Sustainable Living',
                  'Renewable Energy',
                  'Waste Management',
                  'Biodiversity',
                  'Water Conservation',
                  'Sustainable Agriculture',
                ].map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) => selectedCategory = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Content Type'),
                value: selectedContentType,
                items: ['Article', 'Video', 'Infographic'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => selectedContentType = value!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL (optional)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: videoUrlController,
                decoration: const InputDecoration(labelText: 'Video URL (optional)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  hintText: 'sustainability, climate, eco-friendly',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 6,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  contentController.text.isNotEmpty &&
                  authorController.text.isNotEmpty) {
                final tags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();

                final updatedContent = EducationalContent(
                  key: item.key,
                  title: titleController.text,
                  description: descriptionController.text,
                  category: selectedCategory,
                  content: contentController.text,
                  author: authorController.text,
                  publishDate: item.publishDate,
                  tags: tags,
                  imageUrl: imageUrlController.text,
                  contentType: selectedContentType.toLowerCase(),
                  videoUrl: videoUrlController.text.isEmpty ? null : videoUrlController.text,
                );

                try {
                  await EducationalContentDAO.updateEducationalContent(updatedContent);
                  Navigator.pop(context);
                  _loadData();
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => const AlertSuccess('Content updated successfully!'),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertError('Failed to update content: $e'),
                    );
                  }
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteContent(EducationalContent item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await EducationalContentDAO.deleteEducationalContent(item.key);
                Navigator.pop(context);
                _loadData();
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => const AlertSuccess('Content deleted successfully!'),
                  );
                }
              } catch (e) {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertError('Failed to delete content: $e'),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 