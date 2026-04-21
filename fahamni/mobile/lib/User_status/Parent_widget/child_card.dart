import 'package:flutter/material.dart';

class ChildCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;
  final VoidCallback? onRemove;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const ChildCard({
    super.key,
    required this.index,
    required this.data,
    required this.onRemove,
    required this.onChanged,
  });

  static const Map<String, List<String>> gradeMap = {
    'Primary': ['1st year', '2nd year', '3rd year', '4th year', '5th year'],
    'Middle':  ['1st year', '2nd year', '3rd year', '4th year'],
    'High':    ['1st year', '2nd year', '3rd year'],
  };

  static const Map<String, List<String>> SpecialityMap = {
    '1st year': ['Letters and Social Studies', 'Sciences and Technology'],
    '2nd year': [
      'Experimental Sciences', 'Mathematics',
      'Technical Mathematics(Mechanical Engineering)',
      'Technical Mathematics(Electrical Engineering)',
      'Technical Mathematics(Civil Engineering)',
      'Technical Mathematics(Methods (Chemistry))',
      'Management and Economics', 'Philosophy', 'Foreign Languages', 'Arts'
    ],
    '3rd year': [
      'Experimental Sciences', 'Mathematics',
      'Technical Mathematics(Mechanical Engineering)',
      'Technical Mathematics(Electrical Engineering)',
      'Technical Mathematics(Civil Engineering)',
      'Technical Mathematics(Methods (Chemistry))',
      'Management and Economics', 'Philosophy', 'Foreign Languages', 'Arts'
    ],
  };

  static const List<int> levelOffsets = [0, 5, 9];
  static const List<String> levelOrder = ['Primary', 'Middle', 'High'];

  int getRealIndex() {
    if (!levelOrder.contains(data['level'])) return 0;
    int offset = levelOffsets[levelOrder.indexOf(data['level'])];
    int gradePosition = gradeMap[data['level']]!.indexOf(data['grade']);
    return offset + gradePosition;
  }

  static const List<List<String>> subjectLists = [
    ['Arabic Language', 'Mathematics', 'Islamic Education', 'Civic Education', 'Art Education', 'Physical Education and Sports'],
    ['Arabic Language', 'Mathematics', 'Islamic Education', 'Civic Education', 'Art Education', 'Physical Education and Sports'],
    ['Arabic Language', 'Mathematics', 'Science', 'History - Geography', 'French', 'English', 'Islamic Education', 'Civic Education', 'Art Education', 'Physical Education and Sports'],
    ['Arabic Language', 'Tamazight Language (region dependent)', 'Mathematics', 'Science', 'History - Geography', 'French', 'English', 'Islamic Education', 'Civic Education', 'Art Education', 'Physical Education and Sports'],
    ['Arabic Language', 'Tamazight Language (region dependent)', 'Mathematics', 'Science', 'History - Geography', 'French', 'English', 'Islamic Education', 'Civic Education', 'Art Education', 'Physical Education and Sports'],
    ['Arabic Language', 'Tamazight Language (region dependent)', 'Mathematics', 'Life and Earth Sciences', 'Physics Sciences and Technology', 'History - Geography', 'French', 'English', 'Islamic Education', 'Civic Education', 'Computer Science', 'Art Education', 'Physical Education and Sports'],
    ['Arabic Language', 'Tamazight Language (region dependent)', 'Mathematics', 'Life and Earth Sciences', 'Physics Sciences', 'History - Geography', 'French', 'English', 'Islamic Education', 'Civic Education', 'Computer Science', 'Art Education', 'Physical Education and Sports'],
    ['Arabic Language', 'Tamazight Language (region dependent)', 'Mathematics', 'Life and Earth Sciences', 'Physics Sciences', 'History - Geography', 'French', 'English', 'Islamic Education', 'Civic Education', 'Computer Science', 'Art Education', 'Physical Education and Sports'],
    ['Arabic Language', 'Tamazight Language (region dependent)', 'Mathematics', 'Life and Earth Sciences', 'Physics Sciences', 'History - Geography', 'French', 'English', 'Islamic Education', 'Civic Education', 'Computer Science', 'Art Education', 'Physical Education and Sports'],
    ['Arabic Language', 'Tamazight Language (region dependent)', 'Philosophy', 'Mathematics', 'Life and Earth Sciences', 'Physics Sciences', 'History - Geography', 'French', 'English', 'Islamic Education', 'Physical Education and Sports'],
    ['Arabic Language', 'Tamazight Language (region dependent)', 'Philosophy', 'Advanced Mathematics', 'Physics Sciences', 'Life and Earth Sciences', 'History - Geography', 'French', 'English', 'Islamic Education', 'Physical Education and Sports'],
    ['Arabic Language', 'Tamazight Language (region dependent)', 'Philosophy', 'Mathematics', 'Physics Sciences', 'Industrial Technology', 'Engineering (specialty dependent)', 'Technical Drawing', 'History - Geography', 'French', 'English', 'Islamic Education', 'Physical Education and Sports'],
    ['Arabic Language', 'Tamazight Language (region dependent)', 'Philosophy', 'Applied Mathematics', 'General Economics', 'Management and Accounting', 'Law', 'History - Geography', 'French', 'English', 'Islamic Education', 'Physical Education and Sports'],
    ['Advanced Arabic Language', 'Tamazight Language (region dependent)', 'Advanced Philosophy', 'History - Geography', 'Islamic Sciences', 'French', 'English', 'Light Mathematics', 'Physical Education and Sports'],
    ['Arabic Language', 'Tamazight Language (region dependent)', 'Philosophy', 'Advanced French', 'Advanced English', 'Third Foreign Language', 'History - Geography', 'Light Mathematics', 'Islamic Education', 'Physical Education and Sports'],
  ];

  static OutlineInputBorder _border([Color color = const Color(0xFFE0E0E0), double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final List<String> grades =
        data['level'] != null ? gradeMap[data['level']] ?? [] : [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "CHILD ${index + 1}",
                  style: const TextStyle(
                    fontFamily: "Inter",
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.6,
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFEF4444), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Child Name
            const Text(
              "Child Name",
              style: TextStyle(
                fontFamily: "Inter",
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: data['name'],
              onChanged: (value) => onChanged({...data, 'name': value}),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Child name is required';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Mimoun Mahieddine',
                hintStyle: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF94A3B8)),
                enabledBorder: _border(),
                focusedBorder: _border(const Color(0xFFE0E0E0), 2),
                errorBorder: _border(Colors.red, 1.5),
                focusedErrorBorder: _border(Colors.red, 1.5),
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
              ),
            ),

            const SizedBox(height: 16),

            // Gender
            const Text(
              "Gender",
              style: TextStyle(
                fontFamily: "Inter",
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['Male', 'Female'].map((g) {
                final isSelected = data['gender'] == g.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(g),
                    selected: isSelected,
                    checkmarkColor: Colors.white,
                    selectedColor: const Color(0xFF000080),
                    backgroundColor: const Color(0xFFF9F9F9),
                    side: BorderSide(
                      color: data['genderError'] == true
                          ? Colors.red
                          : const Color(0xFFE0E0E0),
                    ),
                    labelStyle: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    onSelected: (_) {
                      onChanged({...data, 'gender': g.toLowerCase(), 'genderError': false});
                    },
                  ),
                );
              }).toList(),
            ),
            if (data['genderError'] == true)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Please select a gender',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            const SizedBox(height: 16),

            // Level of Study
            const Text(
              "Level of Study",
              style: TextStyle(
                fontFamily: "Inter",
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: data['level'],
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
              hint: const Text(
                'Select level',
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontFamily: 'Inter'),
              ),
              validator: (value) {
                if (value == null) return 'Please select a level';
                return null;
              },
              items: gradeMap.keys
                  .map((level) => DropdownMenuItem(
                        value: level,
                        child: Text(level,
                            style: const TextStyle(
                                color: Color(0xFF1f2937),
                                fontSize: 14,
                                fontFamily: 'Inter')),
                      ))
                  .toList(),
              onChanged: (value) {
                onChanged({...data, 'level': value, 'grade': null, 'speciality': null, 'subjects': <String>[]});
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF94A3B8)),
                enabledBorder: _border(),
                focusedBorder: _border(const Color(0xFFE0E0E0), 2),
                errorBorder: _border(Colors.red, 1.5),
                focusedErrorBorder: _border(Colors.red, 1.5),
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
              ),
            ),

            // Grade chips
            if (data['level'] != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    "Grade",
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  if (data['gradeError'] == true) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'Please select a grade',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: grades
                      .map((grade) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(grade),
                              checkmarkColor: Colors.white,
                              selected: data['grade'] == grade,
                              onSelected: (_) {
                                onChanged({
                                  ...data,
                                  'grade': grade,
                                  'gradeError': false,
                                  'speciality': null,
                                  'subjects': <String>[],
                                });
                              },
                              selectedColor: const Color(0xFF000080),
                              backgroundColor: const Color(0xFFF9F9F9),
                              side: BorderSide(
                                color: data['gradeError'] == true
                                    ? Colors.red
                                    : const Color(0xFFE0E0E0),
                              ),
                              labelStyle: TextStyle(
                                fontFamily: "Inter",
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: data['grade'] == grade
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],

            // Speciality chips (High school only)
            if (data['level'] == 'High' && data['grade'] != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    "Speciality",
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  if (data['specialityError'] == true) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'Please select a speciality',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (SpecialityMap[data['grade']] ?? [])
                      .map((speciality) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(speciality),
                              checkmarkColor: Colors.white,
                              selected: data['speciality'] == speciality,
                              onSelected: (_) {
                                onChanged({
                                  ...data,
                                  'speciality': speciality,
                                  'specialityError': false,
                                });
                              },
                              selectedColor: const Color(0xFF000080),
                              backgroundColor: const Color(0xFFF9F9F9),
                              side: BorderSide(
                                color: data['specialityError'] == true
                                    ? Colors.red
                                    : const Color(0xFFE0E0E0),
                              ),
                              labelStyle: TextStyle(
                                fontFamily: "Inter",
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: data['speciality'] == speciality
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],

            // Subjects chips
            if (data['grade'] != null) ...[
              const SizedBox(height: 16),
              const Text(
                "Interests / Subjects of Focus",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: subjectLists[getRealIndex()].map((subject) {
                    final List<String> selected =
                        List<String>.from(data['subjects'] ?? []);
                    final bool isSelected = selected.contains(subject);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(subject),
                        selected: isSelected,
                        checkmarkColor: Colors.white,
                        selectedColor: const Color(0xFF000080),
                        backgroundColor: const Color(0xFFF9F9F9),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        labelStyle: TextStyle(
                          fontFamily: "Inter",
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                        onSelected: (_) {
                          final List<String> updated =
                              List<String>.from(data['subjects'] ?? []);
                          if (isSelected) {
                            updated.remove(subject);
                          } else {
                            updated.add(subject);
                          }
                          onChanged({...data, 'subjects': updated});
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}