/*
 * Reusable registration input checks.
 * Author: Ariel Fajimiyo
 * Date: 22/10/26
 */

class SignUpValidators {
  // Confirm the actual student email domain before deployment.
  static const schoolDomain = 'setu.ie';

  static final _emailPattern = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a username.';
    }

    return null;
  }

  static String? email(String? value) {
    final address = value?.trim() ?? '';

    if (address.isEmpty) {
      return 'Enter your email.';
    }

    if (!_emailPattern.hasMatch(address)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  static bool isSchoolEmail(String value) {
    final address = value.trim().toLowerCase();

    return email(address) == null &&
        address.split('@').last == schoolDomain;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter a password.';
    }

    // Preserve the password exactly as entered.
    if (value.length < 8) {
      return 'Use at least 8 characters.';
    }

    return null;
  }

  static String? invitationCode(
    String? value, {
    required bool required,
  }) {
    // Presence check only; the backend must validate the actual code.
    if (required && (value == null || value.trim().isEmpty)) {
      return 'An invitation code is required for this email.';
    }

    return null;
  }
}