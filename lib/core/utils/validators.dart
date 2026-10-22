class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String? original) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != original) {
        return 'Passwords do not match';
      }
      return null;
    };
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    final nameRegex = RegExp(r"^[a-zA-Z\s\.\-']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name must not contain special characters';
    }
    return null;
  }

  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^09\d{9}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid PH phone number (09XXXXXXXXX)';
    }
    return null;
  }

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? plateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Plate number is required';
    }
    if (value.trim().length < 5) {
      return 'Please enter a valid plate number';
    }
    return null;
  }

  static String? franchiseNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Franchise/OR-CR number is required';
    }
    return null;
  }

  static String? minLength(
    String? value,
    int min, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }

  static String? maxLength(
    String? value,
    int max, {
    String fieldName = 'This field',
  }) {
    if (value != null && value.trim().length > max) {
      return '$fieldName must not exceed $max characters';
    }
    return null;
  }

  static String? adminPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Admin password is required';
    }
    if (value.length < 6) {
      return 'Invalid admin credentials';
    }
    return null;
  }
}
