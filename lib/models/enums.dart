// 2. ENUMS FOR STATUS
// Create this file as 'enums.dart'

/// Status values for orders
enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  canceled;

  // Method to convert enum to string
  String toJson() => name;

  // Method to create enum from string
  static OrderStatus fromJson(String json) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () => OrderStatus.pending,
    );
  }
}

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
