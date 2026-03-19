const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.resetPassword = functions
  .runWith({ invoker: "public" })  // ← allows unauthenticated calls
  .https.onCall(async (data, context) => {
    const { email, newPassword } = data;

    if (!email || !newPassword) {
      throw new functions.https.HttpsError("invalid-argument", "Missing fields.");
    }
    if (newPassword.length < 6) {
      throw new functions.https.HttpsError("invalid-argument", "Password must be at least 6 characters.");
    }

    try {
      const user = await admin.auth().getUserByEmail(email);
      await admin.auth().updateUser(user.uid, { password: newPassword });
      return { success: true };
    } catch (e) {
      throw new functions.https.HttpsError("internal", e.message);
    }
  });