class Challenge {
  final String key;
  final String title;
  final String description;
  final String category;
  final int durationDays;
  final int pointsReward;
  final String difficulty;
  final List<String> tasks;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String environmentalImpact;
  final String benefits;
  final List<String> tips;
  final double carbonReduction; // in kg CO2 per day
  final String icon;

  Challenge({
    required this.key,
    required this.title,
    required this.description,
    required this.category,
    required this.durationDays,
    required this.pointsReward,
    required this.difficulty,
    required this.tasks,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.environmentalImpact = '',
    this.benefits = '',
    this.tips = const [],
    this.carbonReduction = 0.0,
    this.icon = '🌱',
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'durationDays': durationDays,
      'pointsReward': pointsReward,
      'difficulty': difficulty,
      'tasks': tasks,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'isActive': isActive,
      'environmentalImpact': environmentalImpact,
      'benefits': benefits,
      'tips': tips,
      'carbonReduction': carbonReduction,
      'icon': icon,
    };
  }

  factory Challenge.fromJson(String key, Map<String, dynamic> json) {
    return Challenge(
      key: key,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      durationDays: json['durationDays'] ?? 7,
      pointsReward: json['pointsReward'] ?? 0,
      difficulty: json['difficulty'] ?? 'Easy',
      tasks: List<String>.from(json['tasks'] ?? []),
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] ?? 0),
      isActive: json['isActive'] ?? true,
      environmentalImpact: json['environmentalImpact'] ?? '',
      benefits: json['benefits'] ?? '',
      tips: List<String>.from(json['tips'] ?? []),
      carbonReduction: (json['carbonReduction'] ?? 0.0).toDouble(),
      icon: json['icon'] ?? '🌱',
    );
  }
}

class UserChallenge {
  final String key;
  final String userId;
  final String challengeId;
  final DateTime startDate;
  final DateTime? completedDate;
  final bool isCompleted;
  final int progress;
  final List<bool> taskCompletion;

  UserChallenge({
    required this.key,
    required this.userId,
    required this.challengeId,
    required this.startDate,
    this.completedDate,
    this.isCompleted = false,
    this.progress = 0,
    required this.taskCompletion,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'startDate': startDate.millisecondsSinceEpoch,
      'completedDate': completedDate?.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'progress': progress,
      'taskCompletion': taskCompletion,
    };
  }

  factory UserChallenge.fromJson(String key, Map<String, dynamic> json) {
    return UserChallenge(
      key: key,
      userId: json['userId'] ?? '',
      challengeId: json['challengeId'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] ?? 0),
      completedDate: json['completedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedDate'])
          : null,
      isCompleted: json['isCompleted'] ?? false,
      progress: json['progress'] ?? 0,
      taskCompletion: List<bool>.from(json['taskCompletion'] ?? []),
    );
  }
} 