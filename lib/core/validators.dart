class Validators {
  static String? required(String? v, [String label = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  static String? phone(String? v) {
    final s = (v ?? '').trim();
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(s) ? null : 'Enter a valid number (01XXXXXXXXX)';
  }

  static String? email(String? v) {
    final s = (v ?? '').trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s) ? null : 'Enter a valid email';
  }

  static String? password(String? v) =>
      (v ?? '').length >= 6 ? null : 'Password must be at least 6 characters';
}
