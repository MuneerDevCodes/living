import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:living/models/forum_post_model.dart';
import 'package:living/services/forum_post_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/services/admin_service.dart';
import 'package:living/services/performance_service.dart';
import 'package:living/services/user_dao.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/alert_success.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

/// ForumPage displays the community forum, using responsive and theme-driven design.
class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  List<ForumPost> posts = [];
  bool isLoading = true;
  String? userId;
  String selectedCategory = 'All';
  String? selectedTag;
  bool isLiking = false;
  bool isCommenting = false;
  Set<String> likedPostKeys = {};
  String? userRole;
  bool isAdmin = false;
  String? validationError;
  List<String> allTags = [];

  final List<String> categories = [
    'All',
    'General Discussion',
    'Tips & Tricks',
    'Success Stories',
    'Questions',
    'Events',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRole();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      posts = await ForumPostDao().getPublishedPosts(tags: selectedTag != null && selectedTag != 'All' ? [selectedTag!] : null);
      userId = AuthService.getCurrentUserId();
      // Collect all tags from posts
      final tagSet = <String>{};
      for (final post in posts) {
        tagSet.addAll(post.tags);
      }
      allTags = tagSet.toList();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to load forum posts: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadRole() async {
    final role = await AdminService().getCurrentUserRole();
    setState(() {
      userRole = role;
      isAdmin = role == 'admin';
    });
  }

  List<ForumPost> get filteredPosts {
    var filtered = posts;
    if (selectedCategory != 'All') {
      filtered = filtered.where((post) => post.category == selectedCategory).toList();
    }
    if (selectedTag != null && selectedTag != 'All') {
      filtered = filtered.where((post) => post.tags.contains(selectedTag)).toList();
    }
    return filtered;
  }

  /// Build method for the forum page, using only ResponsiveHelper and AppTheme/AppColors.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    _buildCategoryFilter(),
                    _buildTagFilter(),
                    Expanded(
                      child: _buildPostsList(),
                    ),
                  ],
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
          onPressed: _showAddPostDialog,
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
          child: Icon(
            Icons.add,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: ResponsiveHelper.getScreenHeight(context) * 0.08,
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5,
        horizontal: ResponsiveHelper.getAdaptiveSpacing(context)),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.5),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          return ChoiceChip(
            label: Text(
              category,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 15),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.white : AppColors.primary,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                selectedCategory = category;
                _loadData();
              });
            },
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.background,
            elevation: isSelected ? 4 : 0,
            shape: StadiumBorder(),
            shadowColor: AppColors.primary.withOpacity(0.2),
          );
        },
      ),
    );
  }

  Widget _buildTagFilter() {
    if (allTags.isEmpty) return SizedBox.shrink();
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getAdaptiveSpacing(context)),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allTags.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = index == 0 ? 'All' : allTags[index - 1];
          final isSelected = selectedTag == tag || (tag == 'All' && (selectedTag == null || selectedTag == 'All'));
          return ChoiceChip(
            label: Text(tag,
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 13),
                color: isSelected ? AppColors.white : AppColors.primary,
              ),
            ),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                selectedTag = tag;
                _loadData();
              });
            },
            selectedColor: AppColors.success,
            backgroundColor: AppColors.background,
            elevation: isSelected ? 3 : 0,
            shape: StadiumBorder(),
            shadowColor: AppColors.success.withOpacity(0.2),
          );
        },
      ),
    );
  }

  Widget _buildPostsList() {
    if (filteredPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum, color: AppColors.secondaryText, size: 48),
            SizedBox(height: 12),
            Text(
              'No posts found for this category.',
              style: TextStyle(
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      child: ListView.separated(
        itemCount: filteredPosts.length,
        separatorBuilder: (_, __) => SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
        itemBuilder: (context, index) {
          return _buildPostCard(filteredPosts[index]);
        },
      ),
    );
  }

  Widget _buildPostCard(ForumPost post) {
    final isOwner = userId == post.userId;
    final canEdit = isOwner || isAdmin;
    return FutureBuilder<String>(
      future: _getDisplayName(post.userId),
      builder: (context, snapshot) {
        final displayName = snapshot.data ?? 'User';
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showPostDetail(post),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getAdaptiveSpacing(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {/* Future: open profile */},
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 15),
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                if (isOwner || (isAdmin && displayName == 'Admin')) ...[
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isAdmin ? 'ADMIN' : 'OWNER',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              post.timestamp,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canEdit)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _showEditPostDialog(post);
                            if (value == 'delete') _deletePost(post);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                          icon: Icon(Icons.more_vert, color: AppColors.secondaryText),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tag, size: 16, color: AppColors.secondaryText),
                            SizedBox(width: 4),
                            Text(
                              post.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    post.title,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    post.content,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      color: AppColors.secondaryText,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.thumb_up, color: AppColors.secondaryText, size: 20),
                      SizedBox(width: 4),
                      Text(post.likes.toString(), style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
                      SizedBox(width: 16),
                      Icon(Icons.comment_outlined, color: AppColors.secondaryText, size: 20),
                      SizedBox(width: 4),
                      Text('Comments', style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentPreview(String url) {
    if (url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png') || url.endsWith('.gif')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(url, width: 60, height: 60, fit: BoxFit.cover),
      );
    }
    return InkWell(
      onTap: () {
        // Placeholder: open file
      },
      child: Chip(label: Text('File'), avatar: Icon(Icons.attach_file)),
    );
  }

  void _showPostDetail(ForumPost post) async {
    final postAuthorName = await _getDisplayName(post.userId);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {/* Future: open profile */},
                    child: Text(
                      postAuthorName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(post.timestamp, style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                ],
              ),
              SizedBox(height: 8),
              Text(post.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 6),
              Text(post.content, style: TextStyle(fontSize: 15, color: AppColors.secondaryText)),
              SizedBox(height: 16),
              Divider(),
              Text('Comments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              _buildCommentsSection(post),
              SizedBox(height: 12),
              _buildCommentInput(post),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsSection(ForumPost post) {
    return FutureBuilder<List<ForumComment>>(
      future: ForumPostDao().getComments(post.key),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Failed to load comments.', style: TextStyle(color: AppColors.error)),
          );
        }
        final comments = snapshot.data ?? [];
        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('No comments yet. Be the first to comment!', style: TextStyle(color: AppColors.secondaryText)),
          );
        }
        return Column(
          children: comments.map((comment) => FutureBuilder<String>(
            future: _getDisplayName(comment.authorId),
            builder: (context, snap) {
              final commenterName = snap.data ?? 'User';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {/* Future: open profile */},
                      child: Text(
                        commenterName,
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(comment.content, style: TextStyle(fontSize: 14)),
                          SizedBox(height: 2),
                          Text(
                            comment.createdAt.toString(),
                            style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          )).toList(),
        );
      },
    );
  }

  Widget _buildCommentInput(ForumPost post) {
    final controller = TextEditingController();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Write a comment…',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            minLines: 1,
            maxLines: 3,
          ),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            final text = controller.text.trim();
            if (text.isEmpty) return;
            final displayName = await _getDisplayName(userId!);
            final newComment = ForumComment(
              key: DateTime.now().millisecondsSinceEpoch.toString(),
              postId: post.key,
              author: displayName,
              authorId: userId!,
              authorProfileImageUrl: null,
              content: text,
              createdAt: DateTime.now(),
              lastEdited: null,
              attachmentUrls: [],
            );
            await ForumPostDao().addComment(post.key, newComment);
            Navigator.pop(context);
            _showPostDetail(post); // Reopen to refresh comments
          },
          child: Text('Post'),
        ),
      ],
    );
  }

  void _showAddPostDialog() {
    if (userId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Please log in to create a forum post.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/auth');
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedCategory = 'General Discussion';
    String? localValidationError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Create New Post',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (localValidationError != null) ...[
                  Text(
                    localValidationError!,
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                  SizedBox(height: 8),
                ],
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
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  maxLines: 5,
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
              onPressed: () async {
                // Validation
                if (titleController.text.trim().length < 5) {
                  setState(() => localValidationError = 'Title must be at least 5 characters.');
                  return;
                }
                if (contentController.text.trim().length < 10) {
                  setState(() => localValidationError = 'Content must be at least 10 characters.');
                  return;
                }
                if (selectedCategory.isEmpty) {
                  setState(() => localValidationError = 'Please select a category.');
                  return;
                }
                setState(() => localValidationError = null);
                final post = ForumPost(
                  key: DateTime.now().millisecondsSinceEpoch.toString(),
                  userId: userId!,
                  title: titleController.text,
                  content: contentController.text,
                  author: 'User', // In a real app, get from user profile
                  authorId: userId!,
                  authorName: 'User',
                  category: selectedCategory,
                  createdAt: DateTime.now(),
                  likes: 0,
                  timestamp: DateTime.now().toString(),
                  status: 'open', // Default status
                  tags: [], // Default tags
                  postImageUrl: null, // Default image
                  attachmentUrls: [], // Default attachments
                  authorProfileImageUrl: null, // Default profile image
                );

                try {
                  await ForumPostDao().addPost(post);
                  Navigator.pop(context);
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Post created successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertError('Failed to create post: $e'),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: Text(
                'Create Post',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPostDialog(ForumPost post) {
    final titleController = TextEditingController(text: post.title);
    final contentController = TextEditingController(text: post.content);
    String selectedCategory = post.category;
    String? localValidationError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Edit Post',
            style: TextStyle(
              fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (localValidationError != null) ...[
                  Text(
                    localValidationError!,
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                  SizedBox(height: 8),
                ],
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
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  maxLines: 5,
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
              onPressed: () async {
                // Validation
                if (titleController.text.trim().length < 5) {
                  setState(() => localValidationError = 'Title must be at least 5 characters.');
                  return;
                }
                if (contentController.text.trim().length < 10) {
                  setState(() => localValidationError = 'Content must be at least 10 characters.');
                  return;
                }
                if (selectedCategory.isEmpty) {
                  setState(() => localValidationError = 'Please select a category.');
                  return;
                }
                setState(() => localValidationError = null);
                final updatedPost = ForumPost(
                  key: post.key,
                  userId: post.userId,
                  title: titleController.text,
                  content: contentController.text,
                  author: post.author,
                  authorId: post.authorId,
                  authorName: post.authorName,
                  category: selectedCategory,
                  createdAt: post.createdAt,
                  likes: post.likes,
                  timestamp: post.timestamp,
                  status: post.status,
                  tags: post.tags,
                  postImageUrl: post.postImageUrl,
                  attachmentUrls: post.attachmentUrls,
                  authorProfileImageUrl: post.authorProfileImageUrl,
                );

                try {
                  await ForumPostDao().updatePost(updatedPost);
                  Navigator.pop(context);
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Post updated successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertError('Failed to update post: $e'),
                    );
                  }
                }
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
      ),
    );
  }

  void _deletePost(ForumPost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Post',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this post?',
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
            onPressed: () async {
              try {
                await ForumPostDao().deletePost(post.key);
                Navigator.pop(context);
                _loadData();
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => const AlertSuccess('Post deleted successfully!'),
                  );
                }
              } catch (e) {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertError('Failed to delete post: $e'),
                  );
                }
              }
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

  // --- Helper to get display name for a userId ---
  Future<String> _getDisplayName(String userId) async {
    final user = await UserDao().getUserById(userId);
    return user?.displayname ?? 'User';
  }
} 