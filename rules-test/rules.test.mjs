// Security rules tests.
//
// Each test signs in as a pretend user and tries one read or write. The
// rules must allow what the app needs and refuse everything else.
//
// How to run (the Firestore emulator must be running on port 8080):
//   cd rules-test
//   npm install
//   npm test

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  setLogLevel,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

// Many tests expect to be refused. Without this, every refusal prints a
// "PERMISSION_DENIED" line, which makes a passing run look like a failure.
setLogLevel('silent');

const CREATOR = 'creator1';
const OTHER_CREATOR = 'creator2';
const BRAND = 'brand1';
const OTHER_BRAND = 'brand2';
const ADMIN = 'admin1';

let env;

/** Firestore as seen by a signed-in user. */
const as = (uid) => env.authenticatedContext(uid).firestore();
/** Firestore as seen by someone who is not signed in. */
const anonymous = () => env.unauthenticatedContext().firestore();

/** Writes starting data while ignoring the rules. */
async function seed(write) {
  await env.withSecurityRulesDisabled((context) => write(context.firestore()));
}

const userRecord = (role) => ({ role, isActive: true, onboardingComplete: true, email: `${role}@x.test` });

const creatorProfile = (uid) => ({
  uid,
  fullName: 'Test Creator',
  city: 'Kathmandu',
  viewCount: 0,
  saveCount: 0,
  isDemo: false,
});

const brandProfile = (uid, status = 'pending') => ({
  uid,
  brandName: 'Test Brand',
  verificationStatus: status,
  viewCount: 0,
  saveCount: 0,
  isDemo: false,
});

const hiringPost = (brandId, brandVerified = false) => ({
  brandId,
  brandName: 'Test Brand',
  brandVerified,
  title: 'Model needed',
  status: 'open',
  viewCount: 0,
  applicationCount: 0,
  isDemo: false,
});

const application = (jobId, creatorId, brandId, status = 'applied') => ({
  jobId,
  creatorId,
  brandId,
  status,
  message: 'Hello',
  proposedRate: 5000,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-creba-connect-rules',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed(async (db) => {
    await setDoc(doc(db, 'users', CREATOR), userRecord('creator'));
    await setDoc(doc(db, 'users', OTHER_CREATOR), userRecord('creator'));
    await setDoc(doc(db, 'users', BRAND), userRecord('brand'));
    await setDoc(doc(db, 'users', OTHER_BRAND), userRecord('brand'));
    await setDoc(doc(db, 'users', ADMIN), userRecord('admin'));
    await setDoc(doc(db, 'creatorProfiles', CREATOR), creatorProfile(CREATOR));
    await setDoc(doc(db, 'creatorProfiles', OTHER_CREATOR), creatorProfile(OTHER_CREATOR));
    await setDoc(doc(db, 'brandProfiles', BRAND), brandProfile(BRAND));
    await setDoc(doc(db, 'brandProfiles', OTHER_BRAND), brandProfile(OTHER_BRAND));
    await setDoc(doc(db, 'brandProfiles', BRAND, 'private', 'verification'), { panNumber: '123456789' });
    await setDoc(doc(db, 'hiringPosts', 'job1'), hiringPost(BRAND));
  });
});

describe('signed-out users', () => {
  test('cannot read anything', async () => {
    await assertFails(getDoc(doc(anonymous(), 'creatorProfiles', CREATOR)));
    await assertFails(getDocs(collection(anonymous(), 'hiringPosts')));
    await assertFails(getDoc(doc(anonymous(), 'users', CREATOR)));
  });

  test('cannot write anything', async () => {
    await assertFails(setDoc(doc(anonymous(), 'hiringPosts', 'x'), hiringPost(BRAND)));
  });
});

