import 'package:flutter/material.dart';
import 'OTP_updateemail_screen.dart';

class UpdateEmailScreen extends StatefulWidget {
  const UpdateEmailScreen({super.key});

  @override
  State<UpdateEmailScreen> createState() => _UpdateEmailScreenState();
}

class _UpdateEmailScreenState extends State<UpdateEmailScreen> {
  final _newEmailController     = TextEditingController();
  final _confirmEmailController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _newEmailController.dispose();
    _confirmEmailController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final newEmail     = _newEmailController.text.trim();
    final confirmEmail = _confirmEmailController.text.trim();

    if (newEmail.isEmpty || confirmEmail.isEmpty) {
      setState(() => _errorMessage = 'Please fill in both fields.');
      return;
    }
    if (!newEmail.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (newEmail != confirmEmail) {
      setState(() => _errorMessage = 'Emails do not match.');
      return;
    }

    setState(() => _errorMessage = null);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpUpdateEmailPage(newEmail: newEmail),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller,
      {bool isEmail = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.05),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Update Email",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _inputField("New Email Address", _newEmailController),
            const SizedBox(height: 16),
            _inputField("Confirm Email Address", _confirmEmailController),
            const SizedBox(height: 12),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 13,
                  fontFamily: "Inter",
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onConfirm,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF000080),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Confirm",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}