// 2. ENUMS FOR STATUS
// Create this file as 'enums.dart'

/// Status values for contact messages
enum ContactStatus {
  new_,
  inProgress,
  responded,
  closed;

  // Method to convert enum to string
  String toJson() => name == 'new_' ? 'new' : name;

  // Method to create enum from string
  static ContactStatus fromJson(String json) {
    if (json == 'new') return ContactStatus.new_;

    return ContactStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () => ContactStatus.new_,
    );
  }
}
