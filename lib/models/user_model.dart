class User {
  final String name;
  final String email;
  final CarbonFootprint carbonFootprint;
  final WasteTracking wasteTracking;
  final Challenges challenges;
  final Preferences preferences;
  final Map<String, ActivityLog> activityLog;

  User({
    required this.name,
    required this.email,
    required this.carbonFootprint,
    required this.wasteTracking,
    required this.challenges,
    required this.preferences,
    required this.activityLog,
  });

  User.fromJson(Map<dynamic, dynamic> json)
      : name = json['name'] as String,
        email = json['email'] as String,
        carbonFootprint = CarbonFootprint.fromJson(
            json['carbonFootprint'] as Map<dynamic, dynamic>),
        wasteTracking = WasteTracking.fromJson(
            json['wasteTracking'] as Map<dynamic, dynamic>),
        challenges = Challenges.fromJson(json['challenges'] as Map<dynamic, dynamic>),
        preferences = Preferences.fromJson(
            json['preferences'] as Map<dynamic, dynamic>),
        activityLog = (json['activityLog'] as Map<dynamic, dynamic>).map(
          (key, value) => MapEntry(
            key.toString(),
            ActivityLog.fromJson(value as Map<dynamic, dynamic>),
          ),
        );

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'name': name,
        'email': email,
        'carbonFootprint': carbonFootprint.toJson(),
        'wasteTracking': wasteTracking.toJson(),
        'challenges': challenges.toJson(),
        'preferences': preferences.toJson(),
        'activityLog': activityLog.map((key, value) => MapEntry(key, value.toJson())),
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'email': email,
        'carbonFootprint': carbonFootprint.toMap(),
        'wasteTracking': wasteTracking.toMap(),
        'challenges': challenges.toMap(),
        'preferences': preferences.toMap(),
        'activityLog': activityLog.map((key, value) => MapEntry(key, value.toMap())),
      };
}

class CarbonFootprint {
  final double transport;
  final double energy;
  final double food;
  final double total;

  CarbonFootprint({
    required this.transport,
    required this.energy,
    required this.food,
    required this.total,
  });

  CarbonFootprint.fromJson(Map<dynamic, dynamic> json)
      : transport = json['transport'] as double,
        energy = json['energy'] as double,
        food = json['food'] as double,
        total = json['total'] as double;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'transport': transport,
        'energy': energy,
        'food': food,
        'total': total,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'transport': transport,
        'energy': energy,
        'food': food,
        'total': total,
      };
}

class WasteTracking {
  final int recycled;
  final int composted;
  final int plasticReduced;

  WasteTracking({
    required this.recycled,
    required this.composted,
    required this.plasticReduced,
  });

  WasteTracking.fromJson(Map<dynamic, dynamic> json)
      : recycled = json['recycled'] as int,
        composted = json['composted'] as int,
        plasticReduced = json['plasticReduced'] as int;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'recycled': recycled,
        'composted': composted,
        'plasticReduced': plasticReduced,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'recycled': recycled,
        'composted': composted,
        'plasticReduced': plasticReduced,
      };
}

class Challenges {
  final String plasticFreeWeek;
  final String bikeToWork;

  Challenges({
    required this.plasticFreeWeek,
    required this.bikeToWork,
  });

  Challenges.fromJson(Map<dynamic, dynamic> json)
      : plasticFreeWeek = json['plasticFreeWeek'] as String,
        bikeToWork = json['bikeToWork'] as String;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'plasticFreeWeek': plasticFreeWeek,
        'bikeToWork': bikeToWork,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'plasticFreeWeek': plasticFreeWeek,
        'bikeToWork': bikeToWork,
      };
}

class Preferences {
  final String diet;
  final String transport;

  Preferences({
    required this.diet,
    required this.transport,
  });

  Preferences.fromJson(Map<dynamic, dynamic> json)
      : diet = json['diet'] as String,
        transport = json['transport'] as String;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'diet': diet,
        'transport': transport,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'diet': diet,
        'transport': transport,
      };
}

class ActivityLog {
  final double energySaved;
  final int mealsEco;

  ActivityLog({
    required this.energySaved,
    required this.mealsEco,
  });

  ActivityLog.fromJson(Map<dynamic, dynamic> json)
      : energySaved = json['energySaved'] as double,
        mealsEco = json['mealsEco'] as int;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'energySaved': energySaved,
        'mealsEco': mealsEco,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'energySaved': energySaved,
        'mealsEco': mealsEco,
      };
}