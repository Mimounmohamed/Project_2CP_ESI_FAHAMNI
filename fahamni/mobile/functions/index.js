const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const { defineString, defineSecret } = require("firebase-functions/params");

admin.initializeApp();

// ── Config ────────────────────────────────────────────────────────────────────
const mailUser = defineString("MAIL_USER");
const mailPass = defineSecret("MAIL_PASS");

function getTransporter() {
  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: mailUser.value(),
      pass: mailPass.value(),
    },
  });
}

exports.updateUserEmail = onCall(
  { allowUnauthenticated: false, secrets: [mailPass] },
  async (request) => {
    const { newEmail } = request.data;
    const uid = request.auth?.uid;

    if (!uid || !newEmail) {
      throw new HttpsError("invalid-argument", "Missing fields.");
    }

    try {
      // Admin SDK can force-update email without deprecation issues
      await admin.auth().updateUser(uid, { email: newEmail });
      return { success: true };
    } catch (e) {
      throw new HttpsError("internal", e.message);
    }
  }
);

exports.updateUserPhone = onCall(
  { allowUnauthenticated: false },
  async (request) => {
    const { newPhone } = request.data;
    const uid = request.auth?.uid;

    if (!uid || !newPhone) {
      throw new HttpsError("invalid-argument", "Missing fields.");
    }

    try {
      await admin.auth().updateUser(uid, { phoneNumber: newPhone });
      return { success: true };
    } catch (e) {
      throw new HttpsError("internal", e.message);
    }
  }
);

// ── HTML Helpers ──────────────────────────────────────────────────────────────
function digitBoxes(digits) {
  return digits.map(d => `
    <td style="padding:0 5px;">
      <div style="width:40px;height:50px;background:#f8faff;border-bottom:3px solid #000080;
        display:inline-block;text-align:center;line-height:50px;vertical-align:middle;">
        <span style="font-size:24px;font-weight:900;color:#000080;font-family:Arial,sans-serif;">${d}</span>
      </div>
    </td>`).join('');
}

function emailWrapper(headerLeft, headerRight, body) {
  return `
<!DOCTYPE html><html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#f8f9fc;font-family:Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#f8f9fc;">
<tr><td align="center" style="padding:32px 16px;">
<table width="560" cellpadding="0" cellspacing="0"
  style="width:100%;max-width:560px;border-radius:4px;overflow:hidden;">
  <tr>
    <td style="background:#000080;width:38%;padding:24px 20px;vertical-align:bottom;">
      <div style="font-size:18px;font-weight:900;color:#fff;letter-spacing:-0.5px;">Fahamni</div>
      <div style="font-size:9px;color:rgba(255,255,255,0.45);letter-spacing:0.12em;
        text-transform:uppercase;margin-top:3px;">peaceful growth</div>
      ${headerLeft}
    </td>
    <td style="background:#000080;padding:24px 22px;vertical-align:middle;
      border-left:1px solid rgba(255,255,255,0.08);">
      <div style="width:32px;height:3px;background:rgba(255,255,255,0.4);
        border-radius:2px;margin-bottom:10px;"></div>
      ${headerRight}
    </td>
  </tr>
  <tr>
    <td colspan="2" style="padding:24px 22px;background:#fff;border-top:3px solid #000080;">
      ${body}
    </td>
  </tr>
  <tr>
    <td colspan="2" style="background:#f8f9fc;border-top:1px solid #f1f5f9;padding:12px 22px;">
      <table width="100%" cellpadding="0" cellspacing="0"><tr>
        <td><span style="font-size:12px;font-weight:800;color:#000080;">Fahamni</span></td>
        <td align="right"><span style="font-size:9px;color:#cbd5e1;">© 2026 · Automated</span></td>
      </tr></table>
    </td>
  </tr>
</table>
</td></tr></table>
</body></html>`;
}

