# 05 — Backend Architecture, Firestore Schema, API, State Management

## Client architecture
Feature-first, layered:
- **domain/** pure Dart models (no Flutter/Firebase imports) — testable.
- **data/** repositories; abstract the source (local prefs today, Firestore +
  cache in prod). Callers depend on the repository, never the source.
- **presentation** screens/widgets + Riverpod controllers (`StateNotifier`).

**State management:** Riverpod. `Provider` for singletons/repos,
`StateNotifierProvider` for mutable app state (profiles, settings, wallet via
profile, adaptive model). `FutureProvider` for async loads (curriculum).

**Offline-first:** SharedPreferences is the authoritative local store; a sync
service (P1) mirrors to Firestore with last-write-wins + server timestamps, and
Firestore's own offline cache covers reads.

## Firebase services
| Service | Use |
|---|---|
| Auth | Google, Apple, Phone, Email (parent-owned; children have no auth) |
| Firestore | Profiles, progress, wallet, content metadata, classrooms, leaderboards |
| Storage | Curriculum media, avatar renders (image-only, size-capped) |
| Cloud Messaging | Streak reminders, parent progress digests |
| Analytics | Engagement + learning funnels (no child PII) |
| Cloud Functions | Award leaderboard writes, aggregate reports, admin ops |
| Remote Config | Reward pacing, feature flags, live-ops |
| App Check | Abuse protection on API surface |

## Firestore schema
```
parents/{uid}
  email, authProvider, createdAt, fcmTokens[], settings{}
  children/{childId}
    name, grade, avatar{}, mascotId, activeTheme, unlockedThemes[]
    wallet: { coins, gems, stars, xp, energy, streakDays, lastPlayDay }
    progress/{lessonId}       # per-lesson: bestStars, attempts, lastPlayedAt, mastery
    skills/{subject}          # ema skill 0..1, updatedAt   (mirrors on-device model)
    struggles/{questionId}    # count  (feeds smart revision)
    events/{eventId}          # append-only play events for reports

content/                      # world-readable, admin-writable
  grades/{gradeId}
  units/{unitId}              # title, subject, grade, lessonIds[]
  lessons/{lessonId}          # gameType, questions[], rewards
  assetManifest/{version}     # image/lottie/audio → Storage paths + hashes

classrooms/{classId}          # teacher-owned
  teacherId, name, grade, joinCode
  rosters/{studentId}         # childId ref, displayName, assignments[]

leaderboards/{boardId}/entries/{entryId}   # server-written only; non-PII
  displayName, avatarSeed, score, rank, weekId

admin/                        # admin-only analytics & config
```

## Security
- Rules in `firebase/firestore.rules` & `firebase/storage.rules`.
- Parent owns their subtree; children have no independent credentials (COPPA).
- Content read-only to clients; writes require `admin` custom claim.
- Leaderboard entries are server-written (Cloud Functions) and expose no PII.
- Storage uploads: authed owner only, `image/*`, < 5MB.

## API / service layer (client)
Rather than raw Firestore calls in the UI, each feature exposes a repository:
`ProfilesRepository`, `CurriculumRepository`, (P1) `SyncService`,
`LeaderboardApi`, `MessagingService`. Swapping local→cloud is a repository-level
change; screens are untouched. This is the "API structure": typed repository
methods returning domain models / streams.

## Difficulty auto-adjust pipeline
`GradeLevel.difficultyTier` sets the baseline; `SkillModel.difficultyDelta`
nudges ±1 per subject from live performance; the content selector picks the
lesson bank matching `tier + delta`. Fully on-device; server recommendation
engine (P3) can override via Remote Config.
