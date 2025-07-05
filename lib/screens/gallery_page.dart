import 'package:flutter/material.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final List<GalleryImage> galleryImages = [
    GalleryImage(
      id: '1',
      title: 'Solar Panels Installation',
      description: 'Renewable energy solutions for sustainable living',
      category: 'Energy',
      imageUrl: 'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=500',
    ),
    GalleryImage(
      id: '2',
      title: 'Organic Garden',
      description: 'Growing your own food sustainably',
      category: 'Food',
      imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=500',
    ),
    GalleryImage(
      id: '3',
      title: 'Recycling Center',
      description: 'Proper waste management and recycling',
      category: 'Waste',
      imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
    ),
    GalleryImage(
      id: '4',
      title: 'Electric Vehicle',
      description: 'Clean transportation alternatives',
      category: 'Transportation',
      imageUrl: 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=500',
    ),
    GalleryImage(
      id: '5',
      title: 'Green Building',
      description: 'Sustainable architecture and construction',
      category: 'Building',
      imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=500',
    ),
    GalleryImage(
      id: '6',
      title: 'Wind Turbines',
      description: 'Harnessing wind energy for clean power',
      category: 'Energy',
      imageUrl: 'https://images.unsplash.com/photo-1466611653911-95081537e5b7?w=500',
    ),
    GalleryImage(
      id: '7',
      title: 'Composting',
      description: 'Natural waste decomposition for soil health',
      category: 'Waste',
      imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500',
    ),
    GalleryImage(
      id: '8',
      title: 'Bicycle Commuting',
      description: 'Eco-friendly urban transportation',
      category: 'Transportation',
      imageUrl: 'https://images.unsplash.com/photo-1544191696-102dbdaeeaa5?w=500',
    ),
    GalleryImage(
      id: '9',
      title: 'Vertical Farming',
      description: 'Space-efficient urban agriculture',
      category: 'Food',
      imageUrl: 'https://images.unsplash.com/photo-1590779033100-9f60a05a013d?w=500',
    ),
    GalleryImage(
      id: '10',
      title: 'Green Roof',
      description: 'Living roofs for urban biodiversity',
      category: 'Building',
      imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
    ),
    GalleryImage(
      id: '11',
      title: 'Water Conservation',
      description: 'Efficient water usage and rainwater harvesting',
      category: 'Water',
      imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
    ),
    GalleryImage(
      id: '12',
      title: 'Sustainable Fashion',
      description: 'Eco-friendly clothing and textiles',
      category: 'Fashion',
      imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
    ),
  ];

  String selectedCategory = 'All';
  final List<String> categories = [
    'All',
    'Energy',
    'Food',
    'Waste',
    'Transportation',
    'Building',
    'Water',
    'Fashion',
  ];

  List<GalleryImage> get filteredImages {
    if (selectedCategory == 'All') {
      return galleryImages;
    }
    return galleryImages.where((image) => image.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sustainable Living Gallery'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _buildGalleryGrid(),
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

  Widget _buildGalleryGrid() {
    if (filteredImages.isEmpty) {
      return const Center(
        child: Text(
          'No images found for this category.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredImages.length,
      itemBuilder: (context, index) {
        final image = filteredImages[index];
        return _buildImageCard(image);
      },
    );
  }

  Widget _buildImageCard(GalleryImage image) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _showImageDetail(image),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  child: Image.network(
                    image.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    image.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
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

  void _showImageDetail(GalleryImage image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  image.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image,
                        color: Colors.grey[400],
                        size: 60,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      image.category,
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    image.description,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryImage {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;

  GalleryImage({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
  });
} 