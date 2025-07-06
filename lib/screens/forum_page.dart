import 'package:flutter/material.dart';
import 'package:living/models/forum_post_model.dart';
import 'package:living/services/forum_post_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/alert_success.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

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
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      posts = await ForumPostDao().getPublishedPosts();
      userId = AuthService.getCurrentUserId();
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

  List<ForumPost> get filteredPosts {
    if (selectedCategory == 'All') {
      return posts;
    }
    return posts.where((post) => selectedCategory == 'All').toList();
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
                Column(
                  children: [
                    _buildCategoryFilter(),
                    Expanded(
                      child: _buildPostsList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Footer(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPostDialog,
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.white,
        child: Icon(
          Icons.add,
          size: ResponsiveHelper.getAdaptiveIconSize(context),
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

  Widget _buildPostsList() {
    if (filteredPosts.isEmpty) {
      return Center(
        child: Text(
          'No posts found for this category.',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        final post = filteredPosts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(ForumPost post) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
      child: InkWell(
        onTap: () => _showPostDetail(post),
        child: Padding(
          padding: ResponsiveHelper.getAdaptivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      post.userId[0].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userId,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
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
                  if (userId == post.userId)
                    PopupMenuButton(
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
                          _showEditPostDialog(post);
                        } else if (value == 'delete') {
                          _deletePost(post);
                        }
                      },
                    ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
              Text(
                post.title,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
              Text(
                post.content,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tag,
                          size: ResponsiveHelper.getAdaptiveIconSize(context),
                          color: AppColors.secondaryText,
                        ),
                        SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                        Text(
                          'General',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.thumb_up_outlined,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                        color: AppColors.secondaryText,
                      ),
                      SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                      Icon(
                        Icons.comment_outlined,
                        size: ResponsiveHelper.getAdaptiveIconSize(context),
                        color: AppColors.secondaryText,
                      ),
                      SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostDetail(ForumPost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          post.title,
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
                    backgroundColor: AppColors.primary,
                    child: Text(
                      post.userId[0].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
                      Text(
                        post.timestamp,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                post.content,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Text(
                'No comments available',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  color: AppColors.secondaryText,
                ),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
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
                  comments: [],
                  timestamp: DateTime.now().toString(),
                );

                try {
                  await ForumPostDao().addPost(post);
                  Navigator.pop(context);
                  _loadData();
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => const AlertSuccess('Post created successfully!'),
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
    );
  }

  void _showEditPostDialog(ForumPost post) {
    final titleController = TextEditingController(text: post.title);
    final contentController = TextEditingController(text: post.content);
    String selectedCategory = post.category;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
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
                  comments: post.comments,
                  timestamp: post.timestamp,
                );

                try {
                  await ForumPostDao().updatePost(updatedPost);
                  Navigator.pop(context);
                  _loadData();
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => const AlertSuccess('Post updated successfully!'),
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
} 