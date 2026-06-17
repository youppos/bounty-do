# Bounty-Do Gamified Task App - Backend API

A gamified todo-list backend server built with **NestJS**, **TypeScript**, **SQLite**, and **Prisma ORM**. 
It handles authentication, task synchronization with gamified elements (leveling, coin rewards), AI productivity suggestion recommendations, monthly statistics analytics, and a speech-to-task text parser.

---

## 🛠️ Tech Stack & Features

- **Framework**: [NestJS](https://nestjs.com/) (Node.js framework)
- **Database**: SQLite (locally stored in `prisma/dev.db`)
- **ORM**: [Prisma](https://www.prismajs.com/) (Version 7)
- **Authentication**: JWT-based Authentication
- **Speech Parsing**: Regular expressions and keyword-matching for parsing Chinese and English speech transcriptions to task details.
- **Analytics**: Auto-aggregating stats (completion rates, coin earnings, and priority distributions) for the current month.
- **AI Engine**: Gamified recommendations based on player stats and shop skills.

---

## 🚀 Getting Started

### 1. Prerequisites
Ensure you have **Node.js** (v18+ or v22+) and **npm** installed:
```bash
node -v
npm -v
```

### 2. Install Dependencies
Navigate to the `backend` directory and install the packages:
```bash
cd backend
npm install
```

### 3. Database Initialization (Prisma & SQLite)
Generate the Prisma client and apply the migrations to create the local SQLite database (`prisma/dev.db`):
```bash
npx prisma migrate dev --name init
npx prisma generate
```

### 4. Run the Server
Start the development server:
```bash
npm run start:dev
```
The server will bind to `0.0.0.0` and listen on **port 3000** (e.g. `http://localhost:3000` or `http://<YOUR_LAN_IP>:3000`), allowing mobile devices or local emulators to connect.

---

## 🗺️ API Documentation

### 🔒 Authentication (Public)

#### 1. Register
* **Endpoint**: `POST /auth/register`
* **Request Body**:
```json
{
  "email": "warrior@bountydo.com",
  "password": "securepassword123",
  "username": "HeroQuest" // Optional
}
```
* **Response (201 Created)**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "5f606764-f655-46f9-a2ce-6893e32e8db9",
    "email": "warrior@bountydo.com",
    "username": "HeroQuest",
    "level": 1,
    "coins": 0
  }
}
```

#### 2. Login
* **Endpoint**: `POST /auth/login`
* **Request Body**:
```json
{
  "email": "warrior@bountydo.com",
  "password": "securepassword123"
}
```
* **Response (200 OK)**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "5f606764-f655-46f9-a2ce-6893e32e8db9",
    "email": "warrior@bountydo.com",
    "username": "HeroQuest",
    "level": 1,
    "coins": 0
  }
}
```

---

### 📝 Tasks Synchronization (Bearer Token Required)

Headers must include `Authorization: Bearer <JWT_TOKEN>`.

#### 1. Get All Tasks
* **Endpoint**: `GET /tasks`
* **Response (200 OK)**:
```json
{
  "tasks": [
    {
      "id": "client-uuid-1",
      "title": "Call Mom",
      "description": "Weekly checkup",
      "isCompleted": false,
      "hasAlarm": false,
      "hasReminder": true,
      "coinReward": 15,
      "levelIndex": 1,
      "createdAt": "2026-06-17T10:00:00.000Z",
      "deadline": "2026-06-18T17:00:00.000Z",
      "completedAt": null,
      "userId": "5f606764-f655-46f9-a2ce-6893e32e8db9"
    }
  ]
}
```

