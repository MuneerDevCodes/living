class WasteEntry {
  final String key;
  final String userId;
  final String wasteType;
  final double amount;
  final String unit;
  final String disposalMethod;
  final DateTime date;
  final String? notes;

  WasteEntry({
    required this.key,
    required this.userId,
    required this.wasteType,
    required this.amount,
    required this.unit,
    required this.disposalMethod,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'wasteType': wasteType,
      'amount': amount,
      'unit': unit,
      'disposalMethod': disposalMethod,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  factory WasteEntry.fromJson(String key, Map<String, dynamic> json) {
    return WasteEntry(
      key: key,
      userId: json['userId'] ?? '',
      wasteType: json['wasteType'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      disposalMethod: json['disposalMethod'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] ?? 0),
      notes: json['notes'],
    );
  }
}

class WasteReductionGoal {
  final String key;
  final String userId;
  final String goalType;
  final double targetAmount;
  final String unit;
  final DateTime startDate;
  final DateTime endDate;
  final double currentAmount;
  final bool isCompleted;

  WasteReductionGoal({
    required this.key,
    required this.userId,
    required this.goalType,
    required this.targetAmount,
    required this.unit,
    required this.startDate,
    required this.endDate,
    this.currentAmount = 0,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'goalType': goalType,
      'targetAmount': targetAmount,
      'unit': unit,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'currentAmount': currentAmount,
      'isCompleted': isCompleted,
    };
  }

  factory WasteReductionGoal.fromJson(String key, Map<String, dynamic> json) {
    return WasteReductionGoal(
      key: key,
      userId: json['userId'] ?? '',
      goalType: json['goalType'] ?? '',
      targetAmount: (json['targetAmount'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(json['endDate'] ?? 0),
      currentAmount: (json['currentAmount'] ?? 0).toDouble(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
} 