import { getDb } from './firebase.js';
import { FieldValue } from 'firebase-admin/firestore';
import { randomUUID } from 'crypto';
import type { User, District, RewardGrant, RoundSession, AuditLog, Squad, MimzEvent, FeedbackSubmission } from '../models/types.js';

/**
 * Firestore data access layer.
 * All database reads/writes go through this module.
 */

function isFailedPreconditionError(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  return error.message.includes('FAILED_PRECONDITION');
}

// ─── Users ───────────────────────────────────────────────

export async function getUser(userId: string): Promise<User | null> {
  const doc = await getDb().collection('users').doc(userId).get();
  return doc.exists ? (doc.data() as User) : null;
}

export async function createUser(user: User): Promise<User> {
  await getDb().collection('users').doc(user.id).set(user);
  return user;
}

export async function updateUser(userId: string, updates: Partial<User>): Promise<void> {
  await getDb().collection('users').doc(userId).update({
    ...updates,
    updatedAt: new Date().toISOString(),
  });
}

export async function searchUsers(query: string, limit = 15): Promise<Partial<User>[]> {
  const q = query.toLowerCase();
  const snap = await getDb().collection('users')
    .orderBy('displayNameLower')
    .startAt(q)
    .endAt(q + '\uf8ff')
    .limit(limit)
    .get();

  return snap.docs.map(d => {
    const u = d.data() as User;
    return {
      id: u.id,
      displayName: u.displayName,
      xp: u.xp,
      emblemId: u.emblemId,
      districtName: u.districtName,
      streak: u.streak,
      bestStreak: u.bestStreak,
    };
  });
}

export async function incrementUserXp(userId: string, amount: number): Promise<void> {
  await getDb().collection('users').doc(userId).update({
    xp: FieldValue.increment(amount),
    updatedAt: new Date().toISOString(),
  });
}

export async function updateUserStreak(userId: string, streak: number, bestStreak: number): Promise<void> {
  await getDb().collection('users').doc(userId).update({
    streak,
    bestStreak: Math.max(streak, bestStreak),
    updatedAt: new Date().toISOString(),
  });
}

/** Today in YYYY-MM-DD (UTC). */
function todayUtc(): string {
  const d = new Date();
  return d.toISOString().slice(0, 10);
}

/** Yesterday in YYYY-MM-DD (UTC). */
function yesterdayUtc(): string {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() - 1);
  return d.toISOString().slice(0, 10);
}

/**
 * Update daily streak when user has meaningful activity (e.g. round completed, territory gained).
 * Call once per "play session" (e.g. after expandTerritory or end_round).
 */
export async function updateDailyStreak(userId: string): Promise<void> {
  const today = todayUtc();
  const yesterday = yesterdayUtc();
  const user = await getUser(userId);
  if (!user) return;
  const last = (user as any).lastActivityDate as string | undefined;
  const current = ((user as any).dailyStreak as number) ?? 0;
  if (last === today) return; // Already counted today
  const nextStreak = last === yesterday ? current + 1 : 1;
  await getDb().collection('users').doc(userId).update({
    lastActivityDate: today,
    dailyStreak: nextStreak,
    updatedAt: new Date().toISOString(),
  });
}

export async function incrementUserSectors(userId: string, sectors: number): Promise<void> {
  await getDb().collection('users').doc(userId).update({
    sectors: FieldValue.increment(sectors),
    updatedAt: new Date().toISOString(),
  });
}

export async function incrementUserInfluence(userId: string, amount: number): Promise<void> {
  await getDb().collection('users').doc(userId).update({
    influence: FieldValue.increment(amount),
    updatedAt: new Date().toISOString(),
  });
}

export async function incrementDistrictInfluence(districtId: string, amount: number): Promise<void> {
  await getDb().collection('districts').doc(districtId).update({
    influence: FieldValue.increment(amount),
    updatedAt: new Date().toISOString(),
  });
}

// ─── Districts ───────────────────────────────────────────

export async function getDistrict(districtId: string): Promise<District | null> {
  const doc = await getDb().collection('districts').doc(districtId).get();
  return doc.exists ? (doc.data() as District) : null;
}

export async function getDistrictByOwner(ownerId: string): Promise<District | null> {
  const snap = await getDb().collection('districts')
    .where('ownerId', '==', ownerId)
    .limit(1)
    .get();
  return snap.empty ? null : (snap.docs[0].data() as District);
}

export async function createDistrict(district: District): Promise<District> {
  await getDb().collection('districts').doc(district.id).set(district);
  return district;
}