// ── Existing: Reset Password ──────────────────────────────────────────────────
exports.resetPassword = onCall(
  { allowUnauthenticated: true, secrets: [mailPass] },
  async (request) => {
    const { email, newPassword } = request.data;

    if (!email || !newPassword) {
      throw new HttpsError("invalid-argument", "Missing fields.");
    }
    if (newPassword.length < 6) {
      throw new HttpsError("invalid-argument", "Password must be at least 6 characters.");
    }

    try {
      const user = await admin.auth().getUserByEmail(email);
      await admin.auth().updateUser(user.uid, { password: newPassword });
      return { success: true };
    } catch (e) {
      throw new HttpsError("internal", e.message);
    }
  }
);

// ── Send OTP Email ────────────────────────────────────────────────────────────
exports.sendOtpEmail = onCall(
  { allowUnauthenticated: true, secrets: [mailPass] },
  async (request) => {
    const { email, firstName, code, isReset } = request.data;

    if (!email || !code) {
      throw new HttpsError("invalid-argument", "Missing fields.");
    }

    const digits  = code.split('');
    const title   = isReset ? 'Reset your password'   : 'Verify your account';
    const sub     = isReset
      ? 'Your password reset code — valid 10 minutes'
      : 'Your one-time code is ready — valid 10 minutes';
    const greet   = isReset
      ? 'We received a request to reset your Fahamni password. Use the code below.'
      : `Hello <strong style="color:#0f172a;">${firstName}</strong>, use the code below to complete verification.`;
    const warn    = isReset
      ? 'If you did not request this, your account may be at risk. Do not share this code.'
      : 'Never share this code. Fahamni will never ask you for it.';
    const note    = isReset
      ? "Didn't request a reset? You can safely ignore this email."
      : "Didn't request this? You can safely ignore this email.";

    const headerLeft  = `<div style="font-size:72px;font-weight:900;color:rgba(255,255,255,0.06);line-height:1;margin-top:12px;">${isReset ? '!' : '01'}</div>`;
    const headerRight = `
      <div style="font-size:20px;font-weight:800;color:#fff;letter-spacing:-0.4px;line-height:1.25;">${title}</div>
      <div style="font-size:11px;color:rgba(255,255,255,0.5);margin-top:6px;line-height:1.5;">${sub}</div>`;
    const body = `
      <p style="font-size:13px;color:#64748b;margin:0 0 18px;line-height:1.6;">${greet}</p>
      <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:18px;">
        <tr>
          <td valign="top">
            <table cellpadding="0" cellspacing="0"><tr>${digitBoxes(digits)}</tr></table>
          </td>
          <td valign="top" style="padding-left:16px;padding-top:4px;">
            <div style="display:inline-block;background:#eff6ff;color:#1d4ed8;font-size:10px;
              font-weight:700;padding:3px 10px;border-radius:20px;">Valid 10 min</div>
            <div style="font-size:10px;color:#94a3b8;margin-top:4px;">Single use only</div>
          </td>
        </tr>
      </table>
      <div style="height:1px;background:#f1f5f9;margin:0 0 16px;"></div>
      <table width="100%" cellpadding="0" cellspacing="0"
        style="background:#fffbeb;border-left:3px solid #f59e0b;margin-bottom:12px;">
        <tr><td style="padding:10px 12px;">
          <p style="font-size:11px;color:#78350f;margin:0;line-height:1.5;">${warn}</p>
        </td></tr>
      </table>
      <p style="font-size:10px;color:#cbd5e1;margin:0;">${note}</p>`;

    try {
      await getTransporter().sendMail({
        from:    '"Fahamni" <' + mailUser.value() + '>',
        to:      email,
        subject: isReset ? 'Reset your Fahamni password' : 'Your Fahamni verification code',
        html:    emailWrapper(headerLeft, headerRight, body),
      });
      return { success: true };
    } catch (e) {
      throw new HttpsError("internal", e.message);
    }
  }
);

