import 'quiz.dart' show AnswerResult;

/// Unlike a lesson quiz's [Choice], this carries [isCorrect] — the game is
/// casual practice, so the server reveals the answer up front and the app
/// shows right/wrong feedback the instant a choice is tapped, no round trip.
class GameChoice {
  final int id;
  final String text;
  final bool isCorrect;

  GameChoice({required this.id, required this.text, required this.isCorrect});

  factory GameChoice.fromJson(Map<String, dynamic> json) => GameChoice(
    id: json['id'] as int,
    text: json['text'] as String,
    isCorrect: json['is_correct'] as bool,
  );
}

class GameQuestion {
  final int id;
  final String text;
  final List<GameChoice> choices;

  GameQuestion({required this.id, required this.text, required this.choices});

  factory GameQuestion.fromJson(Map<String, dynamic> json) => GameQuestion(
    id: json['id'] as int,
    text: json['text'] as String,
    choices: (json['choices'] as List)
        .map((e) => GameChoice.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class GameResult {
  final int score;
  final int total;
  final double percentage;
  final DateTime submittedAt;
  final List<AnswerResult> answers;

  /// This round's current leaderboard rank — 1 means it's now the
  /// platform's best-ever round. Null only if ranking couldn't be
  /// computed (not expected in practice).
  final int? rank;

  GameResult({
    required this.score,
    required this.total,
    required this.percentage,
    required this.submittedAt,
    required this.answers,
    required this.rank,
  });

  factory GameResult.fromJson(Map<String, dynamic> json) => GameResult(
    score: json['score'] as int,
    total: json['total'] as int,
    percentage: (json['percentage'] as num).toDouble(),
    submittedAt: DateTime.parse(json['submitted_at'] as String),
    answers: (json['answers'] as List)
        .map((e) => AnswerResult.fromJson(e as Map<String, dynamic>))
        .toList(),
    rank: json['rank'] as int?,
  );
}

class GameAttempt {
  final int id;
  final int? courseId;
  final int score;
  final int total;
  final DateTime submittedAt;

  GameAttempt({
    required this.id,
    required this.courseId,
    required this.score,
    required this.total,
    required this.submittedAt,
  });

  factory GameAttempt.fromJson(Map<String, dynamic> json) => GameAttempt(
    id: json['id'] as int,
    courseId: json['course_id'] as int?,
    score: json['score'] as int,
    total: json['total'] as int,
    submittedAt: DateTime.parse(json['submitted_at'] as String),
  );
}

/// A game attempt with the submitting user's identity attached — only
/// ever returned from admin-only endpoints.
class AdminGameAttempt {
  final int id;
  final int userId;
  final String userFullName;
  final String userEmail;
  final int? courseId;
  final String? courseTitle;
  final int score;
  final int total;
  final double percentage;
  final DateTime submittedAt;

  AdminGameAttempt({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.userEmail,
    required this.courseId,
    required this.courseTitle,
    required this.score,
    required this.total,
    required this.percentage,
    required this.submittedAt,
  });

  factory AdminGameAttempt.fromJson(Map<String, dynamic> json) =>
      AdminGameAttempt(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        userFullName: json['user_full_name'] as String,
        userEmail: json['user_email'] as String,
        courseId: json['course_id'] as int?,
        courseTitle: json['course_title'] as String?,
        score: json['score'] as int,
        total: json['total'] as int,
        percentage: (json['percentage'] as num).toDouble(),
        submittedAt: DateTime.parse(json['submitted_at'] as String),
      );
}

/// A player's single best Quick Challenge round, ranked by score
/// percentage.
class LeaderboardEntry {
  final int rank;
  final int userId;
  final String fullName;
  final int score;
  final int total;
  final double percentage;
  final DateTime achievedAt;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.fullName,
    required this.score,
    required this.total,
    required this.percentage,
    required this.achievedAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        rank: json['rank'] as int,
        userId: json['user_id'] as int,
        fullName: json['full_name'] as String,
        score: json['score'] as int,
        total: json['total'] as int,
        percentage: (json['percentage'] as num).toDouble(),
        achievedAt: DateTime.parse(json['achieved_at'] as String),
      );
}
