class CarbonFootprintEntry {
  final String key;
  final String userId;
  final String activityType;
  final double value;
  final String unit;
  final double carbonImpact;
  final DateTime date;
  final String? notes;
  final String category;
  final String subcategory;
  final double emissionFactor;
  final String location;
  final bool isVerified;

  CarbonFootprintEntry({
    required this.key,
    required this.userId,
    required this.activityType,
    required this.value,
    required this.unit,
    required this.carbonImpact,
    required this.date,
    this.notes,
    required this.category,
    required this.subcategory,
    required this.emissionFactor,
    this.location = '',
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'activityType': activityType,
      'value': value,
      'unit': unit,
      'carbonImpact': carbonImpact,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'category': category,
      'subcategory': subcategory,
      'emissionFactor': emissionFactor,
      'location': location,
      'isVerified': isVerified,
    };
  }

  factory CarbonFootprintEntry.fromJson(String key, Map<String, dynamic> json) {
    return CarbonFootprintEntry(
      key: key,
      userId: json['userId'] ?? '',
      activityType: json['activityType'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      carbonImpact: (json['carbonImpact'] ?? 0).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] ?? 0),
      notes: json['notes'],
      category: json['category'] ?? '',
      subcategory: json['subcategory'] ?? '',
      emissionFactor: (json['emissionFactor'] ?? 0).toDouble(),
      location: json['location'] ?? '',
      isVerified: json['isVerified'] ?? false,
    );
  }
}

class ActivityType {
  final String name;
  final String category;
  final String subcategory;
  final double carbonFactor;
  final String unit;
  final String description;
  final String icon;
  final List<String> tips;
  final double minValue;
  final double maxValue;
  final String source;

  ActivityType({
    required this.name,
    required this.category,
    required this.subcategory,
    required this.carbonFactor,
    required this.unit,
    required this.description,
    required this.icon,
    required this.tips,
    this.minValue = 0,
    this.maxValue = 1000,
    required this.source,
  });
}

class CarbonGoal {
  final String key;
  final String userId;
  final String title;
  final String description;
  final double targetValue;
  final String unit;
  final DateTime startDate;
  final DateTime endDate;
  final String category;
  final bool isActive;
  final double currentProgress;
  final String status; // 'on_track', 'behind', 'ahead', 'completed'

  CarbonGoal({
    required this.key,
    required this.userId,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.unit,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.isActive,
    required this.currentProgress,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'targetValue': targetValue,
      'unit': unit,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'category': category,
      'isActive': isActive,
      'currentProgress': currentProgress,
      'status': status,
    };
  }

  factory CarbonGoal.fromJson(String key, Map<String, dynamic> json) {
    return CarbonGoal(
      key: key,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetValue: (json['targetValue'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] ?? 0),
      category: json['category'] ?? '',
      isActive: json['isActive'] ?? true,
      currentProgress: (json['currentProgress'] ?? 0).toDouble(),
      status: json['status'] ?? 'on_track',
    );
  }
}

class CarbonAnalytics {
  final double totalFootprint;
  final double weeklyAverage;
  final double monthlyAverage;
  final double yearlyAverage;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> weeklyTrend;
  final Map<String, double> monthlyTrend;
  final double reductionPercentage;
  final double targetFootprint;
  final String rank;
  final int totalEntries;

  CarbonAnalytics({
    required this.totalFootprint,
    required this.weeklyAverage,
    required this.monthlyAverage,
    required this.yearlyAverage,
    required this.categoryBreakdown,
    required this.weeklyTrend,
    required this.monthlyTrend,
    required this.reductionPercentage,
    required this.targetFootprint,
    required this.rank,
    required this.totalEntries,
  });
}

class EmissionFactor {
  final String activity;
  final String category;
  final String subcategory;
  final double factor;
  final String unit;
  final String source;
  final String region;
  final DateTime lastUpdated;
  final String methodology;

  EmissionFactor({
    required this.activity,
    required this.category,
    required this.subcategory,
    required this.factor,
    required this.unit,
    required this.source,
    required this.region,
    required this.lastUpdated,
    required this.methodology,
  });
} 