// ── Send Welcome Email ────────────────────────────────────────────────────────
exports.sendWelcomeEmail = onCall(
  { allowUnauthenticated: true, secrets: [mailPass] },
  async (request) => {
    const { email, firstName } = request.data;

    if (!email || !firstName) {
      throw new HttpsError("invalid-argument", "Missing fields.");
    }

    const headerLeft  = `<div style="font-size:72px;font-weight:900;color:rgba(255,255,255,0.06);line-height:1;margin-top:12px;">Hi</div>`;
    const headerRight = `
      <div style="font-size:20px;font-weight:800;color:#fff;line-height:1.25;">Welcome, ${firstName}!</div>
      <div style="font-size:11px;color:rgba(255,255,255,0.5);margin-top:6px;">Account verified — you are now in the community</div>`;
    const body = `
      <p style="font-size:13px;color:#64748b;margin:0 0 18px;line-height:1.6;">
        Your profile is all set. Here is how to get started on Fahamni.
      </p>
      <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:16px;">
        <tr>
          <td valign="top" style="padding-right:8px;">
            <div style="background:#f8faff;border-top:2px solid #000080;padding:12px 10px;">
              <div style="font-size:18px;font-weight:900;color:#e0e7ff;margin-bottom:6px;">01</div>
              <div style="font-size:11px;font-weight:700;color:#1e293b;">Complete profile</div>
              <div style="font-size:10px;color:#94a3b8;">Better matches</div>
            </div>
          </td>
          <td valign="top" style="padding:0 4px;">
            <div style="background:#f8faff;border-top:2px solid #000080;padding:12px 10px;">
              <div style="font-size:18px;font-weight:900;color:#e0e7ff;margin-bottom:6px;">02</div>
              <div style="font-size:11px;font-weight:700;color:#1e293b;">Find tutors</div>
              <div style="font-size:10px;color:#94a3b8;">Perfect match</div>
            </div>
          </td>
          <td valign="top" style="padding-left:8px;">
            <div style="background:#f8faff;border-top:2px solid #000080;padding:12px 10px;">
              <div style="font-size:18px;font-weight:900;color:#e0e7ff;margin-bottom:6px;">03</div>
              <div style="font-size:11px;font-weight:700;color:#1e293b;">Book session</div>
              <div style="font-size:10px;color:#94a3b8;">Start learning</div>
            </div>
          </td>
        </tr>
      </table>
      <p style="font-size:10px;color:#cbd5e1;margin:0;">Didn't create this account? Contact us immediately.</p>`;

    try {
      await getTransporter().sendMail({
        from:    '"Fahamni" <' + mailUser.value() + '>',
        to:      email,
        subject: `Welcome to Fahamni, ${firstName}!`,
        html:    emailWrapper(headerLeft, headerRight, body),
      });
      return { success: true };
    } catch (e) {
      throw new HttpsError("internal", e.message);
    }
  }
);

// ── Send Password Changed Email ───────────────────────────────────────────────
exports.sendPasswordChangedEmail = onCall(
  { allowUnauthenticated: true, secrets: [mailPass] },
  async (request) => {
    const { email } = request.data;

    if (!email) {
      throw new HttpsError("invalid-argument", "Missing email.");
    }

    const headerLeft  = `<div style="font-size:72px;font-weight:900;color:rgba(255,255,255,0.06);line-height:1;margin-top:12px;">!</div>`;
    const headerRight = `
      <div style="font-size:20px;font-weight:800;color:#fff;line-height:1.25;">Password changed</div>
      <div style="font-size:11px;color:rgba(255,255,255,0.5);margin-top:6px;">Security notification for your Fahamni account</div>`;
    const body = `
      <table width="100%" cellpadding="0" cellspacing="0"
        style="background:#f0fdf4;border-left:3px solid #10b981;margin-bottom:10px;">
        <tr><td style="padding:12px 14px;">
          <p style="font-size:12px;color:#065f46;margin:0;line-height:1.6;">
            Your password was changed successfully. You can now log in with your new credentials.
          </p>
        </td></tr>
      </table>
      <table width="100%" cellpadding="0" cellspacing="0"
        style="background:#fef2f2;border-left:3px solid #ef4444;margin-bottom:12px;">
        <tr><td style="padding:12px 14px;">
          <p style="font-size:11px;color:#991b1b;margin:0;line-height:1.5;">
            If you did not make this change, contact us immediately and secure your account.
          </p>
        </td></tr>
      </table>
      <p style="font-size:10px;color:#cbd5e1;margin:0;">This is an automated security notification.</p>`;

    try {
      await getTransporter().sendMail({
        from:    '"Fahamni" <' + mailUser.value() + '>',
        to:      email,
        subject: 'Your Fahamni password was changed',
        html:    emailWrapper(headerLeft, headerRight, body),
      });
      return { success: true };
    } catch (e) {
      throw new HttpsError("internal", e.message);
    }
  }
);

