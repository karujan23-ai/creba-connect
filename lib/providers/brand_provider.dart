import '../models/app_user.dart';
import '../models/brand_profile.dart';
import '../services/brand_service.dart';
import '../utils/app_exception.dart';
import 'session_provider.dart';

/// Brand profiles: the signed-in brand's own profile and verification
/// details, and the brand list that creators see.
class BrandProvider extends SessionProvider {
  BrandProvider(this._service);

  final BrandService _service;

  BrandProfile? _myBrand;
  bool _myBrandLoaded = false;
  BrandVerification? _myVerification;
  List<BrandProfile> _brands = [];
  final Map<String, BrandProfile> _cache = {};

  /// The signed-in brand's profile (null for creators and admins).
  BrandProfile? get myBrand => _myBrand;
  bool get myBrandLoaded => _myBrandLoaded;

  /// The signed-in brand's private PAN details.
  BrandVerification? get myVerification => _myVerification;

  /// Recently active brands, shown to creators.
  List<BrandProfile> get brands => _brands;

  @override
  void onSessionStarted(AppUser user) {
    if (user.isBrand) {
      listen(_service.watchProfile(user.uid), (brand) {
        _myBrand = brand;
        _myBrandLoaded = true;
      });
      listen(
        _service.watchVerification(user.uid),
        (verification) => _myVerification = verification,
      );
    } else {
      listen(_service.watchBrands(limit: 30), (brands) => _brands = brands);
    }
  }

  @override
  void onSessionEnded() {
    _myBrand = null;
    _myBrandLoaded = false;
    _myVerification = null;
    _brands = [];
    _cache.clear();
  }

  Future<BrandProfile?> getById(String id) async {
    for (final brand in _brands) {
      if (brand.uid == id) return brand;
    }
    if (_cache.containsKey(id)) return _cache[id];
    try {
      final brand = await _service.getProfile(id);
      if (brand != null) _cache[id] = brand;
      return brand;
    } catch (_) {
      return null;
    }
  }

  Future<String?> createProfile(BrandProfile profile, {String panNumber = ''}) =>
      guard(() => _service.createProfile(profile, panNumber: panNumber));

  Future<String?> updateProfile(BrandProfile profile) =>
      guard(() => _service.updateProfile(profile));

  Future<String?> submitVerification({
    required String panNumber,
    String? panDocumentUrl,
  }) =>
      guard(
        () => _service.submitVerification(
          uid!,
          panNumber: panNumber,
          panDocumentUrl: panDocumentUrl,
        ),
      );

  void recordView(String brandId) {
    if (brandId == uid) return;
    _service.recordView(brandId).ignore();
  }
}