describe('users (account records)', () => {
  test('a new user can register as creator or brand', async () => {
    await assertSucceeds(setDoc(doc(as('new1'), 'users', 'new1'), userRecord('creator')));
    await assertSucceeds(setDoc(doc(as('new2'), 'users', 'new2'), userRecord('brand')));
  });

  test('nobody can register as admin', async () => {
    await assertFails(setDoc(doc(as('new3'), 'users', 'new3'), userRecord('admin')));
  });

  test('a user cannot make themselves admin later', async () => {
    await assertFails(updateDoc(doc(as(CREATOR), 'users', CREATOR), { role: 'admin' }));
  });

  test('a suspended user cannot un-suspend themselves', async () => {
    await seed((db) => updateDoc(doc(db, 'users', CREATOR), { isActive: false }));
    await assertFails(updateDoc(doc(as(CREATOR), 'users', CREATOR), { isActive: true }));
  });

  test('a user can read and edit their own record but not another one', async () => {
    await assertSucceeds(getDoc(doc(as(CREATOR), 'users', CREATOR)));
    await assertSucceeds(updateDoc(doc(as(CREATOR), 'users', CREATOR), { city: 'Pokhara' }));
    await assertFails(getDoc(doc(as(CREATOR), 'users', BRAND)));
    await assertFails(updateDoc(doc(as(CREATOR), 'users', BRAND), { city: 'Pokhara' }));
  });

  test('an admin can read and suspend any user', async () => {
    await assertSucceeds(getDoc(doc(as(ADMIN), 'users', CREATOR)));
    await assertSucceeds(updateDoc(doc(as(ADMIN), 'users', CREATOR), { isActive: false }));
  });
});

describe('creator profiles', () => {
  test('a creator can edit their own profile', async () => {
    await assertSucceeds(updateDoc(doc(as(CREATOR), 'creatorProfiles', CREATOR), { bio: 'New bio' }));
  });

  test("a creator cannot edit another creator's profile", async () => {
    await assertFails(updateDoc(doc(as(CREATOR), 'creatorProfiles', OTHER_CREATOR), { bio: 'Hacked' }));
  });

  test('a creator cannot inflate their own counters or boost themselves', async () => {
    await assertFails(updateDoc(doc(as(CREATOR), 'creatorProfiles', CREATOR), { viewCount: 9999 }));
    await assertFails(updateDoc(doc(as(CREATOR), 'creatorProfiles', CREATOR), { boostedUntil: new Date() }));
  });

  test('a visitor may add exactly one view, and nothing else', async () => {
    const profile = doc(as(BRAND), 'creatorProfiles', CREATOR);
    await assertSucceeds(updateDoc(profile, { viewCount: 1 }));
    await assertFails(updateDoc(profile, { viewCount: 50 }));
    await assertFails(updateDoc(profile, { viewCount: 2, bio: 'Hacked' }));
  });

  test('a brand cannot create a creator profile', async () => {
    await assertFails(setDoc(doc(as(BRAND), 'creatorProfiles', BRAND), creatorProfile(BRAND)));
  });
});

describe('brand profiles and verification', () => {
  test('a brand cannot verify itself', async () => {
    await assertFails(updateDoc(doc(as(BRAND), 'brandProfiles', BRAND), { verificationStatus: 'verified' }));
  });

  test('a brand cannot be created already verified', async () => {
    await seed((db) => setDoc(doc(db, 'users', 'brand3'), userRecord('brand')));
    await assertFails(setDoc(doc(as('brand3'), 'brandProfiles', 'brand3'), brandProfile('brand3', 'verified')));
    await assertSucceeds(setDoc(doc(as('brand3'), 'brandProfiles', 'brand3'), brandProfile('brand3', 'pending')));
  });

  test('an admin can verify a brand', async () => {
    await assertSucceeds(updateDoc(doc(as(ADMIN), 'brandProfiles', BRAND), { verificationStatus: 'verified' }));
  });

  test('the PAN is private to the brand and admins', async () => {
    const pan = (uid) => doc(as(uid), 'brandProfiles', BRAND, 'private', 'verification');
    await assertSucceeds(getDoc(pan(BRAND)));
    await assertSucceeds(getDoc(pan(ADMIN)));
    await assertFails(getDoc(pan(CREATOR)));
    await assertFails(getDoc(pan(OTHER_BRAND)));
  });
});