function normalizePath(path = "") {
  return path.replace(/^\/+/, "").replace(/\/+$/, "");
}

exports.teacherApi = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  const route = normalizePath(req.path);

  try {
    if (req.method === "POST" && route === "services") {
      const {
        tutorId,
        serviceName,
        description,
        domain,
        grade,
        subject,
        price,
        membersNumber,
        mode,
        sessionsNumber,
        sessionDuration,
        image,
      } = req.body || {};

      if (!tutorId || !serviceName || !subject) {
        res.status(400).json({ error: "Missing required fields." });
        return;
      }

      const docRef = admin.firestore().collection("services").doc();
      await docRef.set({
        service_id: docRef.id,
        tutor_id: tutorId,
        name: serviceName,
        description: description || "",
        area: domain || "",
        level: grade || "",
        subject,
        price: Number(price || 0),
        maxstudents: Number(membersNumber || 1),
        is_active: true,
        enrolled_num: 0,
        sessions_num: Number(sessionsNumber || 1),
        duration: Number(sessionDuration || 30),
        mode: mode || "online",
        picture: image || "",
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      res.status(201).json({ id: docRef.id });
      return;
    }

    if (req.method === "GET" && route === "requests") {
      const tutorId = req.query.tutorId;
      if (!tutorId) {
        res.status(400).json({ error: "Missing tutorId query parameter." });
        return;
      }

      const snapshot = await admin
        .firestore()
        .collection("quotes")
        .where("tutor_id", "==", tutorId)
        .get();

      const requests = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      res.status(200).json({ requests });
      return;
    }

    if (req.method === "POST" && route.startsWith("requests/") && route.endsWith("/respond")) {
      const parts = route.split("/");
      const requestId = parts[1];
      const { status, price, sessions, sessionDuration } = req.body || {};

      if (!requestId || !status) {
        res.status(400).json({ error: "Missing request id or status." });
        return;
      }

      const payload = {
        status,
        responded_at: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (price !== undefined) {
        payload.teacher_price = Number(price);
      }
      if (sessions !== undefined) {
        payload.teacher_sessions_num = Number(sessions);
      }
      if (sessionDuration !== undefined) {
        payload.teacher_session_duration = Number(sessionDuration);
      }

      const quoteRef = admin.firestore().collection("quotes").doc(requestId);
      const quoteSnap = await quoteRef.get();
      if (quoteSnap.exists) {
        await quoteRef.set(payload, { merge: true });
      } else {
        await admin.firestore().collection("quote_requests").doc(requestId).set(payload, { merge: true });
      }

      res.status(200).json({ success: true });
      return;
    }

    if (req.method === "POST" && route === "sessions") {
      const {
        tutorId,
        serviceId,
        studentIds,
        dateISO,
        startISO,
        endISO,
        modality,
        type,
        onlineLink,
      } = req.body || {};

      if (!tutorId || !serviceId || !dateISO || !startISO || !endISO) {
        res.status(400).json({ error: "Missing session fields." });
        return;
      }

      const docRef = admin.firestore().collection("sessions").doc();
      await docRef.set({
        session_id: docRef.id,
        tutor_id: tutorId,
        service_id: serviceId,
        student_ids: Array.isArray(studentIds) ? studentIds : [],
        status: "Planned",
        type: type || "regular",
        modality: modality || "online",
        online_link: onlineLink || "",
        date: admin.firestore.Timestamp.fromDate(new Date(dateISO)),
        start_time: admin.firestore.Timestamp.fromDate(new Date(startISO)),
        end_time: admin.firestore.Timestamp.fromDate(new Date(endISO)),
      });

      res.status(201).json({ id: docRef.id });
      return;
    }

    if (req.method === "POST" && route === "resources") {
      const {
        tutorId,
        sessionId,
        name,
        resourceType,
        urlOrPath,
        subject,
        level,
      } = req.body || {};

      if (!tutorId || !sessionId || !name) {
        res.status(400).json({ error: "Missing resource fields." });
        return;
      }

      const docRef = admin.firestore().collection("resources").doc();
      const isLink = (resourceType || "").toLowerCase() === "link";
      await docRef.set({
        resource_id: docRef.id,
        tutor_id: tutorId,
        session_id: sessionId,
        title: name,
        subject: subject || "",
        level: level || "",
        description: "",
        content_type: isLink ? "media" : "document",
        access_level: "session",
        allowed_users: [],
        is_public: false,
        added_at: admin.firestore.FieldValue.serverTimestamp(),
        media_url: isLink ? (urlOrPath || "") : "",
        file_url: isLink ? "" : (urlOrPath || ""),
        platform: isLink ? "url" : "",
        doc_type: isLink ? "" : "file",
      });

      res.status(201).json({ id: docRef.id });
      return;
    }

    res.status(404).json({ error: "Route not found." });
  } catch (error) {
    res.status(500).json({ error: error.message || "Internal error." });
  }
});

function requireAuth(request) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  return request.auth.uid;
}

