import 'package:flutter/material.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  String selectedCategory = 'All';
  List<String> categories = ['All', 'Nature', 'Sustainability', 'Community', 'Events'];

  // Sample gallery items
  List<Map<String, dynamic>> galleryItems = [
    {
      'id': '1',
      'title': 'Community Garden',
      'description': 'Our local community garden thriving with organic vegetables',
      'imageUrl': 'https://via.placeholder.com/300x200',
      'category': 'Community',
      'likes': 24,
      'comments': 8,
    },
    {
      'id': '2',
      'title': 'Solar Panel Installation',
      'description': 'New solar panels installed at the community center',
      'imageUrl': 'https://via.placeholder.com/300x200',
      'category': 'Sustainability',
      'likes': 31,
      'comments': 12,
    },
    {
      'id': '3',
      'title': 'Beach Cleanup',
      'description': 'Volunteers cleaning up the local beach',
      'imageUrl': 'https://via.placeholder.com/300x200',
      'category': 'Events',
      'likes': 45,
      'comments': 15,
    },
    {
      'id': '4',
      'title': 'Urban Forest',
      'description': 'New trees planted in the city center',
      'imageUrl': 'https://via.placeholder.com/300x200',
      'category': 'Nature',
      'likes': 28,
      'comments': 6,
    },
  ];

  List<Map<String, dynamic>> get filteredItems {
    if (selectedCategory == 'All') {
      return galleryItems;
    }
    return galleryItems.where((item) => item['category'] == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Column(
              children: [
                _buildCategoryFilter(),
                Expanded(
                  child: _buildGalleryGrid(),
                ),
              ],
            ),
          ),
          Footer(),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: ResponsiveHelper.getBottomNavHeight(context) + 12,
        ),
        child: FloatingActionButton(
          onPressed: _showAddPhotoDialog,
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
          child: Icon(
            Icons.add_a_photo,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
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

  Widget _buildGalleryGrid() {
    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          'No photos found for this category.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.getScreenWidth(context) > 600 ? 3 : 2,
        crossAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
        mainAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildGalleryItem(item);
      },
    );
  }

  Widget _buildGalleryItem(Map<String, dynamic> item) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _showPhotoDetail(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(ResponsiveHelper.getAdaptiveBorderRadius(context) * 0.2),
                  ),
                  child: Image.network(
                    item['imageUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.borderLight,
                        child: Icon(
                          Icons.image,
                          color: AppColors.mutedText,
                          size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: ResponsiveHelper.getAdaptivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'],
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    item['description'],
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.secondaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
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
                          item['category'],
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 10),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.favorite,
                        size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.8,
                        color: AppColors.mutedText,
                      ),
                      SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                      Text(
                        '${item['likes']}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 10),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoDetail(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          item['title'],
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
              Container(
                height: ResponsiveHelper.getScreenHeight(context) * 0.3,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getAdaptiveBorderRadius(context),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getAdaptiveBorderRadius(context),
                  ),
                  child: Image.network(
                    item['imageUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image,
                        color: AppColors.mutedText,
                        size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                item['description'],
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.mutedText,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    '${item['likes']} likes',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.secondaryText,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Icon(
                    Icons.comment,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.mutedText,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    '${item['comments']} comments',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
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

  void _showAddPhotoDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();
    String selectedCategory = 'Nature';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Photo to Gallery',
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
                  labelText: 'Photo Title',
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
              TextField(
                controller: imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Image URL',
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
              // Add photo logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Photo added successfully!',
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
              'Add Photo',
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