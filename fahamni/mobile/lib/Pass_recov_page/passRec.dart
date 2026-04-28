import 'package:flutter/material.dart';
import 'package:fahamni/otp_verification_Screen/otpverifPage.dart';
import 'package:fahamni/Services/auth_.service.dart';

class passRec extends StatefulWidget {
  const passRec({super.key});

  @override
  State<passRec> createState() => _passRecState();
}

class _passRecState extends State<passRec> {
  int selectedIndex = -1;
  bool _showMethodError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff9f9f9),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xfff9f9f9),
        surfaceTintColor: const Color(0xfff9f9f9),
        shadowColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          iconSize: 24,
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.center,
                child: Image.asset("assets/images/Vector@2x.png", height: 100),
              ),
              const SizedBox(height: 10),
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
              const Text(
                "A peaceful place for growth",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff64748B),
                  height: 24 / 16,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "Recover your password",
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  height: 35 / 28,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "We will send a verification code to reset",
                style: TextStyle(fontFamily: "Inter", fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xff64748B), height: 24 / 16),
              ),
              const SizedBox(height: 5),
              const Text(
                "your password.",
                style: TextStyle(fontFamily: "Inter", fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xff64748B), height: 24 / 16),
              ),
              const SizedBox(height: 40),

              Buttons(
                selectedIndex,
                (index) => setState(() {
                  selectedIndex = index;
                  _showMethodError = false;
                }),
              ),

              if (_showMethodError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.error_outline, color: Colors.red, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Please select Email or Phone to continue',
                        style: TextStyle(color: Colors.red, fontSize: 13, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              if (selectedIndex == 0) const Email_widg(),
              if (selectedIndex == 1) const Phone_widg(),
            ],
          ),
        ),
      ),
    );
  }
}

class Buttons extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectionChanged;

  const Buttons(this.selectedIndex, this.onSelectionChanged, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(30),
        color: const Color(0xFFFAFAFA),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => onSelectionChanged(selectedIndex == 0 ? -1 : 0),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                backgroundColor: selectedIndex == 0 ? const Color(0xFF000080) : const Color(0xFFFAFAFA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("Email",
                    style: TextStyle(
                      fontFamily: "Inter", fontSize: 20, fontWeight: FontWeight.w500,
                      color: selectedIndex == 0 ? const Color(0xFFFAFAFA) : const Color(0xFF000080),
                      height: 24 / 16,
                    )),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => onSelectionChanged(selectedIndex == 1 ? -1 : 1),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                backgroundColor: selectedIndex == 1 ? const Color(0xFF000080) : const Color(0xFFFAFAFA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("Phone",
                    style: TextStyle(
                      fontFamily: "Inter", fontSize: 20, fontWeight: FontWeight.w500,
                      color: selectedIndex == 1 ? const Color(0xFFFAFAFA) : const Color(0xFF000080),
                      height: 24 / 16,
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Email_widg extends StatefulWidget {
  const Email_widg({super.key});

  @override
  State<Email_widg> createState() => _Email_widgState();
}

class _Email_widgState extends State<Email_widg> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  OutlineInputBorder _border([Color color = const Color(0xFFE0E0E0), double width = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: width));

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          Container(
            margin: const EdgeInsets.only(left: 34),
            child: const Text(
              "Email Address",
              style: TextStyle(fontFamily: "Inter", fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xff1f2937), height: 14 / 18),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 24, right: 24),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Email is required';
                if (!value.contains('@')) return 'Enter a valid email';
                return null;
              },
              decoration: InputDecoration(
                hintText: 'name@example.com',
                hintStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), fontSize: 17, fontFamily: 'Lexend'),
                prefixIcon: const Icon(Icons.email_outlined, size: 22, color: Color(0xFF94A3B8)),
                enabledBorder: _border(),
                focusedBorder: _border(const Color(0xFFE0E0E0), 2),
                errorBorder: _border(Colors.red, 1.5),
                focusedErrorBorder: _border(Colors.red, 1.5),
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
              ),
            ),
          ),

           if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 28),
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

          const SizedBox(height: 18),
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
                  onTap: _isLoading ? null : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() { _isLoading = true; _errorMessage = null; });
                  try {
                    final email = _emailController.text.trim();
                    // Check the account exists before sending OTP
                    await AuthService().checkEmailExists(email); // reuse the existence-check logic
                     if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => otpresetpassPage(
                                  contact: email,
                                  isPhoneFlow: false,
                                ),
                              ),
                            );
                  } catch (e) {
                    setState(() => _errorMessage = e.toString());
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                   child: Center(
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text("Send Code",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Phone_widg extends StatefulWidget {
  const Phone_widg({super.key});

  @override
  State<Phone_widg> createState() => _Phone_widgState();
}

class _Phone_widgState extends State<Phone_widg> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  OutlineInputBorder _border([Color color = const Color(0xFFE0E0E0), double width = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: width));

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          Container(
            margin: const EdgeInsets.only(left: 34),
            child: const Text(
              "Phone Number",
              style: TextStyle(fontFamily: "Inter", fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xff1f2937), height: 14 / 18),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 24, right: 24),
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Phone number is required';
                if (value.length != 10) return 'Phone number must be 10 digits';
                if (!value.startsWith('05') && !value.startsWith('06') && !value.startsWith('07')) {
                  return 'Number must start with 05, 06, or 07';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Ex:0555555555',
                hintStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), fontSize: 17, fontFamily: 'Lexend'),
                prefixIcon: const Icon(Icons.phone, size: 22, color: Color(0xFF94A3B8)),
                enabledBorder: _border(),
                focusedBorder: _border(const Color(0xFFE0E0E0), 2),
                errorBorder: _border(Colors.red, 1.5),
                focusedErrorBorder: _border(Colors.red, 1.5),
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
              ),
            ),
          ),

           if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 28),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13, fontFamily: 'Inter'))),
                ],
              ),
            ),

          const SizedBox(height: 18),
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
                 onTap: _isLoading ? null : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() { _isLoading = true; _errorMessage = null; });
                  try {
                    final rawPhone = _phoneController.text.trim();
                    final e164Phone = toE164(rawPhone, '213'); // your existing helper

                    // Verify this phone is linked to an account
                    await AuthService().getEmailFromPhone(e164Phone); // throws if not found

                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => otpresetpassPage(
                        contact: e164Phone,
                        isPhoneFlow: true,
                      ),
                    ));
                  } catch (e) {
                    setState(() => _errorMessage = e.toString());
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                  child: const Center(
                    child: Text("Send Code", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
String toE164(String local, String countryCode) {
  final digits = local.replaceAll(RegExp(r'\D'), '');
  return '+$countryCode${digits.startsWith('0') ? digits.substring(1) : digits}';
}

