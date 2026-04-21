import 'package:flutter/material.dart';
import 'package:fahamni/Services/auth_.service.dart';
import 'OTP_updatephone.dart';

class UpdatePhoneScreen extends StatefulWidget {
  const UpdatePhoneScreen({super.key});

  @override
  State<UpdatePhoneScreen> createState() => _UpdatePhoneScreenState();
}

class _UpdatePhoneScreenState extends State<UpdatePhoneScreen> {
  final _newPhoneController     = TextEditingController();
  final _confirmPhoneController = TextEditingController();
  final _authService            = AuthService();

  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPhoneController.dispose();
    _confirmPhoneController.dispose();
    super.dispose();
  }

  String _normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    return input.startsWith('+') ? '+$digits' : '+213$digits';
  }

  Future<void> _onConfirm() async {
    final newPhone     = _newPhoneController.text.trim();
    final confirmPhone = _confirmPhoneController.text.trim();

    if (newPhone.isEmpty || confirmPhone.isEmpty) {
      setState(() => _errorMessage = 'Please fill in both fields.');
      return;
    }
    if (newPhone != confirmPhone) {
      setState(() => _errorMessage = 'Phone numbers do not match.');
      return;
    }

    final normalized = _normalizePhone(newPhone);

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      // Check if phone already taken before going to OTP
      await _authService.updatePhone(newPhone: normalized);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpUpdatePhonePage(newPhone: normalized),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _inputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 20 / 14,
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
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              hintText: '0xxxxxxxxx',
              hintStyle: TextStyle(color: Color(0xFFCBD5E1)),
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
          "Update Phone Number",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 28,
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
            _inputField("New Phone Number", _newPhoneController),
            const SizedBox(height: 16),
            _inputField("Confirm Phone Number", _confirmPhoneController),
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
                onPressed: _isLoading ? null : _onConfirm,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF000080),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
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