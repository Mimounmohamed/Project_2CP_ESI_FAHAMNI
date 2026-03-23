import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailOtpService {
  static const _resendApiKey = 're_Kt6BAQMX_EE3exnYUTqm3Xpqd92vA7fnJ';
  final _db = FirebaseFirestore.instance;

  // ── Code generation ───────────────────────────────────────────────────────

  String _generateCode() {
    final rng = Random.secure();
    return (100000 + rng.nextInt(900000)).toString();
  }


  Future<void> sendOtp({
    required String email,
    required String firstName,
  }) async {
    final code   = _generateCode();
    final expiry = DateTime.now().add(const Duration(minutes: 10));

    await _db.collection('email_otps').doc(email).set({
      'code':      code,
      'expiresAt': Timestamp.fromDate(expiry),
      'verified':  false,
    });

    final digits = code.split('');
    final response = await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $_resendApiKey',
        'Content-Type':  'application/json',
      },
      body: jsonEncode({
        'from':    'Fahamni <onboarding@resend.dev>',
        'to':      [email],
        'subject': 'Your Fahamni verification code',
        'html':    _buildOtpHtml(firstName: firstName, digits: digits, isReset: false),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to send email: ${response.statusCode} — ${response.body}';
    }
  }

  Future<void> sendPasswordResetOtp({required String email}) async {
    final code   = _generateCode();
    final expiry = DateTime.now().add(const Duration(minutes: 10));

    await _db.collection('email_otps').doc(email).set({
      'code':      code,
      'expiresAt': Timestamp.fromDate(expiry),
      'type':      'password_reset',
      'verified':  false,
    });

    final digits = code.split('');
    final response = await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $_resendApiKey',
        'Content-Type':  'application/json',
      },
      body: jsonEncode({
        'from':    'Fahamni <onboarding@resend.dev>',
        'to':      [email],
        'subject': 'Reset your Fahamni password',
        'html':    _buildOtpHtml(firstName: '', digits: digits, isReset: true),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to send email: ${response.statusCode} — ${response.body}';
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────

  Future<void> verifyOtp({
    required String email,
    required String code,
  }) async {
    final doc = await _db.collection('email_otps').doc(email).get();

    if (!doc.exists) {
      throw 'No verification code found. Please request a new one.';
    }

    final data       = doc.data()!;
    final storedCode = data['code'] as String;
    final expiresAt  = (data['expiresAt'] as Timestamp).toDate();

    if (DateTime.now().isAfter(expiresAt)) {
      await _db.collection('email_otps').doc(email).delete();
      throw 'Code has expired. Please request a new one.';
    }

    if (storedCode != code) {
      throw 'Incorrect code. Please try again.';
    }

    await _db.collection('email_otps').doc(email).delete();
  }

  // ── Send welcome email ────────────────────────────────────────────────────

  Future<void> sendWelcomeEmail({
    required String email,
    required String firstName,
  }) async {
    await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $_resendApiKey',
        'Content-Type':  'application/json',
      },
      body: jsonEncode({
        'from':    'Fahamni <onboarding@resend.dev>',
        'to':      [email],
        'subject': 'Welcome to Fahamni, $firstName!',
        'html':    _buildWelcomeHtml(firstName),
      }),
    );
  }

  // ── Send password changed notification ───────────────────────────────────

  Future<void> sendPasswordChangedEmail({required String email}) async {
    await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $_resendApiKey',
        'Content-Type':  'application/json',
      },
      body: jsonEncode({
        'from':    'Fahamni <onboarding@resend.dev>',
        'to':      [email],
        'subject': 'Your Fahamni password was changed',
        'html':    _buildPasswordChangedHtml(),
      }),
    );
  }

  // ── HTML builders ─────────────────────────────────────────────────────────

  String _digitBoxes(List<String> digits) => digits.map((d) => '''
    <td style="padding:0 5px;">
      <div style="width:40px;height:50px;background:#f8faff;border-bottom:3px solid #000080;
        display:inline-block;text-align:center;line-height:50px;vertical-align:middle;">
        <span style="font-size:24px;font-weight:900;color:#000080;font-family:Arial,sans-serif;">$d</span>
      </div>
    </td>''').join('');

  String _digitBoxesDark(List<String> digits) => digits.map((d) => '''
    <td style="padding:0 5px;">
      <div style="width:40px;height:50px;background:#161b22;border-bottom:3px solid #6366f1;
        display:inline-block;text-align:center;line-height:50px;vertical-align:middle;">
        <span style="font-size:24px;font-weight:900;color:#818cf8;font-family:Arial,sans-serif;">$d</span>
      </div>
    </td>''').join('');

  // ── OTP email (both registration + reset) ────────────────────────────────

  String _buildOtpHtml({
    required String firstName,
    required List<String> digits,
    required bool isReset,
  }) {
    final title  = isReset ? 'Reset your password' : 'Verify your account';
    final sub    = isReset
        ? 'Your password reset code — valid 10 minutes'
        : 'Your one-time code is ready — valid 10 minutes';
    final num    = isReset ? '!' : '01';
    final greet  = isReset
        ? 'We received a request to reset your Fahamni password. Use the code below.'
        : 'Hello <strong style="color:#0f172a;">$firstName</strong>, use the code below to complete verification.';
    final warnLight = isReset
        ? 'If you did not request this, your account may be at risk. Do not share this code.'
        : 'Never share this code. Fahamni will never ask you for it.';
    final warnDark = warnLight;
    final noteLight = isReset
        ? "Didn't request a reset? You can safely ignore this email."
        : "Didn't request this? You can safely ignore this email.";
    final labelLight = isReset ? 'PASSWORD RESET CODE' : 'VERIFICATION CODE';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<meta name="color-scheme" content="light dark">
<meta name="supported-color-schemes" content="light dark">
<style>
  @media only screen and (max-width:600px){
    .outer{padding:16px 8px!important;}
    .top{display:block!important;}
    .left{width:100%!important;display:flex!important;flex-direction:row!important;
          align-items:center!important;justify-content:space-between!important;
          padding:16px 18px!important;}
    .num{display:none!important;}
    .right{padding:16px 18px!important;border-left:none!important;
           border-top:1px solid rgba(255,255,255,0.08)!important;}
    .htitle{font-size:17px!important;}
    .body{padding:18px!important;}
    .code-row{display:block!important;}
    .meta{margin-top:10px!important;}
    .foot-inner{display:block!important;text-align:center!important;}
  }
  @media (prefers-color-scheme:dark){
    .email-bg{background:#0d1117!important;}
    .left{background:#161b22!important;}
    .right{background:#161b22!important;border-left-color:#30363d!important;}
    .bar{background:#6366f1!important;}
    .htitle{color:#e6edf3!important;}
    .hsub{color:rgba(230,237,243,0.4)!important;}
    .body-bg{background:#0d1117!important;border-top-color:#6366f1!important;}
    .greet{color:#8b949e!important;}
    .greet strong{color:#e6edf3!important;}
    .digit-light{display:none!important;}
    .digit-dark{display:table-cell!important;}
    .badge{background:rgba(99,102,241,0.15)!important;color:#818cf8!important;
           border:1px solid rgba(99,102,241,0.3)!important;}
    .exp{color:#484f58!important;}
    .divider{background:#21262d!important;}
    .warn-box{background:rgba(245,158,11,0.08)!important;border-left-color:#f59e0b!important;}
    .warn-txt{color:rgba(245,158,11,0.85)!important;}
    .note{color:#484f58!important;}
    .foot-bg{background:#0a0f1e!important;border-top-color:#21262d!important;}
    .foot-l{color:#8b949e!important;}
    .foot-r{color:#30363d!important;}
    .logo-txt{color:#e6edf3!important;}
    .tag-txt{color:rgba(230,237,243,0.3)!important;}
    .num-txt{color:rgba(99,102,241,0.06)!important;}
  }
</style>
</head>
<body style="margin:0;padding:0;background:#f8f9fc;font-family:Arial,sans-serif;">
<table class="email-bg" width="100%" cellpadding="0" cellspacing="0"
  style="background:#f8f9fc;">
<tr><td class="outer" align="center" style="padding:32px 16px;">
<table width="560" cellpadding="0" cellspacing="0"
  style="width:100%;max-width:560px;overflow:hidden;border-radius:4px;">

  <tr class="top" style="display:table-row;">
    <td class="left" valign="bottom"
      style="background:#000080;width:38%;padding:24px 20px;vertical-align:bottom;position:relative;overflow:hidden;">
      <div>
        <div class="logo-txt" style="font-size:18px;font-weight:900;color:#fff;letter-spacing:-0.5px;">Fahamni</div>
        <div class="tag-txt" style="font-size:9px;color:rgba(255,255,255,0.45);letter-spacing:0.12em;text-transform:uppercase;margin-top:3px;">peaceful growth</div>
      </div>
      <div class="num num-txt" style="font-size:72px;font-weight:900;color:rgba(255,255,255,0.06);line-height:1;margin-top:12px;">$num</div>
    </td>
    <td class="right" valign="middle"
      style="background:#000080;padding:24px 22px;vertical-align:middle;border-left:1px solid rgba(255,255,255,0.08);">
      <div class="bar" style="width:32px;height:3px;background:rgba(255,255,255,0.4);border-radius:2px;margin-bottom:10px;"></div>
      <div class="htitle" style="font-size:20px;font-weight:800;color:#fff;letter-spacing:-0.4px;line-height:1.25;">$title</div>
      <div class="hsub" style="font-size:11px;color:rgba(255,255,255,0.5);margin-top:6px;line-height:1.5;">$sub</div>
    </td>
  </tr>

  <tr>
    <td colspan="2" class="body body-bg"
      style="padding:24px 22px;background:#fff;border-top:3px solid #000080;">
      <p class="greet" style="font-size:13px;color:#64748b;margin:0 0 18px;line-height:1.6;">$greet</p>

      <table class="code-row" width="100%" cellpadding="0" cellspacing="0"
        style="margin-bottom:18px;">
        <tr>
          <td valign="top">
            <table cellpadding="0" cellspacing="0">
              <tr class="digit-light">${_digitBoxes(digits)}</tr>
              <tr class="digit-dark" style="display:none;">${_digitBoxesDark(digits)}</tr>
            </table>
          </td>
          <td class="meta" valign="top" style="padding-left:16px;padding-top:4px;">
            <div class="badge"
              style="display:inline-block;background:#eff6ff;color:#1d4ed8;font-size:10px;
                font-weight:700;padding:3px 10px;border-radius:20px;">Valid 10 min</div>
            <div class="exp" style="font-size:10px;color:#94a3b8;margin-top:4px;">Single use only</div>
          </td>
        </tr>
      </table>

      <div class="divider" style="height:1px;background:#f1f5f9;margin:0 0 16px;"></div>

      <table class="warn-box" width="100%" cellpadding="0" cellspacing="0"
        style="background:#fffbeb;border-left:3px solid #f59e0b;margin-bottom:12px;">
        <tr><td style="padding:10px 12px;">
          <p class="warn-txt" style="font-size:11px;color:#78350f;margin:0;line-height:1.5;">$warnLight</p>
        </td></tr>
      </table>

      <p class="note" style="font-size:10px;color:#cbd5e1;margin:0;">$noteLight</p>
    </td>
  </tr>

  <tr>
    <td colspan="2" class="foot-bg"
      style="background:#f8f9fc;border-top:1px solid #f1f5f9;padding:12px 22px;">
      <table class="foot-inner" width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td><span class="foot-l" style="font-size:12px;font-weight:800;color:#000080;">Fahamni</span></td>
          <td align="right"><span class="foot-r" style="font-size:9px;color:#cbd5e1;">© 2026 · Automated</span></td>
        </tr>
      </table>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>''';
  }

  // ── Welcome email ─────────────────────────────────────────────────────────

  String _buildWelcomeHtml(String firstName) => '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<meta name="color-scheme" content="light dark">
<meta name="supported-color-schemes" content="light dark">
<style>
  @media only screen and (max-width:600px){
    .outer{padding:16px 8px!important;}
    .top{display:block!important;}
    .left{width:100%!important;display:flex!important;flex-direction:row!important;
          align-items:center!important;justify-content:space-between!important;
          padding:16px 18px!important;}
    .num{display:none!important;}
    .right{padding:16px 18px!important;border-left:none!important;
           border-top:1px solid rgba(255,255,255,0.08)!important;}
    .htitle{font-size:17px!important;}
    .body{padding:18px!important;}
    .steps{display:block!important;}
    .step-cell{display:block!important;width:100%!important;margin-bottom:8px!important;}
    .foot-inner{display:block!important;text-align:center!important;}
  }
  @media (prefers-color-scheme:dark){
    .email-bg{background:#0d1117!important;}
    .left{background:#161b22!important;}
    .right{background:#161b22!important;border-left-color:#30363d!important;}
    .bar{background:#6366f1!important;}
    .htitle{color:#e6edf3!important;}
    .hsub{color:rgba(230,237,243,0.4)!important;}
    .body-bg{background:#0d1117!important;border-top-color:#6366f1!important;}
    .greet{color:#8b949e!important;}
    .step-box{background:#161b22!important;border-top-color:#6366f1!important;border-color:#21262d!important;}
    .sn{color:rgba(99,102,241,0.2)!important;}
    .st{color:#c9d1d9!important;}
    .ss{color:#484f58!important;}
    .note{color:#484f58!important;}
    .foot-bg{background:#0a0f1e!important;border-top-color:#21262d!important;}
    .foot-l{color:#8b949e!important;}
    .foot-r{color:#30363d!important;}
    .logo-txt{color:#e6edf3!important;}
    .tag-txt{color:rgba(230,237,243,0.3)!important;}
    .num-txt{color:rgba(99,102,241,0.06)!important;}
  }
</style>
</head>
<body style="margin:0;padding:0;background:#f8f9fc;font-family:Arial,sans-serif;">
<table class="email-bg" width="100%" cellpadding="0" cellspacing="0"
  style="background:#f8f9fc;">
<tr><td class="outer" align="center" style="padding:32px 16px;">
<table width="560" cellpadding="0" cellspacing="0"
  style="width:100%;max-width:560px;overflow:hidden;border-radius:4px;">

  <tr class="top" style="display:table-row;">
    <td class="left" valign="bottom"
      style="background:#000080;width:38%;padding:24px 20px;vertical-align:bottom;">
      <div>
        <div class="logo-txt" style="font-size:18px;font-weight:900;color:#fff;letter-spacing:-0.5px;">Fahamni</div>
        <div class="tag-txt" style="font-size:9px;color:rgba(255,255,255,0.45);letter-spacing:0.12em;text-transform:uppercase;margin-top:3px;">peaceful growth</div>
      </div>
      <div class="num num-txt" style="font-size:72px;font-weight:900;color:rgba(255,255,255,0.06);line-height:1;margin-top:12px;">Hi</div>
    </td>
    <td class="right" valign="middle"
      style="background:#000080;padding:24px 22px;vertical-align:middle;border-left:1px solid rgba(255,255,255,0.08);">
      <div class="bar" style="width:32px;height:3px;background:rgba(255,255,255,0.4);border-radius:2px;margin-bottom:10px;"></div>
      <div class="htitle" style="font-size:20px;font-weight:800;color:#fff;letter-spacing:-0.4px;line-height:1.25;">Welcome, $firstName!</div>
      <div class="hsub" style="font-size:11px;color:rgba(255,255,255,0.5);margin-top:6px;line-height:1.5;">Account verified — you are now in the community</div>
    </td>
  </tr>

  <tr>
    <td colspan="2" class="body body-bg"
      style="padding:24px 22px;background:#fff;border-top:3px solid #000080;">
      <p class="greet" style="font-size:13px;color:#64748b;margin:0 0 18px;line-height:1.6;">
        Your profile is all set. Here is how to get started on Fahamni.
      </p>

      <table class="steps" width="100%" cellpadding="0" cellspacing="0"
        style="margin-bottom:16px;">
        <tr>
          <td class="step-cell" valign="top" style="padding-right:8px;">
            <div class="step-box"
              style="background:#f8faff;border-top:2px solid #000080;padding:12px 10px;">
              <div class="sn" style="font-size:18px;font-weight:900;color:#e0e7ff;margin-bottom:6px;">01</div>
              <div class="st" style="font-size:11px;font-weight:700;color:#1e293b;margin-bottom:1px;">Complete profile</div>
              <div class="ss" style="font-size:10px;color:#94a3b8;">Better matches</div>
            </div>
          </td>
          <td class="step-cell" valign="top" style="padding:0 4px;">
            <div class="step-box"
              style="background:#f8faff;border-top:2px solid #000080;padding:12px 10px;">
              <div class="sn" style="font-size:18px;font-weight:900;color:#e0e7ff;margin-bottom:6px;">02</div>
              <div class="st" style="font-size:11px;font-weight:700;color:#1e293b;margin-bottom:1px;">Find tutors</div>
              <div class="ss" style="font-size:10px;color:#94a3b8;">Perfect match</div>
            </div>
          </td>
          <td class="step-cell" valign="top" style="padding-left:8px;">
            <div class="step-box"
              style="background:#f8faff;border-top:2px solid #000080;padding:12px 10px;">
              <div class="sn" style="font-size:18px;font-weight:900;color:#e0e7ff;margin-bottom:6px;">03</div>
              <div class="st" style="font-size:11px;font-weight:700;color:#1e293b;margin-bottom:1px;">Book session</div>
              <div class="ss" style="font-size:10px;color:#94a3b8;">Start learning</div>
            </div>
          </td>
        </tr>
      </table>

      <p class="note" style="font-size:10px;color:#cbd5e1;margin:0;">
        Didn't create this account? Contact us immediately.
      </p>
    </td>
  </tr>

  <tr>
    <td colspan="2" class="foot-bg"
      style="background:#f8f9fc;border-top:1px solid #f1f5f9;padding:12px 22px;">
      <table class="foot-inner" width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td><span class="foot-l" style="font-size:12px;font-weight:800;color:#000080;">Fahamni</span></td>
          <td align="right"><span class="foot-r" style="font-size:9px;color:#cbd5e1;">© 2026 · Automated</span></td>
        </tr>
      </table>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>''';

  // ── Password changed email ────────────────────────────────────────────────

  String _buildPasswordChangedHtml() => '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<meta name="color-scheme" content="light dark">
<meta name="supported-color-schemes" content="light dark">
<style>
  @media only screen and (max-width:600px){
    .outer{padding:16px 8px!important;}
    .top{display:block!important;}
    .left{width:100%!important;display:flex!important;flex-direction:row!important;
          align-items:center!important;justify-content:space-between!important;
          padding:16px 18px!important;}
    .num{display:none!important;}
    .right{padding:16px 18px!important;border-left:none!important;
           border-top:1px solid rgba(255,255,255,0.08)!important;}
    .htitle{font-size:17px!important;}
    .body{padding:18px!important;}
    .foot-inner{display:block!important;text-align:center!important;}
  }
  @media (prefers-color-scheme:dark){
    .email-bg{background:#0d1117!important;}
    .left{background:#161b22!important;}
    .right{background:#161b22!important;border-left-color:#30363d!important;}
    .bar{background:#6366f1!important;}
    .htitle{color:#e6edf3!important;}
    .hsub{color:rgba(230,237,243,0.4)!important;}
    .body-bg{background:#0d1117!important;border-top-color:#6366f1!important;}
    .greet{color:#8b949e!important;}
    .success-box{background:rgba(16,185,129,0.08)!important;border-left-color:#10b981!important;}
    .success-txt{color:rgba(52,211,153,0.9)!important;}
    .danger-box{background:rgba(239,68,68,0.08)!important;border-left-color:#ef4444!important;}
    .danger-txt{color:rgba(248,113,113,0.9)!important;}
    .note{color:#484f58!important;}
    .foot-bg{background:#0a0f1e!important;border-top-color:#21262d!important;}
    .foot-l{color:#8b949e!important;}
    .foot-r{color:#30363d!important;}
    .logo-txt{color:#e6edf3!important;}
    .tag-txt{color:rgba(230,237,243,0.3)!important;}
    .num-txt{color:rgba(99,102,241,0.06)!important;}
  }
</style>
</head>
<body style="margin:0;padding:0;background:#f8f9fc;font-family:Arial,sans-serif;">
<table class="email-bg" width="100%" cellpadding="0" cellspacing="0"
  style="background:#f8f9fc;">
<tr><td class="outer" align="center" style="padding:32px 16px;">
<table width="560" cellpadding="0" cellspacing="0"
  style="width:100%;max-width:560px;overflow:hidden;border-radius:4px;">

  <tr class="top" style="display:table-row;">
    <td class="left" valign="bottom"
      style="background:#000080;width:38%;padding:24px 20px;vertical-align:bottom;">
      <div>
        <div class="logo-txt" style="font-size:18px;font-weight:900;color:#fff;letter-spacing:-0.5px;">Fahamni</div>
        <div class="tag-txt" style="font-size:9px;color:rgba(255,255,255,0.45);letter-spacing:0.12em;text-transform:uppercase;margin-top:3px;">peaceful growth</div>
      </div>
      <div class="num num-txt" style="font-size:72px;font-weight:900;color:rgba(255,255,255,0.06);line-height:1;margin-top:12px;">!</div>
    </td>
    <td class="right" valign="middle"
      style="background:#000080;padding:24px 22px;vertical-align:middle;border-left:1px solid rgba(255,255,255,0.08);">
      <div class="bar" style="width:32px;height:3px;background:rgba(255,255,255,0.4);border-radius:2px;margin-bottom:10px;"></div>
      <div class="htitle" style="font-size:20px;font-weight:800;color:#fff;letter-spacing:-0.4px;line-height:1.25;">Password changed</div>
      <div class="hsub" style="font-size:11px;color:rgba(255,255,255,0.5);margin-top:6px;line-height:1.5;">Security notification for your Fahamni account</div>
    </td>
  </tr>

  <tr>
    <td colspan="2" class="body body-bg"
      style="padding:24px 22px;background:#fff;border-top:3px solid #000080;">

      <table class="success-box" width="100%" cellpadding="0" cellspacing="0"
        style="background:#f0fdf4;border-left:3px solid #10b981;margin-bottom:10px;">
        <tr><td style="padding:12px 14px;">
          <p class="success-txt" style="font-size:12px;color:#065f46;margin:0;line-height:1.6;">
            Your password was changed successfully. You can now log in with your new credentials.
          </p>
        </td></tr>
      </table>

      <table class="danger-box" width="100%" cellpadding="0" cellspacing="0"
        style="background:#fef2f2;border-left:3px solid #ef4444;margin-bottom:12px;">
        <tr><td style="padding:12px 14px;">
          <p class="danger-txt" style="font-size:11px;color:#991b1b;margin:0;line-height:1.5;">
            If you did not make this change, contact us immediately and secure your account.
          </p>
        </td></tr>
      </table>

      <p class="note" style="font-size:10px;color:#cbd5e1;margin:0;">
        This is an automated security notification.
      </p>
    </td>
  </tr>

  <tr>
    <td colspan="2" class="foot-bg"
      style="background:#f8f9fc;border-top:1px solid #f1f5f9;padding:12px 22px;">
      <table class="foot-inner" width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td><span class="foot-l" style="font-size:12px;font-weight:800;color:#000080;">Fahamni</span></td>
          <td align="right"><span class="foot-r" style="font-size:9px;color:#cbd5e1;">© 2026 · Automated</span></td>
        </tr>
      </table>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>''';
}