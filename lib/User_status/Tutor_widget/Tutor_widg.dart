import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'file_uploader.dart';

class TeacherDetailsWidget extends StatefulWidget {
  const TeacherDetailsWidget({super.key});

  @override
  State<TeacherDetailsWidget> createState() => TeacherDetailsWidgetState();
}

class TeacherDetailsWidgetState extends State<TeacherDetailsWidget> {
  final _formKey = GlobalKey<FormState>();
  final _degreeController = TextEditingController();
  final _universityController = TextEditingController();
  final _expController = TextEditingController();
  final _bioController = TextEditingController();

  // ← ADD THIS
  final _fileKey = GlobalKey<FileUploadWidgetState>();

  // ← UPDATE THIS to include file validation
  bool validate() {
    final formValid = _formKey.currentState!.validate();
    final fileValid = _fileKey.currentState?.validate() ?? false;
    return formValid && fileValid;
  }

  @override
  void dispose() {
    _degreeController.dispose();
    _universityController.dispose();
    _expController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  OutlineInputBorder _border([Color color = const Color(0xFFE0E0E0), double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 20),
            child: const Text(
              "Tutor Information",
              style: TextStyle(
                letterSpacing: -0.25,
                fontFamily: "Inter",
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xff1f2937),
                height: 30 / 18,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 34),
            child: const Text(
              "Highest Degree Earned",
              style: TextStyle(fontFamily: "Inter", fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xff1f2937), height: 14 / 18),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 24, right: 24),
            child: TextFormField(
              controller: _degreeController,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Degree is required';
                return null;
              },
              decoration: InputDecoration(
                hintText: "e.g. Master's in Education",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 17, fontFamily: 'Lexend'),
                prefixIcon: const Icon(Icons.school_outlined, size: 22, color: Color(0xFF94A3B8)),
                enabledBorder: _border(),
                focusedBorder: _border(const Color(0xFFE0E0E0), 2),
                errorBorder: _border(Colors.red, 1.5),
                focusedErrorBorder: _border(Colors.red, 1.5),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.only(left: 34),
            child: const Text(
              "Graduation University",
              style: TextStyle(fontFamily: "Inter", fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xff1f2937), height: 14 / 18),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 24, right: 24),
            child: TextFormField(
              controller: _universityController,
              validator: (value) {
                if (value == null || value.isEmpty) return 'University name is required';
                return null;
              },
              decoration: InputDecoration(
                hintText: "Enter university name",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 17, fontFamily: 'Lexend'),
                prefixIcon: const Icon(Icons.account_balance_outlined, size: 22, color: Color(0xFF94A3B8)),
                enabledBorder: _border(),
                focusedBorder: _border(const Color(0xFFE0E0E0), 2),
                errorBorder: _border(Colors.red, 1.5),
                focusedErrorBorder: _border(Colors.red, 1.5),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.only(left: 34),
            child: const Text(
              "Exp. (Years)",
              style: TextStyle(fontFamily: "Inter", fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xff1f2937), height: 14 / 18),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 24, right: 24),
            child: TextFormField(
              controller: _expController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Experience is required';
                final n = int.tryParse(value);
                if (n == null || n < 0) return 'Enter a valid number';
                return null;
              },
              decoration: InputDecoration(
                hintText: "Enter a number",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 17, fontFamily: 'Lexend'),
                prefixIcon: const Icon(Icons.work, size: 22, color: Color(0xFF94A3B8)),
                enabledBorder: _border(),
                focusedBorder: _border(const Color(0xFFE0E0E0), 2),
                errorBorder: _border(Colors.red, 1.5),
                focusedErrorBorder: _border(Colors.red, 1.5),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.only(left: 34),
            child: const Text(
              "Specialization & Bio",
              style: TextStyle(fontFamily: "Inter", fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xff1f2937), height: 14 / 18),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 24, right: 24),
            child: TextFormField(
              controller: _bioController,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please describe your specialization';
                if (value.trim().length < 20) return 'Please write at least 20 characters';
                return null;
              },
              decoration: InputDecoration(
                hintText: "Describe your teaching style and subjects...",
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15, fontFamily: 'Lexend'),
                enabledBorder: _border(),
                focusedBorder: _border(const Color(0xFFE0E0E0), 2),
                errorBorder: _border(Colors.red, 1.5),
                focusedErrorBorder: _border(Colors.red, 1.5),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.only(left: 34),
            child: const Text(
              "Certifications (PDF/JPG)",
              style: TextStyle(fontFamily: "Inter", fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xff1f2937), height: 14 / 18),
            ),
          ),
          const SizedBox(height: 8),

          // ← ADD key HERE
          FileUploadWidget(key: _fileKey),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}