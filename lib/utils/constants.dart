/// Fixed lists and text used across the app.
///
/// The three category lists below are only the built-in defaults. An admin can
/// change them in Firestore (`categories` collection); `CategoryProvider`
/// falls back to these when nothing is stored there.
class AppConstants {
  AppConstants._();

  static const appName = 'CreBa Connect';
  static const tagline = 'Connect. Create. Collaborate.';
  static const shortTagline = 'Where Brands Meet Creators.';

  static const defaultCreatorTypes = [
    'Model',
    'Influencer',
    'UGC Creator',
    'Content Creator',
    'Photographer',
    'Videographer',
    'Makeup Artist',
    'Designer',
    'Other',
  ];

  static const defaultNiches = [
    'Fashion',
    'Clothing',
    'Beauty',
    'Makeup',
    'Food',
    'Travel',
    'Fitness',
    'Lifestyle',
    'Technology',
    'Gaming',
    'Photography',
    'Finance',
    'Education',
    'Entertainment',
    'Automotive',
    'Hospitality',
    'Other',
  ];

  static const defaultBusinessCategories = [
    'Clothing / Fashion',
    'Beauty',
    'Food & Beverage',
    'Hospitality',
    'Technology',
    'Fitness',
    'Education',
    'E-commerce',
    'Lifestyle',
    'Travel',
    'Events',
    'Photography',
    'Marketing',
    'Other',
  ];

  static const workTypes = [
    '1–2 Hour Shoot',
    'Half Day',
    'Full Day',
    'One-time Campaign',
    'Monthly Collaboration',
    'PR Collaboration',
    'Product Shoot',
    'UGC Campaign',
    'Social Media Content',
    'Brand Ambassador',
    'Other',
  ];

  static const cities = [
    'Kathmandu',
    'Lalitpur',
    'Bhaktapur',
    'Pokhara',
    'Biratnagar',
    'Bharatpur',
    'Butwal',
    'Dharan',
    'Nepalgunj',
    'Other',
  ];

  static const languages = [
    'Nepali',
    'English',
    'Hindi',
    'Newari',
    'Maithili',
    'Other',
  ];

  static const genders = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];

  static const ageRanges = ['18–24', '25–34', '35–44', '45+'];

  static const contactPreferences = ['In-app chat', 'Phone', 'Email'];

  static const reportReasons = [
    'Spam or misleading',
    'Fake profile or business',
    'Inappropriate content',
    'Harassment',
    'Payment or scam concern',
    'Other',
  ];

  /// Which creator niches fit each business category. Used by Best Fit.
  static const categoryToNiches = <String, List<String>>{
    'Clothing / Fashion': ['Fashion', 'Clothing'],
    'Beauty': ['Beauty', 'Makeup'],
    'Food & Beverage': ['Food'],
    'Hospitality': ['Hospitality', 'Travel', 'Food'],
    'Technology': ['Technology', 'Gaming'],
    'Fitness': ['Fitness', 'Lifestyle'],
    'Education': ['Education'],
    'E-commerce': ['Lifestyle', 'Fashion', 'Technology'],
    'Lifestyle': ['Lifestyle'],
    'Travel': ['Travel', 'Hospitality'],
    'Events': ['Entertainment', 'Photography'],
    'Photography': ['Photography'],
    'Marketing': ['Lifestyle', 'Entertainment'],
  };
}

/// A paid promotion option. Prices are stored in NPR.
class PromotionPackage {
  const PromotionPackage({
    required this.days,
    required this.priceNpr,
    required this.label,
  });

  final int days;
  final int priceNpr;
  final String label;

  static const forHiringPost = [
    PromotionPackage(days: 3, priceNpr: 499, label: '3 days'),
    PromotionPackage(days: 7, priceNpr: 899, label: '7 days'),
    PromotionPackage(days: 14, priceNpr: 1499, label: '14 days'),
  ];

  static const forCreatorProfile = [
    PromotionPackage(days: 7, priceNpr: 299, label: '7 days'),
  ];
}
