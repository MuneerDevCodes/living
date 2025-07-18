import 'package:flutter/material.dart';
import 'package:living/models/forum_post_model.dart';
import 'package:living/services/forum_post_dao.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/services/admin_service.dart';
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
                  _loadData(); // Reload data when category changes
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

  Widget _buildTagFilter() {
    if (allTags.isEmpty) return SizedBox.shrink();
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: Text('All'),
            selected: selectedTag == null || selectedTag == 'All',
            onSelected: (_) {
              setState(() {
                selectedTag = 'All';
                _loadData();
              });
            },
          ),
          ...allTags.map((tag) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(tag),
              selected: selectedTag == tag,
              onSelected: (_) {
                setState(() {
                  selectedTag = tag;
                  _loadData();
                });
              },
            ),
          )),
        ],
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
    final isOwner = userId == post.userId;
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
                  post.authorProfileImageUrl != null && post.authorProfileImageUrl!.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(post.authorProfileImageUrl!),
                        )
                      : CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
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
                        Row(
                          children: [
                            Text(
                              post.authorName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                              ),
                            ),
                            if (isAdmin && isOwner) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ADMIN',
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
                  if (post.status == 'closed')
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Chip(
                        label: Text('Closed', style: TextStyle(color: Colors.white)),
                        backgroundColor: AppColors.error,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              if (post.postImageUrl != null && post.postImageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.network(post.postImageUrl!, height: 180, fit: BoxFit.cover),
                ),
              if (post.attachmentUrls.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: post.attachmentUrls.map((url) => _buildAttachmentPreview(url)).toList(),
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
              Wrap(
                spacing: 6,
                children: post.tags.map((tag) => Chip(label: Text(tag))).toList(),
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
                          post.category,
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
                      GestureDetector(
                        onTap: isLiking || likedPostKeys.contains(post.key) ? null : () async {
                          if (userId == null) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Login Required'),
                                content: const Text('Please log in to like posts.'),
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
                          setState(() => isLiking = true);
                          try {
                            final newLikes = post.likes + 1;
                            await ForumPostDao().updateLikes(post.key, newLikes);
                            setState(() {
                              posts = posts.map((p) => p.key == post.key ? ForumPost(
                                key: p.key,
                                userId: p.userId,
                                title: p.title,
                                content: p.content,
                                author: p.author,
                                authorId: p.authorId,
                                authorName: p.authorName,
                                category: p.category,
                                createdAt: p.createdAt,
                                likes: newLikes,
                                timestamp: p.timestamp,
                                status: p.status,
                                tags: p.tags,
                                postImageUrl: p.postImageUrl,
                                attachmentUrls: p.attachmentUrls,
                                authorProfileImageUrl: p.authorProfileImageUrl,
                              ) : p).toList();
                              likedPostKeys.add(post.key);
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('You liked this post!')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertError('Failed to like post: $e'),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => isLiking = false);
                          }
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: isLiking && !likedPostKeys.contains(post.key)
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Row(
                                children: [
                                  Icon(
                                    likedPostKeys.contains(post.key)
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_outlined,
                                    size: ResponsiveHelper.getAdaptiveIconSize(context),
                                    color: likedPostKeys.contains(post.key)
                                      ? AppColors.success
                                      : AppColors.secondaryText,
                                  ),
                                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.1),
                                  Text(
                                    post.likes.toString(),
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                      color: likedPostKeys.contains(post.key)
                                        ? AppColors.success
                                        : AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
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
                        'View Comments',
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

  void _showPostDetail(ForumPost post) {
    final commentController = TextEditingController();
    String? localValidationError;
    List<ForumComment> comments = [];
    bool loadingComments = true;
    // Fetch comments on demand
    ForumPostDao().getComments(post.key).then((fetched) {
      if (mounted) setState(() { comments = fetched; loadingComments = false; });
    });
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                    post.authorProfileImageUrl != null && post.authorProfileImageUrl!.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(post.authorProfileImageUrl!),
                          )
                        : CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
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
                          post.authorName,
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
                if (post.postImageUrl != null && post.postImageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Image.network(post.postImageUrl!, height: 180, fit: BoxFit.cover),
                  ),
                if (post.attachmentUrls.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: post.attachmentUrls.map((url) => _buildAttachmentPreview(url)).toList(),
                  ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                Divider(),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                Text(
                  'Comments:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
                if (loadingComments)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ...comments.map((comment) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      comment.authorProfileImageUrl != null && comment.authorProfileImageUrl!.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(comment.authorProfileImageUrl!),
                            )
                          : CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                comment.author.isNotEmpty ? comment.author[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                                ),
                              ),
                            ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.author,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                              ),
                            ),
                            Text(
                              comment.content,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                                color: AppColors.secondaryText,
                              ),
                            ),
                            Text(
                              comment.createdAt.toString(),
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 10),
                                color: AppColors.secondaryText,
                              ),
                            ),
                            if (comment.attachmentUrls.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                children: comment.attachmentUrls.map((url) => _buildAttachmentPreview(url)).toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                if (userId != null) ...[
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  if (localValidationError != null) ...[
                    Text(
                      localValidationError!,
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                    SizedBox(height: 8),
                  ],
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: 'Add a comment',
                      labelStyle: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: isCommenting ? null : () async {
                      if (commentController.text.trim().length < 2) {
                        setState(() => localValidationError = 'Comment must be at least 2 characters.');
                        return;
                      }
                      setState(() => localValidationError = null);
                      setState(() => isCommenting = true);
                      try {
                        final newComment = ForumComment(
                          key: DateTime.now().millisecondsSinceEpoch.toString(),
                          postId: post.key,
                          author: userId!,
                          authorId: userId!,
                          authorProfileImageUrl: null, // Add logic to get user profile image
                          content: commentController.text.trim(),
                          createdAt: DateTime.now(),
                          lastEdited: null,
                          attachmentUrls: [], // Add logic for attachments
                        );
                        await ForumPostDao().addComment(post.key, newComment);
                        Navigator.pop(context);
                        _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Comment added!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertError('Failed to add comment: $e'),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => isCommenting = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: isCommenting
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : Text(
                          'Post Comment',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
                  ),
                ],
                if (userId == null) ...[
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Text(
                    'Login to add a comment.',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
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
} 