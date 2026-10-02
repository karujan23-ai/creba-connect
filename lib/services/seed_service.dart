import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';

/// Adds and removes SAMPLE data so the app does not look empty in a demo.
///
/// Every document created here has `isDemo: true` and an ID starting with
/// `demo_`. The brands and people are invented for demonstration; they are
/// not real businesses or real creators. Admin only (enforced by the rules).
class SeedService {
  SeedService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _demoCollections = [
    FirestorePaths.creatorProfiles,
    FirestorePaths.brandProfiles,
    FirestorePaths.hiringPosts,
    FirestorePaths.availabilityPosts,
  ];

  Future<void> addDemoData() {
    final batch = _db.batch();
    final now = DateTime.now();
    Timestamp daysFromNow(int days) =>
        Timestamp.fromDate(now.add(Duration(days: days)));

    for (final creator in _creators) {
      batch.set(
        _db.collection(FirestorePaths.creatorProfiles).doc(creator['uid'] as String),
        {
          ...creator,
          'isAvailable': true,
          'isDemo': true,
          'createdAt': daysFromNow(-(creator['ageDays'] as int)),
          'updatedAt': daysFromNow(-(creator['ageDays'] as int) ~/ 4),
        }..remove('ageDays'),
      );
    }

    for (final brand in _brands) {
      batch.set(
        _db.collection(FirestorePaths.brandProfiles).doc(brand['uid'] as String),
        {
          ...brand,
          'saveCount': 0,
          'isDemo': true,
          'createdAt': daysFromNow(-40),
          'updatedAt': daysFromNow(-2),
        },
      );
    }

    for (final post in _hiringPosts) {
      batch.set(
        _db.collection(FirestorePaths.hiringPosts).doc(post['id'] as String),
        {
          ...post,
          'currency': 'NPR',
          'status': 'open',
          'contactPreference': 'In-app chat',
          'applicationCount': 0,
          'isDemo': true,
          'startDate': daysFromNow(post['startsIn'] as int),
          'deadline': daysFromNow((post['startsIn'] as int) - 4),
          'createdAt': daysFromNow(-(post['postedDaysAgo'] as int)),
          'updatedAt': daysFromNow(-(post['postedDaysAgo'] as int)),
        }
          ..remove('id')
          ..remove('startsIn')
          ..remove('postedDaysAgo'),
      );
    }

    for (final post in _availabilityPosts) {
      batch.set(
        _db.collection(FirestorePaths.availabilityPosts).doc(post['id'] as String),
        {
          ...post,
          'currency': 'NPR',
          'isActive': true,
          'isDemo': true,
          'availableFrom': daysFromNow(3),
          'availableTo': daysFromNow(14),
          'createdAt': daysFromNow(-1),
          'updatedAt': daysFromNow(-1),
        }..remove('id'),
      );
    }

    return batch.commit();
  }

  /// Deletes every sample document and returns how many were removed.
  Future<int> removeDemoData() async {
    var removed = 0;
    for (final collection in _demoCollections) {
      final snapshot =
          await _db.collection(collection).where('isDemo', isEqualTo: true).get();
      if (snapshot.docs.isEmpty) continue;
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      removed += snapshot.docs.length;
    }
    return removed;
  }

  static const _sampleNote = 'Sample profile for demonstration.';

