import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../utils/constants.dart';
import '../../widgets/layout.dart';

/// A simple page of headed paragraphs, used for Privacy, Help and About.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.title, required this.sections});

  final String title;

  /// Each entry is a (heading, body) pair.
  final List<(String, String)> sections;

  static const privacy = InfoScreen(
    title: 'Privacy',
    sections: [
      (
        'Your password',
        'Your password is handled by Firebase Authentication. It is never '
            'stored in our database and nobody at CreBa Connect can read it.',
      ),
      (
        'What others can see',
        'Your public profile (name, city, niches, bio, links and rate) is '
            'visible to signed-in users. Your email and phone number are not '
            'shown on your profile.',
      ),
      (
        'Business PAN',
        'A PAN number is visible only to the business that entered it and to '
            'the CreBa Connect review team.',
      ),
      (
        'Messages',
        'Only the two people in a conversation can read its messages.',
      ),
      (
        'Payments',
        'The app does not collect card or bank details. Online payment is '
            'not available yet.',
      ),
    ],
  );

  static const help = InfoScreen(
    title: 'Help',
    sections: [
      (
        'I am a creator. How do I get work?',
        'Complete your profile, then open Discover to browse opportunities '
            'and apply. You can also publish an availability post so brands '
            'can find you.',
      ),
      (
        'I am a brand. How do I hire?',
        'Tap "Hire a creator" to post an opportunity, or open Discover to '
            'browse creators and message them directly.',
      ),
      (
        'What does "Business Verified" mean?',
        'The CreBa Connect team has reviewed the business details the brand '
            'submitted. It is an in-app review and is not a government '
            'verification.',
      ),
      (
        'What is the match percentage?',
        'Best Fit is a simple score based on your requirements: creator '
            'type, niche, city, availability and budget. It is a rule-based '
            'calculation, not artificial intelligence.',
      ),
      (
        'Why do some prices show "≈"?',
        'Prices are entered in one currency. When you view them in the '
            'other, they are converted with a fixed rate and are approximate.',
      ),
      (
        'Something looks wrong',
        'Use Report from the menu on any profile or post, and the team will '
            'review it.',
      ),
    ],
  );

  static const about = InfoScreen(
    title: 'About',
    sections: [
      (
        AppConstants.appName,
        '${AppConstants.tagline}\n\nA platform where brands in Nepal discover '
            'models, influencers, UGC creators, photographers and other '
            'creative professionals, and where creators find paid work.',
      ),
      (
        'Built with',
        'Flutter, Firebase Authentication, Cloud Firestore and Provider.',
      ),
      (
        'Sample data',
        'Any profile or post marked "Sample" is demonstration data and does '
            'not represent a real person or business.',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ContentWidth(
          child: ListView(
            padding: pagePadding(context, top: 12),
            children: [
              for (final (heading, body) in sections) ...[
                Text(heading, style: context.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: context.textTheme.bodyLarge
                      ?.copyWith(color: context.palette.textMuted),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      );
}
