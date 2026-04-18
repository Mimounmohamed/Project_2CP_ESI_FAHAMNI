const { onCall, HttpsError } = require("firebase-functions/v2/https");
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