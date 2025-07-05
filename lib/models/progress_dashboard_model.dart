class UserProgress {
  final String key;
  final String userId;
  final DateTime date;
  final double carbonFootprint;
  final double wasteReduction;
  final double energySavings;
  final int challengesCompleted;
  final int totalPoints;
  final Map<String, double> categoryProgress;

  UserProgress({
    required this.key,
    required this.userId,
    required this.date,
    required this.carbonFootprint,
    required this.wasteReduction,
    required this.energySavings,
    required this.challengesCompleted,
    required this.totalPoints,
    required this.categoryProgress,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
      'carbonFootprint': carbonFootprint,
      'wasteReduction': wasteReduction,
      'energySavings': energySavings,
      'challengesCompleted': challengesCompleted,
      'totalPoints': totalPoints,
      'categoryProgress': categoryProgress,
    };
  }

  factory UserProgress.fromJson(String key, Map<String, dynamic> json) {
    return UserProgress(
      key: key,
      userId: json['userId'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] ?? 0),
      carbonFootprint: (json['carbonFootprint'] ?? 0).toDouble(),
      wasteReduction: (json['wasteReduction'] ?? 0).toDouble(),
      energySavings: (json['energySavings'] ?? 0).toDouble(),
      challengesCompleted: json['challengesCompleted'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      categoryProgress: Map<String, double>.from(json['categoryProgress'] ?? {}),
    );
  }
}

class ProgressGoal {
  final String key;
  final String userId;
  final String goalType;
  final double targetValue;
  final double currentValue;
  final String unit;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;

  ProgressGoal({
    required this.key,
    required this.userId,
    required this.goalType,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'goalType': goalType,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unit': unit,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
    };
  }

  factory ProgressGoal.fromJson(String key, Map<String, dynamic> json) {
    return ProgressGoal(
      key: key,
      userId: json['userId'] ?? '',
      goalType: json['goalType'] ?? '',
      targetValue: (json['targetValue'] ?? 0).toDouble(),
      currentValue: (json['currentValue'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] ?? 0),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
} 