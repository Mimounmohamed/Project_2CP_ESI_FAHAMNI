import 'package:flutter/material.dart';
import 'phoneverif.dart';

class VerificationChoicePage extends StatefulWidget {
  final Map<String, dynamic> data;
  const VerificationChoicePage({super.key, required this.data});

  @override
  State<VerificationChoicePage> createState() => _VerificationChoicePageState();
}
class _VerificationChoicePageState extends State<VerificationChoicePage> {
  int _selectedIndex  = -1;   // -1 = nothing selected, 0 = email, 1 = phone
  bool _showMethodError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff9f9f9),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xfff9f9f9),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          iconSize: 24,
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
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
                  fontFamily: 'Inter', color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700, fontSize: 30, letterSpacing: -0.75,
                ),
              ),
              const Text(
                "A peaceful place for growth",
                style: TextStyle(
                  fontFamily: "Inter", fontSize: 16,
                  fontWeight: FontWeight.w400, color: Color(0xff64748B),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "Verify Your Account",
                style: TextStyle(
                  fontFamily: 'Inter', color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700, fontSize: 28,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Choose how you'd like to verify your account.",
                style: TextStyle(
                  fontFamily: "Inter", fontSize: 16,
                  fontWeight: FontWeight.w400, color: Color(0xff64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(30),
                  color: const Color(0xFFFAFAFA),
                ),
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                margin: const EdgeInsets.fromLTRB(80, 0, 88, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _selectedIndex = _selectedIndex == 0 ? -1 : 0;
                        _showMethodError = false;
                      }),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
                        backgroundColor: _selectedIndex == 0
                            ? const Color(0xFF000080)
                            : const Color(0xFFFAFAFA),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text("Email",
                        style: TextStyle(
                          fontFamily: "Inter", fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: _selectedIndex == 0
                              ? const Color(0xFFFAFAFA)
                              : const Color(0xFF000080),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _selectedIndex = _selectedIndex == 1 ? -1 : 1;
                        _showMethodError = false;
                      }),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
                        backgroundColor: _selectedIndex == 1
                            ? const Color(0xFF000080)
                            : const Color(0xFFFAFAFA),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text("Phone",
                        style: TextStyle(
                          fontFamily: "Inter", fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: _selectedIndex == 1
                              ? const Color(0xFFFAFAFA)
                              : const Color(0xFF000080),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedIndex == 0) ...[
                const SizedBox(height: 20),
                Text(
                  "We'll send a verification link to:\n${widget.data['email']}",
                  style: const TextStyle(
                    fontFamily: "Inter", fontSize: 15, color: Color(0xff64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_selectedIndex == 1) ...[
                const SizedBox(height: 20),
                Text(
                  "We'll send a 6-digit code to:\n${widget.data['phone']}",
                  style: const TextStyle(
                    fontFamily: "Inter", fontSize: 15, color: Color(0xff64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_showMethodError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.error_outline, color: Colors.red, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Please select Email or Phone to continue',
                        style: TextStyle(
                          color: Colors.red, fontSize: 13, fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000080),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33137FEC), offset: Offset(0, 8),  blurRadius: 10, spreadRadius: -6),
                      BoxShadow(color: Color(0x33137FEC), offset: Offset(0, 20), blurRadius: 25, spreadRadius: -5),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        if (_selectedIndex == -1) {
                          setState(() => _showMethodError = true);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PhoneVerificationPage(
                              data: {
                                ...widget.data,
                                'verificationMethod':
                                    _selectedIndex == 0 ? 'email' : 'phone',
                              },
                            ),
                          ),
                        );
                      },
                      child: const Center(
                        child: Text(
                          "Send Code",
                          style: TextStyle(
                            color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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