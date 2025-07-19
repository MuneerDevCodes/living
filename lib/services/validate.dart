String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return "Email is required";
  final regExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!regExp.hasMatch(value)) return "Please enter a valid email address";
  if (value.length > 100) return "Email must be less than 100 characters";
  return null;
}

String? validatePass(String? value) {
  if (value == null || value.isEmpty) return "Password is required";
  final regExp = RegExp(r'^[a-zA-Z0-9]+$');
  return regExp.hasMatch(value)
      ? null
      : "Password should contain only letters and numbers";
}

String? validateName(String? value) {
  if (value == null || value.isEmpty) return "Name is required";
  if (value.length < 3) return "Value must be greater than 3 chars";
  final regExp = RegExp(r'^[a-zA-Z0-9 ]+$');
  return regExp.hasMatch(value)
      ? null
      : "Name should contain only letters, numbers, or spaces";
}

String? validateDob(String? value) {
  return (value == null || value.isEmpty) ? "Value is required" : null;
}

String? validateAge(String? value) {
  if (value == null || value.isEmpty) return "Value is required";
  final regExp = RegExp(r'^[0-9]+$');
  return regExp.hasMatch(value) ? null : "Age should contain numbers";
}

String? validateMobile(String? value) {
  if (value == null || value.isEmpty) return "Value is required";
  if (value.length < 11) return "Value must be greater than 11 chars";
  final regExp = RegExp(r'^03\d{9}$');
  return regExp.hasMatch(value) ? null : "Name should of pattern 03XXXXXXXXX";
}

String? validateAddressLine1(String? value) {
  if (value == null || value.isEmpty) return "Address is required";
  if (value.length < 5) return "Address must be at least 5 characters";
  return null;
}

String? validateCity(String? value) {
  if (value == null || value.isEmpty) return "City is required";
  if (value.length < 2) return "City must be at least 2 characters";
  final regExp = RegExp(r'^[a-zA-Z\s]+$');
  return regExp.hasMatch(value) ? null : "City should contain only letters and spaces";
}

String? validateState(String? value) {
  if (value == null || value.isEmpty) return "State is required";
  if (value.length < 2) return "State must be at least 2 characters";
  final regExp = RegExp(r'^[a-zA-Z\s]+$');
  return regExp.hasMatch(value) ? null : "State should contain only letters and spaces";
}

String? validateZipCode(String? value) {
  if (value == null || value.isEmpty) return "Zip code is required";
  final regExp = RegExp(r'^\d{5}(-\d{4})?$');
  return regExp.hasMatch(value) ? null : "Please enter a valid zip code";
}

String? validateCountry(String? value) {
  if (value == null || value.isEmpty) return "Country is required";
  if (value.length < 2) return "Country must be at least 2 characters";
  final regExp = RegExp(r'^[a-zA-Z\s]+$');
  return regExp.hasMatch(value) ? null : "Country should contain only letters and spaces";
}

String? validatePhone(String? value) {
  if (value == null || value.isEmpty) return "Phone number is required";
  final regExp = RegExp(r'^\+?[\d\s\-\(\)]+$');
  return regExp.hasMatch(value) ? null : "Please enter a valid phone number";
}

String? validateCardNumber(String? value) {
  if (value == null || value.isEmpty) return "Card number is required";
  // Remove spaces and dashes for validation
  final cleanValue = value.replaceAll(RegExp(r'[\s\-]'), '');
  final regExp = RegExp(r'^\d{13,19}$');
  return regExp.hasMatch(cleanValue) ? null : "Please enter a valid card number";
}

String? validateExpiryMonth(String? value) {
  if (value == null || value.isEmpty) return "Expiry month is required";
  final month = int.tryParse(value);
  if (month == null || month < 1 || month > 12) {
    return "Please enter a valid month (1-12)";
  }
  return null;
}

String? validateExpiryYear(String? value) {
  if (value == null || value.isEmpty) return "Expiry year is required";
  final year = int.tryParse(value);
  final currentYear = DateTime.now().year;
  if (year == null || year < currentYear || year > currentYear + 20) {
    return "Please enter a valid year";
  }
  return null;
}

String? validateCVV(String? value) {
  if (value == null || value.isEmpty) return "CVV is required";
  final regExp = RegExp(r'^\d{3,4}$');
  return regExp.hasMatch(value) ? null : "Please enter a valid CVV";
}

String? validatePaymentMethod(String? value) {
  if (value == null || value.isEmpty) return "Payment method is required";
  final validMethods = ['Easypaisa', 'Bank Transfer'];
  return validMethods.contains(value) ? null : "Please select a valid payment method";
}
