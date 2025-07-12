import 'package:living/models/carbon_footprint_model.dart';

class CarbonCalculatorService {
  // Advanced emission factors with regional variations
  static final Map<String, Map<String, double>> regionalEmissionFactors = {
    'US': {
      'electricity': 0.92, // kg CO2/kWh
      'natural_gas': 2.02, // kg CO2/m³
      'gasoline': 2.32, // kg CO2/L
      'diesel': 2.69, // kg CO2/L
      'aviation': 0.255, // kg CO2/km
      'beef': 13.3, // kg CO2/kg
      'pork': 4.6, // kg CO2/kg
      'chicken': 2.9, // kg CO2/kg
      'dairy': 1.4, // kg CO2/kg
      'vegetables': 0.2, // kg CO2/kg
      'fruits': 0.3, // kg CO2/kg
      'grains': 0.5, // kg CO2/kg
    },
    'EU': {
      'electricity': 0.85,
      'natural_gas': 1.89,
      'gasoline': 2.31,
      'diesel': 2.68,
      'aviation': 0.255,
      'beef': 13.3,
      'pork': 4.6,
      'chicken': 2.9,
      'dairy': 1.4,
      'vegetables': 0.2,
      'fruits': 0.3,
      'grains': 0.5,
    },
    'Asia': {
      'electricity': 0.95,
      'natural_gas': 2.15,
      'gasoline': 2.32,
      'diesel': 2.69,
      'aviation': 0.255,
      'beef': 13.3,
      'pork': 4.6,
      'chicken': 2.9,
      'dairy': 1.4,
      'vegetables': 0.2,
      'fruits': 0.3,
      'grains': 0.5,
    },
  };

  // Calculate carbon footprint for transportation
  static double calculateTransportationFootprint({
    required String mode,
    required double distance,
    required String region,
    double? occupancy = 1.0,
    String? fuelType,
  }) {
    final factors = regionalEmissionFactors[region] ?? regionalEmissionFactors['US']!;
    
    switch (mode.toLowerCase()) {
      case 'car_gasoline':
        return factors['gasoline']! * distance * 0.404; // 0.404 L/km average
      case 'car_diesel':
        return factors['diesel']! * distance * 0.35; // 0.35 L/km average
      case 'car_electric':
        return (factors['electricity'] ?? 0.0) * distance * 0.2; // 0.2 kWh/km average
      case 'bus':
        final occ = (occupancy ?? 1) == 0 ? 1 : occupancy ?? 1;
        return (factors['diesel'] ?? 0.0) * distance * 0.35 / occ; // Shared emissions
      case 'train':
        final occ = (occupancy ?? 1) == 0 ? 1 : occupancy ?? 1;
        return (factors['electricity'] ?? 0.0) * distance * 0.1 / occ; // Electric train
      case 'airplane':
        return (factors['aviation'] ?? 0.0) * distance;
      case 'walking':
      case 'cycling':
        return 0.0; // Zero emissions
      default:
        return 0.0;
    }
  }

  // Calculate carbon footprint for energy consumption
  static double calculateEnergyFootprint({
    required String energyType,
    required double consumption,
    required String region,
    double? renewablePercentage = 0.0,
  }) {
    final factors = regionalEmissionFactors[region] ?? regionalEmissionFactors['US']!;
    
    switch (energyType.toLowerCase()) {
      case 'electricity':
        final gridFactor = factors['electricity']!;
        final renewableFactor = gridFactor * (1 - (renewablePercentage ?? 0.0) / 100);
        return renewableFactor * consumption;
      case 'natural_gas':
        return factors['natural_gas']! * consumption;
      case 'heating_oil':
        return 2.68 * consumption; // kg CO2/L
      case 'propane':
        return 1.51 * consumption; // kg CO2/L
      case 'solar':
      case 'wind':
      case 'hydro':
        return 0.0; // Renewable energy
      default:
        return 0.0;
    }
  }

