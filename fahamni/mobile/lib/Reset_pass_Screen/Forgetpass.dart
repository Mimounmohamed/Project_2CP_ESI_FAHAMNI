import 'package:flutter/material.dart';
import 'PasswrdInput.dart';
import 'package:fahamni/Login_Screen/LoginScreen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../Services/email_otp_service.dart';
class ResetPasswordPage extends StatefulWidget {
  final String verifiedEmail;

  const ResetPasswordPage({super.key, required this.verifiedEmail});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  OutlineInputBorder _border([Color color = const Color(0xFFE0E0E0), double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  
  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await FirebaseFunctions.instance
          .httpsCallable('resetPassword')
          .call({
            'email':       widget.verifiedEmail,
            'newPassword': _newPasswordController.text,
          });
       await EmailOtpService().sendPasswordChangedEmail(
      email: widget.verifiedEmail,
    );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        surfaceTintColor: const Color(0xFFFAFAFA),
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
        ),
        centerTitle: true,
        title: const Text(
          "Reset Password",
          style: TextStyle(
            fontFamily: "Inter",
            fontWeight: FontWeight.w700,
            fontSize: 32,
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              PasswordInput(
                label: "New Password",
                controller: _newPasswordController,
              ),

              const SizedBox(height: 20),

              // Confirm Password
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: const Text(
                      "Confirm Password",
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1f2937),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_showConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm Password is required';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: "Re-enter password",
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 17,
                        fontFamily: "Lexend",
                      ),
                      prefixIcon: const Icon(Icons.lock_outline, size: 22, color: Color(0xFF94A3B8)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFF94A3B8),
                        ),
                        onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                      ),
                      enabledBorder: _border(),
                      focusedBorder: _border(const Color(0xFFE0E0E0), 2),
                      errorBorder: _border(Colors.red, 1.5),
                      focusedErrorBorder: _border(Colors.red, 1.5),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
               if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontFamily: 'Inter'),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000080),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33137FEC), offset: Offset(0, 8), blurRadius: 10, spreadRadius: -6),
                      BoxShadow(color: Color(0x33137FEC), offset: Offset(0, 20), blurRadius: 25, spreadRadius: -5),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _isLoading ? null : _confirm,
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text(
                                "Confirm",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}