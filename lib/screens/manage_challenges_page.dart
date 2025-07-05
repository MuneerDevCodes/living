import 'package:flutter/material.dart';
import 'package:living/models/challenge_model.dart';
import 'package:living/services/challenge_dao.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';
import 'package:living/widgets/alert_success.dart';

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
      appBar: AppBar(
        title: const Text('Manage Challenges'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Loader()
          : _buildChallengesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddChallengeDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildChallengesList() {
    if (challenges.isEmpty) {
      return const Center(
        child: Text(
          'No challenges available. Add your first challenge!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getDifficultyColor(challenge.difficulty),
              child: Text(
                challenge.difficulty[0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              challenge.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(challenge.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.durationDays} days',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.star, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.pointsReward} points',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
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
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
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
        title: const Text('Add New Challenge'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: durationController,
                      decoration: const InputDecoration(labelText: 'Duration (days)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: pointsController,
                      decoration: const InputDecoration(labelText: 'Points Reward'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Difficulty'),
                value: selectedDifficulty,
                items: ['Easy', 'Medium', 'Hard'].map((difficulty) {
                  return DropdownMenuItem(value: difficulty, child: Text(difficulty));
                }).toList(),
                onChanged: (value) => selectedDifficulty = value!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tasksController,
                decoration: const InputDecoration(
                  labelText: 'Tasks (one per line)',
                  hintText: 'Task 1\nTask 2\nTask 3',
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  categoryController.text.isNotEmpty &&
                  durationController.text.isNotEmpty &&
                  pointsController.text.isNotEmpty) {
                final duration = int.tryParse(durationController.text);
                final points = int.tryParse(pointsController.text);
                final tasks = tasksController.text
                    .split('\n')
                    .where((task) => task.trim().isNotEmpty)
                    .toList();

                if (duration != null && points != null) {
                  final challenge = Challenge(
                    key: '',
                    title: titleController.text,
                    description: descriptionController.text,
                    category: categoryController.text,
                    durationDays: duration,
                    pointsReward: points,
                    difficulty: selectedDifficulty,
                    tasks: tasks,
                    startDate: DateTime.now(),
                    endDate: DateTime.now().add(Duration(days: duration)),
                  );

                  try {
                    await ChallengeDAO.addChallenge(challenge);
                    Navigator.pop(context);
                    _loadData();
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => const AlertSuccess('Challenge added successfully!'),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertError('Failed to add challenge: $e'),
                      );
                    }
                  }
                }
              }
            },
            child: const Text('Add'),
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
        title: const Text('Edit Challenge'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: durationController,
                      decoration: const InputDecoration(labelText: 'Duration (days)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: pointsController,
                      decoration: const InputDecoration(labelText: 'Points Reward'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Difficulty'),
                value: selectedDifficulty,
                items: ['Easy', 'Medium', 'Hard'].map((difficulty) {
                  return DropdownMenuItem(value: difficulty, child: Text(difficulty));
                }).toList(),
                onChanged: (value) => selectedDifficulty = value!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tasksController,
                decoration: const InputDecoration(
                  labelText: 'Tasks (one per line)',
                  hintText: 'Task 1\nTask 2\nTask 3',
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty &&
                  categoryController.text.isNotEmpty &&
                  durationController.text.isNotEmpty &&
                  pointsController.text.isNotEmpty) {
                final duration = int.tryParse(durationController.text);
                final points = int.tryParse(pointsController.text);
                final tasks = tasksController.text
                    .split('\n')
                    .where((task) => task.trim().isNotEmpty)
                    .toList();

                if (duration != null && points != null) {
                  final updatedChallenge = Challenge(
                    key: challenge.key,
                    title: titleController.text,
                    description: descriptionController.text,
                    category: categoryController.text,
                    durationDays: duration,
                    pointsReward: points,
                    difficulty: selectedDifficulty,
                    tasks: tasks,
                    startDate: challenge.startDate,
                    endDate: challenge.endDate,
                  );

                  try {
                    await ChallengeDAO.updateChallenge(updatedChallenge);
                    Navigator.pop(context);
                    _loadData();
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => const AlertSuccess('Challenge updated successfully!'),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertError('Failed to update challenge: $e'),
                      );
                    }
                  }
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteChallenge(Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Challenge'),
        content: Text('Are you sure you want to delete "${challenge.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ChallengeDAO.deleteChallenge(challenge.key);
                Navigator.pop(context);
                _loadData();
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => const AlertSuccess('Challenge deleted successfully!'),
                  );
                }
              } catch (e) {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertError('Failed to delete challenge: $e'),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 