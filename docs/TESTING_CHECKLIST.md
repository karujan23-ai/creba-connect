# CreBa Connect — Testing Checklist

Use this before a demo or submission. Work through it with **two accounts** (one creator, one brand) and, for the admin section, one admin account.

Tip: run the app on the emulator for one account and on your phone (or Chrome) for the other. Then you can watch real-time updates happen.

---

## Automated checks (run these first)

| Check | Command (from the project folder) | Expected |
|---|---|---|
| Code analysis | `flutter analyze` | "No issues found!" |
| Logic tests | `flutter test` | "All tests passed!" |
| Security rules | start the emulators, then `npm test` inside `rules-test` | all tests pass |
| Full journey | start the emulators and an Android emulator, then `flutter test integration_test/app_test.dart --dart-define=USE_FIREBASE_EMULATOR=true` | "All tests passed!" |

Starting the emulators: `firebase emulators:start --only auth,firestore`

The emulators are a pretend Firebase running on your laptop. The automated tests only ever use them, never the real project's data.

---

## Authentication

- [ ] **Sign up** as a creator with a new email → lands on onboarding
- [ ] **Sign up** with an email that is already used → "An account already exists with this email."
- [ ] **Sign in** with a wrong password → "Incorrect email or password."
- [ ] **Sign in** with correct details → lands on the home screen
- [ ] **Persistence:** close the app completely and reopen → still signed in, no login screen
- [ ] **Sign out** (Profile → Settings → Sign out) → back to the sign-in screen
- [ ] After signing out, the back button does not return to a protected screen
- [ ] Form validation: empty email, bad email format, password under 6 characters all show a message under the field

## Creator

- [ ] **Create profile:** finish the 5 onboarding steps → home screen with a profile completeness card
- [ ] **Edit profile:** Profile → Edit profile → change the starting rate → Save → the new rate is shown
- [ ] **Availability post — create:** Home → Manage availability posts → New → Publish → appears in the list
- [ ] **Availability post — edit:** pencil icon → change the title → Save → the title updates
- [ ] **Availability post — pause:** switch off → shows "Hidden" / "Paused"
- [ ] **Availability post — delete:** bin icon → confirm → it disappears
- [ ] **Apply to a job:** Discover → Apply now → write a message → Send → the card shows "Applied"
- [ ] Applying twice is not possible (the button is replaced by the status)
- [ ] **Withdraw:** Applications → Withdraw → status becomes "Withdrawn"
- [ ] **Save a job:** bookmark icon → it appears under Home → Saved
- [ ] **Unsave:** tap the bookmark again → it is removed
- [ ] **Search and filter:** type in Discover; open Filters and choose a niche → the list narrows
- [ ] **Not interested:** ⋯ menu → Not interested → the post disappears; Undo brings it back
- [ ] **Chat:** Applications → Message brand → send a message

## Brand

- [ ] **Create profile:** finish the 6 onboarding steps → home shows "Pending review"
- [ ] **Edit profile:** Profile → Edit profile → change the description → Save
- [ ] **Create job:** Hire a creator → fill the form → Publish → appears under Opportunities
- [ ] Trying to publish an empty form shows validation messages
- [ ] **Edit job:** ⋯ → Edit → change the title → Save → the title updates
- [ ] **Close job:** ⋯ → Close applications → shows "Closed", and creators can no longer apply
- [ ] **Delete job:** ⋯ → Delete → confirm → it disappears
- [ ] **View applications:** Opportunities → Applicants → the creator's application is under "New"
- [ ] **Shortlist creator:** Move to… → Shortlist → it moves to the "Shortlisted" tab
- [ ] **Discover creators:** Discover → creators listed with a "% match" badge
- [ ] **Filter creators:** Filters → Creator type / Niche / Location → the list narrows
- [ ] **Save a creator:** bookmark icon → appears under Home → Saved creators
- [ ] **Invite:** open a creator → Invite → pick an opportunity → the creator receives a message
- [ ] **Chat:** Messages → open the conversation → reply
- [ ] **Promote:** ⋯ → Promote → Request promotion → status shows "Requested" (no payment is taken)

## Admin

Make an account admin first: Firebase Console → Firestore → `users` → that user's document → change `role` to `admin`.

- [ ] Signing in as that user opens the Admin area (not the creator/brand app)
- [ ] **View users:** Users tab lists creators and brands
- [ ] **Suspend a user:** ⋮ → Suspend → that user sees "This account has been suspended"
- [ ] **Verify brand:** Dashboard → Brands waiting for verification → Verify → the brand shows the verified tick
- [ ] **Reject brand:** Reject with a reason → the brand sees the reason on its Verification screen
- [ ] **View posts:** Content tab lists hiring posts and creator posts; Remove deletes one
- [ ] **View reports:** report something from a normal account → it appears under Content → Reports → Resolve
- [ ] **View promotions:** Payments tab shows the promotion request → Approve manually → the post shows "Promoted"
- [ ] **Payments:** the Payments list is empty and explains why
- [ ] **Sample data:** Settings → Sample data → Add → sample brands and creators appear, all labelled "Sample"

## Theme

- [ ] **Light:** Settings → Theme → Light
- [ ] **Dark:** Settings → Theme → Dark → colours change immediately, and you stay on the same screen
- [ ] **System:** follows the phone's setting
- [ ] **Persistence:** choose Dark, close the app completely, reopen → still Dark

## Currency

- [ ] Settings → Currency → USD → prices show as "≈ USD …"
- [ ] Switch back to NPR → prices show as "NPR …" without "≈"

## Firebase

- [ ] **Real-time jobs:** with the creator on Discover, publish a job as the brand on another device → it appears without refreshing
- [ ] **Real-time applications:** shortlist as the brand → the creator's Applications tab updates by itself
- [ ] **Real-time chat:** send a message from one device → it appears on the other within a second; the unread badge shows on the Messages tab
- [ ] **Real-time notifications:** the bell on Home shows a dot after the other side acts
- [ ] **Security rules deployed:** Firebase Console → Firestore → Rules shows the contents of `firestore.rules` (not the default test rules)
- [ ] In Firebase Console → Firestore → Data, check that a creator's profile document ID equals their UID in Authentication

## Layout

Check there is no yellow-and-black "overflow" stripe and no clipped text on:

- [ ] A small phone (360 × 800)
- [ ] A normal phone (390 × 844)
- [ ] A large phone (412 × 915)
- [ ] A tablet, or the Chrome window made wide (content stays in a centred column)
- [ ] Large text: phone Settings → Display → Font size → largest