export async function updateDistrict(districtId: string, updates: Partial<District>): Promise<void> {
  await getDb().collection('districts').doc(districtId).update({
    ...updates,
    updatedAt: new Date().toISOString(),
  });
}

export async function addStructureToDistrict(
  districtId: string,
  structure: { id: string; name: string; tier: string; description?: string; prestigeValue?: number },
): Promise<void> {
  await getDb().collection('districts').doc(districtId).update({
    structures: FieldValue.arrayUnion({
      ...structure,
      unlockedAt: new Date().toISOString(),
    }),
    updatedAt: new Date().toISOString(),
  });
}

export async function addResources(
  districtId: string,
  resources: { stone?: number; glass?: number; wood?: number },
): Promise<void> {
  const updates: Record<string, any> = { updatedAt: new Date().toISOString() };
  if (resources.stone) updates['resources.stone'] = FieldValue.increment(resources.stone);
  if (resources.glass) updates['resources.glass'] = FieldValue.increment(resources.glass);
  if (resources.wood) updates['resources.wood'] = FieldValue.increment(resources.wood);
  await getDb().collection('districts').doc(districtId).update(updates);
}

export async function expandTerritory(districtId: string, sectors: number): Promise<void> {
  await getDb().collection('districts').doc(districtId).update({
    sectors: FieldValue.increment(sectors),
    updatedAt: new Date().toISOString(),
  });
}

// ─── Rounds ──────────────────────────────────────────────

export async function createRound(round: RoundSession): Promise<RoundSession> {
  await getDb().collection('liveSessions').doc(round.id).set(round);
  return round;
}

export async function getRound(roundId: string): Promise<RoundSession | null> {
  const doc = await getDb().collection('liveSessions').doc(roundId).get();
  return doc.exists ? (doc.data() as RoundSession) : null;
}

export async function updateRound(roundId: string, updates: Partial<RoundSession>): Promise<void> {
  await getDb().collection('liveSessions').doc(roundId).update(updates);
}

export async function getActiveRound(userId: string): Promise<RoundSession | null> {
  // Avoid composite-index dependencies in the hot live grading path.
  // We fetch a small recent window for the user, sort client-side, then
  // return the newest active round so grading can proceed immediately even
  // if Firestore indexes are still building.
  const snap = await getDb().collection('liveSessions')
    .where('userId', '==', userId)
    .limit(20)
    .get();
  if (snap.empty) return null;
  const rounds = snap.docs
    .map((doc) => doc.data() as RoundSession)
    .sort((a, b) => b.startedAt.localeCompare(a.startedAt));
  return rounds.find((round) => round.status === 'active') ?? null;
}

// ─── Vision Quests ───────────────────────────────────────

export async function createVisionQuest(quest: {
  id: string;
  userId: string;
  theme: string;
  status: string;
  confidence: number;
  isValid: boolean;
  sessionId?: string;
  startedAt: string;
}): Promise<void> {
  await getDb().collection('visionQuests').doc(quest.id).set(quest);
}

export async function updateVisionQuest(
  questId: string,
  updates: Record<string, unknown>,
): Promise<void> {
  await getDb().collection('visionQuests').doc(questId).update({
    ...updates,
    updatedAt: new Date().toISOString(),
  });
}

export async function getUserVisionQuests(userId: string, limit = 20): Promise<any[]> {
  const snap = await getDb().collection('visionQuests')
    .where('userId', '==', userId)
    .orderBy('startedAt', 'desc')
    .limit(limit)
    .get();
  return snap.docs.map(d => d.data());
}

// ─── Squads ──────────────────────────────────────────────

export async function getSquad(squadId: string): Promise<Squad | null> {
  const doc = await getDb().collection('squads').doc(squadId).get();
  return doc.exists ? (doc.data() as Squad) : null;
}

export async function getSquadByCode(joinCode: string): Promise<Squad | null> {
  const snap = await getDb().collection('squads')
    .where('joinCode', '==', joinCode)
    .limit(1)
    .get();
  return snap.empty ? null : (snap.docs[0].data() as Squad);
}

export async function createSquad(squad: Squad): Promise<Squad> {
  await getDb().collection('squads').doc(squad.id).set(squad);
  return squad;
}

export async function addSquadMember(squadId: string, member: any): Promise<boolean> {
  const squadRef = getDb().collection('squads').doc(squadId);
  const memberRef = squadRef.collection('members').doc(member.userId);
  return getDb().runTransaction(async (tx) => {
    const existing = await tx.get(memberRef);
    if (existing.exists) {
      tx.set(memberRef, member, { merge: true });
      return false;
    }
    tx.set(memberRef, member);
    tx.update(squadRef, {
      memberCount: FieldValue.increment(1),
    });
    return true;
  });
}