#### 2. Sync / Save Tasks
Synchronizes offline client tasks with the cloud, updating database tasks and syncing player levels and coins.
* **Endpoint**: `POST /tasks`
* **Request Body**:
```json
{
  "coins": 450, // Optional: updates user's coin stash
  "level": 3,   // Optional: updates user's current level
  "tasks": [    // Optional: array of tasks to insert or update
    {
      "id": "client-uuid-1",
      "title": "Call Mom",
      "description": "Weekly checkup",
      "isCompleted": true,
      "hasAlarm": false,
      "hasReminder": true,
      "coinReward": 30, // Double coins applied
      "levelIndex": 1,
      "createdAt": "2026-06-17T10:00:00.000Z",
      "deadline": "2026-06-18T17:00:00.000Z",
      "completedAt": "2026-06-17T11:30:00.000Z"
    }
  ]
}
```
* **Response (200 OK)**:
Returns the latest merged task state and user stats.
```json
{
  "tasks": [
    {
      "id": "client-uuid-1",
      "title": "Call Mom",
      "description": "Weekly checkup",
      "isCompleted": true,
      "hasAlarm": false,
      "hasReminder": true,
      "coinReward": 30,
      "levelIndex": 1,
      "createdAt": "2026-06-17T10:00:00.000Z",
      "deadline": "2026-06-18T17:00:00.000Z",
      "completedAt": "2026-06-17T11:30:00.000Z",
      "userId": "5f606764-f655-46f9-a2ce-6893e32e8db9"
    }
  ],
  "coins": 450,
  "level": 3
}
```

---

### 🧠 AI Productivity Suggestions (Optional Auth)

Generates motivational context-sensitive notifications and shop purchase reminders based on user metrics.

* **Endpoint**: `POST /ai/suggestions`
* **Header**: `Authorization: Bearer <JWT_TOKEN>` (Optional: if provided, fields left blank will automatically fallback to database calculations based on user history).
* **Request Body**:
```json
{
  "playerLevel": 3,           // Optional: default is database or 1
  "taskConsistency": 0.35,    // Optional: completion rate (0.0 to 1.0)
  "activeSkills": ["Shield of Discipline"] // Optional: active skill buffs
}
```
* **Response (200 OK)**:
```json
{
  "playerLevel": 3,
  "taskConsistency": 0.35,
  "activeSkills": [
    "Shield of Discipline"
  ],
  "suggestions": [
    "Warning: Your weekly task completion rate is only 35%. Divide larger items into sub-tasks and prioritize high-value tasks first.",
    "Consider activating 'Shield of Discipline' to prevent coin penalties on overdue tasks.",
    "Shield of Discipline is active! Your coins are protected from late penalties, so take your time and deliver high quality.",
    "Tip: Feeling lucky? Spend 50 coins on the Jackpot Wheel. You stand a chance to win up to 300 coins!"
  ],
  "levelUpAdvice": "Awakened Warrior (Level 3)! Elevate your productivity. Complete medium (level-2) and hard (level-3) tasks to earn larger coin bounties!",
  "recommendedSkills": [
    "Shield of Discipline"
  ]
}
```

---

### 📊 Monthly Analytics (Bearer Token Required)

Computes summary metrics for the current calendar month.

* **Endpoint**: `GET /analytics/monthly`
* **Response (200 OK)**:
```json
{
  "month": "June",
  "year": 2026,
  "totalCreated": 12,
  "totalCompleted": 8,
  "completionRate": 0.67,
  "coinsEarned": 240,
  "completedOnTime": 6,
  "completedOverdue": 2,
  "priorityDistribution": {
    "level_0": 2,
    "level_1": 6,
    "level_2": 3,
    "level_3": 1,
    "level_4": 0
  },
  "priorityLabels": {
    "low": 2,
    "medium": 6,
    "high": 3,
    "epic": 1,
    "legendary": 0
  },
  "dailyTrend": [
    { "day": 1, "count": 0 },
    { "day": 2, "count": 1 },
    { "day": 17, "count": 7 }
    // ... all days of the month represented
  ],
  "userLevel": 3,
  "totalCoins": 450
}
```

---

### 🗣️ Voice Speech Parser (Public)

Parses voice transcriptions to extract a structured task.

* **Endpoint**: `POST /voice/parse`
* **Request Body**:
```json
{
  "text": "提醒我明天下午三点去健身房 优先级五"
}
```
* **Response (200 OK)**:
```json
{
  "title": "去健身房",
  "levelIndex": 4, // Priority level 5 maps to index 4
  "deadline": "2026-06-18T15:00:00.000Z" // ISO datetime for tomorrow at 15:00
}
```

#### English Example:
* **Request Body**:
```json
{
  "text": "Call doctor on Friday level 2"
}
```
* **Response (200 OK)**:
```json
{
  "title": "Call doctor",
  "levelIndex": 1, // Level 2 maps to index 1
  "deadline": "2026-06-19T18:00:00.000Z" // Friday (relative to June 17, 2026) at 18:00
}
```