describe('hiring posts', () => {
  test('a brand can create, edit and delete its own post', async () => {
    const post = doc(as(BRAND), 'hiringPosts', 'job2');
    await assertSucceeds(setDoc(post, hiringPost(BRAND)));
    await assertSucceeds(updateDoc(post, { title: 'Edited' }));
    await assertSucceeds(deleteDoc(post));
  });

  test("a brand cannot edit or delete another brand's post", async () => {
    const post = doc(as(OTHER_BRAND), 'hiringPosts', 'job1');
    await assertFails(updateDoc(post, { title: 'Hacked' }));
    await assertFails(deleteDoc(post));
  });

  test('a brand cannot post under another brand\'s ID', async () => {
    await assertFails(setDoc(doc(as(OTHER_BRAND), 'hiringPosts', 'job3'), hiringPost(BRAND)));
  });

  test('a creator cannot create a hiring post', async () => {
    await assertFails(setDoc(doc(as(CREATOR), 'hiringPosts', 'job4'), hiringPost(CREATOR)));
  });

  test('an unverified brand cannot show a verified badge on its post', async () => {
    await assertFails(setDoc(doc(as(BRAND), 'hiringPosts', 'job5'), hiringPost(BRAND, true)));
  });

  test('a brand cannot promote its own post', async () => {
    await assertFails(updateDoc(doc(as(BRAND), 'hiringPosts', 'job1'), { promotedUntil: new Date() }));
  });

  test('any signed-in user can read posts', async () => {
    await assertSucceeds(getDocs(collection(as(CREATOR), 'hiringPosts')));
  });
});

describe('applications', () => {
  const id = `job1_${CREATOR}`;

  test('a creator can apply as themselves', async () => {
    const db = as(CREATOR);
    const batch = writeBatch(db);
    batch.set(doc(db, 'applications', id), application('job1', CREATOR, BRAND));
    batch.update(doc(db, 'hiringPosts', 'job1'), { applicationCount: 1 });
    await assertSucceeds(batch.commit());
  });

  test('a creator cannot apply in someone else\'s name', async () => {
    await assertFails(
      setDoc(doc(as(CREATOR), 'applications', `job1_${OTHER_CREATOR}`), application('job1', OTHER_CREATOR, BRAND)),
    );
  });

  test('an application cannot start in an advanced stage', async () => {
    await assertFails(setDoc(doc(as(CREATOR), 'applications', id), application('job1', CREATOR, BRAND, 'selected')));
  });

  test('an application must point at the real owner of the job', async () => {
    await assertFails(setDoc(doc(as(CREATOR), 'applications', id), application('job1', CREATOR, OTHER_BRAND)));
  });

  test('a brand cannot apply', async () => {
    await assertFails(
      setDoc(doc(as(OTHER_BRAND), 'applications', `job1_${OTHER_BRAND}`), application('job1', OTHER_BRAND, BRAND)),
    );
  });

  describe('once an application exists', () => {
    beforeEach(() => seed((db) => setDoc(doc(db, 'applications', id), application('job1', CREATOR, BRAND))));

    test('only the creator, the brand and admins can read it', async () => {
      await assertSucceeds(getDoc(doc(as(CREATOR), 'applications', id)));
      await assertSucceeds(getDoc(doc(as(BRAND), 'applications', id)));
      await assertSucceeds(getDoc(doc(as(ADMIN), 'applications', id)));
      await assertFails(getDoc(doc(as(OTHER_CREATOR), 'applications', id)));
      await assertFails(getDoc(doc(as(OTHER_BRAND), 'applications', id)));
    });

    test('each side can list its own applications', async () => {
      await assertSucceeds(getDocs(query(collection(as(CREATOR), 'applications'), where('creatorId', '==', CREATOR))));
      await assertSucceeds(getDocs(query(collection(as(BRAND), 'applications'), where('brandId', '==', BRAND))));
      await assertFails(getDocs(query(collection(as(OTHER_BRAND), 'applications'), where('brandId', '==', BRAND))));
    });

    test('the brand can shortlist; another brand cannot', async () => {
      await assertSucceeds(updateDoc(doc(as(BRAND), 'applications', id), { status: 'shortlisted' }));
      await assertFails(updateDoc(doc(as(OTHER_BRAND), 'applications', id), { status: 'rejected' }));
    });

    test('the creator cannot select themselves', async () => {
      await assertFails(updateDoc(doc(as(CREATOR), 'applications', id), { status: 'selected' }));
    });

    test('the creator can withdraw and then re-apply', async () => {
      await assertSucceeds(updateDoc(doc(as(CREATOR), 'applications', id), { status: 'withdrawn' }));
      await assertSucceeds(updateDoc(doc(as(CREATOR), 'applications', id), { status: 'applied', message: 'Again' }));
    });

    test('the creator cannot undo a rejection', async () => {
      await seed((db) => updateDoc(doc(db, 'applications', id), { status: 'rejected' }));
      await assertFails(updateDoc(doc(as(CREATOR), 'applications', id), { status: 'applied' }));
    });
  });
});