export async function getSquadIdForUser(userId: string): Promise<string | null> {
  const user = await getUser(userId);
  const directSquadId = (user as any)?.squadId as string | undefined;
  if (directSquadId) return directSquadId;

  try {
    const snap = await getDb().collectionGroup('members')
      .where('userId', '==', userId)
      .limit(1)
      .get();
    if (snap.empty) return null;
    return snap.docs[0].ref.parent.parent?.id || null;
  } catch (error) {
    if (isFailedPreconditionError(error)) {
      // Return null until the collection-group index is deployed, rather than
      // failing unrelated app surfaces with a 500.
      return null;
    }
    throw error;
  }
}

export async function updateSquadMissionProgress(squadId: string, missionId: string, amount: number): Promise<void> {
  const missionRef = getDb().collection('squads').doc(squadId).collection('missions').doc(missionId);
  const mission = await missionRef.get();
  if (!mission.exists) {
    throw new Error('Mission not found');
  }
  await missionRef.update({
    currentProgress: FieldValue.increment(amount),
  });
}

export async function addSquadMissionParticipant(
  squadId: string,
  missionId: string,
  userId: string,
): Promise<void> {
  const ref = getDb()
    .collection('squads').doc(squadId)
    .collection('missions').doc(missionId)
    .collection('participants').doc(userId);
  await ref.set({
    userId,
    squadId,
    missionId,
    joinedAt: new Date().toISOString(),
  }, { merge: true }); // merge so rejoining is idempotent
}

export async function getSquadMembers(squadId: string): Promise<any[]> {
  const snap = await getDb().collection('squads').doc(squadId).collection('members')
    .orderBy('rank', 'asc')
    .get();
  return snap.docs.map(d => d.data());
}

export async function getSquadMissions(squadId: string): Promise<any[]> {
  const snap = await getDb().collection('squads').doc(squadId).collection('missions')
    .orderBy('createdAt', 'desc')
    .limit(20)
    .get();
  return snap.docs.map(d => d.data());
}

export async function createSquadMission(squadId: string, mission: {
  id: string;
  title: string;
  description?: string;
  goalProgress: number;
  currentProgress: number;
  createdAt: string;
  deadline?: string;
}): Promise<void> {
  await getDb().collection('squads').doc(squadId).collection('missions').doc(mission.id).set(mission);
}

// ─── Events ──────────────────────────────────────────────

export async function listEvents(): Promise<MimzEvent[]> {
  const snap = await getDb().collection('events')
    .orderBy('startsAt', 'desc')
    .limit(20)
    .get();
  return snap.docs.map(d => d.data() as MimzEvent);
}

export async function getEvent(eventId: string): Promise<MimzEvent | null> {
  const doc = await getDb().collection('events').doc(eventId).get();
  return doc.exists ? (doc.data() as MimzEvent) : null;
}

export async function joinEvent(eventId: string, userId: string): Promise<boolean> {
  const eventRef = getDb().collection('events').doc(eventId);
  const participantRef = eventRef.collection('participants').doc(userId);
  return getDb().runTransaction(async (tx) => {
    const existing = await tx.get(participantRef);
    if (existing.exists) {
      tx.set(participantRef, { joinedAt: existing.data()?.joinedAt ?? new Date().toISOString() }, { merge: true });
      return false;
    }
    tx.set(participantRef, {
      userId,
      eventId,
      score: 0,
      joinedAt: new Date().toISOString(),
    });
    tx.update(eventRef, {
      participantCount: FieldValue.increment(1),
    });
    return true;
  });
}

export async function addEventScore(eventId: string, userId: string, score: number): Promise<void> {
  await getDb().collection('events').doc(eventId).collection('participants').doc(userId).update({
    score: FieldValue.increment(score),
  });
}

// ─── Leaderboard ─────────────────────────────────────────

export async function getLeaderboard(scope: string, limit = 20): Promise<any[]> {
  const snap = await getDb().collection('leaderboards').doc(scope).collection('entries')
    .orderBy('score', 'desc')
    .limit(limit)
    .get();
  return snap.docs.map(d => d.data());
}

export async function upsertLeaderboardEntry(scope: string, userId: string, entry: any): Promise<void> {
  await getDb().collection('leaderboards').doc(scope).collection('entries').doc(userId).set(entry, { merge: true });
}

// ─── Rewards ─────────────────────────────────────────────

export async function logReward(reward: RewardGrant): Promise<void> {
  await getDb().collection('rewards').doc(reward.id).set(reward);
}

