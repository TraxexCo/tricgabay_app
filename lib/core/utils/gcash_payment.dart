final _localMobile = RegExp(r'^09[0-9]{9}$');
final _internationalMobile = RegExp(r'^\+639[0-9]{9}$');
final _reference = RegExp(r'^[A-Za-z0-9]{8,20}$');

String? normalizeGcashNumber(String input) {
  if (_localMobile.hasMatch(input)) return input;
  if (_internationalMobile.hasMatch(input)) return '0${input.substring(3)}';
  return null;
}

bool isValidGcashReference(String input) =>
    input.trim().isEmpty || _reference.hasMatch(input.trim());
