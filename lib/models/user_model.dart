class User {
  final String uuid;
  final String role;
  final String displayname;
  final String? shippingAddress;
  final String? paymentMethod;
  final Preferences? preferences;
  final Map<String, ActivityLog>? activityLog;

  User({
    required this.uuid,
    required this.role,
    required this.displayname,
    this.shippingAddress,
    this.paymentMethod,
    this.preferences,
    this.activityLog,
  });

  User.fromJson(Map<dynamic, dynamic> json)
      : uuid = json['uuid'] as String,
        role = json['role'] as String,
        displayname = json['displayname'] as String,
        shippingAddress = json['shippingAddress'] as String?,
        paymentMethod = json['paymentMethod'] as String?,
        preferences = json['preferences'] != null
            ? Preferences.fromJson(json['preferences'] as Map<dynamic, dynamic>)
            : null,
        activityLog = json['activityLog'] != null
            ? (json['activityLog'] as Map<dynamic, dynamic>).map(
                (key, value) => MapEntry(
                  key.toString(),
                  ActivityLog.fromJson(value as Map<dynamic, dynamic>),
                ),
              )
            : null;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'uuid': uuid,
        'role': role,
        'displayname': displayname,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'preferences': preferences?.toJson(),
        'activityLog': activityLog?.map((key, value) => MapEntry(key, value.toJson())),
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'uuid': uuid,
        'role': role,
        'displayname': displayname,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'preferences': preferences?.toMap(),
        'activityLog': activityLog?.map((key, value) => MapEntry(key, value.toMap())),
      };
}

class Preferences {
  final String? diet;
  final String? transport;

  Preferences({
    this.diet,
    this.transport,
  });

  Preferences.fromJson(Map<dynamic, dynamic> json)
      : diet = json['diet'] as String?,
        transport = json['transport'] as String?;

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
  final double? energySaved;
  final int? mealsEco;

  ActivityLog({
    this.energySaved,
    this.mealsEco,
  });

  ActivityLog.fromJson(Map<dynamic, dynamic> json)
      : energySaved = json['energySaved'] as double?,
        mealsEco = json['mealsEco'] as int?;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'energySaved': energySaved,
        'mealsEco': mealsEco,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'energySaved': energySaved,
        'mealsEco': mealsEco,
      };
}