#!/usr/bin/env node
/**
 * seed_demo_data.js
 * 
 * Seeds Firestore with demo events and a squad so those tabs
 * are populated during the hackathon demo.
 * 
 * Run: node scripts/seed_demo_data.js
 * Requires: GCP credentials (ADC or GOOGLE_APPLICATION_CREDENTIALS)
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

// Use Application Default Credentials (gcloud auth ADC)
// Targets the new Mimz production project by default.
initializeApp({ projectId: process.env.FIREBASE_PROJECT_ID || 'mimz-490520' });

const db = getFirestore();

async function seedEvents() {
  console.log('Seeding events...');
  
  const now = new Date();
  const inOneHour = new Date(now.getTime() + 3600000);
  const tomorrow = new Date(now.getTime() + 86400000);
  const nextWeek = new Date(now.getTime() + 7 * 86400000);

  const events = [
    {
      id: 'event_knowledge_rush',
      title: 'Knowledge Rush',
      description: 'Live voice quiz on architecture, cities, and design. Answer 20 questions to win territory.',
      type: 'quiz_challenge',
      status: 'live',
      startsAt: now.toISOString(),
      endsAt: inOneHour.toISOString(),
      participantCount: 89,
      maxParticipants: 200,
      createdAt: now.toISOString(),
    },
    {
      id: 'event_vision_masters',
      title: 'Vision Masters',
      description: 'Point your camera at 5 different types of structures. Best capturer wins a Landmark unlock.',
      type: 'vision_quest',
      status: 'upcoming',
      startsAt: tomorrow.toISOString(),
      endsAt: nextWeek.toISOString(),
      participantCount: 0,
      maxParticipants: 100,
      createdAt: now.toISOString(),
    },
    {
      id: 'event_squad_showdown',
      title: 'Squad Showdown',
      description: 'Compete squad-vs-squad to expand your district the most in 24 hours. Top 3 squads win bonus prestige.',
      type: 'squad_battle',
      status: 'upcoming',
      startsAt: tomorrow.toISOString(),
      endsAt: nextWeek.toISOString(),
      participantCount: 0,
      maxParticipants: 500,
      createdAt: now.toISOString(),
    },
  ];

  for (const event of events) {
    await db.collection('events').doc(event.id).set(event, { merge: true });
    console.log(`  ✅ Event: ${event.title}`);
  }
}

async function seedSquad() {
  console.log('Seeding demo squad...');
  
  const now = new Date();
  
  const squad = {
    id: 'squad_verdant_alliance',
    name: 'Verdant Alliance',
    joinCode: 'VERDNT',
    leaderId: 'demo_member_1',
    memberCount: 12,
    totalXp: 48750,
    createdAt: now.toISOString(),
  };

  await db.collection('squads').doc(squad.id).set(squad, { merge: true });
  console.log(`  ✅ Squad: ${squad.name}`);

  // Seed missions as subcollection
  const missions = [
    {
      id: 'mission_green_builders_push',
      title: 'Green Builders Push',
      description: 'Collectively unlock 50 sectors this week',
      currentProgress: 34,
      goalProgress: 50,
      rewardXp: 10000,
      deadline: new Date(now.getTime() + 5 * 86400000).toISOString(),
      createdAt: now.toISOString(),
    },
  ];

  for (const mission of missions) {
    await db.collection('squads').doc(squad.id).collection('missions').doc(mission.id).set(mission, { merge: true });
    console.log(`  ✅ Mission: ${mission.title}`);
  }

  // Seed demo members subcollection
  const members = [
    { userId: 'demo_member_1', displayName: 'ArcticFox', rank: 1, xpContributed: 12000, joinedAt: now.toISOString() },
    { userId: 'demo_member_2', displayName: 'UrbanDrift', rank: 2, xpContributed: 9500, joinedAt: now.toISOString() },
    { userId: 'demo_member_3', displayName: 'GlassScape', rank: 3, xpContributed: 7800, joinedAt: now.toISOString() },
  ];

  for (const member of members) {
    await db.collection('squads').doc(squad.id).collection('members').doc(member.userId).set(member, { merge: true });
    console.log(`  ✅ Member: ${member.displayName}`);
  }
}

async function main() {
  try {
    await seedEvents();
    await seedSquad();
    console.log('\n🎉 Demo data seeded successfully!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Seeding failed:', err);
    process.exit(1);
  }
}

main();
