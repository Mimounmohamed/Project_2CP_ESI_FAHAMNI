import 'package:flutter/material.dart';
import '../Home_Screens/Student_HS/Student_homepage.dart';
import '../Services/email_otp_service.dart';


class RegistrationComplete extends StatefulWidget {
  final String email;
  final String firstName;
  const RegistrationComplete({super.key , required this.email, required this.firstName});

  @override
  State<RegistrationComplete> createState() => _RegistrationCompleteState();
}

class _RegistrationCompleteState extends State<RegistrationComplete> {
  @override
  void initState() {
    super.initState();
    EmailOtpService().sendWelcomeEmail(email: widget.email, firstName: widget.firstName);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Color(0xFF0F172A),
          ),
          onPressed: () {
            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const Studentpage()),
                              );
          },
        ),
        title: const Text(
          "Registration Complete",
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [

            const SizedBox(height: 120),

            /// Image
            Image.asset(
              'assets/images/Vector@2x.png',
              height: 120,
            ),

            const SizedBox(height: 30),

            /// Congratulations Title
            const Text(
              'Congratulations!',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            /// Description
            const Text(
              'Your profile is all set. Welcome to our learning community! '
              'Start exploring courses or complete your bio.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
                height: 26 / 16, // 26px line height
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            /// Go to Dashboard Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0B1F8F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const Studentpage()),
                              );
                },
                child: const Text(
                  'Go to Dashboard',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Complete Profile Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFF0B1F8F) ,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {

                },
                child: const Text(
                  'Complete Profile',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B1F8F) ,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}