class Validators {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Enter your full name";
    }

    if (RegExp(r'[0-9]').hasMatch(value)) {
      return "Name cannot contain numbers";
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return "Enter phone number";
    }

    if (!RegExp(r'^[0-9]{10,12}$').hasMatch(value)) {
      return "Invalid phone number";
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Enter email";
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return "Invalid email";
    }

    return null;
  }
}
