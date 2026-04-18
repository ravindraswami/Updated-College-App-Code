import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ─────────────────────────────────────────────────────────────
// HELPER: Send to single token
// ─────────────────────────────────────────────────────────────
async function sendToToken(
  token: string, title: string, body: string, data: Record<string, string>
): Promise<void> {
  if (!token) return;
  try {
    await messaging.send({
      token,
      notification: { title, body },
      data,
      android: {
        priority: "high",
        notification: { channelId: "smart_erp_channel", clickAction: "FLUTTER_NOTIFICATION_CLICK" },
      },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    });
  } catch (err: unknown) {
    if (err instanceof Error &&
        (err.message.includes("registration-token-not-registered") ||
         err.message.includes("invalid-registration-token"))) {
      // Stale token — clear it
      const snap = await db.collection("users").where("fcmToken", "==", token).get();
      snap.docs.forEach((doc) => doc.ref.update({ fcmToken: "" }));
    }
  }
}

// ─────────────────────────────────────────────────────────────
// HELPER: Get tokens for all users with a specific role
// ─────────────────────────────────────────────────────────────
async function getTokensForRole(role: string): Promise<string[]> {
  const snap = await db.collection("users")
    .where("role", "==", role)
    .where("fcmToken", "!=", "")
    .get();
  return snap.docs.map((d) => d.data().fcmToken as string).filter(Boolean);
}

// ─────────────────────────────────────────────────────────────
// HELPER: Get tokens for all users with a specific role (batch)
// ─────────────────────────────────────────────────────────────
async function getAllStudentTokens(): Promise<string[]> {
  return getTokensForRole("student");
}

// ─────────────────────────────────────────────────────────────
// HELPER: Chunk array
// ─────────────────────────────────────────────────────────────
function chunkArray<T>(arr: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < arr.length; i += size) chunks.push(arr.slice(i, i + size));
  return chunks;
}

// ─────────────────────────────────────────────────────────────
// HELPER: Send to multiple tokens (batch)
// ─────────────────────────────────────────────────────────────
async function sendToTokens(
  tokens: string[], title: string, body: string, data: Record<string, string>
): Promise<void> {
  const batches = chunkArray(tokens, 500);
  for (const batch of batches) {
    await messaging.sendEachForMulticast({
      tokens: batch,
      notification: { title, body },
      data,
      android: {
        priority: "high",
        notification: { channelId: "smart_erp_channel", clickAction: "FLUTTER_NOTIFICATION_CLICK" },
      },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    });
  }
}

// ═════════════════════════════════════════════════════════════
// EXAM TRIGGERS
// ═════════════════════════════════════════════════════════════

export const onNewExam = functions.firestore
  .document("exams/{examId}")
  .onCreate(async (snap, context) => {
    const exam = snap.data();
    if (!exam) return;
    const tokens = await getAllStudentTokens();
    if (!tokens.length) return;
    await sendToTokens(tokens, "📝 New Exam Available!", `${exam.title} — ${exam.subject}`, {
      type: "new_exam", examId: context.params.examId, screen: "exam_list",
    });
  });

export const onNewNote = functions.firestore
  .document("notes/{noteId}")
  .onCreate(async (snap, context) => {
    const note = snap.data();
    if (!note) return;
    const tokens = await getAllStudentTokens();
    if (!tokens.length) return;
    await sendToTokens(tokens, "📚 New Study Material!", `${note.title} — ${note.subject}`, {
      type: "new_note", noteId: context.params.noteId, screen: "notes",
    });
  });

export const onResultPublished = functions.firestore
  .document("exams/{examId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return;
    if (before.isResultPublished === true || after.isResultPublished !== true) return;
    const examId = context.params.examId;
    const enrollments = await db.collection("enrollments")
      .where("examId", "==", examId).where("isPaid", "==", true).get();
    const studentIds = enrollments.docs.map((d) => d.data().studentId as string);
    if (!studentIds.length) return;
    const tokens: string[] = [];
    for (const chunk of chunkArray(studentIds, 30)) {
      const snap = await db.collection("users")
        .where(admin.firestore.FieldPath.documentId(), "in", chunk)
        .where("fcmToken", "!=", "").get();
      snap.docs.forEach((d) => { const t = d.data().fcmToken; if (t) tokens.push(t); });
    }
    if (!tokens.length) return;
    await sendToTokens(tokens, "🎉 Result Published!", `Your result for "${after.title}" is now available.`, {
      type: "result_published", examId, screen: "my_results",
    });
  });

export const onReExamGranted = functions.firestore
  .document("enrollments/{enrollmentId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return;
    if (before.reExamGranted === true || after.reExamGranted !== true) return;
    const studentDoc = await db.collection("users").doc(after.studentId as string).get();
    const token = studentDoc.data()?.fcmToken as string;
    if (!token) return;
    const examDoc = await db.collection("exams").doc(after.examId as string).get();
    const title = examDoc.data()?.title ?? "an exam";
    await sendToToken(token, "🔁 Re-exam Granted!", `You can now re-attempt "${title}".`, {
      type: "re_exam_granted", examId: after.examId as string, screen: "exam_list",
    });
  });

