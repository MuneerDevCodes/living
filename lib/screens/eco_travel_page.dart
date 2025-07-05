import 'package:flutter/material.dart';
import 'package:living/models/eco_travel_model.dart';
import 'package:living/services/eco_travel_dao.dart';
import 'package:living/widgets/loader.dart';
import 'package:living/widgets/alert_error.dart';

class EcoTravelPage extends StatefulWidget {
  const EcoTravelPage({super.key});

  @override
  State<EcoTravelPage> createState() => _EcoTravelPageState();
}

class _EcoTravelPageState extends State<EcoTravelPage> {
  List<EcoTravelSuggestion> suggestions = [];
  bool isLoading = true;
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Transportation',
    'Accommodation',
    'Activities',
    'Food & Dining',
    'Shopping',
    'Local Experiences',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      suggestions = await EcoTravelDAO.getAllEcoTravelSuggestions();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertError('Failed to load eco-travel suggestions: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<EcoTravelSuggestion> get filteredSuggestions {
    if (selectedCategory == 'All') {
      return suggestions;
    }
    return suggestions.where((suggestion) => suggestion.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eco-Travel Guide'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Loader()
          : Column(
              children: [
                _buildCategoryFilter(),
                Expanded(
                  child: _buildSuggestionsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedCategory = category;
                });
              },
              selectedColor: Colors.green,
              checkmarkColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (filteredSuggestions.isEmpty) {
      return const Center(
        child: Text(
          'No eco-travel suggestions found for this category.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = filteredSuggestions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(
                _getCategoryIcon(suggestion.category),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              suggestion.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${suggestion.category} • ${suggestion.location}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildCarbonImpactInfo(suggestion),
                    const SizedBox(height: 16),
                    _buildSection('Benefits', suggestion.benefits),
                    const SizedBox(height: 16),
                    _buildSection('Tips', suggestion.tips),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          suggestion.isVerified ? Icons.verified : Icons.warning,
                          color: suggestion.isVerified ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          suggestion.isVerified ? 'Verified' : 'Pending Verification',
                          style: TextStyle(
                            color: suggestion.isVerified ? Colors.green : Colors.orange,
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

  Widget _buildCarbonImpactInfo(EcoTravelSuggestion suggestion) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud, color: Colors.blue[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carbon Impact',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${suggestion.carbonImpact.toStringAsFixed(1)} ${suggestion.carbonUnit}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'transportation':
        return Icons.directions_car;
      case 'accommodation':
        return Icons.hotel;
      case 'activities':
        return Icons.explore;
      case 'food & dining':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'local experiences':
        return Icons.location_city;
      default:
        return Icons.travel_explore;
    }
  }
} 