import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Loads UI text from `assets/lang/<code>.json` at runtime and looks it up by
/// key. To change a translation, edit the word in that JSON file — nothing
/// in the Dart code needs to change.
///
/// Placeholders use `{name}` and are filled in from the `params` map passed
/// to [t]. For counts, [plural] picks the `<key>_plural` entry when [count]
/// != 1 and that entry exists (English), falling back to the base key
/// otherwise (Khmer has no plural form, so it only ever defines the base key).
class Translations extends ChangeNotifier {
  static const supportedLanguageCodes = ['en', 'km'];
  static const fallbackLanguageCode = 'en';

  String _languageCode = fallbackLanguageCode;
  Map<String, dynamic> _values = const {};
  bool _isLoaded = false;

  String get languageCode => _languageCode;
  bool get isLoaded => _isLoaded;

  Future<void> load(String? languageCode) async {
    final code = supportedLanguageCodes.contains(languageCode)
        ? languageCode!
        : fallbackLanguageCode;
    final raw = await rootBundle.loadString('assets/lang/$code.json');
    _values = json.decode(raw) as Map<String, dynamic>;
    _languageCode = code;
    _isLoaded = true;
    notifyListeners();
  }

  String t(String key, [Map<String, Object?>? params]) {
    var value = _values[key] as String? ?? key;
    params?.forEach((name, val) {
      value = value.replaceAll('{$name}', '$val');
    });
    return value;
  }

  String plural(String key, int count, [Map<String, Object?>? params]) {
    final pluralKey = '${key}_plural';
    final resolvedKey = (count != 1 && _values.containsKey(pluralKey))
        ? pluralKey
        : key;
    return t(resolvedKey, {'count': count, ...?params});
  }
}
