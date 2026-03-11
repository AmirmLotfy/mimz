import { getDb } from './firebase.js';
import { FieldValue } from 'firebase-admin/firestore';
import { randomUUID } from 'crypto';
import type { User, District, RewardGrant, RoundSession, AuditLog, Squad, MimzEvent } from '../models/types.js';

/**
 * Firestore data access layer.
 * All database reads/writes go through this module.
 */

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

export async function incrementUserSectors(userId: string, sectors: number): Promise<void> {
  await getDb().collection('users').doc(userId).update({
    sectors: FieldValue.increment(sectors),
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

export async function updateRound(roundId: string, updates: Partial<RoundSession>): Promise<void> {
  await getDb().collection('liveSessions').doc(roundId).update(updates);
}

export async function getActiveRound(userId: string): Promise<RoundSession | null> {
  const snap = await getDb().collection('liveSessions')
    .where('userId', '==', userId)
    .where('status', '==', 'active')
    .orderBy('startedAt', 'desc')
    .limit(1)
    .get();
  return snap.empty ? null : (snap.docs[0].data() as RoundSession);
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

export async function addSquadMember(squadId: string, member: any): Promise<void> {
  await getDb().collection('squads').doc(squadId).collection('members').doc(member.userId).set(member);
  await getDb().collection('squads').doc(squadId).update({
    memberCount: FieldValue.increment(1),
  });
}

export async function updateSquadMissionProgress(squadId: string, missionId: string, amount: number): Promise<void> {
  await getDb().collection('squads').doc(squadId).collection('missions').doc(missionId).update({
    currentProgress: FieldValue.increment(amount),
  });
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

export async function joinEvent(eventId: string, userId: string): Promise<void> {
  await getDb().collection('events').doc(eventId).collection('participants').doc(userId).set({
    userId,
    eventId,
    score: 0,
    joinedAt: new Date().toISOString(),
  });
  await getDb().collection('events').doc(eventId).update({
    participantCount: FieldValue.increment(1),
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

// ─── Audit ───────────────────────────────────────────────

export async function logAudit(entry: AuditLog): Promise<void> {
  await getDb().collection('auditLogs').doc(entry.id).set(entry);
}

// ─── Notifications ───────────────────────────────────────

export async function getUserNotifications(userId: string): Promise<any[]> {
  const snap = await getDb().collection('notifications')
    .where('userId', '==', userId)
    .orderBy('createdAt', 'desc')
    .limit(50)
    .get();
  return snap.docs.map(d => d.data());
}
