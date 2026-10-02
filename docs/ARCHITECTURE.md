# CreBa Connect — Architecture and Feature Status

This document records how the app is built and, honestly, what is and is not implemented.
For setup and the assignment mapping see the [README](../README.md).

---

## 1. Layers

```
SCREENS / WIDGETS   what the user sees. No Firebase code here.
        │  reads state, calls methods
PROVIDERS           hold app state, loading and error flags, notify the UI
        │  call
SERVICES            the only place that talks to Firebase
        │  read / write
FIREBASE            Authentication · Cloud Firestore

MODELS              typed data classes (fromJson / toJson) used by every layer
UTILS               pure logic: validators, formatting, Best Fit, trending
```

- **State management:** Provider (`ChangeNotifier`, `MultiProvider`, `ChangeNotifierProxyProvider`).
- **Navigation:** Flutter's `Navigator` plus one `AuthGate` that decides which area of the app is shown.
- **Real-time data:** services return Firestore streams; providers listen and call `notifyListeners()`.
- **Errors:** `utils/app_exception.dart` turns any Firebase error into a friendly sentence. Provider actions return `null` on success or that sentence on failure, so a screen only has to show it.

### How a provider follows the signed-in user

```
AuthProvider  ──uid──►  UserProvider  ──account record──►  every data provider
(authStateChanges)      (users/{uid})                      (extends SessionProvider)
```

`SessionProvider.bind()` is called whenever the account changes. It cancels the old user's Firestore listeners, clears the old data, and starts listening for the new user. This is why signing out and in as someone else never shows leftover data.

---

## 2. Feature status

**Implemented** means built, working, and covered by the end-to-end test or the manual checklist.

| Feature | Status | Notes |
|---|---|---|
| Sign up, sign in, sign out, persistent session | Implemented | |
| Password reset email | Implemented | uses Firebase's built-in email |
| Role choice at sign-up (creator / brand) | Implemented | admin cannot be chosen |
| Creator onboarding (5 steps) | Implemented | |
| Brand onboarding (6 steps, PAN) | Implemented | |
| Creator profile: create, view, edit | Implemented | |
| Brand profile: create, view, edit | Implemented | |
| Hiring posts: create, live feed, edit, close, delete | Implemented | |
| Availability posts: create, edit, pause, delete | Implemented | |
| Applications and stages | Implemented | apply, withdraw, re-apply, brand moves stages |
| Search and filters (creators, opportunities) | Implemented | filtering happens on the device |
| Best Fit match score | Implemented | rule-based; see `utils/match_scorer.dart` |
| Trending / Rising / Popular / Recently active | Implemented | rule-based; see `utils/trending_scorer.dart` |
| Favourites (creators, opportunities, brands) | Implemented | |
| Real-time chat, unread counts, read ticks | Implemented | text only |
| In-app notifications | Implemented | written by the acting user's app |
| Creator and brand dashboards | Implemented | simple counts |
| Light / Dark / System theme, persisted | Implemented | |
| NPR / USD display | Implemented | fixed rate, converted values marked "≈" |
| Settings, Privacy, Help, About | Implemented | |
| Reporting profiles and posts | Implemented | |
| Admin: users, suspend, plans | Implemented | |
| Admin: brand verification | Implemented | manual in-app review |
| Admin: content removal, reports | Implemented | |
| Admin: category editor, counts, action log | Implemented | log is written; there is no screen to read it |
| Sample data tool | Implemented | everything labelled "Sample" |
| Firestore security rules | Implemented | 56 automated allow / deny tests |
| Promotion requests (Promote post, Boost profile) | **Partial** | saves a request; admin approves by hand; **no payment** |
| Subscription plans | **Partial** | plan stored in Firestore and set by an admin; **no billing** |
| Images (profile photo, logo, post image) | **Partial** | by pasting a link only; no upload |
| "Not interested" | **Partial** | hides for the current session only |
| Stripe payments | **Not implemented** | architecture documented in the README |
| Firebase Storage uploads | **Not implemented** | needs the Blaze plan |
| Push notifications | **Not implemented** | |
| Meta / Instagram / TikTok integration | **Not implemented** | social links are plain links |
| Reviews, contracts, advanced analytics | **Not implemented** | future work |

---

## 3. User flows

**Creator** — register → onboarding → Home (dashboard, Best Fit, trending brands) → Discover (search, filter) → open an opportunity → Apply or Save → Applications (track stages, withdraw) → Messages (chat with the brand) → availability posts → Profile (edit, boost).

Tabs: Home · Discover · Applications · Messages · Profile

**Brand** — register → onboarding with PAN → "Pending review" → Hire a creator → Discover (creators, availability posts, Best Fit) → open a creator → Message, Invite or Save → Opportunities (edit, close, promote, delete) → Applicants (shortlist, select, reject) → Messages.

Tabs: Home · Discover · Opportunities · Messages · Profile

**Admin** — a normal account whose `role` was changed to `admin` in the Firebase Console → Dashboard (queues and counts) → verification → Users → Content and reports → Payments (promotion requests) → Settings (categories, sample data).

Tabs: Dashboard · Users · Content · Payments · Settings

---

## 4. Best Fit scoring

| What matches | Points |
|---|---|
| Creator type | 25 |
| Niche (partial credit when only some match) | 30 |
| Same city, or the job is remote | 15 |
| Creator is available | 15 |
| Creator's rate fits the budget (half credit up to 25% over) | 15 |

For a brand browsing without a specific post, the brand's business category stands in for the niches (see `AppConstants.categoryToNiches`), there is no budget to compare, and the remaining weights are scaled to 100.

This is a fixed formula, not artificial intelligence, and the app labels it "Based on your requirements".

## 5. Trending score

`views × 1 + saves × 3 + completeness ÷ 5 + 15 if updated this week + 10 if available + 25 if boosted`

"Rising" applies the same score to profiles created in the last 30 days.

---

## 6. Design system

- **Typography:** Instrument Serif for a few large headings (names, titles), Inter for everything else. Numbers are always set in Inter because its digits are clearer.
- **Colour:** off-white surfaces and ink-black primary buttons in light mode; charcoal surfaces and off-white primary buttons in dark mode. One accent colour (terracotta) used sparingly for the match score, promoted items and unread badges.
- **Surfaces:** flat cards with a hairline border, no drop shadows.
- **Glass:** used only for the bottom navigation and the sticky action bar on a job, where content scrolls underneath.
- **Tokens:** all colours come from `AppPalette` (`context.palette`); spacing and corner radii from `AppSpacing`. No screen hard-codes a colour.
- **Responsive:** content is held to a 640 px column (`ContentWidth`), so phone layouts stay comfortable on tablets; stat grids reflow with `ResponsiveGrid`.

---

## 7. Testing layers

| Layer | File | What it proves |
|---|---|---|
| Logic | `test/logic_test.dart` | scoring, money, validators, filters, model helpers |
| Security rules | `rules-test/rules.test.mjs` | what each role can and cannot read or write |
| End-to-end | `integration_test/app_test.dart` | a brand → creator → admin journey through the real UI on the Firebase emulators |
| Manual | `docs/TESTING_CHECKLIST.md` | real-time behaviour across two devices, layout on different screens |
