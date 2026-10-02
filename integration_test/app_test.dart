// End-to-end test: drives the real app the way a person would, against the
// Firebase Local Emulator Suite (never against real data).
//
// How to run it:
//   1. Start the emulators:   firebase emulators:start --only auth,firestore
//   2. Start an Android emulator.
//   3. flutter test integration_test/app_test.dart --dart-define=USE_FIREBASE_EMULATOR=true
//
// It walks through one full story: a brand registers and posts an
// opportunity, a creator registers and applies, they chat, the brand
// shortlists the creator, and an admin verifies the brand.

import 'dart:convert';
import 'dart:io';

import 'package:creba_connect/main.dart' as app;
import 'package:creba_connect/services/firebase_bootstrap.dart';
import 'package:creba_connect/widgets/app_bottom_nav.dart';
import 'package:creba_connect/widgets/app_text_field.dart';
import 'package:creba_connect/widgets/category_chip.dart';
import 'package:creba_connect/widgets/layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _host = '10.0.2.2'; // the computer, as seen from the Android emulator
const _password = 'test-password-1';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'brand, creator and admin journey',
    timeout: const Timeout(Duration(minutes: 20)),
    (tester) async {
      // ------------------------------------------------ a clean start
      await FirebaseBootstrap.initialize();
      // Refuse to run against real data: this test wipes the database.
      expect(
        const bool.fromEnvironment('USE_FIREBASE_EMULATOR'),
        isTrue,
        reason: 'Run with --dart-define=USE_FIREBASE_EMULATOR=true',
      );
      final project = Firebase.app().options.projectId;
      await _emulator('DELETE',
          'http://$_host:8080/emulator/v1/projects/$project/databases/(default)/documents');
      await _emulator(
          'DELETE', 'http://$_host:9099/emulator/v1/projects/$project/accounts');
      await FirebaseAuth.instance.signOut();

      const brandName = 'Test Threads';
      const brandEmail = 'brand@test.creba';
      const creatorName = 'Maya Tamang';
      const creatorEmail = 'maya@test.creba';
      const postTitle = 'Lookbook Model Needed';
      const editedTitle = 'Lookbook Model Wanted';

      await app.main();
      await tester.waitFor(find.text('Create an account'));

      // ============================================== BRAND: sign up
      _step('Brand signs up');
      await tester.tapOn(find.text('Create an account'));
      await tester.tapOn(find.text('Brand'));
      await tester.fill('Business name', brandName);
      await tester.fill('Email', brandEmail);
      await tester.fill('Phone number', '9800000001');
      await tester.fill('Password', _password);
      await tester.tapOn(find.text('Create account'), scroll: true);

      _step('Brand onboarding');
      await tester.waitFor(find.text('Step 1 of 6'));
      await tester.tapOn(find.text('Continue'));
      await tester.tapOn(_chip('Clothing / Fashion'));
      await tester.tapOn(find.text('Continue'));
      await tester.tapOn(_chip('Kathmandu'));
      await tester.tapOn(find.text('Continue'));
      await tester.fill('Description', 'Everyday clothing made in Kathmandu.');
      await tester.tapOn(find.text('Continue'));
      await tester.fill('PAN number', '123456789');
      await tester.tapOn(find.text('Continue'));
      await tester.waitFor(find.text('Step 6 of 6'));
      await tester.tapOn(find.text('Skip'));
      await tester.waitFor(find.text('Hire a creator'));
      expect(find.text('Pending review'), findsOneWidget);

      // ======================================== BRAND: create a post
      _step('Brand creates a hiring post (CREATE)');
      await tester.tapOn(find.text('Hire a creator'));
      await tester.fill('Title', postTitle);
      await tester.fill(
        'Description',
        'Half-day studio shoot for our new winter lookbook.',
      );
      await tester.tapOn(_chip('Model'), scroll: true);
      await tester.tapOn(_chip('Full Day'), scroll: true);
      await tester.pickDate();
      await tester.fill('Amount', '15000');
      await tester.fill('Requirements', 'Fashion experience\nComfortable on camera');
      await tester.tapOn(find.text('Publish opportunity'), scroll: true);
      await tester.waitFor(find.text('Opportunity published.'));

      _step('Brand sees the post in its list (READ)');
      await tester.openTab('Opportunities');
      await tester.waitFor(find.text(postTitle));
      expect(find.text('NPR 15,000'), findsOneWidget);

      await tester.signOut();

      // ============================================ CREATOR: sign up
      _step('Creator signs up');
      await tester.tapOn(find.text('Create an account'));
      await tester.fill('Full name', creatorName);
      await tester.fill('Email', creatorEmail);
      await tester.fill('Phone number', '9800000002');
      await tester.fill('Password', _password);
      await tester.tapOn(find.text('Create account'), scroll: true);

      _step('Creator onboarding');
      await tester.waitFor(find.text('Step 1 of 5'));
      await tester.tapOn(_chip('Model'));
      await tester.tapOn(find.text('Continue'));
      await tester.tapOn(_chip('Fashion'));
      await tester.tapOn(find.text('Continue'));
      await tester.tapOn(_chip('Kathmandu'));
      await tester.tapOn(find.text('Continue'));
      await tester.fill('Bio', 'Fashion model based in Kathmandu, open to shoots.');
      await tester.tapOn(find.text('Continue'));
      await tester.waitFor(find.text('Step 5 of 5'));
      await tester.tapOn(find.text('Skip'));
      await tester.waitFor(find.textContaining('% complete'));
      await tester.reveal(find.text('Recently posted'));

      // ============================================== CREATOR: apply
      _step('Creator finds the post in the live feed and applies');
      await tester.openTab('Discover');
      await tester.waitFor(find.text(postTitle));
      expect(find.textContaining('% match'), findsWidgets);
      await tester.tapOn(find.text('Apply now'));
      await tester.fill('Message to the brand', 'I have shot three lookbooks this year.');
      await tester.fill('Your rate for this job', '12000');
      await tester.tapOn(find.text('Send application'));
      await tester.waitFor(find.text('Application sent.'));
      await tester.waitFor(find.text('Applied'));

      _step('Creator opens the full post');
      await tester.tapOn(find.text(postTitle));
      await tester.waitFor(find.text('You applied'));
      await tester.reveal(find.text('REQUIREMENTS'));
      // The action bar must sit at the bottom, not cover the screen.
      expect(tester.getSize(find.byType(GlassCard).last).height, lessThan(140));
      await tester.back();

      _step('Creator saves the post');
      await tester.tapOn(find.byTooltip('Save'));
      await tester.waitFor(find.byTooltip('Remove from saved'));

      _step('Creator filters the feed');
      await tester.tapOn(find.byIcon(Icons.tune));
      await tester.tapOn(_chip('Fashion'), scroll: true);
      await tester.tapOn(find.text('Show results'));
      await tester.waitFor(find.text(postTitle));
      await tester.tapOn(find.byIcon(Icons.tune));
      await tester.tapOn(_chip('Gaming'), scroll: true);
      await tester.tapOn(_chip('Fashion'), scroll: true);
      await tester.tapOn(find.text('Show results'));
      await tester.waitFor(find.text('No opportunities found'));
      await tester.tapOn(find.text('Clear filters'));
      await tester.waitFor(find.text(postTitle));

      _step('Creator reports the post');
      await tester.tapOn(find.byTooltip('More'));
      await tester.tapOn(find.text('Report'));
      await tester.tapOn(_chip('Spam or misleading'));
      await tester.tapOn(find.text('Send report'));
      await tester.waitFor(find.text('Report sent. Thank you.'));

      _step('Creator opens saved opportunities and notifications');
      await tester.openTab('Home');
      await tester.tapOn(find.text('Saved'), scroll: true);
      await tester.waitFor(find.text(postTitle));
      await tester.back();
      await tester.tapOn(find.byIcon(Icons.notifications_none), scroll: true);
      await tester.waitFor(find.text('You are all caught up'));
      await tester.back();

      _step('Creator sees the application and messages the brand');
      await tester.openTab('Applications');
      await tester.waitFor(find.text(postTitle));
      await tester.tapOn(find.text('Message brand'));
      await tester.waitFor(find.text('Say hello'));
      await tester.sendChat('Hello, is the shoot date flexible?');
      await tester.back();

      // ================================= CREATOR: availability CRUD
      _step('Creator creates an availability post (CREATE)');
      await tester.openTab('Home');
      await tester.tapOn(find.text('Manage availability posts'), scroll: true);
      await tester.tapOn(find.text('New'));
      await tester.fill('Title', 'Available for fashion shoots');
      await tester.pickDate();
      await tester.pickDate();
      await tester.tapOn(_chip('Full Day'), scroll: true);
      await tester.tapOn(find.text('Publish post'), scroll: true);
      await tester.waitFor(find.text('Available for fashion shoots'));

      _step('Creator edits it (UPDATE)');
      await tester.tapOn(find.byTooltip('Edit'));
      await tester.fill('Title', 'Available for lookbook shoots');
      await tester.tapOn(find.text('Save changes'), scroll: true);
      await tester.waitFor(find.text('Available for lookbook shoots'));

      _step('Creator pauses it');
      await tester.tapOn(find.byType(Switch));
      await tester.waitFor(find.text('Hidden'));

      _step('Creator deletes it (DELETE)');
      await tester.tapOn(find.byTooltip('Delete'));
      await tester.tapOn(_inDialog('Delete'));
      await tester.waitFor(find.text('No availability posts'));
      await tester.back();

      _step('Creator edits their profile (UPDATE)');
      await tester.openTab('Profile');
      await tester.tapOn(find.text('Edit profile'));
      await tester.fill('Starting rate', '7000');
      await tester.tapOn(find.text('Save changes'), scroll: true);
      await tester.waitFor(find.text('Profile updated.'));
      await tester.reveal(find.textContaining('NPR 7,000'));

      _step('Creator requests a profile boost (no payment is taken)');
      await tester.tapOn(find.text('Boost profile'), scroll: true);
      await tester.tapOn(find.text('Request promotion'));
      await tester.waitFor(find.text('Requested'));
      await tester.back();

      _step('Creator views the plans');
      await tester.tapOn(find.byTooltip('Settings'));
      await tester.tapOn(find.text('Plan'));
      await tester.waitFor(find.text('Your plan'));
      await tester.back();
      await tester.back();

      await tester.signOut();

      // ============================================== BRAND: sign in
      _step('Brand signs in again');
      await tester.fill('Email', brandEmail);
      await tester.fill('Password', _password);
      await tester.tapOn(find.text('Sign in'));
      await tester.waitFor(find.text('Hire a creator'));

      _step('Brand was notified about the application');
      await tester.tapOn(find.byIcon(Icons.notifications_none));
      await tester.waitFor(find.text('New application'));
      await tester.back();

      _step('Brand reads the chat in real time and replies');
      await tester.openTab('Messages');
      await tester.tapOn(find.text(creatorName));
      await tester.waitFor(find.text('Hello, is the shoot date flexible?'));
      await tester.sendChat('Yes, any day that week works.');
      await tester.back();

      _step('Brand shortlists the applicant (UPDATE)');
      await tester.openTab('Opportunities');
      await tester.tapOn(find.text('Applicants'));
      await tester.waitFor(find.text(creatorName));
      await tester.tapOn(find.byTooltip('Change stage'));
      await tester.tapOn(find.text('Shortlist'));
      await tester.waitFor(find.text('Shortlisted (1)'));
      await tester.back();

      _step('Brand discovers the creator with a Best Fit score and saves them');
      await tester.openTab('Discover');
      await tester.waitFor(find.text(creatorName));
      expect(find.textContaining('% match'), findsWidgets);
      await tester.tapOn(find.byTooltip('Save creator'));
      await tester.waitFor(find.byTooltip('Remove from saved'));

      _step('Brand opens the creator profile and invites them');
      await tester.tapOn(find.text(creatorName));
      await tester.waitFor(find.text('Based on your requirements'));
      await tester.tapOn(find.text('Invite'));
      await tester.tapOn(find.text(postTitle));
      await tester.waitFor(find.text('Invitation sent to $creatorName.'));
      await tester.back();

      _step('Brand opens saved creators and its verification status');
      await tester.openTab('Home');
      await tester.tapOn(find.text('Saved creators'), scroll: true);
      await tester.waitFor(find.text(creatorName));
      await tester.back();
      await tester.openTab('Profile');
      await tester.tapOn(find.text('Verification'));
      await tester.waitFor(find.text('Business verification'));
      await tester.back();

      _step('Brand edits the post (UPDATE)');
      await tester.openTab('Opportunities');
      await tester.tapOn(find.byTooltip('More'));
      await tester.tapOn(find.text('Edit'));
      await tester.fill('Title', editedTitle);
      await tester.tapOn(find.text('Save changes'), scroll: true);
      await tester.waitFor(find.text(editedTitle));

      // ================================== THEME and CURRENCY settings
      _step('Theme switches at runtime');
      await tester.openTab('Profile');
      await tester.tapOn(find.byTooltip('Settings'));
      await tester.tapOn(_chip('Dark'));
      expect(tester.brightness, Brightness.dark);
      await tester.tapOn(_chip('Light'));
      expect(tester.brightness, Brightness.light);

      _step('Currency switches to USD and back');
      await tester.tapOn(_chip('USD'), scroll: true);
      await tester.back();
      await tester.openTab('Opportunities');
      await tester.waitFor(find.textContaining('≈ USD'));
      await tester.openTab('Profile');
      await tester.tapOn(find.byTooltip('Settings'));
      await tester.tapOn(_chip('NPR'), scroll: true);
      await tester.back();

      _step('Brand deletes the post (DELETE)');
      await tester.openTab('Opportunities');
      await tester.tapOn(find.byTooltip('More'));
      await tester.tapOn(find.text('Delete'));
      await tester.tapOn(_inDialog('Delete'));
      await tester.waitFor(find.text('No opportunities yet'));

      await tester.signOut();

      // ======================================================= ADMIN
      _step('A user is made admin by hand in Firestore');
      await tester.tapOn(find.text('Create an account'));
      await tester.fill('Full name', 'Admin Person');
      await tester.fill('Email', 'admin@test.creba');
      await tester.fill('Phone number', '9800000003');
      await tester.fill('Password', _password);
      await tester.tapOn(find.text('Create account'), scroll: true);
      await tester.waitFor(find.text('Step 1 of 5'));
      // This is what "assigning an admin manually" does: it edits the role
      // field of users/{uid} from outside the app.
      final adminUid = FirebaseAuth.instance.currentUser!.uid;
      await _emulator(
        'PATCH',
        'http://$_host:8080/v1/projects/$project/databases/(default)/documents'
            '/users/$adminUid?updateMask.fieldPaths=role',
        body: {
          'fields': {
            'role': {'stringValue': 'admin'},
          },
        },
      );
      await tester.waitFor(find.text('Overview'));

      _step('Admin verifies the brand');
      await tester.tapOn(find.text('Brands waiting for verification'));
      await tester.waitFor(find.text(brandName));
      await tester.waitFor(find.text('123456789'));
      await tester.tapOn(find.text('Verify'));
      await tester.waitFor(find.text('$brandName verified.'));
      await tester.back();

      _step('Admin adds sample data');
      await tester.openTab('Settings');
      await tester.tapOn(find.text('Sample data'), scroll: true);
      await tester.tapOn(find.text('Add sample data'));
      await tester.waitFor(find.text('Sample data added.'));

      _step('Admin sees users and content');
      await tester.openTab('Users');
      await tester.waitFor(find.text(creatorName));
      await tester.openTab('Content');
      await tester.waitFor(find.text('Fashion Model Needed'));

      _step('Admin resolves the report');
      await tester.tapOn(find.text('Reports (1)'));
      await tester.tapOn(find.text('Resolve'));
      await tester.waitFor(find.text('Report resolved.'));

      _step('Admin approves the boost request by hand');
      await tester.openTab('Payments');
      await tester.tapOn(find.text('Approve manually'));
      await tester.tapOn(_inDialog('Approve'));
      await tester.waitFor(find.text('Promotion activated.'));

      _step('Admin sets a plan and opens the category editor');
      await tester.openTab('Users');
      await tester.tapOn(find.byTooltip('Manage'));
      await tester.tapOn(find.text('Set Pro plan'));
      await tester.waitFor(find.textContaining('Plan set to'));
      await tester.openTab('Settings');
      await tester.tapOn(find.text('Categories'), scroll: true);
      await tester.reveal(find.text('Business categories'));
      await tester.back();

      await tester.signOut(tab: 'Settings');
      await tester.waitFor(find.text('Create an account'));
      _step('Journey complete');
    },
  );
}

