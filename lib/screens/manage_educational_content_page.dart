import 'package:flutter/material.dart';
import 'package:living/models/educational_content_model.dart';
import 'package:living/services/educational_content_dao.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

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
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Stack(
              children: [
                if (isLoading) const Positioned.fill(child: Loader()),
                _buildContentList(),
              ],
            ),
          ),
          const Footer(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContentDialog,
        backgroundColor: AppColors.success,
        child: Icon(
          Icons.add,
          color: AppColors.white,
          size: ResponsiveHelper.getAdaptiveIconSize(context),
        ),
      ),
    );
  }

  Widget _buildContentList() {
    if (content.isEmpty) {
      return Center(
        child: Text(
          'No educational content available. Add your first article!',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      itemCount: content.length,
      itemBuilder: (context, index) {
        final item = content[index];
        return Card(
          margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getContentTypeColor(item.contentType),
              child: Icon(
                _getContentTypeIcon(item.contentType),
                color: AppColors.white,
                size: ResponsiveHelper.getAdaptiveIconSize(context),
              ),
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                Row(
                  children: [
                    Text(
                      item.category,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                    Text(
                      '• ${item.contentType}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        color: AppColors.secondaryText,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                    Text(
                      'By ${item.author}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                      ),
                      SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        color: AppColors.error,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                      ),
                      SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
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
        return AppColors.info;
      case 'video':
        return AppColors.error;
      case 'infographic':
        return AppColors.warning;
      default:
        return AppColors.mutedText;
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
        title: Text(
          'Add Educational Content',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
                items: [
                  'Climate Change',
                  'Waste Reduction',
                  'Energy Conservation',
                  'Sustainable Living',
                ].map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                )).toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              DropdownButtonFormField<String>(
                value: selectedContentType,
                decoration: InputDecoration(
                  labelText: 'Content Type',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
                items: [
                  'Article',
                  'Video',
                  'Infographic',
                ].map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                )).toList(),
                onChanged: (value) {
                  selectedContentType = value!;
                },
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              TextField(
                controller: authorController,
                decoration: InputDecoration(
                  labelText: 'Author',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              TextField(
                controller: contentController,
                decoration: InputDecoration(
                  labelText: 'Content',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
                maxLines: 5,
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              TextField(
                controller: imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Image URL (optional)',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              TextField(
                controller: videoUrlController,
                decoration: InputDecoration(
                  labelText: 'Video URL (optional)',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              TextField(
                controller: tagsController,
                decoration: InputDecoration(
                  labelText: 'Tags (comma separated)',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Add content logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Content added successfully!',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text(
              'Add Content',
              style: TextStyle(
                color: AppColors.white,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditContentDialog(EducationalContent content) {
    // Similar to add dialog but with pre-filled values
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Educational Content',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Edit form would go here',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Content updated successfully!',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text(
              'Update',
              style: TextStyle(
                color: AppColors.white,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteContent(EducationalContent content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Content',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${content.title}"?',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete content logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Content deleted successfully!',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.white,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 