/// Enums shared by the models. Each has a `value` (what is stored in
/// Firestore) and a `label` (what the user sees).
library;

enum UserRole {
  creator('creator', 'Creator'),
  brand('brand', 'Brand'),
  admin('admin', 'Admin');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  static UserRole fromValue(String? value) => UserRole.values.firstWhere(
        (role) => role.value == value,
        orElse: () => UserRole.creator,
      );
}

enum VerificationStatus {
  pending('pending', 'Pending review'),
  verified('verified', 'Business Verified'),
  rejected('rejected', 'Not approved');

  const VerificationStatus(this.value, this.label);

  final String value;
  final String label;

  static VerificationStatus fromValue(String? value) =>
      VerificationStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => VerificationStatus.pending,
      );
}

enum ApplicationStatus {
  applied('applied', 'Applied'),
  shortlisted('shortlisted', 'Shortlisted'),
  discussion('discussion', 'In Discussion'),
  selected('selected', 'Selected'),
  rejected('rejected', 'Rejected'),
  withdrawn('withdrawn', 'Withdrawn');

  const ApplicationStatus(this.value, this.label);

  final String value;
  final String label;

  static ApplicationStatus fromValue(String? value) =>
      ApplicationStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => ApplicationStatus.applied,
      );
}

enum BudgetType {
  fixed('fixed', 'Fixed'),
  range('range', 'Range'),
  negotiable('negotiable', 'Negotiable');

  const BudgetType(this.value, this.label);

  final String value;
  final String label;

  static BudgetType fromValue(String? value) => BudgetType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => BudgetType.negotiable,
      );
}

enum PostStatus {
  open('open', 'Open'),
  closed('closed', 'Closed');

  const PostStatus(this.value, this.label);

  final String value;
  final String label;

  static PostStatus fromValue(String? value) =>
      value == 'closed' ? PostStatus.closed : PostStatus.open;
}

/// What a favourite, report or promotion points at.
enum TargetType {
  creator('creator', 'Creator'),
  brand('brand', 'Brand'),
  hiringPost('hiringPost', 'Hiring post'),
  availabilityPost('availabilityPost', 'Availability post');

  const TargetType(this.value, this.label);

  final String value;
  final String label;

  static TargetType fromValue(String? value) => TargetType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => TargetType.creator,
      );
}

enum ReportStatus {
  open('open', 'Open'),
  resolved('resolved', 'Resolved'),
  dismissed('dismissed', 'Dismissed');

  const ReportStatus(this.value, this.label);

  final String value;
  final String label;

  static ReportStatus fromValue(String? value) =>
      ReportStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => ReportStatus.open,
      );
}

enum PromotionStatus {
  requested('requested', 'Requested'),
  active('active', 'Active'),
  expired('expired', 'Expired'),
  rejected('rejected', 'Declined');

  const PromotionStatus(this.value, this.label);

  final String value;
  final String label;

  static PromotionStatus fromValue(String? value) =>
      PromotionStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => PromotionStatus.requested,
      );
}

enum SubscriptionPlan {
  free('free', 'Free', 0),
  creatorPro('creator_pro', 'Creator Pro', 499),
  brandPro('brand_pro', 'Brand Pro', 999);

  const SubscriptionPlan(this.value, this.label, this.monthlyPriceNpr);

  final String value;
  final String label;
  final int monthlyPriceNpr;

  static SubscriptionPlan fromValue(String? value) =>
      SubscriptionPlan.values.firstWhere(
        (plan) => plan.value == value,
        orElse: () => SubscriptionPlan.free,
      );
}
