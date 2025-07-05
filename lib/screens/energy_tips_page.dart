import 'package:flutter/material.dart';
import 'package:living/models/energy_tip_model.dart';
import 'package:living/services/energy_tip_dao.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';

class EnergyTipsPage extends StatefulWidget {
  const EnergyTipsPage({super.key});

  @override
  State<EnergyTipsPage> createState() => _EnergyTipsPageState();
}

class _EnergyTipsPageState extends State<EnergyTipsPage> {
  List<EnergyTip> energyTips = [];
  bool isLoading = true;
  String selectedCategory = 'All';
  String selectedDifficulty = 'All';

  final List<String> categories = [
    'All',
    'Lighting',
    'Heating & Cooling',
    'Appliances',
    'Insulation',
    'Renewable Energy',
    'Behavioral',
  ];

  final List<String> difficulties = [
    'All',
    'Easy',
    'Medium',
    'Hard',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      energyTips = await EnergyTipDAO.getAllEnergyTips();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to load energy tips: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<EnergyTip> get filteredTips {
    return energyTips.where((tip) {
      final categoryMatch = selectedCategory == 'All' || tip.category == selectedCategory;
      final difficultyMatch = selectedDifficulty == 'All' || tip.difficulty == selectedDifficulty;
      return categoryMatch && difficultyMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Conservation Tips'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Loader()
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: _buildTipsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Category filter
          Row(
            children: [
              const Text('Category: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: categories.map((category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Difficulty filter
          Row(
            children: [
              const Text('Difficulty: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: DropdownButton<String>(
                  value: selectedDifficulty,
                  isExpanded: true,
                  items: difficulties.map((difficulty) {
                    return DropdownMenuItem(value: difficulty, child: Text(difficulty));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDifficulty = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsList() {
    if (filteredTips.isEmpty) {
      return const Center(
        child: Text(
          'No energy tips found for the selected filters.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTips.length,
      itemBuilder: (context, index) {
        final tip = filteredTips[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getDifficultyColor(tip.difficulty),
              child: Icon(
                Icons.lightbulb,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              tip.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${tip.category} • ${tip.difficulty}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildSavingsInfo(tip),
                    const SizedBox(height: 16),
                    _buildStepsList(tip.steps),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          tip.isVerified ? Icons.verified : Icons.warning,
                          color: tip.isVerified ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tip.isVerified ? 'Verified Tip' : 'Pending Verification',
                          style: TextStyle(
                            color: tip.isVerified ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavingsInfo(EnergyTip tip) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.savings, color: Colors.green[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Potential Savings',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${tip.potentialSavings.toStringAsFixed(1)} ${tip.savingsUnit}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsList(List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Steps:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
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
} 