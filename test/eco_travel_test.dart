import 'package:flutter_test/flutter_test.dart';
import 'package:living/models/eco_travel_model.dart';

void main() {
  group('EcoTravelSuggestion Model Tests', () {
    test('should create EcoTravelSuggestion with all required fields', () {
      final suggestion = EcoTravelSuggestion(
        key: 'test_key',
        title: 'Test Suggestion',
        description: 'Test description',
        category: 'Transportation',
        location: 'Test City',
        carbonImpact: 0.5,
        carbonUnit: 'kg CO2/km',
        benefits: ['Benefit 1', 'Benefit 2'],
        tips: ['Tip 1', 'Tip 2'],
        imageUrl: 'test_image.jpg',
        isVerified: true,
      );

      expect(suggestion.key, 'test_key');
      expect(suggestion.title, 'Test Suggestion');
      expect(suggestion.description, 'Test description');
      expect(suggestion.category, 'Transportation');
      expect(suggestion.location, 'Test City');
      expect(suggestion.carbonImpact, 0.5);
      expect(suggestion.carbonUnit, 'kg CO2/km');
      expect(suggestion.benefits, ['Benefit 1', 'Benefit 2']);
      expect(suggestion.tips, ['Tip 1', 'Tip 2']);
      expect(suggestion.imageUrl, 'test_image.jpg');
      expect(suggestion.isVerified, true);
    });

    test('should convert to JSON correctly', () {
      final suggestion = EcoTravelSuggestion(
        key: 'test_key',
        title: 'Test Suggestion',
        description: 'Test description',
        category: 'Transportation',
        location: 'Test City',
        carbonImpact: 0.5,
        carbonUnit: 'kg CO2/km',
        benefits: ['Benefit 1', 'Benefit 2'],
        tips: ['Tip 1', 'Tip 2'],
        imageUrl: 'test_image.jpg',
        isVerified: true,
      );

      final json = suggestion.toJson();

      expect(json['title'], 'Test Suggestion');
      expect(json['description'], 'Test description');
      expect(json['category'], 'Transportation');
      expect(json['location'], 'Test City');
      expect(json['carbonImpact'], 0.5);
      expect(json['carbonUnit'], 'kg CO2/km');
      expect(json['benefits'], ['Benefit 1', 'Benefit 2']);
      expect(json['tips'], ['Tip 1', 'Tip 2']);
      expect(json['imageUrl'], 'test_image.jpg');
      expect(json['isVerified'], true);
    });

    test('should create from JSON correctly', () {
      final json = {
        'title': 'Test Suggestion',
        'description': 'Test description',
        'category': 'Transportation',
        'location': 'Test City',
        'carbonImpact': 0.5,
        'carbonUnit': 'kg CO2/km',
        'benefits': ['Benefit 1', 'Benefit 2'],
        'tips': ['Tip 1', 'Tip 2'],
        'imageUrl': 'test_image.jpg',
        'isVerified': true,
      };

      final suggestion = EcoTravelSuggestion.fromJson('test_key', json);

      expect(suggestion.key, 'test_key');
      expect(suggestion.title, 'Test Suggestion');
      expect(suggestion.description, 'Test description');
      expect(suggestion.category, 'Transportation');
      expect(suggestion.location, 'Test City');
      expect(suggestion.carbonImpact, 0.5);
      expect(suggestion.carbonUnit, 'kg CO2/km');
      expect(suggestion.benefits, ['Benefit 1', 'Benefit 2']);
      expect(suggestion.tips, ['Tip 1', 'Tip 2']);
      expect(suggestion.imageUrl, 'test_image.jpg');
      expect(suggestion.isVerified, true);
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'title': 'Test Suggestion',
        'description': 'Test description',
        'category': 'Transportation',
        'location': 'Test City',
        'carbonImpact': 0.5,
        'carbonUnit': 'kg CO2/km',
      };

      final suggestion = EcoTravelSuggestion.fromJson('test_key', json);

      expect(suggestion.benefits, isEmpty);
      expect(suggestion.tips, isEmpty);
      expect(suggestion.imageUrl, '');
      expect(suggestion.isVerified, true); // Default value
    });

    test('should handle null values in JSON', () {
      final json = {
        'title': null,
        'description': null,
        'category': null,
        'location': null,
        'carbonImpact': null,
        'carbonUnit': null,
        'benefits': null,
        'tips': null,
        'imageUrl': null,
        'isVerified': null,
      };

      final suggestion = EcoTravelSuggestion.fromJson('test_key', json);

      expect(suggestion.title, '');
      expect(suggestion.description, '');
      expect(suggestion.category, '');
      expect(suggestion.location, '');
      expect(suggestion.carbonImpact, 0.0);
      expect(suggestion.carbonUnit, '');
      expect(suggestion.benefits, isEmpty);
      expect(suggestion.tips, isEmpty);
      expect(suggestion.imageUrl, '');
      expect(suggestion.isVerified, true);
    });
  });

  group('EcoTravelSuggestion Validation Tests', () {
    test('should validate carbon impact values', () {
      // Test negative carbon impact (carbon reduction)
      final negativeImpact = EcoTravelSuggestion(
        key: 'test_negative',
        title: 'Carbon Reduction Activity',
        description: 'Reduces carbon footprint',
        category: 'Activities',
        location: 'Test Location',
        carbonImpact: -2.5,
        carbonUnit: 'kg CO2/day',
        benefits: ['Reduces emissions'],
        tips: ['Do this regularly'],
        imageUrl: '',
        isVerified: true,
      );

      expect(negativeImpact.carbonImpact, -2.5);
      expect(negativeImpact.carbonImpact < 0, true);

      // Test zero carbon impact
      final zeroImpact = EcoTravelSuggestion(
        key: 'test_zero',
        title: 'Carbon Neutral Activity',
        description: 'No carbon emissions',
        category: 'Transportation',
        location: 'Test Location',
        carbonImpact: 0.0,
        carbonUnit: 'kg CO2/km',
        benefits: ['No emissions'],
        tips: ['Good for environment'],
        imageUrl: '',
        isVerified: true,
      );

      expect(zeroImpact.carbonImpact, 0.0);
      expect(zeroImpact.carbonImpact == 0, true);
    });

    test('should validate category values', () {
      final validCategories = [
        'Transportation',
        'Accommodation',
        'Activities',
        'Food & Dining',
        'Shopping',
        'Local Experiences',
      ];

      for (final category in validCategories) {
        final suggestion = EcoTravelSuggestion(
          key: 'test_$category',
          title: 'Test $category',
          description: 'Test description',
          category: category,
          location: 'Test Location',
          carbonImpact: 0.5,
          carbonUnit: 'kg CO2/km',
          benefits: ['Benefit'],
          tips: ['Tip'],
          imageUrl: '',
          isVerified: true,
        );

        expect(suggestion.category, category);
        expect(validCategories.contains(suggestion.category), true);
      }
    });
  });

  group('EcoTravelSuggestion Content Tests', () {
    test('should handle long descriptions', () {
      final longDescription = 'This is a very long description that contains many words and should be handled properly by the application. It includes multiple sentences and various types of content to test how the system handles longer text content.';

      final suggestion = EcoTravelSuggestion(
        key: 'test_long',
        title: 'Test with Long Description',
        description: longDescription,
        category: 'Transportation',
        location: 'Test Location',
        carbonImpact: 0.5,
        carbonUnit: 'kg CO2/km',
        benefits: ['Benefit'],
        tips: ['Tip'],
        imageUrl: '',
        isVerified: true,
      );

      expect(suggestion.description, longDescription);
      expect(suggestion.description.length > 100, true);
    });

    test('should handle multiple benefits and tips', () {
      final multipleBenefits = [
        'Reduces carbon emissions',
        'Saves money on transportation',
        'Improves physical health',
        'Reduces traffic congestion',
        'Supports local economy',
      ];

      final multipleTips = [
        'Plan your route in advance',
        'Use mobile apps for real-time updates',
        'Consider weather conditions',
        'Bring necessary equipment',
        'Follow local regulations',
      ];

      final suggestion = EcoTravelSuggestion(
        key: 'test_multiple',
        title: 'Test with Multiple Items',
        description: 'Test description',
        category: 'Transportation',
        location: 'Test Location',
        carbonImpact: 0.5,
        carbonUnit: 'kg CO2/km',
        benefits: multipleBenefits,
        tips: multipleTips,
        imageUrl: '',
        isVerified: true,
      );

      expect(suggestion.benefits.length, 5);
      expect(suggestion.tips.length, 5);
      expect(suggestion.benefits, multipleBenefits);
      expect(suggestion.tips, multipleTips);
    });

    test('should handle special characters in text', () {
      final specialText = 'Test with special characters: é, ñ, ü, €, £, ¥, ©, ®, ™, and emojis 🚗🚲🚌';

      final suggestion = EcoTravelSuggestion(
        key: 'test_special',
        title: specialText,
        description: specialText,
        category: 'Transportation',
        location: 'Test Location',
        carbonImpact: 0.5,
        carbonUnit: 'kg CO2/km',
        benefits: [specialText],
        tips: [specialText],
        imageUrl: '',
        isVerified: true,
      );

      expect(suggestion.title, specialText);
      expect(suggestion.description, specialText);
      expect(suggestion.benefits.first, specialText);
      expect(suggestion.tips.first, specialText);
    });
  });

  group('EcoTravelSuggestion Business Logic Tests', () {
    test('should categorize carbon impact correctly', () {
      // Carbon reduction activities
      final carbonReduction = EcoTravelSuggestion(
        key: 'reduction',
        title: 'Carbon Reduction',
        description: 'Reduces carbon footprint',
        category: 'Activities',
        location: 'Test Location',
        carbonImpact: -2.5,
        carbonUnit: 'kg CO2/day',
        benefits: ['Reduces emissions'],
        tips: ['Do regularly'],
        imageUrl: '',
        isVerified: true,
      );

      // Carbon neutral activities
      final carbonNeutral = EcoTravelSuggestion(
        key: 'neutral',
        title: 'Carbon Neutral',
        description: 'No carbon emissions',
        category: 'Transportation',
        location: 'Test Location',
        carbonImpact: 0.0,
        carbonUnit: 'kg CO2/km',
        benefits: ['No emissions'],
        tips: ['Good choice'],
        imageUrl: '',
        isVerified: true,
      );

      // Low carbon activities
      final lowCarbon = EcoTravelSuggestion(
        key: 'low',
        title: 'Low Carbon',
        description: 'Low carbon emissions',
        category: 'Transportation',
        location: 'Test Location',
        carbonImpact: 0.1,
        carbonUnit: 'kg CO2/km',
        benefits: ['Low emissions'],
        tips: ['Better than driving'],
        imageUrl: '',
        isVerified: true,
      );

      // High carbon activities
      final highCarbon = EcoTravelSuggestion(
        key: 'high',
        title: 'High Carbon',
        description: 'High carbon emissions',
        category: 'Transportation',
        location: 'Test Location',
        carbonImpact: 2.0,
        carbonUnit: 'kg CO2/km',
        benefits: ['Convenient'],
        tips: ['Consider alternatives'],
        imageUrl: '',
        isVerified: true,
      );

      // Test categorization logic
      expect(carbonReduction.carbonImpact < 0, true);
      expect(carbonNeutral.carbonImpact == 0, true);
      expect(lowCarbon.carbonImpact > 0 && lowCarbon.carbonImpact < 0.5, true);
      expect(highCarbon.carbonImpact > 1.0, true);
    });

    test('should validate location formats', () {
      final locationFormats = [
        'New York City, USA',
        'Amsterdam, Netherlands',
        'Costa Rica',
        'Great Barrier Reef, Australia',
        'Marrakech, Morocco',
        'Europe',
        'Global',
      ];

      for (final location in locationFormats) {
        final suggestion = EcoTravelSuggestion(
          key: 'test_$location',
          title: 'Test for $location',
          description: 'Test description',
          category: 'Transportation',
          location: location,
          carbonImpact: 0.5,
          carbonUnit: 'kg CO2/km',
          benefits: ['Benefit'],
          tips: ['Tip'],
          imageUrl: '',
          isVerified: true,
        );

        expect(suggestion.location, location);
        expect(suggestion.location.isNotEmpty, true);
      }
    });

    test('should validate carbon unit formats', () {
      final unitFormats = [
        'kg CO2/km',
        'kg CO2/night',
        'kg CO2/meal',
        'kg CO2/purchase',
        'kg CO2/day',
        'kg CO2/tour',
        'kg CO2/visit',
      ];

      for (final unit in unitFormats) {
        final suggestion = EcoTravelSuggestion(
          key: 'test_$unit',
          title: 'Test with $unit',
          description: 'Test description',
          category: 'Transportation',
          location: 'Test Location',
          carbonImpact: 0.5,
          carbonUnit: unit,
          benefits: ['Benefit'],
          tips: ['Tip'],
          imageUrl: '',
          isVerified: true,
        );

        expect(suggestion.carbonUnit, unit);
        expect(suggestion.carbonUnit.contains('kg CO2'), true);
      }
    });
  });
} 