  // Calculate carbon footprint for food consumption
  static double calculateFoodFootprint({
    required String foodType,
    required double weight,
    required String region,
    bool isOrganic = false,
    bool isLocal = false,
    String? transportMode,
    double? transportDistance,
  }) {
    final factors = regionalEmissionFactors[region] ?? regionalEmissionFactors['US']!;
    double baseFactor = 0.0;
    
    switch (foodType.toLowerCase()) {
      case 'beef':
        baseFactor = factors['beef']!;
        break;
      case 'pork':
        baseFactor = factors['pork']!;
        break;
      case 'chicken':
        baseFactor = factors['chicken']!;
        break;
      case 'dairy':
        baseFactor = factors['dairy']!;
        break;
      case 'vegetables':
        baseFactor = factors['vegetables']!;
        break;
      case 'fruits':
        baseFactor = factors['fruits']!;
        break;
      case 'grains':
        baseFactor = factors['grains']!;
        break;
      default:
        baseFactor = 0.5; // Default factor
    }

    double footprint = baseFactor * weight;

    // Apply modifiers
    if (isOrganic) {
      footprint *= 0.8; // 20% reduction for organic
    }
    
    if (isLocal) {
      footprint *= 0.9; // 10% reduction for local
    }

    // Add transport emissions if specified
    if (transportMode != null && transportDistance != null) {
      footprint += calculateTransportationFootprint(
        mode: transportMode,
        distance: transportDistance,
        region: region,
      ) * weight / 1000; // Convert to per kg
    }

    return footprint;
  }

  // Calculate carbon footprint for waste
  static double calculateWasteFootprint({
    required double weight,
    required String wasteType,
    required String region,
    double? recyclingPercentage = 0.0,
    double? compostingPercentage = 0.0,
  }) {
    double footprint = 0.0;
    
    switch (wasteType.toLowerCase()) {
      case 'general_waste':
        footprint = 0.5 * weight; // kg CO2/kg waste
        break;
      case 'recycled':
        footprint = -0.3 * weight; // Carbon saved
        break;
      case 'composted':
        footprint = -0.2 * weight; // Carbon saved
        break;
      case 'landfill':
        footprint = 0.8 * weight; // Higher emissions
        break;
      default:
        footprint = 0.5 * weight;
    }

    // Apply recycling and composting benefits
    final recycledWeight = weight * (recyclingPercentage ?? 0.0) / 100;
    final compostedWeight = weight * (compostingPercentage ?? 0.0) / 100;
    final generalWasteWeight = weight - recycledWeight - compostedWeight;

    footprint = (0.5 * generalWasteWeight) + (-0.3 * recycledWeight) + (-0.2 * compostedWeight);

    return footprint;
  }

  // Calculate carbon footprint for water usage
  static double calculateWaterFootprint({
    required double volume,
    required String waterType,
    required String region,
    bool isHotWater = false,
  }) {
    double footprint = 0.0;
    
    switch (waterType.toLowerCase()) {
      case 'hot_water':
        footprint = 0.298 * volume; // kg CO2/L (heating)
        break;
      case 'cold_water':
        footprint = 0.001 * volume; // Minimal treatment emissions
        break;
      case 'bottled_water':
        footprint = 0.298 * volume; // Production and transport
        break;
      default:
        footprint = 0.001 * volume;
    }

    return footprint;
  }

  // Calculate carbon footprint for digital activities
  static double calculateDigitalFootprint({
    required String activity,
    required double usage,
    required String region,
    String? deviceType,
    String? dataCenterLocation,
  }) {
    double footprint = 0.0;
    
    switch (activity.toLowerCase()) {
      case 'internet_usage':
        footprint = 0.0001 * usage; // kg CO2/GB
        break;
      case 'video_streaming':
        footprint = 0.0004 * usage; // kg CO2/hour
        break;
      case 'email':
        footprint = 0.00001 * usage; // kg CO2/email
        break;
      case 'cloud_storage':
        footprint = 0.0002 * usage; // kg CO2/GB
        break;
      case 'video_call':
        footprint = 0.0006 * usage; // kg CO2/hour
        break;
      default:
        footprint = 0.0001 * usage;
    }

    // Apply device efficiency modifier
    if (deviceType != null) {
      switch (deviceType.toLowerCase()) {
        case 'laptop':
          footprint *= 0.8;
          break;
        case 'desktop':
          footprint *= 1.2;
          break;
        case 'mobile':
          footprint *= 0.6;
          break;
        case 'tablet':
          footprint *= 0.7;
          break;
      }
    }

    return footprint;
  }