  static final List<Map<String, dynamic>> _creators = [
    {
      'uid': 'demo_anisha_sharma',
      'fullName': 'Anisha Sharma',
      'creatorTypes': ['Model', 'UGC Creator'],
      'niches': ['Fashion', 'Beauty', 'Lifestyle'],
      'city': 'Kathmandu',
      'bio': 'Fashion model and UGC creator working with clothing and beauty '
          'labels across the valley. $_sampleNote',
      'gender': 'Female',
      'ageRange': '18–24',
      'languages': ['Nepali', 'English', 'Hindi'],
      'skills': ['Runway', 'Lookbook shoots', 'Short-form video'],
      'startingRate': 5000,
      'workTypes': ['Full Day', 'One-time Campaign', 'UGC Campaign', 'PR Collaboration'],
      'previousCollaborations': ['Winter lookbook (sample)', 'Skincare launch (sample)'],
      'viewCount': 142,
      'saveCount': 18,
      'ageDays': 20,
    },
    {
      'uid': 'demo_sanjay_thapa',
      'fullName': 'Sanjay Thapa',
      'creatorTypes': ['Photographer', 'Videographer'],
      'niches': ['Photography', 'Travel', 'Food'],
      'city': 'Pokhara',
      'bio': 'Lakeside-based photographer shooting travel, hospitality and '
          'food stories. $_sampleNote',
      'gender': 'Male',
      'ageRange': '25–34',
      'languages': ['Nepali', 'English'],
      'skills': ['Product photography', 'Drone footage', 'Editing'],
      'startingRate': 8000,
      'workTypes': ['Half Day', 'Full Day', 'Product Shoot'],
      'previousCollaborations': ['Cafe menu shoot (sample)'],
      'viewCount': 96,
      'saveCount': 11,
      'ageDays': 45,
    },
    {
      'uid': 'demo_riya_gurung',
      'fullName': 'Riya Gurung',
      'creatorTypes': ['Influencer', 'Content Creator'],
      'niches': ['Food', 'Travel', 'Lifestyle'],
      'city': 'Lalitpur',
      'bio': 'Food and lifestyle creator sharing cafes, weekend trips and '
          'everyday finds around Patan. $_sampleNote',
      'gender': 'Female',
      'ageRange': '25–34',
      'languages': ['Nepali', 'English', 'Newari'],
      'skills': ['Reels', 'Reviews', 'Storytelling'],
      'startingRate': 6000,
      'workTypes': ['Social Media Content', 'Monthly Collaboration', 'PR Collaboration'],
      'previousCollaborations': ['Restaurant opening (sample)'],
      'viewCount': 211,
      'saveCount': 27,
      'ageDays': 12,
    },
    {
      'uid': 'demo_aarav_shrestha',
      'fullName': 'Aarav Shrestha',
      'creatorTypes': ['Content Creator', 'Videographer'],
      'niches': ['Technology', 'Gaming', 'Education'],
      'city': 'Bhaktapur',
      'bio': 'Tech reviewer explaining gadgets and apps in simple Nepali. '
          '$_sampleNote',
      'gender': 'Male',
      'ageRange': '18–24',
      'languages': ['Nepali', 'English'],
      'skills': ['Unboxing', 'Tutorials', 'Video editing'],
      'startingRate': 7000,
      'workTypes': ['One-time Campaign', 'Brand Ambassador', 'Social Media Content'],
      'previousCollaborations': <String>[],
      'viewCount': 64,
      'saveCount': 6,
      'ageDays': 8,
    },
  ];

  static final List<Map<String, dynamic>> _brands = [
    {
      'uid': 'demo_glamco',
      'brandName': 'GLAMCO',
      'category': 'Clothing / Fashion',
      'city': 'Kathmandu',
      'description': 'Modern everyday clothing brand. Sample business for demonstration.',
      'verificationStatus': 'verified',
      'viewCount': 320,
    },
    {
      'uid': 'demo_urban_nepal',
      'brandName': 'Urban Nepal',
      'category': 'Lifestyle',
      'city': 'Lalitpur',
      'description': 'Home and lifestyle goods made locally. Sample business for demonstration.',
      'verificationStatus': 'verified',
      'viewCount': 180,
    },
    {
      'uid': 'demo_ktm_streetwear',
      'brandName': 'KTM Streetwear',
      'category': 'Clothing / Fashion',
      'city': 'Kathmandu',
      'description': 'Street-style apparel drops. Sample business for demonstration.',
      'verificationStatus': 'pending',
      'viewCount': 75,
    },
    {
      'uid': 'demo_himalayan_brew',
      'brandName': 'Himalayan Brew',
      'category': 'Food & Beverage',
      'city': 'Pokhara',
      'description': 'Speciality coffee roasted in the hills. Sample business for demonstration.',
      'verificationStatus': 'verified',
      'viewCount': 240,
    },
    {
      'uid': 'demo_mero_beauty',
      'brandName': 'Mero Beauty',
      'category': 'Beauty',
      'city': 'Bhaktapur',
      'description': 'Skincare for Nepali weather. Sample business for demonstration.',
      'verificationStatus': 'pending',
      'viewCount': 58,
    },
  ];

