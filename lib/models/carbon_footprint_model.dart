class CarbonFootprintEntry {
  final String key;
  final String userId;
  final String activityType;
  final double value;
  final String unit;
  final double carbonImpact;
  final DateTime date;
  final String? notes;

  CarbonFootprintEntry({
    required this.key,
    required this.userId,
    required this.activityType,
    required this.value,
    required this.unit,
    required this.carbonImpact,
    required this.date,
    this.notes,
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
    );
  }
}

class ActivityType {
  final String name;
  final String category;
  final double carbonFactor;
  final String unit;

  ActivityType({
    required this.name,
    required this.category,
    required this.carbonFactor,
    required this.unit,
  });
} 