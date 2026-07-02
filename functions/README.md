# KidVerse Cloud Functions

Server-side writer for the **friends leaderboard** (and weekly reset). The app
is fully playable without these — the leaderboard simply shows a friendly
"connect to play with friends" state until they're deployed.

## What's here
- `aggregateFriendScore` — Firestore trigger on `parents/{uid}`. When a family
  publishes `friendGroup: { code, displayName, avatarSeed, score }` onto their
  own doc (the only write clients are allowed), this fans it into the shared,
  tamper-proof `leaderboards/{code}/entries/{uid}`.
- `resetWeeklyBoards` — scheduled Monday 00:05 UTC; archives and clears each
  board so competition restarts weekly.

## Why this shape
`firebase/firestore.rules` lets a parent write only under their own
`parents/{uid}` subtree and makes `leaderboards/**` **read-only** to clients
(`allow write: if false`). So the client can't write the shared board directly;
this function bridges the gap with the Admin SDK (which bypasses rules). No new
client dependency (e.g. `cloud_functions`) is required.

## Deploy
```bash
# from repo root, once:
npm --prefix functions install
firebase deploy --only functions,firestore:rules
```
Requires a configured Firebase project and `firebase.json` (at repo root).
