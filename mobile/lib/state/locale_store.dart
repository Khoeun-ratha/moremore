import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the user's chosen app language (English / Khmer), persisted across
/// launches. Null means "follow the device's language" (falling back to
/// English if the device language isn't one the app ships).
class LocaleStore extends ChangeNotifier {
  LocaleStore() {
    _restore();
  }

  static const _storageKey = 'app_locale';
  final _storage = const FlutterSecureStorage();

  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> _restore() async {
    final saved = await _storage.read(key: _storageKey);
    if (saved != null) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    if (locale == null) {
      await _storage.delete(key: _storageKey);
    } else {
      await _storage.write(key: _storageKey, value: locale.languageCode);
    }
  }
}
