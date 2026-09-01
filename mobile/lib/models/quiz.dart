class Choice {
  final int id;
  final String text;

  Choice({required this.id, required this.text});

  factory Choice.fromJson(Map<String, dynamic> json) =>
      Choice(id: json['id'] as int, text: json['text'] as String);
}

class Question {
  final int id;
  final String text;
  final int orderIndex;
  final List<Choice> choices;

  Question({
    required this.id,
    required this.text,
    required this.orderIndex,
    required this.choices,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] as int,
    text: json['text'] as String,
    orderIndex: json['order_index'] as int,
    choices: (json['choices'] as List)
        .map((e) => Choice.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class Quiz {
  final int id;
  final int lessonId;
  final String title;
  final int passingScore;
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.passingScore,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
    id: json['id'] as int,
    lessonId: json['lesson_id'] as int,
    title: json['title'] as String,
    passingScore: json['passing_score'] as int,
    questions: (json['questions'] as List)
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class AnswerResult {
  final int questionId;
  final int? selectedChoiceId;
  final int correctChoiceId;
  final bool isCorrect;

  AnswerResult({
    required this.questionId,
    required this.selectedChoiceId,
    required this.correctChoiceId,
    required this.isCorrect,
  });

  factory AnswerResult.fromJson(Map<String, dynamic> json) => AnswerResult(
    questionId: json['question_id'] as int,
    selectedChoiceId: json['selected_choice_id'] as int?,
    correctChoiceId: json['correct_choice_id'] as int,
    isCorrect: json['is_correct'] as bool,
  );
}

class QuizResult {
  final int attemptId;
  final int score;
  final int total;
  final double percentage;
  final bool passed;
  final DateTime submittedAt;
  final List<AnswerResult> answers;

  QuizResult({
    required this.attemptId,
    required this.score,
    required this.total,
    required this.percentage,
    required this.passed,
    required this.submittedAt,
    required this.answers,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
    attemptId: json['attempt_id'] as int,
    score: json['score'] as int,
    total: json['total'] as int,
    percentage: (json['percentage'] as num).toDouble(),
    passed: json['passed'] as bool,
    submittedAt: DateTime.parse(json['submitted_at'] as String),
    answers: (json['answers'] as List)
        .map((e) => AnswerResult.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class QuizAttempt {
  final int id;
  final int quizId;
  final int score;
  final int total;
  final bool passed;
  final DateTime submittedAt;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.score,
    required this.total,
    required this.passed,
    required this.submittedAt,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) => QuizAttempt(
    id: json['id'] as int,
    quizId: json['quiz_id'] as int,
    score: json['score'] as int,
    total: json['total'] as int,
    passed: json['passed'] as bool,
    submittedAt: DateTime.parse(json['submitted_at'] as String),
  );
}
