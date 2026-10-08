import 'package:flutter/foundation.dart';

/// App-wide "something the learner did changed server-side state" signal.
///
/// Tab screens live in an IndexedStack and pushed screens stay mounted under
/// whatever is pushed on top of them, so each one loading only in `initState`
/// meant e.g. finishing a lesson left the course page still showing the next
/// lesson locked, and Home/Progress showing old percentages, until a manual
/// pull-to-refresh. Screens that show progress listen to this and quietly
/// reload; screens that change it call [progressChanged].
class LearningEvents extends ChangeNotifier {
  /// A lesson was completed, a quiz/game was submitted, or a review saved.
  void progressChanged() => notifyListeners();
}
