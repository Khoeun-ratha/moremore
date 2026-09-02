import '../l10n/translations.dart';

enum UserRole { user, admin }

UserRole userRoleFromJson(String value) =>
    value == 'admin' ? UserRole.admin : UserRole.user;

enum Gender { male, female, other, preferNotToSay }

Gender? genderFromJson(String? value) => switch (value) {
  'male' => Gender.male,
  'female' => Gender.female,
  'other' => Gender.other,
  'prefer_not_to_say' => Gender.preferNotToSay,
  _ => null,
};

String genderToJson(Gender gender) => switch (gender) {
  Gender.male => 'male',
  Gender.female => 'female',
  Gender.other => 'other',
  Gender.preferNotToSay => 'prefer_not_to_say',
};

String genderLabel(Translations t, Gender gender) => switch (gender) {
  Gender.male => t.t('genderMale'),
  Gender.female => t.t('genderFemale'),
  Gender.other => t.t('genderOther'),
  Gender.preferNotToSay => t.t('genderPreferNotToSay'),
};

class AppUser {
  final int id;
  final String email;
  final String? phone;
  final String fullName;
  final Gender? gender;
  final String? avatarUrl;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.gender,
    required this.avatarUrl,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as int,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    fullName: json['full_name'] as String,
    gender: genderFromJson(json['gender'] as String?),
    avatarUrl: json['avatar_url'] as String?,
    role: userRoleFromJson(json['role'] as String),
    isActive: json['is_active'] as bool,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class TokenPair {
  final String accessToken;
  final String refreshToken;

  TokenPair({required this.accessToken, required this.refreshToken});

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
  );
}
