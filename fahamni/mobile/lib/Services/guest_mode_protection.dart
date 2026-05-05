import 'package:flutter/material.dart';
import '../Services/guest_mode_service.dart';

/// Middleware to protect restricted teacher features from guest mode access.
/// Shows an informational dialog and prevents navigation.
class GuestModeProtection {
  static Future<bool> canAccessTeacherFeature(BuildContext context) async {
    final isGuest = await GuestModeService.isTeacherInGuestMode();
    if (isGuest && context.mounted) {
      _showGuestModeDialog(context);
      return false;
    }
    return true;
  }

  static void _showGuestModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Feature Unavailable'),
        content: const Text(
          'This feature is only available after your account is validated by admin. '
          'Please check your profile settings for updates on your account status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
