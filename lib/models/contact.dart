import 'enums.dart';

class Contact {
  final String name;
  final String email;
  final String subject;
  final String message;
  final int createdAt;
  final ContactStatus status;
  final String? responseMessage;
  final int? respondedAt;
  final String? responseBy;

  Contact({
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.createdAt,
    required this.status,
    this.responseMessage,
    this.respondedAt,
    this.responseBy,
  });

  Contact.fromJson(Map<dynamic, dynamic> json)
    : name = json["name"] as String,
      email = json["email"] as String,
      subject = json["subject"] as String,
      message = json["message"] as String,
      createdAt = json["createdAt"] as int,
      status = ContactStatus.fromJson(json["status"] as String),
      responseMessage = json["responseMessage"] as String?,
      respondedAt = json["respondedAt"] as int?,
      responseBy = json["responseBy"] as String?;

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
    'name': name,
    'email': email,
    'subject': subject,
    'message': message,
    'createdAt': createdAt,
    'status': status.toJson(),
    'responseMessage': responseMessage,
    'respondedAt': respondedAt,
    'responseBy': responseBy,
  };

  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    'email': email,
    'subject': subject,
    'message': message,
    'createdAt': createdAt,
    'status': status.toJson(),
    'responseMessage': responseMessage,
    'respondedAt': respondedAt,
    'responseBy': responseBy,
  };
}
