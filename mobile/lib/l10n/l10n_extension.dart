import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'translations.dart';

/// `context.tr('someKey')` looks up the current language's text for that
/// key (see assets/lang/en.json and assets/lang/km.json). Subscribes to
/// language changes, so widgets using it rebuild when the language switches.
///
/// Only call `tr`/`trPlural` during `build()` (directly, or inside a lazily
/// invoked `builder:` callback such as `showDialog`'s) — the underlying
/// `context.watch` throws if called from outside a build phase, e.g. an
/// `onPressed` handler or after an `await`. Use `trRead`/`trPluralRead` there
/// instead: same lookup, but via `context.read`, which is safe anywhere.
extension L10nX on BuildContext {
  String tr(String key, [Map<String, Object?>? params]) =>
      watch<Translations>().t(key, params);

  String trPlural(String key, int count, [Map<String, Object?>? params]) =>
      watch<Translations>().plural(key, count, params);

  String trRead(String key, [Map<String, Object?>? params]) =>
      read<Translations>().t(key, params);

  String trPluralRead(String key, int count, [Map<String, Object?>? params]) =>
      read<Translations>().plural(key, count, params);
}
