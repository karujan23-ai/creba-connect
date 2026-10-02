import '../models/app_user.dart';
import '../models/availability_post.dart';
import '../models/brand_profile.dart';
import '../models/enums.dart';
import '../models/hiring_post.dart';
import '../models/promotion.dart';
import '../models/report.dart';
import '../services/admin_service.dart';
import '../services/availability_service.dart';
import '../services/brand_service.dart';
import '../services/firestore_paths.dart';
import '../services/hiring_post_service.dart';
import '../services/report_service.dart';
import '../services/seed_service.dart';
import '../utils/app_config.dart';
import '../utils/app_exception.dart';
import 'session_provider.dart';

/// Everything the admin area shows and does. It also files reports for
/// normal users, because reports are an admin-facing feature.
///
/// The admin lists are only loaded when the signed-in user's role is admin,
/// and the security rules refuse them to anyone else regardless.
class AdminProvider extends SessionProvider {
  AdminProvider({
    required AdminService adminService,
    required this._brandService,
    required this._hiringPostService,
    required this._availabilityService,
    required this._reportService,
    required this._seedService,
  }) : _admin = adminService;

  final AdminService _admin;
  final BrandService _brandService;
  final HiringPostService _hiringPostService;
  final AvailabilityService _availabilityService;
  final ReportService _reportService;
  final SeedService _seedService;

  List<AppUser> _users = [];
  List<BrandProfile> _brands = [];
  List<HiringPost> _hiringPosts = [];
  List<AvailabilityPost> _availabilityPosts = [];
  List<Report> _reports = [];
  List<Promotion> _promotions = [];
  List<Payment> _payments = [];
  List<Subscription> _subscriptions = [];
  AdminCounts _counts = const AdminCounts();
  bool _isLoadingCounts = false;
  String? _error;

  List<AppUser> get users => _users;
  List<BrandProfile> get brands => _brands;
  List<HiringPost> get hiringPosts => _hiringPosts;
  List<AvailabilityPost> get availabilityPosts => _availabilityPosts;
  List<Report> get reports => _reports;
  List<Promotion> get promotions => _promotions;
  List<Payment> get payments => _payments;
  List<Subscription> get subscriptions => _subscriptions;
  AdminCounts get counts => _counts;
  bool get isLoadingCounts => _isLoadingCounts;
  String? get error => _error;

  List<AppUser> usersWithRole(UserRole role) =>
      _users.where((user) => user.role == role).toList();

  List<BrandProfile> brandsWithStatus(VerificationStatus status) =>
      _brands.where((brand) => brand.verificationStatus == status).toList();

  List<Report> get openReports =>
      _reports.where((report) => report.status == ReportStatus.open).toList();

  List<Promotion> get promotionRequests => _promotions
      .where((promotion) => promotion.status == PromotionStatus.requested)
      .toList();

  SubscriptionPlan planOf(String uid) {
    for (final subscription in _subscriptions) {
      if (subscription.userId == uid && subscription.isPro) return subscription.plan;
    }
    return SubscriptionPlan.free;
  }

  @override
  void onSessionStarted(AppUser user) {
    if (!user.isAdmin) return;
    const limit = AppConfig.adminListLimit;
    void onError(String message) => _error = 'Unable to load admin data.';

    listen(_admin.watchUsers(limit: limit), (v) => _users = v, onError: onError);
    listen(_brandService.watchBrands(limit: limit), (v) => _brands = v, onError: onError);
    listen(_hiringPostService.watchLatest(limit: limit), (v) => _hiringPosts = v, onError: onError);
    listen(_availabilityService.watchLatest(limit: limit), (v) => _availabilityPosts = v, onError: onError);
    listen(_reportService.watchAll(limit: limit), (v) => _reports = v, onError: onError);
    listen(_admin.watchPromotions(limit: limit), (v) => _promotions = v, onError: onError);
    listen(_admin.watchPayments(limit: limit), (v) => _payments = v, onError: onError);
    listen(_admin.watchSubscriptions(), (v) => _subscriptions = v, onError: onError);
    refreshCounts();
  }

  @override
  void onSessionEnded() {
    _users = [];
    _brands = [];
    _hiringPosts = [];
    _availabilityPosts = [];
    _reports = [];
    _promotions = [];
    _payments = [];
    _subscriptions = [];
    _counts = const AdminCounts();
    _isLoadingCounts = false;
    _error = null;
  }

  Future<void> refreshCounts() async {
    _isLoadingCounts = true;
    notifySafely();
    try {
      _counts = await _admin.loadCounts();
    } catch (_) {
      _error = 'Unable to load the latest numbers.';
    }
    _isLoadingCounts = false;
    notifySafely();
  }

  /// The brand's private PAN details, fetched only when an admin opens them.
  Future<BrandVerification?> verificationOf(String brandId) async {
    try {
      return await _brandService.getVerification(brandId);
    } catch (_) {
      return null;
    }
  }

  Future<String?> setVerification(
    BrandProfile brand,
    VerificationStatus status, {
    String? rejectionReason,
  }) =>
      guard(
        () => _admin.setVerification(
          brandId: brand.uid,
          brandName: brand.brandName,
          status: status,
          adminId: uid!,
          rejectionReason: rejectionReason,
        ),
      );

  Future<String?> setUserActive(AppUser user, {required bool isActive}) => guard(
        () => _admin.setUserActive(
          uid: user.uid,
          name: user.displayName,
          isActive: isActive,
          adminId: uid!,
        ),
      );

  Future<String?> setPlan(AppUser user, SubscriptionPlan plan) => guard(
        () => _admin.setPlan(
          uid: user.uid,
          name: user.displayName,
          plan: plan,
          adminId: uid!,
        ),
      );

  Future<String?> deleteHiringPost(HiringPost post) => guard(
        () => _admin.deleteContent(
          collection: FirestorePaths.hiringPosts,
          id: post.id,
          label: post.title,
          adminId: uid!,
        ),
      );

  Future<String?> deleteAvailabilityPost(AvailabilityPost post) => guard(
        () => _admin.deleteContent(
          collection: FirestorePaths.availabilityPosts,
          id: post.id,
          label: post.title,
          adminId: uid!,
        ),
      );

  Future<String?> setReportStatus(Report report, ReportStatus status) =>
      guard(() => _reportService.setStatus(report.id, status, uid!));

  Future<String?> approvePromotion(Promotion promotion) =>
      guard(() => _admin.approvePromotion(promotion, uid!));

  Future<String?> rejectPromotion(Promotion promotion) =>
      guard(() => _admin.rejectPromotion(promotion, uid!));

  Future<String?> addDemoData() async {
    final error = await guard(_seedService.addDemoData);
    if (error == null) refreshCounts();
    return error;
  }

  /// Returns a message describing what happened.
  Future<String> removeDemoData() async {
    try {
      final removed = await _seedService.removeDemoData();
      refreshCounts();
      return removed == 0 ? 'No sample data found.' : 'Removed $removed sample items.';
    } catch (error) {
      return friendlyError(error);
    }
  }

  /// Used by every role: sends a report about a profile or post.
  Future<String?> submitReport({
    required String targetId,
    required TargetType targetType,
    required String targetLabel,
    required String reason,
    required String description,
  }) =>
      guard(
        () => _reportService.submit(
          Report(
            id: '',
            reporterId: uid!,
            targetId: targetId,
            targetType: targetType,
            targetLabel: targetLabel,
            reason: reason,
            description: description,
            createdAt: DateTime.now(),
          ),
        ),
      );
}
