import 'package:tricgabay_app/core/l10n/message_codes.g.dart';

class Validators {
  Validators._();
  static const emailMaxLength = 254;
  static const passwordMaxLength = 128;
  static const fullNameMaxLength = 100;
  static const plateNumberMaxLength = 20;
  static const franchiseNumberMaxLength = 50;

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return MessageCode.emailAddressIsRequired;
    if (text.length > emailMaxLength) {
      return MessageCode.emailAddressMustNotExceedCharactersValue(
        (emailMaxLength).toString(),
      );
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return MessageCode.pleaseEnterAValidEmailAddress;
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return MessageCode.passwordIsRequired;
    }
    if (value.length < 8) {
      return MessageCode.passwordMustBeAtLeast8Characters;
    }
    if (value.length > passwordMaxLength) {
      return MessageCode.passwordMustNotExceedCharactersValue(
        (passwordMaxLength).toString(),
      );
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return MessageCode.passwordMustContainAtLeastOneUppercaseLetter;
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return MessageCode.passwordMustContainAtLeastOneNumber;
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String? original) =>
      (value) {
        if (value == null || value.isEmpty) {
          return MessageCode.pleaseConfirmYourPassword;
        }
        return value == original ? null : MessageCode.passwordsDoNotMatch;
      };
  static String? fullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return MessageCode.fullNameIsRequired;
    if (text.length < 2) {
      return MessageCode.nameMustBeAtLeast2Characters;
    }
    if (text.length > fullNameMaxLength) {
      return MessageCode.nameMustNotExceedCharactersValue(
        (fullNameMaxLength).toString(),
      );
    }
    if (!RegExp(
      r"^[\p{L}][\p{L}\p{M} .\-'’]*$",
      unicode: true,
    ).hasMatch(text)) {
      return MessageCode.useLettersSpacesHyphensApostrophesOrPeriodsInYourName;
    }
    return null;
  }

  static String normalizePhone(String value) {
    final compact = value.trim().replaceAll(RegExp(r'[ ()-]'), '');
    if (RegExp(r'^09\d{9}$').hasMatch(compact)) {
      return '+63${compact.substring(1)}';
    }
    return compact;
  }

  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return MessageCode.phoneNumberIsRequired;
    }
    if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(normalizePhone(value))) {
      return MessageCode
          .enterAPhMobileNumberOrInternationalNumberWithCountryCode;
    }
    return null;
  }

  static String? required(
    String? value, {
    String fieldName = MessageCode.thisField,
  }) => value == null || value.trim().isEmpty
      ? MessageCode.isRequiredValue((fieldName).toString())
      : null;
  static String? plateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return MessageCode.plateNumberIsRequired;
    }
    if (value.trim().length < 5) {
      return MessageCode.pleaseEnterAValidPlateNumber;
    }
    if (value.trim().length > plateNumberMaxLength) {
      return MessageCode.plateNumberMustNotExceedCharactersValue(
        (plateNumberMaxLength).toString(),
      );
    }
    return null;
  }

  static String? franchiseNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return MessageCode.franchiseOrCrNumberIsRequired;
    }
    if (value.trim().length > franchiseNumberMaxLength) {
      return MessageCode.franchiseOrCrNumberMustNotExceedCharactersValue(
        (franchiseNumberMaxLength).toString(),
      );
    }
    return null;
  }

  static String? minLength(
    String? value,
    int min, {
    String fieldName = MessageCode.thisField,
  }) {
    if (value == null || value.trim().isEmpty) {
      return MessageCode.isRequiredValue((fieldName).toString());
    }
    return value.trim().length < min
        ? MessageCode.mustBeAtLeastCharactersValue(
            (fieldName).toString(),
            (min).toString(),
          )
        : null;
  }

  static String? maxLength(
    String? value,
    int max, {
    String fieldName = MessageCode.thisField,
  }) => value != null && value.trim().length > max
      ? MessageCode.mustNotExceedCharactersValue(
          (fieldName).toString(),
          (max).toString(),
        )
      : null;
  static String? adminPassword(String? value) {
    if (value == null || value.isEmpty) {
      return MessageCode.adminPasswordIsRequired;
    }
    return value.length < 6 ? MessageCode.invalidAdminCredentials : null;
  }
}