void _step(String message) => debugPrint('STEP: $message');

Finder _chip(String label) => find.widgetWithText(CategoryChip, label);

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

/// Calls the emulator's REST API as the "owner", which bypasses security
/// rules. Only the local emulator accepts this; real Firebase does not.
Future<void> _emulator(String method, String url, {Map<String, Object?>? body}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, Uri.parse(url));
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer owner');
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 300) {
      throw StateError('Emulator $method $url failed: ${response.statusCode} $text');
    }
  } finally {
    client.close();
  }
}

extension on WidgetTester {
  /// Waits (in real time) until [finder] matches something on screen.
  Future<void> waitFor(Finder finder, {int seconds = 30}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 120));
      if (any(finder)) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  /// Scrolls the screen's list until [finder] is built and visible. Lists
  /// only build what is near the screen, so it looks down first, then up.
  Future<void> reveal(Finder finder) async {
    for (final step in const [-240.0, 240.0]) {
      for (var attempt = 0; attempt < 30 && !any(finder); attempt++) {
        await drag(find.byType(ListView).first, Offset(0, step), warnIfMissed: false);
        await pump(const Duration(milliseconds: 120));
      }
    }
    if (!any(finder)) throw TestFailure('Could not scroll to $finder');
    await ensureVisible(finder.first);
    await pump(const Duration(milliseconds: 250));
  }

  Future<void> tapOn(Finder finder, {bool scroll = false}) async {
    if (scroll) {
      await reveal(finder);
    } else {
      await waitFor(finder);
    }
    await dismissSnackBar();
    await tap(finder.first);
    await pump(const Duration(milliseconds: 450));
  }

  /// A person would wait for a message at the bottom of the screen to go
  /// away before tapping something underneath it. The test removes it.
  Future<void> dismissSnackBar() async {
    if (!any(find.byType(SnackBar))) return;
    ScaffoldMessenger.of(element(find.byType(Scaffold).first))
      ..removeCurrentSnackBar()
      ..clearSnackBars();
    await pump(const Duration(milliseconds: 100));
  }

  /// Types into the [AppTextField] with the given label.
  Future<void> fill(String label, String text) async {
    final field = find.descendant(
      of: find.widgetWithText(AppTextField, label),
      matching: find.byType(TextFormField),
    );
    await waitFor(find.byType(AppTextField));
    if (any(find.byType(ListView))) {
      await reveal(field);
    } else {
      await waitFor(field);
      await ensureVisible(field.first);
    }
    await enterText(field.first, text);
    await pump(const Duration(milliseconds: 200));
  }

  /// Opens the first empty date field and accepts the suggested date.
  Future<void> pickDate() async {
    await tapOn(find.text('Choose a date'), scroll: true);
    await tapOn(find.text('OK'));
  }

  Future<void> openTab(String label) => tapOn(
        find.descendant(of: find.byType(AppBottomNav), matching: find.text(label)),
      );

  Future<void> back() async {
    await pageBack();
    await pump(const Duration(milliseconds: 500));
  }

  Future<void> sendChat(String text) async {
    await enterText(find.byType(TextField).last, text);
    await tapOn(find.byTooltip('Send'));
    await waitFor(find.text(text));
  }

  Future<void> signOut({String tab = 'Profile'}) async {
    await openTab(tab);
    if (tab == 'Profile') await tapOn(find.byTooltip('Settings'));
    await tapOn(find.text('Sign out'), scroll: true);
    await tapOn(_inDialog('Sign out'));
    await waitFor(find.text('Create an account'));
  }

  Brightness get brightness =>
      Theme.of(element(find.byType(Scaffold).first)).brightness;
}
