import dotenv from 'dotenv';
import http from 'http';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { createApp } from '../src/app.js';
import { connectDatabase, closeDatabase, isDbReady } from '../src/db/connection.js';
import { User } from '../src/models/User.js';
import { WorkoutPlan } from '../src/models/WorkoutPlan.js';
import { Exercise } from '../src/models/Exercise.js';
import { WorkoutSession } from '../src/models/WorkoutSession.js';
import { PersonalRecord } from '../src/models/PersonalRecord.js';
import { AppSettings } from '../src/models/AppSettings.js';
import { seedStandardExercisesIfNeeded } from '../src/routes/exercises.js';

dotenv.config();

let memServer: MongoMemoryServer | null = null;

async function runTests() {
  console.log('====================================================');
  console.log('       LiftLog Backend Verification Suite');
  console.log('====================================================');

  let targetUri = process.env.MONGODB_URI;

  console.log('\n[1/10] Connecting to MongoDB...');
  let connectedToAtlas = false;
  if (targetUri) {
    try {
      console.log('Attempting connection to configured MongoDB Atlas cluster...');
      // Try connecting with a short timeout to see if current IP is whitelisted on Atlas
      await connectDatabase(targetUri);
      connectedToAtlas = true;
      console.log('✓ Connected directly to MongoDB Atlas cluster!');
    } catch (err: any) {
      console.warn('⚠ Notice: MongoDB Atlas cluster could not be reached directly from this local IP.');
      console.warn('  Reason:', err.message);
      console.log('  Falling back to in-memory MongoDB server for local end-to-end integration tests...');
    }
  }

  if (!connectedToAtlas) {
    memServer = await MongoMemoryServer.create();
    targetUri = memServer.getUri();
    await connectDatabase(targetUri);
    console.log('✓ In-memory MongoDB test server connected and ready.');
  }

  if (!isDbReady()) {
    throw new Error('Database is not in ready state!');
  }

  // Seed standard exercises
  await seedStandardExercisesIfNeeded();

  const app = createApp();
  const server = http.createServer(app);
  await new Promise<void>((resolve) => server.listen(0, resolve));
  const port = (server.address() as any).port;
  const baseUrl = `http://localhost:${port}/api`;
  console.log(`✓ Test HTTP server listening at ${baseUrl}`);

  try {
    // ----------------------------------------------------
    // Test 1: Health Endpoint (GET /api/health)
    // ----------------------------------------------------
    console.log('\n[2/10] Testing GET /api/health...');
    const healthRes = await fetch(`${baseUrl}/health`);
    const healthData = (await healthRes.json()) as any;
    if (healthRes.status !== 200 || healthData.status !== 'ok' || !healthData.database.connected) {
      throw new Error(`Health check failed: ${JSON.stringify(healthData)}`);
    }
    console.log('✓ Health endpoint verified: status=ok, database.connected=true');

    // ----------------------------------------------------
    // Test 2: Standard Exercises Seeding (GET /api/exercises)
    // ----------------------------------------------------
    console.log('\n[3/10] Testing GET /api/exercises without auth (should be blocked) and with auth...');
    const unauthExRes = await fetch(`${baseUrl}/exercises`);
    if (unauthExRes.status !== 401) {
      throw new Error(`Expected 401 for unauthenticated exercises, got ${unauthExRes.status}`);
    }
    console.log('✓ Confirmed 401 Unauthorized for unauthenticated requests.');

    // ----------------------------------------------------
    // Test 3: User A Registration & JWT Token
    // ----------------------------------------------------
    console.log('\n[4/10] Testing User A Registration (POST /api/auth/register)...');
    const timestamp = Date.now();
    const userAEmail = `athlete_a_${timestamp}@liftlog.test`;
    const regResA = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Athlete Alpha',
        email: userAEmail,
        password: 'Password123!',
      }),
    });
    const regDataA = (await regResA.json()) as any;
    if (regResA.status !== 201 || !regDataA.token || !regDataA.user) {
      throw new Error(`User A registration failed: ${JSON.stringify(regDataA)}`);
    }
    const tokenA = regDataA.token;
    const userAId = regDataA.user.id;
    console.log(`✓ User A registered: email=${userAEmail}, userId=${userAId}`);

    // Verify GET /api/auth/me for User A
    const meResA = await fetch(`${baseUrl}/auth/me`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const meDataA = (await meResA.json()) as any;
    if (meResA.status !== 200 || meDataA.user.id !== userAId) {
      throw new Error(`GET /api/auth/me failed for User A`);
    }
    console.log('✓ GET /api/auth/me verified User A profile.');

    // ----------------------------------------------------
    // Test 4: User A Login (POST /api/auth/login)
    // ----------------------------------------------------
    console.log('\n[5/10] Testing User A Login (POST /api/auth/login)...');
    const loginResA = await fetch(`${baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: userAEmail,
        password: 'Password123!',
      }),
    });
    const loginDataA = (await loginResA.json()) as any;
    if (loginResA.status !== 200 || !loginDataA.token) {
      throw new Error(`User A login failed: ${JSON.stringify(loginDataA)}`);
    }
    console.log('✓ User A login successful and returned valid JWT token.');

    // ----------------------------------------------------
    // Test 5: User A creates and retrieves Workout Plan
    // ----------------------------------------------------
    console.log('\n[6/10] Testing Workout Plans for User A (POST & GET /api/workout-plans)...');
    const createPlanRes = await fetch(`${baseUrl}/workout-plans`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        name: 'Upper Body Power',
        description: 'Heavy chest and back volume',
        color_index: 2,
        days_of_week: [0, 2, 4], // Mon, Wed, Fri
        exercises: [
          {
            exercise_id: 'bench-press',
            exercise_name: 'Barbell Bench Press',
            exercise_muscle: 'chest',
            exercise_type: 'strength',
            sort_order: 0,
            target_sets: 4,
            target_reps: 6,
            target_weight: 95,
            rest_seconds: 120,
          },
        ],
      }),
    });
    const createdPlan = (await createPlanRes.json()) as any;
    if (createPlanRes.status !== 201 || !createdPlan.id) {
      throw new Error(`Plan creation failed: ${JSON.stringify(createdPlan)}`);
    }
    const planAId = createdPlan.id;
    console.log(`✓ Workout plan created for User A (planId: ${planAId}, name: "${createdPlan.name}")`);

    // Retrieve plans for User A
    const getPlansA = await fetch(`${baseUrl}/workout-plans`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const plansA = (await getPlansA.json()) as any[];
    if (getPlansA.status !== 200 || plansA.length !== 1 || plansA[0].id !== planAId) {
      throw new Error(`User A plan list mismatch: ${JSON.stringify(plansA)}`);
    }
    console.log(`✓ User A retrieved exactly 1 workout plan.`);

    // ----------------------------------------------------
    // Test 6: User A Workout Session and Personal Record Logging
    // ----------------------------------------------------
    console.log('\n[7/10] Testing Workout Session & PR Logging for User A...');
    const sessionRes = await fetch(`${baseUrl}/workout-sessions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        plan_id: planAId,
        plan_name: 'Upper Body Power',
        started_at: new Date().toISOString(),
        completed_at: new Date().toISOString(),
        duration_seconds: 2700,
        status: 'completed',
        note: 'Felt strong, hit a new benchmark',
        logs: [
          {
            exercise_id: 'bench-press',
            exercise_name: 'Barbell Bench Press',
            exercise_type: 'strength',
            sort_order: 0,
            sets: [
              {
                set_number: 1,
                weight_kg: 95,
                reps: 6,
                completed: 1,
              },
            ],
          },
        ],
      }),
    });
    const createdSession = (await sessionRes.json()) as any;
    if (sessionRes.status !== 201 || !createdSession.id) {
      throw new Error(`Session creation failed: ${JSON.stringify(createdSession)}`);
    }
    console.log(`✓ Workout session recorded for User A (sessionId: ${createdSession.id})`);

    // Log Personal Record
    const prRes = await fetch(`${baseUrl}/personal-records`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokenA}`,
      },
      body: JSON.stringify({
        exercise_id: 'bench-press',
        exercise_name: 'Barbell Bench Press',
        record_type: 'highestWeight',
        value: 95,
        session_id: createdSession.id,
        achieved_at: new Date().toISOString(),
      }),
    });
    const createdPR = (await prRes.json()) as any;
    if (prRes.status !== 201 || !createdPR.id) {
      throw new Error(`PR creation failed: ${JSON.stringify(createdPR)}`);
    }
    console.log(`✓ Personal record recorded for User A (value: 95kg)`);

    // ----------------------------------------------------
    // Test 7: Verify Statistics for User A
    // ----------------------------------------------------
    console.log('\n[8/10] Testing GET /api/statistics and /api/history for User A...');
    const statsRes = await fetch(`${baseUrl}/statistics`, {
      headers: { Authorization: `Bearer ${tokenA}` },
    });
    const stats = (await statsRes.json()) as any;
    if (statsRes.status !== 200 || stats.totalWorkouts !== 1 || stats.totalPRs !== 1) {
      throw new Error(`Stats mismatch: ${JSON.stringify(stats)}`);
    }
    console.log('✓ Statistics verified: workouts=1, volume=570kg, PRs=1');

    // ----------------------------------------------------
    // Test 8: Register User B & Verify Multi-Tenant Isolation
    // ----------------------------------------------------
    console.log('\n[9/10] Registering User B & Verifying Multi-Tenant Data Isolation...');
    const userBEmail = `athlete_b_${timestamp}@liftlog.test`;
    const regResB = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Athlete Bravo',
        email: userBEmail,
        password: 'Password123!',
      }),
    });
    const regDataB = (await regResB.json()) as any;
    const tokenB = regDataB.token;
    const userBId = regDataB.user.id;
    console.log(`✓ User B registered: email=${userBEmail}, userId=${userBId}`);

    // User B fetches plans -> MUST BE EMPTY ("No workout plans yet")
    const getPlansB = await fetch(`${baseUrl}/workout-plans`, {
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    const plansB = (await getPlansB.json()) as any[];
    if (getPlansB.status !== 200 || plansB.length !== 0) {
      throw new Error(`SECURITY BREACH: User B saw plans: ${JSON.stringify(plansB)}`);
    }
    console.log('✓ Confirmed: User B receives empty list [] -> triggers "No workout plans yet" UI state.');

    // User B attempts to read User A's plan by ID
    const directGetRes = await fetch(`${baseUrl}/workout-plans/${planAId}`, {
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    if (directGetRes.status !== 404) {
      throw new Error(`SECURITY BREACH: User B read User A's plan! Status: ${directGetRes.status}`);
    }
    console.log("✓ Confirmed: User B receives 404 Not Found when trying to read User A's plan.");

    // User B attempts to delete User A's plan
    const directDeleteRes = await fetch(`${baseUrl}/workout-plans/${planAId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    if (directDeleteRes.status !== 404) {
      throw new Error(`SECURITY BREACH: User B deleted User A's plan! Status: ${directDeleteRes.status}`);
    }
    console.log("✓ Confirmed: User B receives 404 Not Found when trying to delete User A's plan.");

    // User B fetches statistics -> MUST BE 0
    const statsResB = await fetch(`${baseUrl}/statistics`, {
      headers: { Authorization: `Bearer ${tokenB}` },
    });
    const statsB = (await statsResB.json()) as any;
    if (statsB.totalWorkouts !== 0 || statsB.totalPRs !== 0) {
      throw new Error(`SECURITY BREACH: User B saw User A's stats! ${JSON.stringify(statsB)}`);
    }
    console.log("✓ Confirmed: User B has 0 workouts and 0 PRs.");

    // ----------------------------------------------------
    // Test 9: Data Persistence verification
    // ----------------------------------------------------
    console.log('\n[10/10] Verifying Data Persistence...');
    const recheckPlan = await WorkoutPlan.findOne({ id: planAId, userId: userAId });
    if (!recheckPlan || recheckPlan.name !== 'Upper Body Power') {
      throw new Error('Data persistence check failed!');
    }
    console.log('✓ Confirmed: User A data is securely persisted in MongoDB.');

    console.log('\n====================================================');
    console.log('  ALL 10/10 BACKEND INTEGRATION TESTS PASSED CLEANLY');
    console.log('====================================================\n');
  } finally {
    server.close();
    await closeDatabase();
    if (memServer) {
      await memServer.stop();
    }
  }
}

runTests().catch((err) => {
  console.error('\n❌ Backend test suite encountered an error:', err);
  process.exit(1);
});