describe('availability posts', () => {
  const post = (creatorId) => ({ creatorId, creatorName: 'Test', title: 'Available', isActive: true });

  test('a creator can create, edit and delete their own post', async () => {
    const ref = doc(as(CREATOR), 'creatorAvailabilityPosts', 'a1');
    await assertSucceeds(setDoc(ref, post(CREATOR)));
    await assertSucceeds(updateDoc(ref, { isActive: false }));
    await assertSucceeds(deleteDoc(ref));
  });

  test("a creator cannot touch another creator's post", async () => {
    await seed((db) => setDoc(doc(db, 'creatorAvailabilityPosts', 'a2'), post(OTHER_CREATOR)));
    await assertFails(updateDoc(doc(as(CREATOR), 'creatorAvailabilityPosts', 'a2'), { title: 'Hacked' }));
    await assertFails(deleteDoc(doc(as(CREATOR), 'creatorAvailabilityPosts', 'a2')));
  });

  test('a brand cannot create one', async () => {
    await assertFails(setDoc(doc(as(BRAND), 'creatorAvailabilityPosts', 'a3'), post(BRAND)));
  });
});

describe('chat', () => {
  const conversationId = [BRAND, CREATOR].sort().join('_');
  const participants = [BRAND, CREATOR].sort();
  const message = (senderId, receiverId) => ({ senderId, receiverId, text: 'Hi', read: false });

  function send(uid, receiverId) {
    const db = as(uid);
    const batch = writeBatch(db);
    batch.set(doc(db, 'conversations', conversationId), { participants, lastMessage: 'Hi' }, { merge: true });
    batch.set(doc(collection(db, 'conversations', conversationId, 'messages')), message(uid, receiverId));
    return batch.commit();
  }

  test('a participant can start a conversation and send the first message together', async () => {
    await assertSucceeds(send(CREATOR, BRAND));
    await assertSucceeds(send(BRAND, CREATOR));
  });

  test('an outsider cannot create a conversation for two other people', async () => {
    await assertFails(setDoc(doc(as(OTHER_BRAND), 'conversations', conversationId), { participants }));
  });

  test('a conversation ID must match its participants', async () => {
    await assertFails(setDoc(doc(as(CREATOR), 'conversations', 'made_up_id'), { participants }));
  });

  describe('once a conversation exists', () => {
    beforeEach(() =>
      seed(async (db) => {
        await setDoc(doc(db, 'conversations', conversationId), { participants, lastMessage: 'Hi' });
        await setDoc(doc(db, 'conversations', conversationId, 'messages', 'm1'), message(CREATOR, BRAND));
      }),
    );

    test('participants can read it; outsiders cannot', async () => {
      const messages = (uid) => getDocs(collection(as(uid), 'conversations', conversationId, 'messages'));
      await assertSucceeds(messages(CREATOR));
      await assertSucceeds(messages(BRAND));
      await assertFails(messages(OTHER_CREATOR));
      await assertFails(getDoc(doc(as(OTHER_CREATOR), 'conversations', conversationId)));
    });

    test('an outsider cannot post into it', async () => {
      await assertFails(
        setDoc(doc(as(OTHER_CREATOR), 'conversations', conversationId, 'messages', 'm2'), message(OTHER_CREATOR, BRAND)),
      );
    });

    test('nobody can send a message in another person\'s name', async () => {
      await assertFails(
        setDoc(doc(as(BRAND), 'conversations', conversationId, 'messages', 'm3'), message(CREATOR, BRAND)),
      );
    });

    test('only the receiver can mark a message read, and cannot rewrite it', async () => {
      const m1 = (uid) => doc(as(uid), 'conversations', conversationId, 'messages', 'm1');
      await assertSucceeds(updateDoc(m1(BRAND), { read: true }));
      await assertFails(updateDoc(m1(CREATOR), { read: true }));
      await assertFails(updateDoc(m1(BRAND), { text: 'Changed' }));
    });
  });
});

