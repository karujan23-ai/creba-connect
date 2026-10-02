// Tests for the app's pure logic: no Firebase and no screens are involved,
// so these run in a second with `flutter test`.

import 'package:creba_connect/models/brand_profile.dart';
import 'package:creba_connect/models/conversation.dart';
import 'package:creba_connect/models/creator_profile.dart';
import 'package:creba_connect/models/enums.dart';
import 'package:creba_connect/models/filters.dart';
import 'package:creba_connect/models/hiring_post.dart';
import 'package:creba_connect/models/job_application.dart';
import 'package:creba_connect/utils/app_config.dart';
import 'package:creba_connect/utils/formatters.dart';
import 'package:creba_connect/utils/match_scorer.dart';
import 'package:creba_connect/utils/trending_scorer.dart';
import 'package:creba_connect/utils/validators.dart';
import 'package:creba_connect/widgets/form_fields.dart';
import 'package:creba_connect/widgets/price_display.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 1);

CreatorProfile _creator({
  String uid = 'c1',
  List<String> types = const ['Model'],
  List<String> niches = const ['Fashion'],
  String city = 'Kathmandu',
  num? rate = 7000,
  bool available = true,
  int views = 0,
  int saves = 0,
  String? gender,
}) =>
    CreatorProfile(
      uid: uid,
      fullName: 'Anisha Sharma',
      creatorTypes: types,
      niches: niches,
      city: city,
      startingRate: rate,
      isAvailable: available,
      viewCount: views,
      saveCount: saves,
      gender: gender,
      createdAt: _now,
      updatedAt: _now,
    );

HiringPost _post({
  List<String> types = const ['Model'],
  List<String> niches = const ['Fashion'],
  String city = 'Kathmandu',
  bool remote = false,
  BudgetType budgetType = BudgetType.fixed,
  num? min = 10000,
  num? max,
  Currency currency = Currency.npr,
}) =>
    HiringPost(
      id: 'p1',
      brandId: 'b1',
      brandName: 'GLAMCO',
      title: 'Fashion Model Needed',
      description: 'Winter collection campaign.',
      creatorTypes: types,
      niches: niches,
      city: city,
      isRemote: remote,
      budgetType: budgetType,
      budgetMin: min,
      budgetMax: max,
      currency: currency,
      createdAt: _now,
      updatedAt: _now,
    );

