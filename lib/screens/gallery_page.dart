import 'package:flutter/material.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:living/widgets/local_image_widget.dart';

/// GalleryPage displays a gallery of community images, using responsive and theme-driven design.
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  String selectedCategory = 'All';
  List<String> categories = ['All', 'Nature', 'Sustainability', 'Community', 'Events'];

  // Sample gallery items (start with some demo data)
  List<Map<String, dynamic>> galleryItems = [
    {
      'id': '1',
      'title': 'Community Garden',
      'description': 'Our local community garden thriving with organic vegetables',
      'imageUrl': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80',
      'category': 'Community',
      'likes': 24,
      'comments': 8,
    },
    {
      'id': '2',
      'title': 'Solar Panel Installation',
      'description': 'New solar panels installed at the community center',
      'imageUrl': 'https://images.unsplash.com/photo-1464983953574-0892a716854b?auto=format&fit=crop&w=600&q=80',
      'category': 'Sustainability',
      'likes': 31,
      'comments': 12,
    },
    {
      'id': '3',
      'title': 'Beach Cleanup',
      'description': 'Volunteers cleaning up the local beach',
      'imageUrl': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
      'category': 'Events',
      'likes': 45,
      'comments': 15,
    },
    {
      'id': '4',
      'title': 'Urban Forest',
      'description': 'New trees planted in the city center',
      'imageUrl': 'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=600&q=80',
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

  final ImagePicker _picker = ImagePicker();
  // Add a variable to store picked image bytes for web
  Uint8List? _webImageBytes;

  /// Build method for the gallery page, using only ResponsiveHelper and AppTheme/AppColors.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: EdgeInsets.all(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showPhotoDetail(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    child: item['isWebMemory'] == true && item['webImageBytes'] != null
                        ? Image.memory(
                            item['webImageBytes'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : item['isLocal'] == true && !kIsWeb
                            ? LocalImageWidget(item['imageUrl'])
                            : item['isLocal'] == true && kIsWeb
                                ? Container(
                                    color: AppColors.borderLight,
                                    child: Center(
                                      child: Text(
                                        'Local images not supported on Web',
                                        style: TextStyle(color: AppColors.mutedText),
                                      ),
                                    ),
                                  )
                                : Image.network(
                                    item['imageUrl'],
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.borderLight,
                                        child: Icon(
                                          Icons.broken_image,
                                          color: AppColors.mutedText,
                                          size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
                                        ),
                                      );
                                    },
                                  ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  SizedBox(height: 4),
                  Text(
                    item['description'],
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.secondaryText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['category'],
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
                  child: item['isWebMemory'] == true && item['webImageBytes'] != null
                      ? Image.memory(
                          item['webImageBytes'],
                          fit: BoxFit.cover,
                        )
                      : item['isLocal'] == true && !kIsWeb
                          ? LocalImageWidget(item['imageUrl'])
                          : item['isLocal'] == true && kIsWeb
                              ? Center(
                                  child: Text(
                                    'Local images not supported on Web',
                                    style: TextStyle(color: AppColors.mutedText),
                                  ),
                                )
                              : Image.network(
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
    ValueNotifier<String> imagePreviewUrl = ValueNotifier('');
    ValueNotifier<bool> isValidUrl = ValueNotifier(true);
    ValueNotifier<XFile?> pickedImage = ValueNotifier<XFile?>(null);
    ValueNotifier<Uint8List?> pickedWebImageBytes = ValueNotifier<Uint8List?>(null);

    Future<void> pickImage() async {
      if (kIsWeb) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
        if (result != null && result.files.single.bytes != null) {
          pickedWebImageBytes.value = result.files.single.bytes;
          imagePreviewUrl.value = '';
          pickedImage.value = null;
          isValidUrl.value = true;
        }
      } else {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          pickedImage.value = image;
          imagePreviewUrl.value = '';
          pickedWebImageBytes.value = null;
          isValidUrl.value = true;
        }
      }
    }

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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'Image URL',
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                        errorText: isValidUrl.value ? null : 'Invalid image URL',
                      ),
                      onChanged: (val) {
                        imagePreviewUrl.value = val;
                        pickedImage.value = null;
                        pickedWebImageBytes.value = null;
                        isValidUrl.value = true;
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.photo_library, color: AppColors.success),
                    tooltip: 'Pick from device',
                    onPressed: pickImage,
                  ),
                ],
              ),
              SizedBox(height: 10),
              ValueListenableBuilder<Uint8List?>(
                valueListenable: pickedWebImageBytes,
                builder: (context, webBytes, _) {
                  if (webBytes != null) {
                    return Container(
                      height: 120,
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.borderLight,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          webBytes,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  } else {
                    return ValueListenableBuilder<XFile?>(
                      valueListenable: pickedImage,
                      builder: (context, file, _) {
                        if (file != null && !kIsWeb) {
                          return Container(
                            height: 120,
                            width: double.infinity,
                            margin: EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.borderLight,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LocalImageWidget(file.path),
                            ),
                          );
                        } else if (file != null && kIsWeb) {
                          return Container(
                            height: 120,
                            width: double.infinity,
                            margin: EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.borderLight,
                            ),
                            child: Center(
                              child: Text(
                                'Local image preview not supported on Web',
                                style: TextStyle(color: AppColors.mutedText),
                              ),
                            ),
                          );
                        }
                        return ValueListenableBuilder<String>(
                          valueListenable: imagePreviewUrl,
                          builder: (context, url, _) {
                            if (url.isEmpty) {
                              return Container();
                            }
                            return Container(
                              height: 120,
                              width: double.infinity,
                              margin: EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.borderLight,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    isValidUrl.value = false;
                                    return Center(child: Icon(Icons.broken_image, color: AppColors.mutedText, size: 40));
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                },
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
              if (titleController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty ||
                  (pickedImage.value == null && pickedWebImageBytes.value == null && (imageUrlController.text.trim().isEmpty || !isValidUrl.value))) {
                isValidUrl.value = false;
                return;
              }
              setState(() {
                galleryItems.insert(0, {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'imageUrl': pickedImage.value != null ? pickedImage.value!.path : imageUrlController.text.trim(),
                  'webImageBytes': pickedWebImageBytes.value,
                  'category': selectedCategory,
                  'likes': 0,
                  'comments': 0,
                  'isLocal': pickedImage.value != null || pickedWebImageBytes.value != null,
                  'isWebMemory': pickedWebImageBytes.value != null,
                });
              });
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