  // Calculate total daily carbon footprint
  static double calculateDailyFootprint({
    required Map<String, double> activities,
    required String region,
    Map<String, dynamic>? modifiers,
  }) {
    double totalFootprint = 0.0;

    for (final entry in activities.entries) {
      final activity = entry.key;
      final value = entry.value;

      switch (activity) {
        case 'car_distance':
          totalFootprint += calculateTransportationFootprint(
            mode: 'car_gasoline',
            distance: value,
            region: region,
          );
          break;
        case 'bus_distance':
          totalFootprint += calculateTransportationFootprint(
            mode: 'bus',
            distance: value,
            region: region,
            occupancy: modifiers?['bus_occupancy'] ?? 20.0,
          );
          break;
        case 'train_distance':
          totalFootprint += calculateTransportationFootprint(
            mode: 'train',
            distance: value,
            region: region,
            occupancy: modifiers?['train_occupancy'] ?? 100.0,
          );
          break;
        case 'electricity_usage':
          totalFootprint += calculateEnergyFootprint(
            energyType: 'electricity',
            consumption: value,
            region: region,
            renewablePercentage: modifiers?['renewable_percentage'] ?? 0.0,
          );
          break;
        case 'natural_gas_usage':
          totalFootprint += calculateEnergyFootprint(
            energyType: 'natural_gas',
            consumption: value,
            region: region,
          );
          break;
        case 'beef_consumption':
          totalFootprint += calculateFoodFootprint(
            foodType: 'beef',
            weight: value,
            region: region,
            isOrganic: modifiers?['organic'] ?? false,
            isLocal: modifiers?['local'] ?? false,
          );
          break;
        case 'vegetables_consumption':
          totalFootprint += calculateFoodFootprint(
            foodType: 'vegetables',
            weight: value,
            region: region,
            isOrganic: modifiers?['organic'] ?? false,
            isLocal: modifiers?['local'] ?? false,
          );
          break;
        case 'waste_generated':
          totalFootprint += calculateWasteFootprint(
            weight: value,
            wasteType: 'general_waste',
            region: region,
            recyclingPercentage: modifiers?['recycling_percentage'] ?? 0.0,
            compostingPercentage: modifiers?['composting_percentage'] ?? 0.0,
          );
          break;
        case 'hot_water_usage':
          totalFootprint += calculateWaterFootprint(
            volume: value,
            waterType: 'hot_water',
            region: region,
          );
          break;
        case 'internet_usage':
          totalFootprint += calculateDigitalFootprint(
            activity: 'internet_usage',
            usage: value,
            region: region,
            deviceType: modifiers?['device_type'],
          );
          break;
        case 'video_streaming':
          totalFootprint += calculateDigitalFootprint(
            activity: 'video_streaming',
            usage: value,
            region: region,
            deviceType: modifiers?['device_type'],
          );
          break;
      }
    }

    return totalFootprint;
  }

  // Calculate carbon offset recommendations
  static List<CarbonOffsetRecommendation> getOffsetRecommendations({
    required double dailyFootprint,
    required String region,
  }) {
    final recommendations = <CarbonOffsetRecommendation>[];

    // Tree planting recommendation
    final treesNeeded = (dailyFootprint * 365) / 22.0; // 22 kg CO2 per tree per year
    recommendations.add(CarbonOffsetRecommendation(
      type: 'Tree Planting',
      description: 'Plant ${treesNeeded.toStringAsFixed(1)} trees annually',
      costPerYear: treesNeeded * 10.0, // $10 per tree
      carbonOffset: treesNeeded * 22.0,
      impact: 'High',
    ));

    // Renewable energy investment
    final renewableInvestment = dailyFootprint * 365 * 0.5; // $0.50 per kg CO2
    recommendations.add(CarbonOffsetRecommendation(
      type: 'Renewable Energy',
      description: 'Invest in renewable energy projects',
      costPerYear: renewableInvestment,
      carbonOffset: dailyFootprint * 365 * 0.8, // 80% offset
      impact: 'Very High',
    ));

    // Energy efficiency upgrades
    final efficiencyCost = dailyFootprint * 365 * 0.3; // $0.30 per kg CO2
    recommendations.add(CarbonOffsetRecommendation(
      type: 'Energy Efficiency',
      description: 'Upgrade to energy-efficient appliances',
      costPerYear: efficiencyCost,
      carbonOffset: dailyFootprint * 365 * 0.4, // 40% reduction
      impact: 'High',
    ));

    // Public transportation
    final transitCost = dailyFootprint * 365 * 0.1; // $0.10 per kg CO2
    recommendations.add(CarbonOffsetRecommendation(
      type: 'Public Transit',
      description: 'Switch to public transportation',
      costPerYear: transitCost,
      carbonOffset: dailyFootprint * 365 * 0.6, // 60% reduction
      impact: 'Medium',
    ));

    return recommendations;
  }