void main() {
  group('Best Fit (MatchScorer)', () {
    test('a creator who matches everything scores 100', () {
      expect(MatchScorer.creatorForPost(_creator(), _post()), 100);
    });

    test('wrong creator type loses the 25 type points', () {
      final photographer = _creator(types: ['Photographer']);
      expect(MatchScorer.creatorForPost(photographer, _post()), 75);
    });

    test('matching one of two wanted niches earns half the niche points', () {
      final post = _post(niches: ['Fashion', 'Beauty']);
      expect(MatchScorer.creatorForPost(_creator(), post), 85);
    });

    test('a different city loses location points unless the job is remote', () {
      final pokhara = _creator(city: 'Pokhara');
      expect(MatchScorer.creatorForPost(pokhara, _post()), 85);
      expect(MatchScorer.creatorForPost(pokhara, _post(remote: true)), 100);
    });

    test('an unavailable creator loses the availability points', () {
      expect(MatchScorer.creatorForPost(_creator(available: false), _post()), 85);
    });

    test('a rate far above the budget loses the budget points', () {
      expect(MatchScorer.creatorForPost(_creator(rate: 20000), _post()), 85);
    });

    test('a USD budget is converted before comparing with an NPR rate', () {
      // 100 USD is 13,400 NPR at the fixed rate, so a 7,000 NPR rate fits.
      final post = _post(min: 100, currency: Currency.usd);
      expect(MatchScorer.creatorForPost(_creator(), post), 100);
    });

    test('for a brand, category stands in for the niches it wants', () {
      final brand = BrandProfile(
        uid: 'b1',
        brandName: 'GLAMCO',
        category: 'Clothing / Fashion',
        city: 'Kathmandu',
        createdAt: _now,
        updatedAt: _now,
      );
      // Wanted niches are Fashion and Clothing; the creator has one of them.
      expect(MatchScorer.creatorForBrand(_creator(), brand), 75);
      expect(
        MatchScorer.creatorForBrand(_creator(niches: ['Fashion', 'Clothing']), brand),
        100,
      );
    });
  });

  group('Trending (TrendingScorer)', () {
    test('saves count three times as much as views', () {
      final viewed = _creator(uid: 'viewed', views: 3);
      final saved = _creator(uid: 'saved', saves: 2);
      expect(TrendingScorer.score(saved), greaterThan(TrendingScorer.score(viewed)));
    });

    test('trending puts the highest score first', () {
      final ranked = TrendingScorer.trending([
        _creator(uid: 'quiet'),
        _creator(uid: 'popular', views: 200, saves: 20),
      ]);
      expect(ranked.first.uid, 'popular');
    });

    test('popularIn only returns creators with that niche', () {
      final result = TrendingScorer.popularIn(
        [_creator(uid: 'fashion'), _creator(uid: 'food', niches: ['Food'])],
        'Food',
      );
      expect(result.map((creator) => creator.uid), ['food']);
    });
  });

  group('Money', () {
    test('formats NPR with thousands separators', () {
      expect(Money.format(15000, Currency.npr), 'NPR 15,000');
    });

    test('same currency is shown exactly', () {
      expect(Money.display(15000, Currency.npr, Currency.npr), 'NPR 15,000');
    });

    test('a converted amount is marked as approximate', () {
      final expected = (15000 / AppConfig.nprPerUsd).round();
      expect(Money.display(15000, Currency.npr, Currency.usd), '≈ USD $expected');
    });

    test('parses numbers typed with commas', () {
      expect(Money.parse('10,000'), 10000);
      expect(Money.parse(''), isNull);
    });

    test('budget text covers fixed, range and negotiable', () {
      expect(budgetText(_post(), Currency.npr), 'NPR 10,000');
      expect(
        budgetText(_post(budgetType: BudgetType.range, max: 20000), Currency.npr),
        'NPR 10,000–20,000',
      );
      expect(
        budgetText(_post(budgetType: BudgetType.negotiable), Currency.npr),
        'Negotiable',
      );
    });
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.email('anisha@example.com'), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('password needs at least 6 characters', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('phone accepts digits with an optional country code', () {
      expect(Validators.phone('9812345678'), isNull);
      expect(Validators.phone('+977 981-2345678'), isNull);
      expect(Validators.phone('12ab'), isNotNull);
    });

    test('PAN must be exactly 9 digits', () {
      expect(Validators.pan('123456789'), isNull);
      expect(Validators.pan('12345'), isNotNull);
      expect(Validators.pan('', isRequired: false), isNull);
    });

    test('amount must be a positive number', () {
      expect(Validators.amount('5000'), isNull);
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('', isRequired: false), isNull);
    });

    test('links must be full web addresses', () {
      expect(Validators.url('https://example.com/portfolio'), isNull);
      expect(Validators.url('example'), isNotNull);
      expect(Validators.url(''), isNull);
    });
  });

  group('Filters', () {
    test('creator filter matches search text against name, niche and city', () {
      final creator = _creator();
      expect(const CreatorFilter(query: 'anisha').matches(creator), isTrue);
      expect(const CreatorFilter(query: 'fashion').matches(creator), isTrue);
      expect(const CreatorFilter(query: 'pokhara').matches(creator), isFalse);
    });

    test('creator filter applies rate, city and availability', () {
      final creator = _creator(rate: 7000);
      expect(const CreatorFilter(maxRate: 5000).matches(creator), isFalse);
      expect(const CreatorFilter(maxRate: 8000).matches(creator), isTrue);
      expect(const CreatorFilter(city: 'Lalitpur').matches(creator), isFalse);
      expect(
        const CreatorFilter(availableOnly: true).matches(_creator(available: false)),
        isFalse,
      );
    });

    test('job filter matches brand name and remote-only', () {
      expect(const JobFilter(query: 'glamco').matches(_post()), isTrue);
      expect(const JobFilter(remoteOnly: true).matches(_post()), isFalse);
      expect(const JobFilter(remoteOnly: true).matches(_post(remote: true)), isTrue);
    });
  });

  group('Models', () {
    test('profile completeness rises as fields are filled in', () {
      final empty = CreatorProfile(uid: 'x', fullName: '', createdAt: _now, updatedAt: _now);
      expect(empty.completeness, 0);
      expect(_creator().completeness, greaterThan(empty.completeness));
    });

    test('a conversation ID is the same whichever user starts it', () {
      expect(Conversation.idFor('bob', 'alice'), Conversation.idFor('alice', 'bob'));
      expect(Conversation.idFor('bob', 'alice'), 'alice_bob');
    });

    test('an application ID combines the job and the creator', () {
      expect(JobApplication.idFor('job1', 'creator1'), 'job1_creator1');
    });

    test('unknown stored values fall back to safe defaults', () {
      expect(UserRole.fromValue('superuser'), UserRole.creator);
      expect(VerificationStatus.fromValue(null), VerificationStatus.pending);
      expect(ApplicationStatus.fromValue('???'), ApplicationStatus.applied);
    });

    test('multi-line text becomes a clean list', () {
      expect(linesToList('• One\n\n- Two\n  Three  '), ['One', 'Two', 'Three']);
    });
  });
}
