class User {
  final String uuid;
  final String role;
  final String displayname;
  final String? shippingAddress;
  final String? paymentMethod;
  final ShippingInfo? shippingInfo;
  final PaymentInfo? paymentInfo;
  final Preferences? preferences;
  final Map<String, ActivityLog>? activityLog;

  User({
    required this.uuid,
    required this.role,
    required this.displayname,
    this.shippingAddress,
    this.paymentMethod,
    this.shippingInfo,
    this.paymentInfo,
    this.preferences,
    this.activityLog,
  });

  User.fromJson(Map<dynamic, dynamic> json)
      : uuid = json['uuid'] as String,
        role = json['role'] as String,
        displayname = json['displayname'] as String,
        shippingAddress = json['shippingAddress'] as String?,
        paymentMethod = json['paymentMethod'] as String?,
        shippingInfo = json['shippingInfo'] != null
            ? ShippingInfo.fromJson(json['shippingInfo'] as Map<dynamic, dynamic>)
            : null,
        paymentInfo = json['paymentInfo'] != null
            ? PaymentInfo.fromJson(json['paymentInfo'] as Map<dynamic, dynamic>)
            : null,
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
        'shippingInfo': shippingInfo?.toJson(),
        'paymentInfo': paymentInfo?.toJson(),
        'preferences': preferences?.toJson(),
        'activityLog': activityLog?.map((key, value) => MapEntry(key, value.toJson())),
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'uuid': uuid,
        'role': role,
        'displayname': displayname,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'shippingInfo': shippingInfo?.toMap(),
        'paymentInfo': paymentInfo?.toMap(),
        'preferences': preferences?.toMap(),
        'activityLog': activityLog?.map((key, value) => MapEntry(key, value.toMap())),
      };

  User copyWith({
    String? uuid,
    String? role,
    String? displayname,
    String? shippingAddress,
    String? paymentMethod,
    ShippingInfo? shippingInfo,
    PaymentInfo? paymentInfo,
    Preferences? preferences,
    Map<String, ActivityLog>? activityLog,
  }) {
    return User(
      uuid: uuid ?? this.uuid,
      role: role ?? this.role,
      displayname: displayname ?? this.displayname,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      preferences: preferences ?? this.preferences,
      activityLog: activityLog ?? this.activityLog,
    );
  }
}

class ShippingInfo {
  final String fullName;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String phone;
  final String? email;

  ShippingInfo({
    required this.fullName,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.phone,
    this.email,
  });

  ShippingInfo.fromJson(Map<dynamic, dynamic> json)
      : fullName = json['fullName'] as String,
        addressLine1 = json['addressLine1'] as String,
        addressLine2 = json['addressLine2'] as String?,
        city = json['city'] as String,
        state = json['state'] as String,
        zipCode = json['zipCode'] as String,
        country = json['country'] as String,
        phone = json['phone'] as String,
        email = json['email'] as String?;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'fullName': fullName,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'country': country,
        'phone': phone,
        'email': email,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'fullName': fullName,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'country': country,
        'phone': phone,
        'email': email,
      };

  String get formattedAddress {
    final parts = [fullName, addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    parts.addAll([city, state, zipCode, country]);
    return parts.join(', ');
  }
}

class PaymentInfo {
  final String? cardType;
  final String? lastFourDigits;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cardholderName;
  final String? easypaisaNumber;
  final String? bankName;
  final String? accountNumber;

  PaymentInfo({
    this.cardType,
    this.lastFourDigits,
    this.expiryMonth,
    this.expiryYear,
    this.cardholderName,
    this.easypaisaNumber,
    this.bankName,
    this.accountNumber,
  });

  PaymentInfo.fromJson(Map<dynamic, dynamic> json)
      : cardType = json['cardType'] as String?,
        lastFourDigits = json['lastFourDigits'] as String?,
        expiryMonth = json['expiryMonth'] as String?,
        expiryYear = json['expiryYear'] as String?,
        cardholderName = json['cardholderName'] as String?,
        easypaisaNumber = json['easypaisaNumber'] as String?,
        bankName = json['bankName'] as String?,
        accountNumber = json['accountNumber'] as String?;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'cardType': cardType,
        'lastFourDigits': lastFourDigits,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
        'cardholderName': cardholderName,
        'easypaisaNumber': easypaisaNumber,
        'bankName': bankName,
        'accountNumber': accountNumber,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'cardType': cardType,
        'lastFourDigits': lastFourDigits,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
        'cardholderName': cardholderName,
        'easypaisaNumber': easypaisaNumber,
        'bankName': bankName,
        'accountNumber': accountNumber,
      };

  String get formattedCard {
    if (cardType != null && lastFourDigits != null) {
      return '$cardType •••• $lastFourDigits';
    } else if (easypaisaNumber != null) {
      return 'Easypaisa •••• ${easypaisaNumber!.substring(easypaisaNumber!.length - 4)}';
    } else if (bankName != null && accountNumber != null) {
      return '$bankName •••• ${accountNumber!.substring(accountNumber!.length - 4)}';
    }
    return 'Payment Method';
  }
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