// ═════════════════════════════════════════════════════════════
// BONAFIDE TRIGGERS
// ═════════════════════════════════════════════════════════════

// When student submits bonafide → notify all Technical Staff
export const onNewBonafide = functions.firestore
  .document("bonafide_requests/{bonafideId}")
  .onCreate(async (snap) => {
    const req = snap.data();
    if (!req) return;
    // Notify all technical staff
    const tokens = await getTokensForRole("technical");
    if (tokens.length) {
      await sendToTokens(
        tokens,
        "📋 New Bonafide Request",
        `${req.studentName} has submitted a bonafide request.`,
        { type: "new_bonafide", screen: "bonafide_requests" }
      );
    }
  });

// When bonafide is approved → notify student
export const onBonafideApproved = functions.firestore
  .document("bonafide_requests/{bonafideId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return;
    // approved: pending_approval → approved
    if (before.status !== "pending_approval" || after.status !== "approved") return;
    const studentDoc = await db.collection("users").doc(after.studentId as string).get();
    const token = studentDoc.data()?.fcmToken as string;
    if (!token) return;
    await sendToToken(
      token,
      "✅ Bonafide Certificate Ready!",
      "Your bonafide certificate has been approved and is ready to download.",
      { type: "bonafide_approved", screen: "bonafide" }
    );
  });

// When payment done → notify Technical Staff that bonafide needs approval
export const onBonafidePaid = functions.firestore
  .document("bonafide_requests/{bonafideId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return;
    // pending_payment → pending_approval (payment done)
    if (before.status !== "pending_payment" || after.status !== "pending_approval") return;
    const tokens = await getTokensForRole("technical");
    if (!tokens.length) return;
    await sendToTokens(
      tokens,
      "💰 Bonafide Payment Received",
      `${after.studentName}'s bonafide payment confirmed. Please review and approve.`,
      { type: "bonafide_paid", screen: "bonafide_requests" }
    );
  });

// ═════════════════════════════════════════════════════════════
// SCHOLARSHIP TRIGGERS
// ═════════════════════════════════════════════════════════════

// When student submits scholarship → notify CC (coordinator)
export const onNewScholarship = functions.firestore
  .document("scholarship_requests/{scholarshipId}")
  .onCreate(async (snap) => {
    const req = snap.data();
    if (!req) return;
    // Notify the class coordinator
    const coordinatorId = req.coordinatorId as string;
    if (coordinatorId) {
      const coordDoc = await db.collection("users").doc(coordinatorId).get();
      const token = coordDoc.data()?.fcmToken as string;
      if (token) {
        await sendToToken(
          token,
          "📝 New Scholarship Application",
          `${req.studentName} has submitted a scholarship application for your review.`,
          { type: "new_scholarship", screen: "scholarship_review" }
        );
      }
    }
  });

// When CC approves scholarship → notify Technical Staff
export const onScholarshipCcApproved = functions.firestore
  .document("scholarship_requests/{scholarshipId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return;
    // pending_cc → pending_technical
    if (before.status !== "pending_cc" || after.status !== "pending_technical") return;
    const tokens = await getTokensForRole("technical");
    if (!tokens.length) return;
    await sendToTokens(
      tokens,
      "📋 Scholarship Forwarded to You",
      `${after.studentName}'s scholarship application has been approved by CC and needs your review.`,
      { type: "scholarship_pending_technical", screen: "scholarship_review" }
    );
  });

// When Technical approves/rejects scholarship → notify student
export const onScholarshipTechnicalDecision = functions.firestore
  .document("scholarship_requests/{scholarshipId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return;
    if (before.status !== "pending_technical") return;
    if (after.status !== "approved" && after.status !== "rejected") return;
    const studentDoc = await db.collection("users").doc(after.studentId as string).get();
    const token = studentDoc.data()?.fcmToken as string;
    if (!token) return;
    const isApproved = after.status === "approved";
    await sendToToken(
      token,
      isApproved ? "✅ Scholarship Approved!" : "❌ Scholarship Application Update",
      isApproved
        ? `Your ${after.scholarshipType} scholarship application has been approved.`
        : `Your ${after.scholarshipType} scholarship application was not approved. Check remarks.`,
      { type: "scholarship_decision", status: after.status as string, screen: "my_scholarships" }
    );
  });

// When CC rejects scholarship → notify student
export const onScholarshipCcRejected = functions.firestore
  .document("scholarship_requests/{scholarshipId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return;
    if (before.status !== "pending_cc" || after.status !== "cc_rejected") return;
    const studentDoc = await db.collection("users").doc(after.studentId as string).get();
    const token = studentDoc.data()?.fcmToken as string;
    if (!token) return;
    await sendToToken(
      token,
      "❌ Scholarship Application Returned",
      `Your ${after.scholarshipType} scholarship application has been returned by the coordinator. Check remarks.`,
      { type: "scholarship_decision", status: "cc_rejected", screen: "my_scholarships" }
    );
  });