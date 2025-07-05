class Certification {
  final String key;
  final String name;
  final String description;
  final String category;
  final String logoUrl;
  final List<String> criteria;
  final String verificationProcess;
  final String benefits;
  final bool isVerified;

  Certification({
    required this.key,
    required this.name,
    required this.description,
    required this.category,
    required this.logoUrl,
    required this.criteria,
    required this.verificationProcess,
    required this.benefits,
    this.isVerified = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'logoUrl': logoUrl,
      'criteria': criteria,
      'verificationProcess': verificationProcess,
      'benefits': benefits,
      'isVerified': isVerified,
    };
  }

  factory Certification.fromJson(String key, Map<String, dynamic> json) {
    return Certification(
      key: key,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
      criteria: List<String>.from(json['criteria'] ?? []),
      verificationProcess: json['verificationProcess'] ?? '',
      benefits: json['benefits'] ?? '',
      isVerified: json['isVerified'] ?? true,
    );
  }
} 