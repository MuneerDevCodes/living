import 'package:flutter/material.dart';
import 'package:living/models/challenge_model.dart';
import 'package:living/services/challenge_dao.dart';
import 'package:living/services/admin_service.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';
import 'package:living/services/validate.dart';

class ManageChallengesPage extends StatefulWidget {
  const ManageChallengesPage({super.key});

  @override
  State<ManageChallengesPage> createState() => _ManageChallengesPageState();
}

class _ManageChallengesPageState extends State<ManageChallengesPage> {
  List<Challenge> challenges = [];
  bool isLoading = true;
  final AdminService adminService = AdminService();
  bool _isAdmin = false;
  bool _isLoading = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadData();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await adminService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isLoading = false;
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      challenges = await ChallengeDAO.getActiveChallenges();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to load challenges: $e'),
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: Loader()),
      );
    }

    return Scaffold(
      drawer: Header.buildDrawer(context),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Stack(
              children: [
                if (isLoading) const Positioned.fill(child: Loader()),
                _buildChallengesList(),
              ],
            ),
          ),
          Footer(),
        ],
      ),
      // Only show floating action button for admin users
      floatingActionButton: _isAdmin ? Padding(
        padding: EdgeInsets.only(
          bottom: ResponsiveHelper.getBottomNavHeight(context) + 12,
        ),
        child: FloatingActionButton(
          onPressed: _showAddChallengeDialog,
          backgroundColor: AppColors.success,
          child: Icon(
            Icons.add,
            color: AppColors.white,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
        ),
      ) : null,
    );
  }

  Widget _buildChallengesList() {
    if (challenges.isEmpty) {
      return Center(
        child: Text(
          'No challenges available. Add your first challenge!',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
            color: AppColors.secondaryText,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: ResponsiveHelper.getAdaptivePadding(context),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return Card(
          margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getDifficultyColor(challenge.difficulty),
              child: Text(
                challenge.difficulty[0],
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
                ),
              ),
            ),
            title: Text(
              challenge.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 16),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.description,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                      color: AppColors.secondaryText,
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                    Text(
                      '${challenge.durationDays} days',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        color: AppColors.secondaryText,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.8),
                    Icon(
                      Icons.star,
                      size: ResponsiveHelper.getAdaptiveIconSize(context),
                      color: AppColors.secondaryText,
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.2),
                    Text(
                      '${challenge.pointsReward} points',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 12),
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Only show popup menu for admin users
            trailing: _isAdmin ? PopupMenuButton(
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
                  _showEditChallengeDialog(challenge);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(challenge);
                }
              },
            ) : null,
          ),
        );
      },
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.mutedText;
    }
  }

  void _showAddChallengeDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final durationController = TextEditingController();
    final pointsController = TextEditingController();
    String selectedDifficulty = 'Easy';
    final tasksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Challenge',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  validator: validateName,
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? 'Please enter a description' : null,
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                TextFormField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  validator: validateName,
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: durationController,
                        decoration: InputDecoration(
                          labelText: 'Duration (days)',
                          labelStyle: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final value = int.tryParse(v ?? '');
                          if (value == null || value <= 0) return 'Please enter a valid duration (positive number)';
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                    Expanded(
                      child: TextFormField(
                        controller: pointsController,
                        decoration: InputDecoration(
                          labelText: 'Points Reward',
                          labelStyle: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final value = int.tryParse(v ?? '');
                          if (value == null || value < 0) return 'Please enter a valid points reward (non-negative number)';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                DropdownButtonFormField<String>(
                  value: selectedDifficulty,
                  decoration: InputDecoration(
                    labelText: 'Difficulty',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  items: [
                    'Easy',
                    'Medium',
                    'Hard',
                  ].map((difficulty) => DropdownMenuItem(
                    value: difficulty,
                    child: Text(
                      difficulty,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      ),
                    ),
                  )).toList(),
                  onChanged: (value) {
                    selectedDifficulty = value!;
                  },
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                TextFormField(
                  controller: tasksController,
                  decoration: InputDecoration(
                    labelText: 'Tasks (one per line)',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  maxLines: 5,
                  validator: (v) {
                    final tasks = v?.split('\n').map((task) => task.trim()).where((task) => task.isNotEmpty).toList() ?? [];
                    if (tasks.isEmpty) return 'Please enter at least one task';
                    return null;
                  },
                ),
              ],
            ),
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
              if (!_formKey.currentState!.validate()) {
                return;
              }
              final duration = int.parse(durationController.text);
              final points = int.parse(pointsController.text);
              final tasks = tasksController.text
                  .split('\n')
                  .map((task) => task.trim())
                  .where((task) => task.isNotEmpty)
                  .toList();
              try {
                // Create challenge object
                final challenge = Challenge(
                  key: '', // Will be set by Firebase
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  category: categoryController.text.trim(),
                  durationDays: duration,
                  pointsReward: points,
                  difficulty: selectedDifficulty,
                  tasks: tasks,
                  startDate: DateTime.now(),
                  endDate: DateTime.now().add(Duration(days: duration)),
                  isActive: true,
                );
                // Add challenge to database
                await ChallengeDAO.addChallenge(challenge);
                // Close dialog
                Navigator.pop(context);
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Challenge added successfully!',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      ),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
                // Reload challenges list
                _loadData();
              } catch (e) {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertError('Failed to add challenge: $e'),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text(
              'Add Challenge',
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

  void _showEditChallengeDialog(Challenge challenge) {
    final titleController = TextEditingController(text: challenge.title);
    final descriptionController = TextEditingController(text: challenge.description);
    final categoryController = TextEditingController(text: challenge.category);
    final durationController = TextEditingController(text: challenge.durationDays.toString());
    final pointsController = TextEditingController(text: challenge.pointsReward.toString());
    String selectedDifficulty = challenge.difficulty;
    final tasksController = TextEditingController(text: challenge.tasks.join('\n'));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Challenge',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  validator: validateName,
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty ? 'Please enter a description' : null,
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                TextFormField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  validator: validateName,
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: durationController,
                        decoration: InputDecoration(
                          labelText: 'Duration (days)',
                          labelStyle: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final value = int.tryParse(v ?? '');
                          if (value == null || value <= 0) return 'Please enter a valid duration (positive number)';
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                    Expanded(
                      child: TextFormField(
                        controller: pointsController,
                        decoration: InputDecoration(
                          labelText: 'Points Reward',
                          labelStyle: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final value = int.tryParse(v ?? '');
                          if (value == null || value < 0) return 'Please enter a valid points reward (non-negative number)';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                DropdownButtonFormField<String>(
                  value: selectedDifficulty,
                  decoration: InputDecoration(
                    labelText: 'Difficulty',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  items: [
                    'Easy',
                    'Medium',
                    'Hard',
                  ].map((difficulty) => DropdownMenuItem(
                    value: difficulty,
                    child: Text(
                      difficulty,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      ),
                    ),
                  )).toList(),
                  onChanged: (value) {
                    selectedDifficulty = value!;
                  },
                ),
                SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                TextFormField(
                  controller: tasksController,
                  decoration: InputDecoration(
                    labelText: 'Tasks (one per line)',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  maxLines: 5,
                  validator: (v) {
                    final tasks = v?.split('\n').map((task) => task.trim()).where((task) => task.isNotEmpty).toList() ?? [];
                    if (tasks.isEmpty) return 'Please enter at least one task';
                    return null;
                  },
                ),
              ],
            ),
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
              if (!_formKey.currentState!.validate()) {
                return;
              }
              final duration = int.parse(durationController.text);
              final points = int.parse(pointsController.text);
              final tasks = tasksController.text
                  .split('\n')
                  .map((task) => task.trim())
                  .where((task) => task.isNotEmpty)
                  .toList();
              try {
                // Create updated challenge object
                final updatedChallenge = Challenge(
                  key: challenge.key,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  category: categoryController.text.trim(),
                  durationDays: duration,
                  pointsReward: points,
                  difficulty: selectedDifficulty,
                  tasks: tasks,
                  startDate: challenge.startDate,
                  endDate: challenge.startDate.add(Duration(days: duration)),
                  isActive: challenge.isActive,
                );
                // Update challenge in database
                await ChallengeDAO.updateChallenge(updatedChallenge);
                // Close dialog
                Navigator.pop(context);
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Challenge updated successfully!',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                      ),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
                // Reload challenges list
                _loadData();
              } catch (e) {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertError('Failed to update challenge: $e'),
                );
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

  void _showDeleteConfirmation(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Challenge',
          style: TextStyle(
            fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${challenge.title}"?',
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
                // Delete challenge from database
                await ChallengeDAO.deleteChallenge(challenge.key);
                
                // Close dialog
              Navigator.pop(context);
                
                // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Challenge deleted successfully!',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                    ),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
                
                // Reload challenges list
                _loadData();
                
              } catch (e) {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertError('Failed to delete challenge: $e'),
                );
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