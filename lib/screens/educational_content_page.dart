import 'package:flutter/material.dart';
import 'package:living/models/educational_content_model.dart';
import 'package:living/services/educational_content_dao.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class EducationalContentPage extends StatefulWidget {
  const EducationalContentPage({super.key});

  @override
  State<EducationalContentPage> createState() => _EducationalContentPageState();
}

class _EducationalContentPageState extends State<EducationalContentPage> {
  List<EducationalContent> content = [];
  bool isLoading = true;
  String selectedCategory = 'All';
  String selectedContentType = 'All';

  final List<String> categories = [
    'All',
    'Climate Change',
    'Sustainable Living',
    'Renewable Energy',
    'Waste Management',
    'Biodiversity',
    'Water Conservation',
    'Sustainable Agriculture',
  ];

  final List<String> contentTypes = [
    'All',
    'Article',
    'Video',
    'Infographic',
  ];

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

  List<EducationalContent> get filteredContent {
    return content.where((item) {
      final categoryMatch = selectedCategory == 'All' || item.category == selectedCategory;
      final typeMatch = selectedContentType == 'All' || item.contentType == selectedContentType;
      return categoryMatch && typeMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Stack(
              children: [
                if (isLoading) const Positioned.fill(child: Loader()),
                Column(
                  children: [
                    _buildFilters(),
                    Expanded(
                      child: _buildContentList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Footer(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContentDialog,
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.white,
        child: Icon(
          Icons.add,
          size: ResponsiveHelper.getAdaptiveIconSize(context),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: ResponsiveHelper.getScreenHeight(context) * 0.08,
      padding: ResponsiveHelper.getVerticalPadding(context),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: ResponsiveHelper.getHorizontalPadding(context),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Container(
            margin: EdgeInsets.only(right: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category;
                });
              },
              selectedColor: AppColors.success,
              checkmarkColor: AppColors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentList() {
    if (filteredContent.isEmpty) {
      return Center(
        child: Text(
          'No educational content found for this category.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      itemCount: filteredContent.length,
      itemBuilder: (context, index) {
        final item = filteredContent[index];
        return _buildContentCard(item);
      },
    );
  }

  Widget _buildContentCard(EducationalContent item) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
      child: InkWell(
        onTap: () => _showContentDetail(item),
        child: Padding(
          padding: ResponsiveHelper.getAdaptivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getContentTypeColor(item.contentType),
                    child: Icon(
                      _getContentTypeIcon(item.contentType),
                      color: AppColors.white,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                            color: AppColors.secondaryText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.secondaryText,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    'By ${item.author}',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.secondaryText,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
                  Icon(
                    Icons.calendar_today,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.secondaryText,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    item.publishDate.toString().split(' ')[0],
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
                      vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                      ),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3,
                      vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.3,
                      ),
                    ),
                    child: Text(
                      item.contentType,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContentDetail(EducationalContent item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getContentTypeColor(item.contentType),
                    child: Icon(
                      _getContentTypeIcon(item.contentType),
                      color: AppColors.white,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'By ${item.author}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
                        Text(
                          item.publishDate.toString().split(' ')[0],
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                item.description,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                item.content,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Wrap(
                spacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
                children: item.tags.map((tag) => Chip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.info,
                    ),
                  ),
                  backgroundColor: AppColors.info.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: AppColors.info,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
        ],
      ),
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
                items: categories.where((cat) => cat != 'All').map((category) => DropdownMenuItem(
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
} 