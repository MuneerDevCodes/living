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
