/*
 * Privacy-preserving breached-password lookup.
 * Author: Ariel Fajimiyo
 * Date: 24/10/26
 */

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class PasswordBreachService {
  Future<bool> isBreached(String password) async {
    // SHA-1 is required by this lookup protocol, not used for storage.
    final hash = sha1.convert(utf8.encode(password)).toString().toUpperCase();
    final prefix = hash.substring(0, 5);
    final suffix = hash.substring(5);

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _checkRange(prefix, suffix);
      } catch (_) {
        if (attempt == 1) rethrow;

        await Future<void>.delayed(
          const Duration(milliseconds: 500),
        );
      }
    }

    throw StateError('Password lookup did not complete.');
  }

  Future<bool> _checkRange(String prefix, String suffix) async {
    final response = await http.get(
      Uri.https('api.pwnedpasswords.com', '/range/$prefix'),
      headers: {
        'Add-Padding': 'true',
      },
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw StateError('Password lookup request failed.');
    }

    final lines = const LineSplitter().convert(response.body);
    var found = false;
    var records = 0;

    // Reject unexpected responses rather than treating them as a clean result.
    for (final line in lines) {
      if (line.isEmpty) continue;

      final parts = line.split(':');

      if (parts.length != 2 ||
          !RegExp(r'^[A-Fa-f0-9]{35}$').hasMatch(parts[0])) {
        throw const FormatException('Invalid password lookup response.');
      }

      final count = int.tryParse(parts[1].trim());

      if (count == null || count < 0) {
        throw const FormatException('Invalid password occurrence count.');
      }

      records++;

      // Padded records have zero occurrences and must not block a password.
      if (parts[0].toUpperCase() == suffix && count > 0) {
        found = true;
      }
    }

    if (records == 0) {
      throw const FormatException('Empty password lookup response.');
    }

    return found;
  }
}