  static final List<Map<String, dynamic>> _hiringPosts = [
    {
      'id': 'demo_post_glamco_model',
      'brandId': 'demo_glamco',
      'brandName': 'GLAMCO',
      'brandVerified': true,
      'title': 'Fashion Model Needed',
      'description': 'Looking for a fashion model for our new winter '
          'collection campaign. (Sample post)',
      'creatorTypes': ['Model'],
      'niches': ['Fashion', 'Clothing'],
      'city': 'Kathmandu',
      'isRemote': false,
      'workType': 'Full Day',
      'duration': '1 day',
      'budgetType': 'fixed',
      'budgetMin': 15000,
      'budgetMax': null,
      'creatorsNeeded': 2,
      'requirements': ['Fashion experience', 'Comfortable on camera', 'Kathmandu based'],
      'deliverables': ['4 hour shoot', '3 outfits', 'Social media usage rights'],
      'viewCount': 420,
      'startsIn': 13,
      'postedDaysAgo': 1,
    },
    {
      'id': 'demo_post_brew_ugc',
      'brandId': 'demo_himalayan_brew',
      'brandName': 'Himalayan Brew',
      'brandVerified': true,
      'title': 'UGC Creators for Coffee Launch',
      'description': 'Short, honest videos of our new cold brew for social '
          'media. Product is sent to you. (Sample post)',
      'creatorTypes': ['UGC Creator', 'Content Creator'],
      'niches': ['Food', 'Lifestyle'],
      'city': 'Pokhara',
      'isRemote': true,
      'workType': 'UGC Campaign',
      'duration': '2 weeks',
      'budgetType': 'range',
      'budgetMin': 6000,
      'budgetMax': 10000,
      'creatorsNeeded': 4,
      'requirements': ['Clear voice-over', 'Good natural light'],
      'deliverables': ['2 vertical videos', 'Raw footage'],
      'viewCount': 265,
      'startsIn': 9,
      'postedDaysAgo': 2,
    },
    {
      'id': 'demo_post_urban_photo',
      'brandId': 'demo_urban_nepal',
      'brandName': 'Urban Nepal',
      'brandVerified': true,
      'title': 'Product Photographer for Catalogue',
      'description': 'Half-day studio shoot of about 30 home products for '
          'our online catalogue. (Sample post)',
      'creatorTypes': ['Photographer'],
      'niches': ['Photography', 'Lifestyle'],
      'city': 'Lalitpur',
      'isRemote': false,
      'workType': 'Product Shoot',
      'duration': 'Half day',
      'budgetType': 'fixed',
      'budgetMin': 12000,
      'budgetMax': null,
      'creatorsNeeded': 1,
      'requirements': ['Own camera and lights', 'Editing included'],
      'deliverables': ['30 edited photos', 'White-background versions'],
      'viewCount': 150,
      'startsIn': 18,
      'postedDaysAgo': 4,
    },
    {
      'id': 'demo_post_ktm_ambassador',
      'brandId': 'demo_ktm_streetwear',
      'brandName': 'KTM Streetwear',
      'brandVerified': false,
      'title': 'Monthly Streetwear Ambassador',
      'description': 'Wear and post our monthly drop. Ongoing collaboration '
          'for the right fit. (Sample post)',
      'creatorTypes': ['Influencer', 'Model'],
      'niches': ['Fashion', 'Lifestyle'],
      'city': 'Kathmandu',
      'isRemote': false,
      'workType': 'Monthly Collaboration',
      'duration': '3 months',
      'budgetType': 'negotiable',
      'budgetMin': null,
      'budgetMax': null,
      'creatorsNeeded': 3,
      'requirements': ['Active Instagram or TikTok', 'Street-style look'],
      'deliverables': ['4 posts per month', 'Stories on drop day'],
      'viewCount': 98,
      'startsIn': 21,
      'postedDaysAgo': 6,
    },
    {
      'id': 'demo_post_mero_makeup',
      'brandId': 'demo_mero_beauty',
      'brandName': 'Mero Beauty',
      'brandVerified': false,
      'title': 'Makeup Artist for Tutorial Series',
      'description': 'Create three tutorial videos using our skincare and '
          'tinted range. (Sample post)',
      'creatorTypes': ['Makeup Artist', 'Content Creator'],
      'niches': ['Beauty', 'Makeup'],
      'city': 'Bhaktapur',
      'isRemote': true,
      'workType': 'One-time Campaign',
      'duration': '1 week',
      'budgetType': 'range',
      'budgetMin': 8000,
      'budgetMax': 14000,
      'creatorsNeeded': 1,
      'requirements': ['Portfolio of past looks'],
      'deliverables': ['3 tutorial videos', '5 product photos'],
      'viewCount': 73,
      'startsIn': 15,
      'postedDaysAgo': 3,
    },
  ];

  static final List<Map<String, dynamic>> _availabilityPosts = [
    {
      'id': 'demo_avail_anisha',
      'creatorId': 'demo_anisha_sharma',
      'creatorName': 'Anisha Sharma',
      'title': 'Available for Fashion Shoots',
      'niches': ['Fashion', 'Clothing'],
      'city': 'Kathmandu',
      'workTypes': ['Full Day', 'UGC Campaign', 'Product Shoot'],
      'rateFrom': 7000,
      'note': 'Open for lookbooks and campaign shoots. (Sample post)',
    },
    {
      'id': 'demo_avail_sanjay',
      'creatorId': 'demo_sanjay_thapa',
      'creatorName': 'Sanjay Thapa',
      'title': 'Booking Food & Hotel Shoots',
      'niches': ['Food', 'Travel', 'Photography'],
      'city': 'Pokhara',
      'workTypes': ['Half Day', 'Full Day'],
      'rateFrom': 9000,
      'note': 'Travelling to Kathmandu on request. (Sample post)',
    },
  ];
}
