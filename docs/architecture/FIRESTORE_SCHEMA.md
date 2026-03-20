# Firestore Schema

## Collections and Document Shapes

### `users/{uid}`
```json
{
  "id": "user_abc123",
  "displayName": "Explorer",
  "handle": "@mimz_abc123",
  "email": "user@example.com",
  "xp": 12450,
  "streak": 7,
  "bestStreak": 12,
  "sectors": 3,
  "districtId": "district_abc123",
  "districtName": "Verdant Reach",
  "interests": ["Technology", "Science"],
  "visibility": "coarse",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-15T12:00:00.000Z"
}
```
**Access pattern**: Read on every authenticated request. Write on XP/streak updates, profile changes.

### `districts/{districtId}`
```json
{
  "id": "district_abc123",
  "ownerId": "user_abc123",
  "name": "Verdant Reach",
  "sectors": 3,
  "area": "3.3 sq km",
  "cells": ["8a2a1072b59ffff", "8a2a1072b5bffff"],
  "anchorCell": "862a1072fffffff",
  "structures": [
    { "id": "library", "name": "Library", "tier": "common", "prestigeValue": 2, "unlockedAt": "..." }
  ],
  "resources": { "stone": 340, "glass": 120, "wood": 280 },
  "visibility": "coarse",
  "prestigeLevel": 4,
  "createdAt": "...",
  "updatedAt": "..."
}
```
**Index needed**: `ownerId ASC`

### `liveSessions/{roundId}`
```json
{
  "id": "round_abc123",
  "userId": "user_abc123",
  "topic": "Geography",
  "difficulty": "medium",
  "questionsAsked": 10,
  "correctAnswers": 7,
  "totalScore": 850,
  "maxStreak": 5,
  "status": "completed",
  "startedAt": "...",
  "endedAt": "..."
}
```
**Index needed**: `userId ASC, status ASC, startedAt DESC`

### `rewards/{rewardId}`
```json
{
  "id": "rw_abc123",
  "userId": "user_abc123",
  "type": "xp",
  "amount": 130,
  "detail": { "streak": 3, "difficulty": "medium" },
  "source": "grade_answer",
  "sessionId": "round_abc123",
  "grantedAt": "..."
}
```
**Index needed**: `userId ASC, grantedAt ASC`

### `squads/{squadId}`
```json
{
  "id": "squad_abc123",
  "name": "Night Owls",
  "joinCode": "XK7M2P",
  "leaderId": "user_abc123",
  "memberCount": 4,
  "totalXp": 45000,
  "createdAt": "..."
}
```
**Index needed**: `joinCode ASC`

### `squads/{squadId}/members/{uid}`
```json
{
  "userId": "user_abc123",
  "displayName": "Explorer",
  "rank": 1,
  "xpContributed": 12000,
  "joinedAt": "..."
}
```

### `squads/{squadId}/missions/{missionId}`
```json
{
  "id": "mission_abc123",
  "title": "Geography Marathon",
  "description": "Answer 50 geography questions as a team",
  "targetProgress": 50,
  "currentProgress": 32,
  "reward": { "stone": 500, "glass": 300, "wood": 400 },
  "status": "active",
  "expiresAt": "..."
}
```

### `events/{eventId}`
```json
{
  "id": "event_abc123",
  "title": "Weekend Challenge",
  "description": "Compete for the most XP this weekend",
  "status": "live",
  "participantCount": 234,
  "startsAt": "...",
  "endsAt": "...",
  "reward": { "stone": 200, "glass": 100, "wood": 150 }
}
```

### `events/{eventId}/participants/{uid}`
```json
{
  "userId": "user_abc123",
  "eventId": "event_abc123",
  "score": 850,
  "joinedAt": "..."
}
```

### `leaderboards/{scope}/entries/{uid}`
```json
{
  "userId": "user_abc123",
  "displayName": "Explorer",
  "score": 12450,
  "districtName": "Verdant Reach"
}
```

### `auditLogs/{logId}`
```json
{
  "id": "audit_abc123",
  "userId": "user_abc123",
  "action": "grade_answer",
  "toolName": "grade_answer",
  "sessionId": "round_abc123",
  "correlationId": "corr_xyz789",
  "detail": { "isCorrect": true, "points": 130 },
  "timestamp": "..."
}
```

### `notifications/{notificationId}`
```json
{
  "id": "notif_abc123",
  "userId": "user_abc123",
  "type": "reward",
  "title": "Structure Unlocked!",
  "body": "You unlocked the Library in your district.",
  "read": false,
  "createdAt": "..."
}
```

## Required Composite Indexes

| Collection | Fields | Purpose |
|-----------|--------|---------|
| `liveSessions` | `userId ASC, status ASC, startedAt DESC` | Find active round |
| `rewards` | `userId ASC, grantedAt ASC` | Reward cap check |
| `squads` | `joinCode ASC` | Join by code |
| `districts` | `ownerId ASC` | User's district |
| `notifications` | `userId ASC, createdAt DESC` | User notification feed |
| `events` | `startsAt DESC` | Event listing |