function assertString(value, field, { min = 1 } = {}) {
  if (typeof value !== "string" || value.trim().length < min) {
    throw new HttpsError("invalid-argument", `${field} is invalid.`);
  }
  return value.trim();
}

function assertNumber(value, field, { min = 0 } = {}) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < min) {
    throw new HttpsError("invalid-argument", `${field} is invalid.`);
  }
  return parsed;
}

function assertEnum(value, field, accepted) {
  if (!accepted.includes(value)) {
    throw new HttpsError("invalid-argument", `${field} is invalid.`);
  }
  return value;
}

async function verifyTutor(uid) {
  const tutorRef = admin.firestore().collection("tutors").doc(uid);
  const tutorSnap = await tutorRef.get();
  if (!tutorSnap.exists) {
    throw new HttpsError("permission-denied", "Teacher profile not found.");
  }
  return tutorRef;
}

exports.createTeacherService = onCall(async (request) => {
  const tutorId = requireAuth(request);
  await verifyTutor(tutorId);

  const payload = request.data || {};
  const now = admin.firestore.FieldValue.serverTimestamp();
  const serviceRef = admin.firestore().collection("services").doc();

  const service = {
    service_id: serviceRef.id,
    tutor_id: tutorId,
    name: assertString(payload.name, "name"),
    description: assertString(payload.description, "description"),
    area: assertString(payload.domain, "domain"),
    level: assertString(payload.grade, "grade"),
    subject: assertString(payload.subject || payload.domain, "subject"),
    mode: assertEnum(payload.mode, "mode", ["Online", "Onsite", "Hybrid"]),
    price: assertNumber(payload.price, "price", { min: 0 }),
    duration: assertNumber(payload.duration, "duration", { min: 15 }),
    sessions_num: assertNumber(payload.sessionsCount, "sessionsCount", { min: 1 }),
    maxstudents: assertNumber(payload.membersCount, "membersCount", { min: 1 }),
    enrolled_num: 0,
    is_active: payload.isActive !== false,
    picture: typeof payload.picture === "string" ? payload.picture : "",
    created_at: now,
    updated_at: now,
  };

  await serviceRef.set(service);
  return { success: true, serviceId: serviceRef.id, service };
});

