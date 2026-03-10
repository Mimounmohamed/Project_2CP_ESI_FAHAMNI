import 'package:flutter/material.dart';
import 'OTPbox.dart';
import 'package:fahamni/Registration_Completed_Screen/RegistraionCompleteScreen.dart';

class PhoneVerificationPage extends StatefulWidget {
  const PhoneVerificationPage({super.key});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  // One controller + focusNode per box
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());
      String? _errorMessage;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),

      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFFAFAFA),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              /// LOGO
              Container(
                alignment: Alignment.center,
                child: Image.asset(
                  "assets/images/Vector@2x.png",
                  height: 100,
                ),
              ),

              const SizedBox(height: 10),

              /// FAHAMNI TITLE
              const Text(
                "Fahamni",
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 30,
                  letterSpacing: -0.75,
                ),
              ),

              /// TAGLINE
              const Text(
                "A peaceful place for growth",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff64748B),
                ),
              ),

              const SizedBox(height: 40),

              /// OTP TITLE
              const Text(
                "Phone Verification",
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),

              const SizedBox(height: 6),

              /// DESCRIPTION
              const Text(
                "Enter the code that we have sent you",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 16,
                  color: Color(0xff64748B),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              /// OTP BOXES
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return OTPBox(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      // last box has no nextFocusNode
                      nextFocusNode: index < 5 ? _focusNodes[index + 1] : null,
                    );
                  }),
                ),
              ),

              const SizedBox(height: 40),

              
  if (_errorMessage != null)
    Text(
      _errorMessage!,
      style: const TextStyle(
        color: Color(0xFFE53935),
        fontSize: 14,
        fontFamily: "Inter",
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    ),
           const SizedBox(height: 8),

            SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000080),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x33137FEC),
                            offset: const Offset(0, 8),
                            blurRadius: 10,
                            spreadRadius: -6,
                          ),
                          BoxShadow(
                            color: const Color(0x33137FEC),
                            offset: const Offset(0, 20),
                            blurRadius: 25,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {

                             if (_otpCode.length == 6) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegistrationComplete(),
                      ),
                    );

                    
                    
                  } else {
  setState(() => _errorMessage = "Please enter the full 6-digit code");
  
}

                          },
                          child: const Center(
                            child: Text(
                              "Send Code",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 15),

              TextButton(
                onPressed: () {
                  // resend code logic
                },
                child: const Text(
                  "Resend Code",
                  style: TextStyle(
                    fontFamily: "Inter",
                    color: Color(0xBF000080),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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