export async function getRewardsSince(userId: string, since: Date): Promise<RewardGrant[]> {
  const snap = await getDb().collection('rewards')
    .where('userId', '==', userId)
    .where('grantedAt', '>=', since.toISOString())
    .get();
  return snap.docs.map(d => d.data() as RewardGrant);
}

export async function getUserRewards(userId: string, limit = 20): Promise<RewardGrant[]> {
  const snap = await getDb().collection('rewards')
    .where('userId', '==', userId)
    .orderBy('grantedAt', 'desc')
    .limit(limit)
    .get();
  return snap.docs.map(d => d.data() as RewardGrant);
}

// ─── Audit ───────────────────────────────────────────────

export async function logAudit(entry: AuditLog): Promise<void> {
  await getDb().collection('auditLogs').doc(entry.id).set(entry);
}

// ─── Notifications ───────────────────────────────────────

export async function createNotification(notification: {
  id: string;
  userId: string;
  title: string;
  body: string;
  type: string;
  createdAt: string;
  read: boolean;
  data?: Record<string, unknown>;
}): Promise<void> {
  await getDb().collection('notifications').doc(notification.id).set(notification);

  try {
    const tokens = await getDb().collection('deviceTokens')
      .where('userId', '==', notification.userId)
      .get();
    if (!tokens.empty) {
      const { getMessaging } = await import('firebase-admin/messaging');
      const messaging = getMessaging();
      const fcmTokens = tokens.docs.map(d => d.data().fcmToken);
      await messaging.sendEachForMulticast({
        tokens: fcmTokens,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: { type: notification.type, notificationId: notification.id },
      }).catch(() => {});
    }
  } catch {}
}

export async function getUserNotifications(userId: string): Promise<any[]> {
  const snap = await getDb().collection('notifications')
    .where('userId', '==', userId)
    .orderBy('createdAt', 'desc')
    .limit(50)
    .get();
  return snap.docs.map(d => d.data());
}

export async function markNotificationRead(userId: string, notificationId: string): Promise<void> {
  const snap = await getDb().collection('notifications')
    .where('userId', '==', userId)
    .where('id', '==', notificationId)
    .limit(1)
    .get();
  if (snap.empty) return;
  await snap.docs[0].ref.update({
    read: true,
    readAt: new Date().toISOString(),
  });
}

export async function markAllNotificationsRead(userId: string): Promise<void> {
  const snap = await getDb().collection('notifications')
    .where('userId', '==', userId)
    .where('read', '==', false)
    .limit(100)
    .get();
  if (snap.empty) return;

  const batch = getDb().batch();
  for (const doc of snap.docs) {
    batch.update(doc.ref, {
      read: true,
      readAt: new Date().toISOString(),
    });
  }
  await batch.commit();
}

// ─── Badges / Achievements ───────────────────────────

export async function getUserBadges(userId: string): Promise<Array<{ achievementId: string; unlockedAt: string }>> {
  const snap = await getDb().collection('users').doc(userId).collection('badges')
    .orderBy('unlockedAt', 'desc')
    .get();
  return snap.docs.map(d => d.data() as { achievementId: string; unlockedAt: string });
}

export async function grantBadge(userId: string, achievementId: string): Promise<void> {
  await getDb().collection('users').doc(userId).collection('badges').doc(achievementId).set({
    achievementId,
    unlockedAt: new Date().toISOString(),
  });
}

// ─── Conflicts ───────────────────────────────────────

export async function createConflict(conflict: Record<string, unknown>): Promise<void> {
  await getDb().collection('conflicts').doc(conflict.id as string).set(conflict);
}

export async function updateConflict(conflictId: string, updates: Record<string, unknown>): Promise<void> {
  await getDb().collection('conflicts').doc(conflictId).update({
    ...updates,
    updatedAt: new Date().toISOString(),
  });
}

export async function getActiveConflicts(userId: string): Promise<any[]> {
  const snap = await getDb().collection('conflicts')
    .where('defenderId', '==', userId)
    .where('status', '==', 'active')
    .limit(10)
    .get();
  return snap.docs.map(d => d.data());
}

export async function getConflict(conflictId: string): Promise<Record<string, unknown> | null> {
  const doc = await getDb().collection('conflicts').doc(conflictId).get();
  return doc.exists ? (doc.data() as Record<string, unknown>) : null;
}

// ─── Feedback ────────────────────────────────────────────

export async function createFeedback(
  userId: string,
  feedback: FeedbackSubmission,
): Promise<string> {
  const id = `fb_${randomUUID()}`;
  await getDb().collection('feedback').doc(id).set({
    id,
    userId,
    ...feedback,
    createdAt: new Date().toISOString(),
  });
  return id;
}
