import '../l10n/translations.dart';

enum FeedbackType { feedback, lessonSuggestion }

FeedbackType feedbackTypeFromJson(String value) => value == 'lesson_suggestion'
    ? FeedbackType.lessonSuggestion
    : FeedbackType.feedback;

String feedbackTypeToJson(FeedbackType type) => switch (type) {
  FeedbackType.feedback => 'feedback',
  FeedbackType.lessonSuggestion => 'lesson_suggestion',
};

String feedbackTypeLabel(Translations t, FeedbackType type) => switch (type) {
  FeedbackType.feedback => t.t('feedbackTypeGeneral'),
  FeedbackType.lessonSuggestion => t.t('feedbackTypeLessonSuggestion'),
};

enum FeedbackStatus { new_, reviewed, dismissed }

FeedbackStatus feedbackStatusFromJson(String value) => switch (value) {
  'reviewed' => FeedbackStatus.reviewed,
  'dismissed' => FeedbackStatus.dismissed,
  _ => FeedbackStatus.new_,
};

String feedbackStatusLabel(Translations t, FeedbackStatus status) =>
    switch (status) {
      FeedbackStatus.new_ => t.t('feedbackStatusSubmitted'),
      FeedbackStatus.reviewed => t.t('feedbackStatusReviewed'),
      FeedbackStatus.dismissed => t.t('feedbackStatusDismissed'),
    };

class FeedbackItem {
  final int id;
  final FeedbackType type;
  final String subject;
  final String message;
  final FeedbackStatus status;
  final DateTime createdAt;

  FeedbackItem({
    required this.id,
    required this.type,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) => FeedbackItem(
    id: json['id'] as int,
    type: feedbackTypeFromJson(json['type'] as String),
    subject: json['subject'] as String,
    message: json['message'] as String,
    status: feedbackStatusFromJson(json['status'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
