# 08 — Parent, Teacher & Admin Dashboards

## Parent Dashboard ✅ (implemented)
`lib/features/parent/parent_dashboard_screen.dart`, reached via the COPPA
**Parent Gate** (`a×b` challenge). Shows, per child:
- Stat row: Level, XP, Coins, Streak.
- **Subject mastery** bars (from on-device `SkillModel`).
- **Needs practice** (weak areas) & **Strengths** chips.
- Controls: screen-time limit, notifications, privacy (COPPA/GDPR).

Roadmap (P1–P2): performance graph over time, per-lesson history, homework
assignment, goal setting, reward approval, multi-device sync of these views from
Firestore `children/{id}/events`.

## Teacher Dashboard (spec, P3 — web + tablet)
Data root: `classrooms/{classId}` (teacher-owned, join-code enrollment).
- **Roster & attendance**, student progress (live from `events`).
- **Assignments:** push specific lessons/units to a class; due dates.
- **Analytics:** class mastery heatmap by subject/standard; struggling-student
  flags from aggregated `struggles`.
- **Leaderboard:** class-scoped, effort-banded.
- Exports (CSV/PDF) for report cards.
Auth via `teacher` custom claim; rules already scaffolded in `firestore.rules`.

## Admin Panel (spec, P3 — internal web app)
Data root: `content/**`, `admin/**`, users. Auth via `admin` custom claim.
- **User management:** search parents/children, support actions, GDPR
  export/delete requests.
- **Content management:** author/publish lessons & units (writes to `content/`),
  asset manifest versioning, review workflow.
- **Game management:** enable/disable game types, tune reward tables via Remote
  Config.
- **Analytics & revenue:** DAU/WAU/retention, subscription funnels, cohort
  learning outcomes.
- **Notifications:** broadcast/segmented FCM campaigns.
- **Reports:** content coverage, safety audits.

## Data flow
Client repositories → Firestore (rules-enforced) → Cloud Functions for
privileged writes (leaderboards, aggregates, admin ops) → BigQuery export
(P3) for analytics dashboards. No child PII leaves the parent subtree except
non-identifying aggregate signals.
