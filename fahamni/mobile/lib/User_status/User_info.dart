import 'package:flutter/material.dart';
import 'package:fahamni/widgets/widgets.dart';
import 'Student_widget/Student_widg.dart';
import 'Parent_widget/Parent_widg.dart';
import 'Tutor_widget/Tutor_widg.dart';
import 'package:fahamni/otp_verification_Screen/verification_choice_page.dart';
import 'package:fahamni/models/user_model.dart';

class studentinfo extends StatefulWidget {
  final Map<String, dynamic> data;
  const studentinfo({super.key, required this.data });

  @override
  State<studentinfo> createState() => _studentinfoState();
}

class _studentinfoState extends State<studentinfo> {
  int selectedIndex = -1;
  bool _showRoleError = false;

  // Keys to access each widget's validate() method
  final _studentKey = GlobalKey<Student_widgetState>();
  final _parentKey = GlobalKey<Parent_widgetState>();
  final _tutorKey = GlobalKey<TeacherDetailsWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff9f9f9),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: ElevatedButton(
          onPressed: () {
            if (selectedIndex == -1) {
              setState(() => _showRoleError = true);
              return;
            }

            bool isValid = true;

            if (selectedIndex == 0) {
              isValid = _studentKey.currentState?.validate() ?? false;
            } else if (selectedIndex == 1) {
              isValid = _parentKey.currentState?.validate() ?? false;
            } else if (selectedIndex == 2) {
              isValid = _tutorKey.currentState?.validate() ?? false;
            }

            if (!isValid) return;
            final data = widget.data;
            if (selectedIndex == 0){
              final s = _studentKey.currentState!;
              data['role'] = UserRole.student;
              data['schoolLevel'] = s.levels[s.selectedIndex];
              data['grade'] = s.selectedGrade;
              data['speciality'] = s.selectedSpeciality ?? '';
              data['learningObjectives'] = s.schoolController.text.trim();
              data['preferredSubjects'] = s.selectedSubjectsList;
            }
            else if (selectedIndex == 1){
              data['role'] = UserRole.parent;
              data['childrenUids'] = <String>[];
              data['children'] = _parentKey.currentState!.childrenData;
            }
            else if (selectedIndex == 2){
              final t = _tutorKey.currentState!;
              data['role'] = UserRole.tutor;
              data['academicDescription']    = '${t.degreeController.text.trim()} — ${t.universityController.text.trim()}';
              data['yearsOfExperience']      = int.tryParse(t.expController.text.trim()) ?? 0;
              data['pedagogicalDescription'] = t.bioController.text.trim();
              data['certified']              = (t.fileKey.currentState?.uploadedFiles.isNotEmpty) ?? false;
              data['expertiseDomain']        = t.selectedDomains.join(', ');
              data['levelsTaught']           = t.selectedLevels;
              data['teachingMode']           = '';
              data['isAvailable']            = false;
              data['averageRating']          = 0.0;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
               builder: (_) => VerificationChoicePage(data: data) 
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            shadowColor: const Color(0xFF000080),
            elevation: 6,
            backgroundColor: const Color(0xFF000080),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'NEXT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
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
        title: const Text(
          "User Registration",
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xff0f172a),
            height: 23 / 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Bare(2, 1),
              Container(
                margin: const EdgeInsets.only(left: 20),
                child: const Text(
                  "Who are you?",
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
              const SizedBox(height: 20),

              Buttons(
                selectedIndex,
                (index) => setState(() {
                  selectedIndex = index;
                  _showRoleError = false;
                }),
              ),

              if (_showRoleError)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Row(
                    children: const [
                      Icon(Icons.error_outline, color: Colors.red, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Please select who you are to continue',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              if (selectedIndex == 0) Student_widget(key: _studentKey),
              if (selectedIndex == 1) Parent_widget(key: _parentKey),
              if (selectedIndex == 2) TeacherDetailsWidget(key: _tutorKey),
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
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
      margin: const EdgeInsets.fromLTRB(10, 0, 18, 0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => onSelectionChanged(selectedIndex == 0 ? -1 : 0),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: selectedIndex == 0
                    ? const Color(0xFF000080)
                    : const Color(0xFFFAFAFA),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Student",
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: selectedIndex == 0
                        ? const Color(0xFFFAFAFA)
                        : const Color(0xFF000080),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ElevatedButton(
              onPressed: () => onSelectionChanged(selectedIndex == 1 ? -1 : 1),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: selectedIndex == 1
                    ? const Color(0xFF000080)
                    : const Color(0xFFFAFAFA),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Parent",
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: selectedIndex == 1
                        ? const Color(0xFFFAFAFA)
                        : const Color(0xFF000080),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ElevatedButton(
              onPressed: () => onSelectionChanged(selectedIndex == 2 ? -1 : 2),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: selectedIndex == 2
                    ? const Color(0xFF000080)
                    : const Color(0xFFFAFAFA),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Tutor",
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: selectedIndex == 2
                        ? const Color(0xFFFAFAFA)
                        : const Color(0xFF000080),
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

class Buttons1 extends StatefulWidget {
  const Buttons1({super.key});

  @override
  State<Buttons1> createState() => Buttons1State();
}

class Buttons1State extends State<Buttons1> {
  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => setState(() => selectedIndex = selectedIndex == 1 ? -1 : 1),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.fromLTRB(60, 15, 60, 15),
                backgroundColor: selectedIndex == 1 ? const Color(0xFF000080) : const Color(0xfff9f9f9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text("Primary",
                  style: TextStyle(
                    fontFamily: "Inter", fontSize: 20, fontWeight: FontWeight.w500,
                    color: selectedIndex == 1 ? const Color(0xFFFAFAFA) : const Color(0xFF94A3B8),
                    height: 24 / 16,
                  )),
            ),
            SizedBox.fromSize(size: const Size(20, 0)),
            ElevatedButton(
              onPressed: () => setState(() => selectedIndex = selectedIndex == 2 ? -1 : 2),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.fromLTRB(60, 15, 60, 15),
                backgroundColor: selectedIndex == 2 ? const Color(0xFF000080) : const Color(0xfff9f9f9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text("Middle",
                  style: TextStyle(
                    fontFamily: "Inter", fontSize: 20, fontWeight: FontWeight.w500,
                    color: selectedIndex == 2 ? const Color(0xFFFAFAFA) : const Color(0xFF94A3B8),
                    height: 24 / 16,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => setState(() => selectedIndex = selectedIndex == 3 ? -1 : 3),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.fromLTRB(60, 15, 60, 15),
                backgroundColor: selectedIndex == 3 ? const Color(0xFF000080) : const Color(0xfff9f9f9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text("Primary",
                  style: TextStyle(
                    fontFamily: "Inter", fontSize: 20, fontWeight: FontWeight.w500,
                    color: selectedIndex == 3 ? const Color(0xFFFAFAFA) : const Color(0xFF94A3B8),
                    height: 24 / 16,
                  )),
            ),
            SizedBox.fromSize(size: const Size(20, 0)),
            ElevatedButton(
              onPressed: () => setState(() => selectedIndex = selectedIndex == 4 ? -1 : 4),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.fromLTRB(60, 15, 60, 15),
                backgroundColor: selectedIndex == 4 ? const Color(0xFF000080) : const Color(0xfff9f9f9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text("Middle",
                  style: TextStyle(
                    fontFamily: "Inter", fontSize: 20, fontWeight: FontWeight.w500,
                    color: selectedIndex == 4 ? const Color(0xFFFAFAFA) : const Color(0xFF94A3B8),
                    height: 24 / 16,
                  )),
            ),
          ],
        ),
      ],
    );
  }
}

