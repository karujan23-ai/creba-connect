import 'enums.dart';
import 'model_utils.dart';

/// The account record stored at `users/{uid}`.
/// The password is never stored here; Firebase Authentication keeps it.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.displayName,
    required this.phone,
    this.city = '',
    this.onboardingComplete = false,
    this.isActive = true,
    required this.createdAt,
  });

  final String uid;
  final String email;
  final UserRole role;
  final String displayName;
  final String phone;
  final String city;
  final bool onboardingComplete;

  /// Set to false by an admin to suspend the account.
  final bool isActive;
  final DateTime createdAt;

  bool get isCreator => role == UserRole.creator;
  bool get isBrand => role == UserRole.brand;
  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromJson(Map<String, dynamic> json, String uid) => AppUser(
        uid: uid,
        email: readString(json['email']),
        role: UserRole.fromValue(json['role'] as String?),
        displayName: readString(json['displayName']),
        phone: readString(json['phone']),
        city: readString(json['city']),
        onboardingComplete: readBool(json['onboardingComplete']),
        isActive: readBool(json['isActive'], true),
        createdAt: readDateOrNow(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'role': role.value,
        'displayName': displayName,
        'phone': phone,
        'city': city,
        'onboardingComplete': onboardingComplete,
        'isActive': isActive,
        'createdAt': writeDate(createdAt),
      };
}
