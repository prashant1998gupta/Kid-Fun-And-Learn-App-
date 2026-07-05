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
const functionsV1 = require("firebase-functions/v1");
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

  const rawBeforeCode = beforeGroup?.code || null;
  const rawAfterCode = afterGroup?.code || null;
  const beforeCode = validGroupCode(rawBeforeCode) ? rawBeforeCode : null;
  const afterCode = validGroupCode(rawAfterCode) ? rawAfterCode : null;

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
    // BulkWriter transparently chunks large boards beyond Firestore's
    // 500-operation batch limit and retries transient failures.
    const writer = db.bulkWriter();
    for (const entry of entries.docs) {
      // Archive under leaderboards/{code}/archive/{weekId}/entries/{uid}
      const archiveRef = board
        .collection("archive")
        .doc(entry.data().weekId || "unknown")
        .collection("entries")
        .doc(entry.id);
      writer.set(archiveRef, entry.data());
      writer.delete(entry.ref);
    }
    await writer.close();
  }
});

function validGroupCode(value) {
  return typeof value === "string" && /^[A-Z0-9]{6,12}$/.test(value);
}

/** Remove all parent-owned cloud data after Firebase Auth account deletion. */
exports.cleanupDeletedParent = functionsV1.auth.user().onDelete(async (user) => {
  const parentRef = db.doc(`parents/${user.uid}`);
  const parent = await parentRef.get();
  const groupCode = parent.data()?.friendGroup?.code;
  if (validGroupCode(groupCode)) {
    await db
      .doc(`leaderboards/${groupCode}/entries/${user.uid}`)
      .delete()
      .catch(() => {});
  }
  await db.recursiveDelete(parentRef);
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
