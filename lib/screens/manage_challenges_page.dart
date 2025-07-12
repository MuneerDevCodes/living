import 'package:flutter/material.dart';
import 'package:living/models/challenge_model.dart';
import 'package:living/services/challenge_dao.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/header.dart';
import 'package:living/widgets/footer.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class ManageChallengesPage extends StatefulWidget {
  const ManageChallengesPage({super.key});

  @override
  State<ManageChallengesPage> createState() => _ManageChallengesPageState();
}

class _ManageChallengesPageState extends State<ManageChallengesPage> {
  List<Challenge> challenges = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddChallengeDialog,
        backgroundColor: AppColors.success,
        child: Icon(
          Icons.add,
          color: AppColors.white,
          size: ResponsiveHelper.getAdaptiveIconSize(context),
        ),
      ),
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
                  _showEditChallengeDialog(challenge);
                } else if (value == 'delete') {
                  _deleteChallenge(challenge);
                }
              },
            ),
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
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: durationController,
                      decoration: InputDecoration(
                        labelText: 'Duration (days)',
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Expanded(
                    child: TextField(
                      controller: pointsController,
                      decoration: InputDecoration(
                        labelText: 'Points Reward',
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
                      keyboardType: TextInputType.number,
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
              TextField(
                controller: tasksController,
                decoration: InputDecoration(
                  labelText: 'Tasks (one per line)',
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
              // Validate form data
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a title'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              if (descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a description'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              if (categoryController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a category'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              final duration = int.tryParse(durationController.text);
              if (duration == null || duration <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid duration (positive number)'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              final points = int.tryParse(pointsController.text);
              if (points == null || points < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid points reward (non-negative number)'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              // Parse tasks
              final tasks = tasksController.text
                  .split('\n')
                  .map((task) => task.trim())
                  .where((task) => task.isNotEmpty)
                  .toList();
              
              if (tasks.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter at least one task'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
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
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: durationController,
                      decoration: InputDecoration(
                        labelText: 'Duration (days)',
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Expanded(
                    child: TextField(
                      controller: pointsController,
                      decoration: InputDecoration(
                        labelText: 'Points Reward',
                        labelStyle: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
                        ),
                      ),
                      keyboardType: TextInputType.number,
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
              TextField(
                controller: tasksController,
                decoration: InputDecoration(
                  labelText: 'Tasks (one per line)',
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
              // Validate form data
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a title'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              if (descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a description'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              if (categoryController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a category'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              final duration = int.tryParse(durationController.text);
              if (duration == null || duration <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid duration (positive number)'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              final points = int.tryParse(pointsController.text);
              if (points == null || points < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid points reward (non-negative number)'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              // Parse tasks
              final tasks = tasksController.text
                  .split('\n')
                  .map((task) => task.trim())
                  .where((task) => task.isNotEmpty)
                  .toList();
              
              if (tasks.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter at least one task'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
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

  void _deleteChallenge(Challenge challenge) {
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