  // Calculate carbon reduction potential
  static CarbonReductionPotential calculateReductionPotential({
    required double currentFootprint,
    required String region,
    Map<String, double>? currentActivities,
  }) {
    final potentialReductions = <String, double>{};
    double totalPotential = 0.0;

    // Transportation reductions
    if (currentActivities?['car_distance'] != null) {
      final carReduction = currentActivities!['car_distance']! * 0.6; // 60% reduction by switching to public transit
      potentialReductions['Transportation'] = carReduction * 0.404; // kg CO2
      totalPotential += potentialReductions['Transportation']!;
    }

    // Energy reductions
    if (currentActivities?['electricity_usage'] != null) {
      final energyReduction = currentActivities!['electricity_usage']! * 0.3; // 30% reduction by efficiency
      potentialReductions['Energy'] = energyReduction * 0.92; // kg CO2
      totalPotential += potentialReductions['Energy']!;
    }

    // Food reductions
    if (currentActivities?['beef_consumption'] != null) {
      final foodReduction = currentActivities!['beef_consumption']! * 0.5; // 50% reduction by switching to plant-based
      potentialReductions['Food'] = foodReduction * 13.3; // kg CO2
      totalPotential += potentialReductions['Food']!;
    }

    // Waste reductions
    if (currentActivities?['waste_generated'] != null) {
      final wasteReduction = currentActivities!['waste_generated']! * 0.7; // 70% reduction by recycling/composting
      potentialReductions['Waste'] = wasteReduction * 0.5; // kg CO2
      totalPotential += potentialReductions['Waste']!;
    }

    return CarbonReductionPotential(
      totalPotential: totalPotential,
      reductionsByCategory: potentialReductions,
      percentageReduction: (totalPotential / currentFootprint) * 100,
    );
  }

  // Get personalized tips based on user's footprint
  static List<String> getPersonalizedTips({
    required double dailyFootprint,
    required Map<String, double> activities,
    required String region,
  }) {
    final tips = <String>[];

    if (activities['car_distance'] != null && activities['car_distance']! > 20) {
      tips.add('Consider carpooling or using public transportation to reduce your daily commute emissions');
    }

    if (activities['electricity_usage'] != null && activities['electricity_usage']! > 30) {
      tips.add('Switch to LED bulbs and unplug unused devices to reduce electricity consumption');
    }

    if (activities['beef_consumption'] != null && activities['beef_consumption']! > 0.2) {
      tips.add('Try meatless Mondays or switch to plant-based alternatives to reduce food emissions');
    }

    if (activities['waste_generated'] != null && activities['waste_generated']! > 2) {
      tips.add('Start composting and recycling to reduce waste emissions');
    }

    if (dailyFootprint > 10) {
      tips.add('Your footprint is above average. Consider setting specific reduction goals');
    }

    if (dailyFootprint < 5) {
      tips.add('Great job! You\'re already below the target. Share your tips with others');
    }

    return tips;
  }
}

class CarbonOffsetRecommendation {
  final String type;
  final String description;
  final double costPerYear;
  final double carbonOffset;
  final String impact;

  CarbonOffsetRecommendation({
    required this.type,
    required this.description,
    required this.costPerYear,
    required this.carbonOffset,
    required this.impact,
  });
}

class CarbonReductionPotential {
  final double totalPotential;
  final Map<String, double> reductionsByCategory;
  final double percentageReduction;

  CarbonReductionPotential({
    required this.totalPotential,
    required this.reductionsByCategory,
    required this.percentageReduction,
  });
} 