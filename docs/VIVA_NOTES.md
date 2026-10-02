# CreBa Connect — Viva Notes

Plain-language answers to the questions you are most likely to be asked.
Each answer says **where in the code** to point, so you can open the file and show it.

---

## The basics

### What is Flutter?
Flutter is Google's toolkit for building apps. You write the app once in the **Dart** language and it runs on Android, iPhone and the web. Everything on screen is a **widget** (a button, a text, a whole screen), and widgets are nested inside each other like boxes.

### What is Firebase?
Firebase is a set of ready-made backend services from Google. Instead of building and hosting our own server, the app talks directly to Firebase. CreBa Connect uses two of them:

- **Firebase Authentication** — accounts and passwords
- **Cloud Firestore** — the database

### What is Firebase Authentication?
It handles sign up, sign in and sign out. It stores the password safely (we never see or store it) and remembers the signed-in user on the phone, so the user is still signed in after closing the app.

*Show:* `lib/services/auth_service.dart`

### What is Firestore?
A cloud database. Data is stored as **documents** (like a form with named fields) grouped into **collections** (like folders). Example: the collection `hiringPosts` contains one document per job post.

It is **real-time**: when data changes, every phone that is listening is told immediately.

### What is a UID?
The **U**ser **ID**: a unique code Firebase gives every account, for example `k3Jd92...`. It never changes.

### Why is the UID used?
To tie data to its owner. Examples:

- A creator's profile is stored at `creatorProfiles/{uid}` — the document's name *is* the UID.
- Every hiring post has a `brandId` field holding the UID of the brand that created it.
- Every application has `creatorId` and `brandId`.

The security rules compare these to the UID of the person making the request. That is how "you can only edit your own data" is enforced.

---

## State management

### What is Provider?
Provider is a state-management package. **State** means "the data the app is holding right now" (who is signed in, the list of posts, the chosen theme). A provider is a class that holds some state and tells the screens to rebuild when it changes.

### What is the role of a provider?
Three jobs:

1. Hold the data (for example, the list of hiring posts).
2. Offer actions (for example, `createPost`, `deletePost`).
3. Call `notifyListeners()` so the screens redraw.

*Show:* `lib/providers/hiring_post_provider.dart`

### Why Provider (and not BLoC or Riverpod)?
It is the simplest of the three, it is recommended by the Flutter team for small and medium apps, and it was required by the assignment. It keeps logic out of the screens without a lot of extra code.

### How do the layers fit together?

```
Screen (widget)   shows data, reacts to taps      lib/screens, lib/widgets
     ↓ calls
Provider          holds state, loading and errors lib/providers
     ↓ calls
Service           the only code that talks to Firebase   lib/services
     ↓
Firebase
```

### Why are Firebase calls separated into services?
- **Screens stay simple.** A screen only says "create this post"; it does not know how.
- **One place to change.** If the database changed, only the service files would need editing.
- **Easier to test and to explain.** Each file has one job.

You can prove it: search the `lib/screens` and `lib/widgets` folders for the word `FirebaseFirestore`. There are no results.

---

## CRUD

### What is CRUD?
The four basic things you can do with data: **C**reate, **R**ead, **U**pdate, **D**elete.

### Where is CRUD in CreBa Connect?
The clearest example is **hiring posts**, because one collection shows all four:

| Operation | What the user does | Code |
|---|---|---|
| Create | Brand taps "Hire a creator" and publishes | `HiringPostService.createPost` |
| Read | Creator's Discover feed, updating live | `HiringPostService.watchLatest` |
| Update | Brand edits or closes the post | `HiringPostService.updatePost`, `setStatus` |
| Delete | Brand deletes the post | `HiringPostService.deletePost` |

Every one of these is tied to the brand's UID through the `brandId` field.

Other CRUD in the app:

- **Create:** profile (onboarding), availability post, application, chat message, saved item, report
- **Read:** profiles, applications, notifications, chat
- **Update:** edit profile, application status (shortlist/select/reject), pause an availability post
- **Delete:** availability post, saved item, notification

---

## Real-time

### What is a Stream?
A stream is a pipe that delivers data **over time**. A normal request gives one answer; a stream keeps giving new answers whenever the data changes.

Firestore gives us streams with `.snapshots()`. The provider listens to the stream and redraws the screen each time.

### How does real-time chat work?
1. When a chat opens, `ChatProvider` starts listening to that conversation's messages (`ChatService.watchMessages`).
2. Sending a message saves a new document in `conversations/{id}/messages`.
3. Firestore immediately pushes the new message to **both** phones through the stream. Nobody presses refresh.
4. The conversation document also stores the last message and an unread counter for each person, which is what the Messages list and the badge on the tab show.
5. When the receiver opens the chat, their messages are marked `read: true`, and the sender's tick changes.

The conversation's ID is the two UIDs sorted and joined (`uidA_uidB`), so both people always land in the same conversation.

*Show:* `lib/services/chat_service.dart`, `lib/providers/chat_provider.dart`

---

## Theme

