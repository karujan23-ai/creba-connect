/// Firestore collection names, kept in one place so a typo cannot create a
/// second, empty collection by accident.
class FirestorePaths {
  FirestorePaths._();

  static const users = 'users';
  static const creatorProfiles = 'creatorProfiles';
  static const brandProfiles = 'brandProfiles';
  static const brandPrivate = 'private';
  static const brandVerificationDoc = 'verification';
  static const hiringPosts = 'hiringPosts';
  static const availabilityPosts = 'creatorAvailabilityPosts';
  static const applications = 'applications';
  static const conversations = 'conversations';
  static const messages = 'messages';
  static const notifications = 'notifications';
  static const favorites = 'favorites';
  static const reports = 'reports';
  static const promotions = 'promotions';
  static const subscriptions = 'subscriptions';
  static const payments = 'payments';
  static const categories = 'categories';
  static const adminLogs = 'adminLogs';
}