describe('notifications, favourites, reports', () => {
  test('notifications are private to their recipient', async () => {
    await seed((db) => setDoc(doc(db, 'notifications', 'n1'), { recipientId: CREATOR, senderId: BRAND, read: false }));
    await assertSucceeds(getDoc(doc(as(CREATOR), 'notifications', 'n1')));
    await assertFails(getDoc(doc(as(OTHER_CREATOR), 'notifications', 'n1')));
    await assertSucceeds(updateDoc(doc(as(CREATOR), 'notifications', 'n1'), { read: true }));
    await assertFails(deleteDoc(doc(as(BRAND), 'notifications', 'n1')));
  });

  test('a notification cannot be sent in someone else\'s name', async () => {
    await assertFails(setDoc(doc(as(BRAND), 'notifications', 'n2'), { recipientId: CREATOR, senderId: OTHER_BRAND }));
    await assertSucceeds(setDoc(doc(as(BRAND), 'notifications', 'n3'), { recipientId: CREATOR, senderId: BRAND }));
  });

  test('saved items belong to the user who saved them', async () => {
    const favorite = { userId: BRAND, targetId: CREATOR, targetType: 'creator' };
    await assertSucceeds(setDoc(doc(as(BRAND), 'favorites', `${BRAND}_${CREATOR}`), favorite));
    await assertFails(getDoc(doc(as(OTHER_BRAND), 'favorites', `${BRAND}_${CREATOR}`)));
    await assertFails(setDoc(doc(as(OTHER_BRAND), 'favorites', `${BRAND}_x`), { ...favorite, targetId: 'x' }));
    await assertSucceeds(deleteDoc(doc(as(BRAND), 'favorites', `${BRAND}_${CREATOR}`)));
  });

  test('anyone can file a report; only admins can read them', async () => {
    const report = { reporterId: CREATOR, targetId: 'job1', targetType: 'hiringPost', reason: 'Spam', status: 'open' };
    await assertSucceeds(setDoc(doc(as(CREATOR), 'reports', 'r1'), report));
    await assertFails(getDoc(doc(as(CREATOR), 'reports', 'r1')));
    await assertSucceeds(getDoc(doc(as(ADMIN), 'reports', 'r1')));
    await assertSucceeds(updateDoc(doc(as(ADMIN), 'reports', 'r1'), { status: 'resolved' }));
  });
});

describe('promotions, subscriptions, payments', () => {
  const promotion = (status) => ({ ownerId: BRAND, targetId: 'job1', targetType: 'hiringPost', status });

  test('a user can request a promotion but cannot create an active one', async () => {
    await assertSucceeds(setDoc(doc(as(BRAND), 'promotions', 'p1'), promotion('requested')));
    await assertFails(setDoc(doc(as(BRAND), 'promotions', 'p2'), promotion('active')));
  });

  test('a user cannot activate their own request; an admin can', async () => {
    await seed((db) => setDoc(doc(db, 'promotions', 'p3'), promotion('requested')));
    await assertFails(updateDoc(doc(as(BRAND), 'promotions', 'p3'), { status: 'active' }));
    await assertSucceeds(updateDoc(doc(as(ADMIN), 'promotions', 'p3'), { status: 'active' }));
  });

  test('a user cannot give themselves a paid plan', async () => {
    await assertFails(setDoc(doc(as(BRAND), 'subscriptions', BRAND), { plan: 'brand_pro', status: 'active' }));
    await assertSucceeds(getDoc(doc(as(BRAND), 'subscriptions', BRAND)));
  });

  test('a user cannot write a payment record', async () => {
    await assertFails(setDoc(doc(as(BRAND), 'payments', 'pay1'), { userId: BRAND, amount: 999, status: 'paid' }));
  });
});

describe('admin-only collections', () => {
  test('only admins can change categories', async () => {
    await assertFails(setDoc(doc(as(BRAND), 'categories', 'niches'), { items: ['X'] }));
    await assertSucceeds(setDoc(doc(as(ADMIN), 'categories', 'niches'), { items: ['Fashion'] }));
    await assertSucceeds(getDoc(doc(as(CREATOR), 'categories', 'niches')));
  });

  test('only admins can read or write the admin log', async () => {
    await assertSucceeds(setDoc(doc(as(ADMIN), 'adminLogs', 'l1'), { adminId: ADMIN, action: 'test' }));
    await assertFails(getDoc(doc(as(BRAND), 'adminLogs', 'l1')));
    await assertFails(setDoc(doc(as(BRAND), 'adminLogs', 'l2'), { adminId: BRAND, action: 'test' }));
  });

  test('an admin can remove any post', async () => {
    await assertSucceeds(deleteDoc(doc(as(ADMIN), 'hiringPosts', 'job1')));
  });
});
