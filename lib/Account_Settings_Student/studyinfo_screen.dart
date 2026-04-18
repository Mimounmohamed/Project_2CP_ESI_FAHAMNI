import 'package:flutter/material.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/subject_picker_screenlisso.dart';

class StudyInfoScreen extends StatefulWidget {
  const StudyInfoScreen({super.key});

  @override
  State<StudyInfoScreen> createState() => _StudyInfoScreenState();
}

class _StudyInfoScreenState extends State<StudyInfoScreen> {
  String selectedLevel = "High School";
  String selectedGrade = "Experimental Sciences";
  int selectedIndex = 9; // default → High School Experimental Sciences

  // Levels
  final List<String> levels = [
    "Primary School",
    "Middle School",
    "High School",
    "Higher Education",
  ];

  // Grades per level
  final Map<String, List<String>> gradesMap = {
    "Primary School": [
      "1st year",
      "2nd year",
      "3rd year",
      "4th year",
      "5th year",
    ],
    "Middle School": [
      "1st year",
      "2nd year",
      "3rd year",
      "4th year",
    ],
    "High School": [
      "Experimental Sciences",
      "Mathematics",
      "Technical Mathematics",
      "Management and Economics",
      "Letters and Philosophy",
      "Foreign Languages",
    ],
    "Higher Education": [
      "1CP",
      "2CP",
      "1CS",
      "2CS",
      "3CS Master",
    ],
  };

  ///  MAP → SUBJECT INDEX (IMPORTANT)
  int getSubjectIndex() {
    if (selectedLevel == "Primary School") {
      return gradesMap["Primary School"]!.indexOf(selectedGrade);
    }

    if (selectedLevel == "Middle School") {
      return 5 + gradesMap["Middle School"]!.indexOf(selectedGrade);
    }

    if (selectedLevel == "High School") {
      return 9 + gradesMap["High School"]!.indexOf(selectedGrade);
    }

    if (selectedLevel == "Higher Education") {
      return 15 + gradesMap["Higher Education"]!.indexOf(selectedGrade);
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    selectedIndex = getSubjectIndex();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context), 
        ),

        centerTitle: true,
        title: const Text(
          "Study Info",
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // School Level
              const Text(
                "School Level",
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              dropdown(
                value: selectedLevel,
                items: levels,
                onChanged: (val) {
                  setState(() {
                    selectedLevel = val!;
                    selectedGrade = gradesMap[selectedLevel]!.first;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Grade
              const Text(
                "Grade",
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              dropdown(
                value: selectedGrade,
                items: gradesMap[selectedLevel]!,
                onChanged: (val) {
                  setState(() {
                    selectedGrade = val!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // School
              const CustomInputField(
                label: "School",
                hint: "Didouch Mourad",
              ),

              const SizedBox(height: 20),

              // Subjects title
              const Text(
                "Subjects of Interest",
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),

              // Dynamic Subject Picker
              SubjectPickerlissoWidget(selectedIndex),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Styled Dropdown 
  Widget dropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        style: const TextStyle(
          fontFamily: "Nunito",
          fontSize: 14,
          color: Color(0xFF111827),
        ),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ),
            )
            .toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.keyboard_arrow_down),
      ),
    );
  }
}