# Pulse

Daily health snapshot app: one score, every morning, from your real data.

Pulse aggregates wearable metrics (sleep, steps, HRV), nutrition logs (calories, water), and user goals into a single daily readout, so you know where you stand before the day starts.

## Architecture

```
frontend/   Flutter app (Dart): daily pulse UI
index.js    Firebase Cloud Functions backend
```

- **Backend:** Firebase Functions + Firestore. `getDailyPulse` joins the day's wearable data, food logs, and user profile into one snapshot response.
- **Frontend:** Flutter, talking to the Functions API via `firebase_core`.

## Run

```bash
# backend (requires Firebase project + credentials)
npm install
firebase deploy --only functions

# frontend
cd frontend
flutter pub get
flutter run
```

## Status

Working prototype. Built solo as part of a series of health-tech products (see also [JasdLifeOS](https://github.com/Jasperdeshields97/jasd_lifeos_flutter)).
