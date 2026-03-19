import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_.service.dart';

class EmailOtpService {
  static const _resendApiKey = 're_Kt6BAQMX_EE3exnYUTqm3Xpqd92vA7fnJ'; // ← your Resend API key
  final _db = FirebaseFirestore.instance;

  String _generateCode() {
    final rng = Random.secure();
    return (100000 + rng.nextInt(900000)).toString();
  }

  Future<void> sendPasswordResetOtp({required String email}) async {
  final code   = _generateCode();
  final expiry = DateTime.now().add(const Duration(minutes: 10));

  // Use Timestamp (not ISO string) so verifyOtp can read it consistently
  await _db.collection('email_otps').doc(email).set({
    'code':      code,
    'expiresAt': Timestamp.fromDate(expiry),  // ← matches verifyOtp's cast
    'type':      'password_reset',
    'verified':  false,
  });

  // Reuse the existing mailer — pass a generic first name since we only have email here
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
      'html':    _buildPasswordResetHtml(digits),
    }),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw 'Failed to send email: ${response.statusCode} — ${response.body}';
  }
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
        'html':    _buildEmailHtml(firstName, digits),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw 'Failed to send email: ${response.statusCode} — ${response.body}';
    }
  }

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


  String _buildEmailHtml(String firstName, List<String> digits) {
    final boxes = digits.map((d) => '''
      <td style="padding:0 4px;">
        <div style="width:44px;height:56px;background:#ffffff;border:1.5px solid #000080;
          border-radius:10px;text-align:center;line-height:56px;">
          <span style="font-size:26px;font-weight:700;color:#000080;">$d</span>
        </div>
      </td>
    ''').join('');

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    @media only screen and (max-width:600px) {
      .email-card { width:100% !important; border-radius:12px !important; }
      .header-pad { padding:24px 20px !important; }
      .body-pad   { padding:24px 20px !important; }
      .footer-pad { padding:16px 20px !important; }
    }
  </style>
</head>
<body style="margin:0;padding:0;background:#f1f5f9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f1f5f9;">
    <tr><td align="center" style="padding:48px 20px;">
      <table class="email-card" width="520" cellpadding="0" cellspacing="0"
        style="background:#ffffff;border-radius:20px;overflow:hidden;
               border:1px solid #e2e8f0;box-shadow:0 4px 24px rgba(0,0,128,0.08);">

        <tr><td class="header-pad"
          style="background:linear-gradient(135deg,#000080 0%,#1a1aad 100%);
                 padding:40px 32px;text-align:center;">
          <div style="display:inline-block;background:rgba(255,255,255,0.15);
            border-radius:16px;padding:12px 20px;margin-bottom:16px;">
            <p style="color:#ffffff;font-size:26px;font-weight:700;margin:0;">Fahamni</p>
          </div>
          <p style="color:rgba(255,255,255,0.75);font-size:13px;margin:0;">
            A peaceful place for growth
          </p>
        </td></tr>

        <tr><td class="body-pad" style="padding:40px 40px 32px;">
          <p style="font-size:15px;color:#64748b;margin:0 0 4px;">
            Hello <strong style="color:#0f172a;">$firstName</strong>,
          </p>
          <p style="font-size:15px;color:#64748b;margin:0 0 32px;line-height:1.6;">
            Use the code below to verify your account.<br>
            It expires in <strong style="color:#0f172a;">10 minutes</strong>.
          </p>

          <table width="100%" cellpadding="0" cellspacing="0"
            style="background:#f8fafc;border-radius:16px;border:1.5px solid #e2e8f0;">
            <tr><td style="padding:32px 24px;text-align:center;">
              <p style="font-size:11px;color:#94a3b8;margin:0 0 20px;
                letter-spacing:0.15em;text-transform:uppercase;">Verification Code</p>
              <table cellpadding="0" cellspacing="0" style="margin:0 auto;">
                <tr>$boxes</tr>
              </table>
              <p style="font-size:12px;color:#94a3b8;margin:20px 0 0;">
                Valid for <strong style="color:#0f172a;">10 minutes</strong>
              </p>
            </td></tr>
          </table>

          <table width="100%" cellpadding="0" cellspacing="0"
            style="background:#fff7ed;border-radius:10px;
                   border:1px solid #fed7aa;margin-top:24px;">
            <tr><td style="padding:14px 16px;">
              <p style="font-size:13px;color:#9a3412;margin:0;line-height:1.5;">
                ⚠️ &nbsp;Never share this code with anyone.
                Fahamni will never ask for your code.
              </p>
            </td></tr>
          </table>

          <p style="font-size:13px;color:#94a3b8;margin:20px 0 0;line-height:1.6;">
            Didn't request this? You can safely ignore this email.
          </p>
        </td></tr>

        <tr><td class="footer-pad"
          style="border-top:1px solid #f1f5f9;padding:20px 40px;
                 text-align:center;background:#fafafa;">
          <p style="font-size:12px;color:#94a3b8;margin:0 0 4px;">
            © 2026 Fahamni · All rights reserved
          </p>
          <p style="font-size:11px;color:#cbd5e1;margin:0;">
            This is an automated message, please do not reply.
          </p>
        </td></tr>

      </table>
    </td></tr>
  </table>
</body>
</html>''';
  }

  String _buildWelcomeHtml(String firstName) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    @media only screen and (max-width:600px) {
      .email-card { width:100% !important; }
      .body-pad   { padding:24px 20px !important; }
    }
  </style>
</head>
<body style="margin:0;padding:0;background:#f1f5f9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f1f5f9;">
    <tr><td align="center" style="padding:48px 20px;">
      <table class="email-card" width="520" cellpadding="0" cellspacing="0"
        style="background:#ffffff;border-radius:20px;overflow:hidden;
               border:1px solid #e2e8f0;box-shadow:0 4px 24px rgba(0,0,128,0.08);">

        <tr><td style="background:linear-gradient(135deg,#000080 0%,#1a1aad 100%);
                       padding:40px 32px;text-align:center;">
          <div style="display:inline-block;background:rgba(255,255,255,0.15);
            border-radius:16px;padding:12px 20px;margin-bottom:16px;">
            <p style="color:#ffffff;font-size:26px;font-weight:700;margin:0;">Fahamni</p>
          </div>
          <p style="color:rgba(255,255,255,0.75);font-size:13px;margin:0;">
            A peaceful place for growth
          </p>
        </td></tr>

        <tr><td class="body-pad" style="padding:40px;">
          <p style="font-size:22px;font-weight:700;color:#0f172a;margin:0 0 8px;">
            Welcome, $firstName! 🎉
          </p>
          <p style="font-size:15px;color:#64748b;margin:0 0 32px;line-height:1.6;">
            Your account has been verified. You're now part of the Fahamni community.
          </p>

          <table width="100%" cellpadding="0" cellspacing="0"
            style="background:#f8fafc;border-radius:16px;
                   border:1.5px solid #e2e8f0;margin-bottom:32px;">
            <tr><td style="padding:24px;">

              <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:16px;">
                <tr>
                  <td style="width:36px;vertical-align:top;">
                    <div style="width:28px;height:28px;background:#000080;border-radius:50%;
                      text-align:center;line-height:28px;color:white;
                      font-size:14px;font-weight:700;">1</div>
                  </td>
                  <td style="padding-left:12px;vertical-align:top;">
                    <p style="font-size:14px;font-weight:700;color:#0f172a;margin:0 0 2px;">
                      Complete your profile</p>
                    <p style="font-size:13px;color:#64748b;margin:0;">
                      Add more details to get better matches</p>
                  </td>
                </tr>
              </table>

              <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:16px;">
                <tr>
                  <td style="width:36px;vertical-align:top;">
                    <div style="width:28px;height:28px;background:#000080;border-radius:50%;
                      text-align:center;line-height:28px;color:white;
                      font-size:14px;font-weight:700;">2</div>
                  </td>
                  <td style="padding-left:12px;vertical-align:top;">
                    <p style="font-size:14px;font-weight:700;color:#0f172a;margin:0 0 2px;">
                      Explore tutors</p>
                    <p style="font-size:13px;color:#64748b;margin:0;">
                      Find the perfect tutor for your needs</p>
                  </td>
                </tr>
              </table>

              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="width:36px;vertical-align:top;">
                    <div style="width:28px;height:28px;background:#000080;border-radius:50%;
                      text-align:center;line-height:28px;color:white;
                      font-size:14px;font-weight:700;">3</div>
                  </td>
                  <td style="padding-left:12px;vertical-align:top;">
                    <p style="font-size:14px;font-weight:700;color:#0f172a;margin:0 0 2px;">
                      Book your first session</p>
                    <p style="font-size:13px;color:#64748b;margin:0;">
                      Start learning at your own pace</p>
                  </td>
                </tr>
              </table>

            </td></tr>
          </table>
        </td></tr>

        <tr><td style="border-top:1px solid #f1f5f9;padding:20px 40px;
                       text-align:center;background:#fafafa;">
          <p style="font-size:12px;color:#94a3b8;margin:0 0 4px;">
            © 2025 Fahamni · All rights reserved
          </p>
          <p style="font-size:11px;color:#cbd5e1;margin:0;">
            This is an automated message, please do not reply.
          </p>
        </td></tr>

      </table>
    </td></tr>
  </table>
</body>
</html>''';
  }

  String _buildPasswordResetHtml(List<String> digits) {
  final boxes = digits.map((d) => '''
    <td style="padding:0 4px;">
      <div style="width:44px;height:56px;background:#ffffff;border:1.5px solid #000080;
        border-radius:10px;text-align:center;line-height:56px;">
        <span style="font-size:26px;font-weight:700;color:#000080;">$d</span>
      </div>
    </td>
  ''').join('');

  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;background:#f1f5f9;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f1f5f9;">
    <tr><td align="center" style="padding:48px 20px;">
      <table width="520" cellpadding="0" cellspacing="0"
        style="background:#ffffff;border-radius:20px;overflow:hidden;
               border:1px solid #e2e8f0;box-shadow:0 4px 24px rgba(0,0,128,0.08);">

        <tr><td style="background:linear-gradient(135deg,#000080 0%,#1a1aad 100%);
                       padding:40px 32px;text-align:center;">
          <div style="display:inline-block;background:rgba(255,255,255,0.15);
            border-radius:16px;padding:12px 20px;margin-bottom:16px;">
            <p style="color:#ffffff;font-size:26px;font-weight:700;margin:0;">Fahamni</p>
          </div>
          <p style="color:rgba(255,255,255,0.75);font-size:13px;margin:0;">
            A peaceful place for growth
          </p>
        </td></tr>

        <tr><td style="padding:40px 40px 32px;">
          <p style="font-size:15px;color:#64748b;margin:0 0 4px;">Hello,</p>
          <p style="font-size:15px;color:#64748b;margin:0 0 32px;line-height:1.6;">
            We received a request to reset your Fahamni password.<br>
            Use the code below — it expires in
            <strong style="color:#0f172a;">10 minutes</strong>.
          </p>

          <table width="100%" cellpadding="0" cellspacing="0"
            style="background:#f8fafc;border-radius:16px;border:1.5px solid #e2e8f0;">
            <tr><td style="padding:32px 24px;text-align:center;">
              <p style="font-size:11px;color:#94a3b8;margin:0 0 20px;
                letter-spacing:0.15em;text-transform:uppercase;">Password Reset Code</p>
              <table cellpadding="0" cellspacing="0" style="margin:0 auto;">
                <tr>$boxes</tr>
              </table>
              <p style="font-size:12px;color:#94a3b8;margin:20px 0 0;">
                Valid for <strong style="color:#0f172a;">10 minutes</strong>
              </p>
            </td></tr>
          </table>

          <table width="100%" cellpadding="0" cellspacing="0"
            style="background:#fff7ed;border-radius:10px;
                   border:1px solid #fed7aa;margin-top:24px;">
            <tr><td style="padding:14px 16px;">
              <p style="font-size:13px;color:#9a3412;margin:0;line-height:1.5;">
                ⚠️ &nbsp;If you did not request this, your account may be at risk.
                Do not share this code with anyone.
              </p>
            </td></tr>
          </table>

          <p style="font-size:13px;color:#94a3b8;margin:20px 0 0;line-height:1.6;">
            Didn't request a password reset? You can safely ignore this email.
          </p>
        </td></tr>

        <tr><td style="border-top:1px solid #f1f5f9;padding:20px 40px;
                       text-align:center;background:#fafafa;">
          <p style="font-size:12px;color:#94a3b8;margin:0 0 4px;">
            © 2026 Fahamni · All rights reserved
          </p>
          <p style="font-size:11px;color:#cbd5e1;margin:0;">
            This is an automated message, please do not reply.
          </p>
        </td></tr>

      </table>
    </td></tr>
  </table>
</body>
</html>''';
}

}