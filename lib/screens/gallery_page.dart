import 'package:flutter/material.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show File;
import 'package:living/models/gallery_item_model.dart';
import 'package:living/services/dynamic_gallery_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';

/// GalleryPage displays a dynamic gallery of community images with real-time updates,
/// admin controls, and multi-user support using Firebase.
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  String selectedCategory = 'All';
  List<String> categories = ['All', 'Nature', 'Sustainability', 'Community', 'Events'];

  List<GalleryItem> galleryItems = [];
  final DynamicGalleryService _galleryService = DynamicGalleryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  
  // User permissions
  Map<String, bool> userPermissions = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserPermissions();
  }

  Future<void> _loadUserPermissions() async {
    try {
      final permissions = await _galleryService.getUserPermissions();
      if (mounted) {
        setState(() {
          userPermissions = permissions;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load user permissions: $e';
          isLoading = false;
        });
      }
    }
  }

  List<GalleryItem> get filteredItems {
    if (selectedCategory == 'All') {
      return galleryItems;
    }
    return galleryItems.where((item) => item.category == selectedCategory).toList();
  }

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
                  child: _buildGalleryContent(),
                ),
              ],
            ),
          ),
          Footer(),
        ],
      ),
      floatingActionButton: userPermissions['canUpload'] == true
          ? Padding(
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
            )
          : null,
    );
  }

  Widget _buildGalleryContent() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: 16),
            Text(
              'Error loading gallery',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  errorMessage = null;
                  isLoading = true;
                });
                _loadUserPermissions();
              },
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Use StreamBuilder for real-time updates
    return StreamBuilder<List<GalleryItem>>(
      stream: _galleryService.getGalleryItemsByCategoryStream(selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading gallery',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    color: AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          );
        }

        final items = snapshot.data ?? [];
        
        if (items.isEmpty) {
          return _buildEmptyState();
        }

        return _buildGalleryGrid(items);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: AppColors.success,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No photos found',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 20),
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: 8),
          Text(
            userPermissions['canUpload'] == true
                ? 'Be the first to add a photo to this category!'
                : 'Try selecting a different category or check back later!',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          if (userPermissions['isAdmin'] == true) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeSampleData,
              icon: Icon(Icons.add_photo_alternate, size: 18),
              label: Text('Initialize Sample Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: ResponsiveHelper.getScreenHeight(context) * 0.08,
      padding: ResponsiveHelper.getVerticalPadding(context),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
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
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.white : AppColors.primaryText,
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
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: isSelected ? AppColors.success : AppColors.borderLight,
                      width: 1.5,
                    ),
                    elevation: isSelected ? 2 : 0,
                    shadowColor: AppColors.success.withValues(alpha: 0.3),
                  ),
                );
              },
            ),
          ),
          if (userPermissions['isAdmin'] == true)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _showPendingApprovalDialog,
                icon: Icon(Icons.admin_panel_settings, color: AppColors.success),
                tooltip: 'Pending Approval',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.success.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(List<GalleryItem> items) {
    return GridView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.getScreenWidth(context) > 600 ? 3 : 2,
        crossAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
        mainAxisSpacing: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildGalleryItem(item);
      },
    );
  }

  Widget _buildGalleryItem(GalleryItem item) {
    return Card(
      elevation: 4,
      shadowColor: AppColors.success.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.all(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showPhotoDetail(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    child: _buildImageWidget(item),
                  ),
                  // Like and comment overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${item.likes}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Admin controls overlay
                  if (userPermissions['isAdmin'] == true)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ADMIN',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.secondaryText,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.comment,
                        size: 16,
                        color: AppColors.mutedText,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${item.comments}',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (item.uploadedBy != null) ...[
                    SizedBox(height: 4),
                    Text(
                      'By: ${item.uploadedBy}',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(GalleryItem item) {
    // Display image from URL (Firebase Storage or network)
    if (item.imageUrl.isNotEmpty) {
      return Image.network(
        item.imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.background,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else {
      // Fallback for any unsupported case
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: AppColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: AppColors.mutedText,
            size: ResponsiveHelper.getAdaptiveIconSize(context) * 2,
          ),
          SizedBox(height: 8),
          Text(
            'Image unavailable',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailImageWidget(GalleryItem item) {
    // Display image from URL (Firebase Storage or network)
    if (item.imageUrl.isNotEmpty) {
      return Image.network(
        item.imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.background,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                strokeWidth: 3,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDetailErrorWidget();
        },
      );
    } else {
      // Fallback for any unsupported case
      return _buildDetailErrorWidget();
    }
  }

  Widget _buildDetailErrorWidget() {
    return Container(
      color: AppColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: AppColors.mutedText,
            size: ResponsiveHelper.getAdaptiveIconSize(context) * 3,
          ),
          SizedBox(height: 16),
          Text(
            'Image unavailable',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoDetail(GalleryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.photo, color: AppColors.success),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: ResponsiveHelper.getScreenHeight(context) * 0.4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getAdaptiveBorderRadius(context),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getAdaptiveBorderRadius(context),
                  ),
                  child: _buildDetailImageWidget(item),
                ),
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
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                    color: AppColors.mutedText,
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                  Text(
                    '${item.likes} likes',
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
                    '${item.comments} comments',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              if (item.uploadedBy != null) ...[
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                      color: AppColors.mutedText,
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                    Text(
                      'Uploaded by: ${item.uploadedBy}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
              if (item.uploadedAt != null) ...[
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                      color: AppColors.mutedText,
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                    Text(
                      'Uploaded: ${_formatDate(item.uploadedAt!)}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (userPermissions['canDelete'] == true || 
              item.uploadedBy == _auth.currentUser?.email ||
              item.uploadedBy == _auth.currentUser?.uid)
            TextButton(
              onPressed: () => _deleteGalleryItem(item),
              child: Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
            ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _showAddPhotoDialog() {
    if (!userPermissions['canUpload']!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to upload photos'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Nature';
    ValueNotifier<Uint8List?> pickedWebImageBytes = ValueNotifier<Uint8List?>(null);
    ValueNotifier<bool> isLoading = ValueNotifier(false);

    Future<void> pickImage() async {
      try {
        if (kIsWeb) {
          // On web, use FilePicker to get bytes directly
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: false,
          );
          if (result != null && result.files.single.bytes != null) {
            pickedWebImageBytes.value = result.files.single.bytes;
          }
        } else {
          // On mobile/desktop, use ImagePicker and convert to bytes
          final XFile? image = await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );
          if (image != null) {
            final bytes = await image.readAsBytes();
            pickedWebImageBytes.value = bytes;
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to pick image: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_a_photo, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'Add Photo to Gallery',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Photo Title',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                  border: OutlineInputBorder(),
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
                  border: OutlineInputBorder(),
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
                  border: OutlineInputBorder(),
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
                    child: ElevatedButton.icon(
                      onPressed: pickImage,
                      icon: Icon(Icons.photo_library),
                      label: Text('Pick Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                      ),
                    ),
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
                        color: AppColors.background,
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          webBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: AppColors.mutedText, size: 32),
                                  SizedBox(height: 4),
                                  Text(
                                    'Invalid image',
                                    style: TextStyle(
                                      color: AppColors.mutedText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  } else {
                    return Container();
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
          ValueListenableBuilder<bool>(
            valueListenable: isLoading,
            builder: (context, loading, _) {
              return ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (titleController.text.trim().isEmpty ||
                            descriptionController.text.trim().isEmpty ||
                            pickedWebImageBytes.value == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please fill all fields and select an image'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                          return;
                        }
                        isLoading.value = true;
                        final newItem = GalleryItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          imageUrl: '', // Will be set by Firebase Storage
                          webImageBytes: pickedWebImageBytes.value,
                          category: selectedCategory,
                          likes: 0,
                          comments: 0,
                        );
                        try {
                          await _galleryService.addGalleryItem(newItem);
                          isLoading.value = false;
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  userPermissions['isAdmin'] == true
                                      ? 'Photo added successfully!'
                                      : 'Photo uploaded! Waiting for admin approval.',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          isLoading.value = false;
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to add photo: ${e.toString()}',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : Text(
                        'Add Photo',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPendingApprovalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'Pending Approval',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: ResponsiveHelper.getScreenHeight(context) * 0.6,
          child: StreamBuilder<List<GalleryItem>>(
            stream: _galleryService.getPendingApprovalStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading pending items: ${snapshot.error}',
                    style: TextStyle(color: AppColors.error),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                );
              }

              final items = snapshot.data ?? [];
              
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.success,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No pending approvals',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'All gallery items are approved!',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 60,
                        height: 60,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImageWidget(item),
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.description),
                          SizedBox(height: 4),
                          Text(
                            'By: ${item.uploadedBy ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _approveGalleryItem(item, true),
                            icon: Icon(Icons.check, color: AppColors.success),
                            tooltip: 'Approve',
                          ),
                          IconButton(
                            onPressed: () => _approveGalleryItem(item, false),
                            icon: Icon(Icons.close, color: AppColors.error),
                            tooltip: 'Reject',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveGalleryItem(GalleryItem item, bool approved) async {
    try {
      await _galleryService.approveGalleryItem(item.id, approved);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved ? 'Item approved!' : 'Item rejected!',
            ),
            backgroundColor: approved ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${approved ? 'approve' : 'reject'} item: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteGalleryItem(GalleryItem item) async {
    try {
      await _galleryService.deleteGalleryItem(item.id);
      if (context.mounted) {
        Navigator.pop(context); // Close detail dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item deleted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete item: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _initializeSampleData() async {
    try {
      await _galleryService.initializeSampleData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sample data initialized successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize sample data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _galleryService.dispose();
    super.dispose();
  }
} 