exports.getTeacherRequests = onCall(async (request) => {
  const tutorId = requireAuth(request);
  await verifyTutor(tutorId);

  const collections = ["quote_requests", "quotes"];
  const results = [];

  for (const collectionName of collections) {
    const snap = await admin.firestore()
      .collection(collectionName)
      .where("tutor_id", "==", tutorId)
      .get();

    snap.forEach((doc) => {
      const data = doc.data();
      if ((data.status || "pending") === "pending") {
        results.push({
          id: doc.id,
          source: collectionName,
          ...data,
        });
      }
    });
  }

  results.sort((a, b) => {
    const aTime = a.created_at && a.created_at.toMillis ? a.created_at.toMillis() : 0;
    const bTime = b.created_at && b.created_at.toMillis ? b.created_at.toMillis() : 0;
    return bTime - aTime;
  });

  return { success: true, requests: results };
});

exports.respondToQuoteRequest = onCall(async (request) => {
  const tutorId = requireAuth(request);
  await verifyTutor(tutorId);

  const payload = request.data || {};
  const quoteId = assertString(payload.quoteId, "quoteId");
  const status = assertEnum(payload.status, "status", ["accepted", "rejected"]);
  const collections = ["quote_requests", "quotes"];

  let targetRef = null;
  let quoteData = null;

  for (const collectionName of collections) {
    const ref = admin.firestore().collection(collectionName).doc(quoteId);
    const snap = await ref.get();
    if (snap.exists) {
      targetRef = ref;
      quoteData = snap.data();
      break;
    }
  }

  if (!targetRef || !quoteData) {
    throw new HttpsError("not-found", "Quote request not found.");
  }
  if (quoteData.tutor_id !== tutorId) {
    throw new HttpsError("permission-denied", "You cannot manage this request.");
  }

  const update = {
    status,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (status === "accepted") {
    update.response_price = assertString(payload.priceLabel || "", "priceLabel");
    update.response_sessions_count = assertNumber(
      payload.sessionsCount,
      "sessionsCount",
      { min: 1 },
    );
  }

  await targetRef.update(update);
  return { success: true, quoteId, status };
});

exports.createTeacherSession = onCall(async (request) => {
  const tutorId = requireAuth(request);
  await verifyTutor(tutorId);

  const payload = request.data || {};
  const sessionRef = admin.firestore().collection("sessions").doc();
  const date = new Date(assertString(payload.date, "date"));
  const startTime = new Date(assertString(payload.startTime, "startTime"));
  const duration = assertNumber(payload.durationMinutes, "durationMinutes", { min: 15 });
  const endTime = new Date(startTime.getTime() + duration * 60000);

  const session = {
    session_id: sessionRef.id,
    service_id: typeof payload.serviceId === "string" ? payload.serviceId : "",
    tutor_id: tutorId,
    student_ids: Array.isArray(payload.studentIds) ? payload.studentIds : [],
    status: "Planned",
    type: typeof payload.type === "string" ? payload.type : "Session",
    modality: assertEnum(payload.sessionType, "sessionType", ["Online", "Onsite", "Hybrid"]),
    meeting_link: typeof payload.meetingLink === "string" ? payload.meetingLink : "",
    notes: typeof payload.notes === "string" ? payload.notes : "",
    date: admin.firestore.Timestamp.fromDate(date),
    start_time: admin.firestore.Timestamp.fromDate(startTime),
    end_time: admin.firestore.Timestamp.fromDate(endTime),
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  await sessionRef.set(session);
  return { success: true, sessionId: sessionRef.id, session };
});

exports.rescheduleTeacherSession = onCall(async (request) => {
  const tutorId = requireAuth(request);
  await verifyTutor(tutorId);

  const payload = request.data || {};
  const sessionId = assertString(payload.sessionId, "sessionId");
  const sessionRef = admin.firestore().collection("sessions").doc(sessionId);
  const sessionSnap = await sessionRef.get();

  if (!sessionSnap.exists) {
    throw new HttpsError("not-found", "Session not found.");
  }
  if (sessionSnap.data().tutor_id !== tutorId) {
    throw new HttpsError("permission-denied", "You cannot update this session.");
  }

  const date = new Date(assertString(payload.date, "date"));
  const startTime = new Date(assertString(payload.startTime, "startTime"));
  const duration = assertNumber(payload.durationMinutes, "durationMinutes", { min: 15 });
  const endTime = new Date(startTime.getTime() + duration * 60000);

  await sessionRef.update({
    date: admin.firestore.Timestamp.fromDate(date),
    start_time: admin.firestore.Timestamp.fromDate(startTime),
    end_time: admin.firestore.Timestamp.fromDate(endTime),
    modality: assertEnum(payload.sessionType, "sessionType", ["Online", "Onsite", "Hybrid"]),
    meeting_link: typeof payload.meetingLink === "string" ? payload.meetingLink : "",
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, sessionId };
});

exports.addTeacherResource = onCall(async (request) => {
  const tutorId = requireAuth(request);
  await verifyTutor(tutorId);

  const payload = request.data || {};
  const resourceRef = admin.firestore().collection("resources").doc();
  const type = assertEnum(payload.type, "type", ["document", "link"]);

  const resource = {
    resource_id: resourceRef.id,
    tutor_id: tutorId,
    session_id: typeof payload.sessionId === "string" ? payload.sessionId : "",
    service_id: typeof payload.serviceId === "string" ? payload.serviceId : "",
    student_id: typeof payload.studentId === "string" ? payload.studentId : "",
    title: assertString(payload.name, "name"),
    subject: typeof payload.subject === "string" ? payload.subject : "",
    level: typeof payload.level === "string" ? payload.level : "",
    description: typeof payload.description === "string" ? payload.description : "",
    content_type: type,
    access_level: "request",
    allowed_users: Array.isArray(payload.allowedUsers) ? payload.allowedUsers : [],
    is_public: false,
    file_url: type === "document" ? assertString(payload.filePath || "", "filePath") : "",
    file_name: type === "document" && typeof payload.filePath === "string"
      ? payload.filePath.split("/").pop()
      : "",
    link_url: type === "link" ? assertString(payload.link || "", "link") : "",
    added_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  await resourceRef.set(resource);
  return { success: true, resourceId: resourceRef.id, resource };
});

// ── Send Estimate ──────────────────────────────────────────────────────────────
exports.sendEstimate = onCall(
  { allowUnauthenticated: false, secrets: [mailPass] },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Login required.");

    const {
      pdfBase64,
      recipientEmail,
      studentName,
      teacherName,
      invoiceNumber,
      subject,
      invoiceData,
    } = request.data;

    if (!pdfBase64 || !recipientEmail || !invoiceNumber) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }

    const pdfBuffer = Buffer.from(pdfBase64, "base64");

    const transporter = getTransporter();
    await transporter.sendMail({
      from: `"Fahamni" <${mailUser.value()}>`,
      to: recipientEmail,
      subject: `Your Estimate ${invoiceNumber} — ${subject ?? "Tutoring Session"}`,
      html: `
        <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto">
          <h2 style="color:#000080">Fahamni Estimate</h2>
          <p>Dear <strong>${studentName ?? "Student"}</strong>,</p>
          <p>
            <strong>${teacherName ?? "Your teacher"}</strong> has sent you an estimate
            for your tutoring sessions. Please find the PDF attached.
          </p>
          <p style="color:#6B7280;font-size:13px">
            Reference: <strong>${invoiceNumber}</strong>
          </p>
          <hr style="border:none;border-top:1px solid #E5E7EB;margin:24px 0"/>
          <p style="color:#9CA3AF;font-size:12px">
            Fahamni — Mobile Tutoring Application<br/>
            www.fahamni.app | contact@fahamni.app
          </p>
        </div>
      `,
      attachments: [
        {
          filename: `${invoiceNumber}.pdf`,
          content: pdfBuffer,
          contentType: "application/pdf",
        },
      ],
    });

    await admin.firestore().collection("estimates").add({
      ...invoiceData,
      sender_uid: uid,
      status: "sent",
      sent_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, invoiceNumber };
  },
);
