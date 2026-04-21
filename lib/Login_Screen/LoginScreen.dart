import 'package:flutter/material.dart';
import 'package:fahamni/user_infos/ipersonal_info.dart';
import '../Pass_recov_page/passRec.dart';
import '../ParentDashboread/ParentHomePage/home_page.dart';
import '../StudentHomePage/Student_homepage.dart';
import '../TeacherDashboard/teacher_dashboard.dart';
import '../Services/auth_.service.dart';
import '../models/user_model.dart';

class LoginScreenPage extends StatelessWidget {
  const LoginScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result == null) {
        setState(() => _errorMessage = 'Login failed. Please try again.');
        return;
      }

      if (!mounted) return;

      switch (result.role) {
        case UserRole.student:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Studentpage()),
          );
          break;
        case UserRole.tutor:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Teacherpage()),
          );
          break;
        case UserRole.parent:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Parentpage()),
          );
          break;
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.loginWithGoogle();

      if (result == null) {
        setState(
          () => _errorMessage = 'No account found for this Google account.',
        );
        return;
      }

      if (!mounted) return;

      switch (result.role) {
        case UserRole.student:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Studentpage()),
          );
          break;
        case UserRole.tutor:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Teacherpage()),
          );
          break;
        case UserRole.parent:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Parentpage()),
          );
          break;
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Top decorative dots
            Positioned(
              top: 20,
              left: 20,
              child: Image.asset('assets/images/Container (3).png', height: 20),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  const Text(
                    'LOGIN',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      letterSpacing: 0.35,
                    ),
                  ),
                  const SizedBox(height: 30),

                  Image.asset('assets/images/Vector@2x.png', height: 83),
                  const SizedBox(height: 11.5),

                  const Text(
                    'Fahamni',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.75,
                      height: 36 / 30,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),

                  const Text(
                    'A peaceful place for growth',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Decorative lines
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Container(
                          width: 32,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0x80000080),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 48,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0x80000080),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 24,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0x80000080),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14.5),

                  // ── FORM ──────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email label
                        const Text(
                          ' EMAIL OR PHONE NUMBER',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff1f2937),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Email or Phone number is required';
                            final isEmail = value.contains('@');
                            final isPhone = RegExp(
                              r'^(0[567]\d{8}|\+213\d{9})$',
                            ).hasMatch(value);
                            if (!isEmail && !isPhone)
                              return 'Enter a valid email or phone number';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'name@example.com or 055XXXXXXX',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.perm_identity,
                              color: Color(0xFF94A3B8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0x80F8FAFC),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF64748B),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password label
                        const Text(
                          'PASSWORD',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff1f2937),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Password is required';
                            if (value.length < 8) return 'Minimum 8 characters';
                            if (!value.contains(RegExp(r'[A-Z]')))
                              return 'Must contain at least one uppercase letter';
                            if (!value.contains(RegExp(r'[0-9]')))
                              return 'Must contain at least one number';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter password',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 20,
                              color: Color(0xFF94A3B8),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF94A3B8),
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0x80F8FAFC),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF64748B),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const passRec(),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF000080),
                              ),
                            ),
                          ),
                        ),

                        // Error message box
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // ── SIGN IN BUTTON ──────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF000080),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33137FEC),
                                  offset: Offset(0, 8),
                                  blurRadius: 10,
                                  spreadRadius: -6,
                                ),
                                BoxShadow(
                                  color: Color(0x33137FEC),
                                  offset: Offset(0, 20),
                                  blurRadius: 25,
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: _isLoading ? null : _handleLogin,
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
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

                        // ── END SIGN IN BUTTON ──────────────
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _handleGoogleLogin,
                          child: Container(
                            margin: const EdgeInsets.all(30),
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/SVG.png',
                                height: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFFAFAFA),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFFAFAFA),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Create account link
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IpersonalInfo(),
                        ),
                      );
                    },
                    child: Text.rich(
                      const TextSpan(
                        text: 'New to Fahamni? ',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Create Account',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF000080),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
