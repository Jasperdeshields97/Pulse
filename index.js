const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.getDailyPulse = functions.https.onRequest(async (req, res) => {
  const userId = req.query.userId;
  const date = new Date().toISOString().split('T')[0];

  const wearableSnap = await admin.firestore().doc(`wearableData/${userId}/${date}`).get();
  const nutritionSnap = await admin.firestore().doc(`foodLogs/${userId}/${date}`).get();
  const userSnap = await admin.firestore().doc(`users/${userId}`).get();

  const wearable = wearableSnap.data() || {};
  const nutrition = nutritionSnap.data() || {};
  const user = userSnap.data() || {};

  const snapshot = {
    sleep: { hours: wearable.sleepHours || 0 },
    activity: { steps: wearable.steps || 0, hrv: wearable.hrv || 0 },
    nutrition: { calories: nutrition.calories || 0, water: nutrition.water || 0 },
    goals: { step_goal: user.stepGoal || 8000 }
  };

  let focus = [];
  if (snapshot.sleep.hours < 6) focus.push('rest');
  if (snapshot.nutrition.water < 2) focus.push('hydration');
  if (snapshot.activity.steps < snapshot.goals.step_goal * 0.5) focus.push('movement');

  let msgParts = [];
  if (snapshot.sleep.hours < 6) msgParts.push(`You slept ${snapshot.sleep.hours} hours, below usual.`);
  if (snapshot.nutrition.water < 2) msgParts.push('Drink 2 extra glasses of water.');
  if (snapshot.activity.steps < snapshot.goals.step_goal * 0.5) msgParts.push('Consider a short walk today.');

  const fact = 'Did you know power naps can improve reaction time by 30%?';
  const pulseMessage = msgParts.join(' ') + ' Fun fact: ' + fact;

  await admin.firestore().doc(`dailyPulse/${userId}/${date}`).set({
    pulseMessage,
    focusAreas: focus
  });

  res.json({ pulseMessage, focusAreas: focus });
});

/**
 * POST /api/logMeal
 * Body: { userId, photoUrl, foods: string[], calories, water }
 */
exports.logMeal = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const { userId, photoUrl, foods = [], calories = 0, water = 0 } = req.body || {};
  if (!userId || !photoUrl) {
    res.status(400).send('userId and photoUrl required');
    return;
  }

  const date = new Date().toISOString().split('T')[0];
  const logRef = admin.firestore().doc(`foodLogs/${userId}/${date}`);
  const existing = (await logRef.get()).data() || {};

  const newLog = {
    photoUrl,
    foods,
    calories: (existing.calories || 0) + calories,
    water: (existing.water || 0) + water,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };

  await logRef.set(newLog, { merge: true });
  res.json({ success: true, log: newLog });
});

/**
 * GET /api/healthDashboard?userId=123
 * Returns combined daily wearable and nutrition data
 */
exports.healthDashboard = functions.https.onRequest(async (req, res) => {
  const userId = req.query.userId;
  if (!userId) {
    res.status(400).send('userId required');
    return;
  }

  const date = new Date().toISOString().split('T')[0];
  const wearableSnap = await admin.firestore().doc(`wearableData/${userId}/${date}`).get();
  const foodSnap = await admin.firestore().doc(`foodLogs/${userId}/${date}`).get();

  const wearable = wearableSnap.data() || {};
  const food = foodSnap.data() || {};

  const dashboard = {
    sleepHours: wearable.sleepHours || 0,
    hrv: wearable.hrv || 0,
    steps: wearable.steps || 0,
    calories: food.calories || 0,
    water: food.water || 0,
    foods: food.foods || []
  };

  res.json(dashboard);
});

