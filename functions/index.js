/**
 * KidVerse Cloud Functions.
 *
 * Friends-leaderboard split of responsibility (see firebase/firestore.rules):
 * - Clients write their OWN weekly score onto `parents/{uid}.friendGroup`
 *   (a path the owner may write). They never touch the shared board.
 * - This aggregator fans each family's `friendGroup` into
 *   `leaderboards/{code}/entries/{uid}` using the Admin SDK, which bypasses
 *   security rules — so the shared board stays tamper-proof and non-PII.
 * - Clients only READ `leaderboards/{code}/entries` (authed read allowed).
 *
 * A weekly scheduled job archives and resets the boards so competition is
 * fresh each week.
 */
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

/**
 * Mirror a family's self-reported score into the shared board entry.
 * Handles group changes (moves/removes the old entry) and validates shape.
 */
exports.aggregateFriendScore = onDocumentWritten("parents/{uid}", async (event) => {
  const uid = event.params.uid;
  const before = event.data?.before?.data() || {};
  const after = event.data?.after?.data() || {};

  const beforeGroup = before.friendGroup || null;
  const afterGroup = after.friendGroup || null;

  const beforeCode = beforeGroup?.code || null;
  const afterCode = afterGroup?.code || null;

  // If the family left/changed groups, remove their stale entry.
  if (beforeCode && beforeCode !== afterCode) {
    await db.doc(`leaderboards/${beforeCode}/entries/${uid}`).delete().catch(() => {});
  }

  if (!afterCode) return;

  // Sanitize: only non-PII, bounded fields reach the shared board.
  const displayName = String(afterGroup.displayName || "Player").slice(0, 24);
  const avatarSeed = String(afterGroup.avatarSeed || "").slice(0, 40);
  const score = Math.max(0, Math.min(100000, Number(afterGroup.score) || 0));

  await db.doc(`leaderboards/${afterCode}/entries/${uid}`).set(
    {
      displayName,
      avatarSeed,
      score,
      weekId: currentWeekId(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
});

/**
 * Every Monday 00:05 UTC: archive last week's boards and clear entries so the
 * new week starts from zero. Archives are kept for parent history.
 */
exports.resetWeeklyBoards = onSchedule("5 0 * * 1", async () => {
  const boards = await db.collection("leaderboards").listDocuments();
  for (const board of boards) {
    const entries = await board.collection("entries").get();
    const batch = db.batch();
    for (const entry of entries.docs) {
      // Archive under leaderboards/{code}/archive/{weekId}/entries/{uid}
      const archiveRef = board
        .collection("archive")
        .doc(entry.data().weekId || "unknown")
        .collection("entries")
        .doc(entry.id);
      batch.set(archiveRef, entry.data());
      batch.delete(entry.ref);
    }
    await batch.commit();
  }
});

/** ISO-week id like "2026-W27" — stable key for weekly boards. */
function currentWeekId() {
  const now = new Date();
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const dayNum = (d.getUTCDay() + 6) % 7; // Mon=0
  d.setUTCDate(d.getUTCDate() - dayNum + 3); // nearest Thursday
  const firstThursday = new Date(Date.UTC(d.getUTCFullYear(), 0, 4));
  const week =
    1 +
    Math.round(
      ((d - firstThursday) / 86400000 - 3 + ((firstThursday.getUTCDay() + 6) % 7)) / 7
    );
  return `${d.getUTCFullYear()}-W${String(week).padStart(2, "0")}`;
}
