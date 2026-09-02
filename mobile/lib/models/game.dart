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

  GameResult({
    required this.score,
    required this.total,
    required this.percentage,
    required this.submittedAt,
    required this.answers,
  });

  factory GameResult.fromJson(Map<String, dynamic> json) => GameResult(
    score: json['score'] as int,
    total: json['total'] as int,
    percentage: (json['percentage'] as num).toDouble(),
    submittedAt: DateTime.parse(json['submitted_at'] as String),
    answers: (json['answers'] as List)
        .map((e) => AnswerResult.fromJson(e as Map<String, dynamic>))
        .toList(),
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
