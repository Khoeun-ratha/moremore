// Pure data checks on assets/lang/*.json — catches the mistake this project
// has hit before: adding a key to one language file and forgetting the
// other, or breaking JSON syntax while hand-editing a translation.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadLang(String code) {
  final file = File('assets/lang/$code.json');
  return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  final en = _loadLang('en');
  final km = _loadLang('km');

  test('every English key has a Khmer translation', () {
    final enKeys = en.keys.where((k) => !k.endsWith('_plural')).toSet();
    final kmKeys = km.keys.toSet();
    final missing = enKeys.difference(kmKeys);
    expect(
      missing,
      isEmpty,
      reason: 'assets/lang/km.json is missing: ${missing.join(', ')}',
    );
  });

  test('every Khmer key exists in English (no orphaned keys)', () {
    final enKeys = en.keys.toSet();
    final kmKeys = km.keys.toSet();
    final orphaned = kmKeys.difference(enKeys);
    expect(
      orphaned,
      isEmpty,
      reason:
          'assets/lang/km.json has keys not in en.json: '
          '${orphaned.join(', ')}',
    );
  });

  test('all values are non-empty strings', () {
    for (final entry in en.entries) {
      expect(
        entry.value,
        isA<String>(),
        reason: 'en.json["${entry.key}"] is not a string',
      );
      expect(
        (entry.value as String).trim(),
        isNotEmpty,
        reason: 'en.json["${entry.key}"] is empty',
      );
    }
    for (final entry in km.entries) {
      expect(
        entry.value,
        isA<String>(),
        reason: 'km.json["${entry.key}"] is not a string',
      );
      expect(
        (entry.value as String).trim(),
        isNotEmpty,
        reason: 'km.json["${entry.key}"] is empty',
      );
    }
  });

  test('every {placeholder} used in an English value also appears in the '
      'matching Khmer value', () {
    final placeholderPattern = RegExp(r'\{(\w+)\}');
    final mismatches = <String>[];
    for (final key in en.keys) {
      if (!km.containsKey(key)) continue;
      final enPlaceholders = placeholderPattern
          .allMatches(en[key] as String)
          .map((m) => m.group(1))
          .toSet();
      final kmPlaceholders = placeholderPattern
          .allMatches(km[key] as String)
          .map((m) => m.group(1))
          .toSet();
      if (enPlaceholders.difference(kmPlaceholders).isNotEmpty) {
        mismatches.add(key);
      }
    }
    expect(
      mismatches,
      isEmpty,
      reason:
          'Placeholder mismatch between en.json and km.json for: '
          '${mismatches.join(', ')}',
    );
  });
}