### How does Light/Dark mode work?
- `lib/theme/app_theme.dart` defines two custom themes: `AppTheme.lightTheme` and `AppTheme.darkTheme`. Both are built from a colour palette in `app_palette.dart`.
- `ThemeProvider` holds the current choice: Light, Dark or System.
- `MaterialApp` is given both themes and the current choice. When the choice changes, Flutter repaints with the other colours.
- The choice is saved on the phone with `shared_preferences`, so it is still there after restarting the app.

### Does switching theme reset the app?
No. Only the colours change. The screens are not rebuilt from scratch, so whatever the user typed or scrolled to stays as it was. (`_ThemedApp` in `lib/app.dart` watches only the theme mode.)

---

## Security

### What are Firestore Security Rules?
Rules that run **on Google's servers** and decide whether each read or write is allowed. They are the real protection: even if someone modified the app, the server would still refuse.

They are in `firestore.rules`. Some examples in plain words:

- Not signed in → no access to anything.
- You can edit only the profile whose ID is your own UID.
- You cannot change your own `role`, so you cannot make yourself admin.
- A brand cannot mark itself verified; only an admin can.
- Only the brand that owns a post can edit or delete it.
- Only the two people in a conversation can read its messages.
- A promotion can only be *requested* by a user; only an admin can activate it.

There is no `allow read, write: if true` anywhere.

### How does the application protect user data?
- **Passwords** are handled only by Firebase Authentication. They are never stored in Firestore.
- **Security rules** enforce ownership using the UID (above).
- **Private data is kept separate.** A brand's PAN number is in a private sub-document that only the brand and admins can read. Email and phone are in `users/{uid}`, readable only by the owner and admins.
- **No payment details** are collected.
- **Errors shown to users are friendly messages**, never raw technical errors.

### How were the rules checked?
`rules-test/rules.test.mjs` signs in as pretend users and tries things that should be refused (editing someone else's profile, making yourself admin, reading someone else's chat). The tests pass only if the rules refuse them.

---

## Admin

### How does the admin role work?
- Registration only offers **Creator** or **Brand**. There is no "register as admin".
- To make an admin, you open the Firebase Console, find the person's document in the `users` collection and change `role` to `admin` by hand.
- When that person opens the app, `AuthGate` reads their role and shows the admin area.
- The security rules check the same `role` field on the server for every admin action, so hiding the admin screens is not the only protection.

### What can the admin do?
See users, suspend accounts, verify or reject brands, remove posts, handle reports, approve promotion requests, set plans, edit category lists, and add or remove sample data.

### Is the PAN really verified?
No, and the app does not claim it is. "Business Verified" means an admin of this app reviewed the details. It is an in-app workflow, not a government check.

---

## The "smart" features

### How does Best Fit work?
It is a point system out of 100 (`lib/utils/match_scorer.dart`):

| What matches | Points |
|---|---|
| Creator type (e.g. Model) | 25 |
| Niche (e.g. Fashion) — partial credit if only some match | 30 |
| Same city, or the job is remote | 15 |
| Creator is marked available | 15 |
| Creator's rate fits the budget | 15 |

Add them up and that is the match percentage. The app labels it "Based on your requirements".

### Why did we not use AI?
- The assignment is about Flutter, Firebase and Provider, not machine learning.
- A rule-based score is **explainable**: we can say exactly why someone scored 85%.
- It needs no extra service, cost or training data.
- It would be dishonest to call a simple formula "AI", so we do not.

### How do Trending and Rising creators work?
Also a simple score (`lib/utils/trending_scorer.dart`): profile views + saves × 3 + a bonus for a complete profile, recent activity, being available, and an active boost. "Rising" is the same score but only for profiles created in the last 30 days.

---

## Money

### How does NPR / USD work?
Prices are stored in the currency they were entered in (NPR by default). The user picks a display currency in Settings. If it differs, the app converts using **one fixed rate** set in `lib/utils/app_config.dart` and marks the result with "≈" so nobody mistakes it for an exact price. There is no live exchange-rate service.

### How could Stripe be integrated?
It is **not implemented**. The plan:

```
Flutter app  →  Cloud Function (our secure backend)  →  Stripe
                                                          ↓
Firestore    ←  Cloud Function  ←  Stripe confirms the payment
```

1. The app asks our backend to start a payment.
2. The backend, which holds the Stripe **secret key**, creates the payment with Stripe.
3. The user pays on Stripe's secure page.
4. Stripe tells our backend the result.
5. The backend writes the payment and activates the promotion in Firestore.

The secret key must never be inside the Flutter app, because anything inside an app can be extracted. That is why a backend is required.

Today, choosing a promotion only saves a **request**. The app never shows a payment as successful, and the security rules stop a user from activating their own promotion.

*Show:* `lib/services/payment_service.dart`

---

## Honest limitations (say these before you are asked)

- Online payment (Stripe) is not implemented; promotions are requests approved by hand.
- PAN verification is a manual in-app review, not a government check.
- Images are added by pasting a link; uploading from the phone gallery is not implemented (it needs Firebase Storage, which requires a billing account).
- Notifications are in-app only; there are no push notifications.
- Search filters a limited list on the phone, because Firestore has no full-text search.
- Notifications are written by the app of the person who caused them; a production app would create them from a backend.
