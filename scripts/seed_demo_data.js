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
initializeApp({ projectId: 'mimzapp' });

const db = getFirestore();

async function seedEvents() {
  console.log('Seeding events...');
  
  const now = new Date();
  const inOneHour = new Date(now.getTime() + 3600000);
  const tomorrow = new Date(now.getTime() + 86400000);
  const nextWeek = new Date(now.getTime() + 7 * 86400000);

  const events = [
    {
      id: 'event_city_builders_cup',
      title: 'City Builders Cup',
      description: 'Compete to expand your district the most in 24 hours. Top 3 districts win bonus prestige.',
      status: 'active',
      category: 'competition',
      participantCount: 247,
      maxParticipants: 500,
      startTime: Timestamp.fromDate(now),
      endTime: Timestamp.fromDate(tomorrow),
      rewardXp: 5000,
      rewardMaterials: { stone: 200, glass: 100, wood: 150 },
      coverImageUrl: null,
      createdAt: Timestamp.fromDate(now),
    },
    {
      id: 'event_urban_trivia_blitz',
      title: 'Urban Trivia Blitz',
      description: 'Live voice quiz on architecture, cities, and design. Answer 20 questions to win territory.',
      status: 'active',
      category: 'quiz',
      participantCount: 89,
      maxParticipants: 200,
      startTime: Timestamp.fromDate(now),
      endTime: Timestamp.fromDate(inOneHour),
      rewardXp: 2500,
      rewardMaterials: { stone: 100, glass: 50, wood: 75 },
      coverImageUrl: null,
      createdAt: Timestamp.fromDate(now),
    },
    {
      id: 'event_vision_explorer_challenge',
      title: 'Vision Explorer Challenge',
      description: 'Point your camera at 5 different types of structures. Best capturer wins a Landmark unlock.',
      status: 'upcoming',
      category: 'vision',
      participantCount: 0,
      maxParticipants: 100,
      startTime: Timestamp.fromDate(tomorrow),
      endTime: Timestamp.fromDate(nextWeek),
      rewardXp: 3500,
      rewardMaterials: { stone: 150, glass: 80, wood: 120 },
      coverImageUrl: null,
      createdAt: Timestamp.fromDate(now),
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
    description: 'A coalition of builders dedicated to green urban design. Join us to grow together.',
    emblemId: 'leaf_circle',
    memberCount: 12,
    maxMembers: 20,
    totalXp: 48750,
    rank: 3,
    isPublic: true,
    createdAt: Timestamp.fromDate(now),
    missions: [
      {
        id: 'mission_green_builders_push',
        title: 'Green Builders Push',
        description: 'Collectively unlock 50 sectors this week',
        currentProgress: 34,
        targetProgress: 50,
        rewardXp: 10000,
        status: 'active',
        endsAt: Timestamp.fromDate(new Date(now.getTime() + 5 * 86400000)),
      },
    ],
    topMembers: [
      { userId: 'demo_member_1', displayName: 'ArcticFox', districtName: 'Frostgate', xp: 12000 },
      { userId: 'demo_member_2', displayName: 'UrbanDrift', districtName: 'Neonharbor', xp: 9500 },
      { userId: 'demo_member_3', displayName: 'GlassScape', districtName: 'Luminary', xp: 7800 },
    ],
  };

  await db.collection('squads').doc(squad.id).set(squad, { merge: true });
  console.log(`  ✅ Squad: ${squad.name}`);
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
