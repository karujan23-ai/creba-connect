/// Form validation rules. Each returns `null` when the value is fine,
/// or the message to show under the field.
class Validators {
  Validators._();

  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final _phonePattern = RegExp(r'^\+?[0-9]{7,15}$');
  static final _panPattern = RegExp(r'^[0-9]{9}$');

  static String? required(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < 6) return 'Use at least 6 characters';
    return null;
  }

  static String? phone(String? value) {
    final text = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (text.isEmpty) return 'Phone number is required';
    if (!_phonePattern.hasMatch(text)) return 'Enter a valid phone number';
    return null;
  }

  /// Nepal PAN numbers are 9 digits. This only checks the format; it does not
  /// confirm the number with any government system.
  static String? pan(String? value, {bool isRequired = true}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return isRequired ? 'PAN number is required' : null;
    if (!_panPattern.hasMatch(text)) return 'PAN must be 9 digits';
    return null;
  }

  static String? minLength(String? value, int length, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    if (text.length < length) return '$label must be at least $length characters';
    return null;
  }

  static String? amount(String? value, {bool isRequired = true}) {
    final text = value?.trim().replaceAll(',', '') ?? '';
    if (text.isEmpty) return isRequired ? 'Enter an amount' : null;
    final number = num.tryParse(text);
    if (number == null) return 'Enter numbers only';
    if (number <= 0) return 'Amount must be more than 0';
    return null;
  }

  static String? wholeNumber(String? value, {int min = 1, int max = 999}) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null) return 'Enter a number';
    if (number < min || number > max) return 'Must be between $min and $max';
    return null;
  }

  static String? url(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    final looksValid = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.contains('.');
    return looksValid ? null : 'Enter a full link starting with https://';
  }
}
