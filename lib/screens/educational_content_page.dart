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
          // Intro banner for user guidance
          _buildIntroBanner(),
          Expanded(
            child: Stack(
              children: [
                if (isLoading) const Positioned.fill(child: Loader()),
                Column(
                  children: [
                    // Section heading for filters
                    _buildSectionHeading('Filter by Category'),
                    _buildFilters(),
                    // Section heading for content
                    _buildSectionHeading('Educational Content'),
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

  Widget _buildIntroBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.info.withOpacity(0.08),
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.7,
        horizontal: ResponsiveHelper.getAdaptiveSpacing(context)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb, color: AppColors.info, size: 28),
          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
          Expanded(
            child: Text(
              'Explore articles, videos, and infographics to learn about sustainability. Use the filters to find topics you care about. Tap any card for details and actionable steps!',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 15),
                color: AppColors.primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: ResponsiveHelper.getAdaptiveSpacing(context),
        top: ResponsiveHelper.getAdaptiveSpacing(context) * 0.7,
        bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: AppColors.secondaryText, size: 40),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
            Text(
              'No educational content found for this category.',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                color: AppColors.secondaryText,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
            Text(
              'Try changing the filters or check back later for new content.',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 13),
                color: AppColors.secondaryText,
              ),
            ),
          ],
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
                      color: AppColors.success.withValues(alpha: 0.1),
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
                      color: AppColors.info.withValues(alpha: 0.1),
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
                  backgroundColor: AppColors.info.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: AppColors.info,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                  ),
                )).toList(),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Divider(),
              // How to Take Action section
              _buildActionSection(item),
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

  // Actionable tips based on category/type
  Widget _buildActionSection(EducationalContent item) {
    final tips = _getActionTips(item);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to Take Action',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 15),
            color: AppColors.success,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.3),
        ...tips.map((tip) => Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(tip, style: TextStyle(fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 13)))),
            ],
          ),
        )),
      ],
    );
  }

  List<String> _getActionTips(EducationalContent item) {
    switch (item.category) {
      case 'Climate Change':
        return [
          'Share what you learned with friends or family.',
          'Take small steps to reduce your carbon footprint.',
          'Stay informed and support climate-friendly policies.'
        ];
      case 'Sustainable Living':
        return [
          'Try one new sustainable habit this week.',
          'Reduce, reuse, and recycle whenever possible.',
          'Encourage others to join you in sustainable actions.'
        ];
      case 'Renewable Energy':
        return [
          'Switch to renewable energy sources if available.',
          'Advocate for clean energy in your community.',
          'Educate yourself about local energy options.'
        ];
      case 'Waste Management':
        return [
          'Sort your waste and recycle properly.',
          'Compost organic waste if possible.',
          'Reduce single-use plastics in your daily life.'
        ];
      case 'Biodiversity':
        return [
          'Support local conservation efforts.',
          'Plant native species in your garden.',
          'Learn about local wildlife and habitats.'
        ];
      case 'Water Conservation':
        return [
          'Fix leaks and use water-saving devices.',
          'Take shorter showers and turn off the tap when not needed.',
          'Educate others about the importance of water conservation.'
        ];
      case 'Sustainable Agriculture':
        return [
          'Buy local and seasonal produce.',
          'Reduce food waste by planning meals.',
          'Support farmers who use sustainable practices.'
        ];
      default:
        return [
          'Reflect on what you learned and share it with others.',
          'Look for ways to apply this knowledge in your daily life.'
        ];
    }
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