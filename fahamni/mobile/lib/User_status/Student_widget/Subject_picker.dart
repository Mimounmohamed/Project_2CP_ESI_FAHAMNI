import 'package:flutter/material.dart';

class SubjectPickerWidget extends StatefulWidget {
  final int i;
  const SubjectPickerWidget(this.i,{super.key});

  @override
  State<SubjectPickerWidget> createState() => SubjectPickerWidgetState();
}

class SubjectPickerWidgetState extends State<SubjectPickerWidget> {
  final List<List<String>> subjectLists = [
  // 1st Year Primary School
  [
    'Arabic Language', 'Mathematics', 'Islamic Education', 'Civic Education',
    'Art Education', 'Physical Education and Sports'
  ],
  
  // 2nd Year Primary School
  [
    'Arabic Language', 'Mathematics', 'Islamic Education', 'Civic Education',
    'Art Education', 'Physical Education and Sports'
  ],
  
  // 3rd Year Primary School
  [
    'Arabic Language', 'Mathematics', 'Science', 'History - Geography',
    'French', 'English', 'Islamic Education', 'Civic Education',
    'Art Education', 'Physical Education and Sports'
  ],
  
  // 4th Year Primary School
  [
    'Arabic Language', 'Tamazight Language (region dependent)', 'Mathematics', 'Science',
    'History - Geography', 'French', 'English', 'Islamic Education',
    'Civic Education', 'Art Education', 'Physical Education and Sports'
  ],
  
  // 5th Year Primary School
  [
    'Arabic Language', 'Tamazight Language (region dependent)', 'Mathematics', 'Science',
    'History - Geography', 'French', 'English', 'Islamic Education',
    'Civic Education', 'Art Education', 'Physical Education and Sports'
  ],
  
  // 1st Year Middle School
  [
    'Arabic Language', 'Tamazight Language (region dependent)', 'Mathematics',
    'Life and Earth Sciences', 'Physics Sciences and Technology',
    'History - Geography', 'French', 'English', 'Islamic Education',
    'Civic Education', 'Computer Science', 'Art Education',
    'Physical Education and Sports'
  ],
  
  // 2nd Year Middle School
  [
    'Arabic Language', 'Tamazight Language (region dependent)', 'Mathematics',
    'Life and Earth Sciences', 'Physics Sciences',
    'History - Geography', 'French', 'English', 'Islamic Education',
    'Civic Education', 'Computer Science', 'Art Education',
    'Physical Education and Sports'
  ],
  
  // 3rd Year Middle School
  [
    'Arabic Language', 'Tamazight Language (region dependent)', 'Mathematics',
    'Life and Earth Sciences', 'Physics Sciences',
    'History - Geography', 'French', 'English', 'Islamic Education',
    'Civic Education', 'Computer Science', 'Art Education',
    'Physical Education and Sports'
  ],
  
  // 4th Year Middle School
  [
    'Arabic Language', 'Tamazight Language (region dependent)', 'Mathematics',
    'Life and Earth Sciences', 'Physics Sciences',
    'History - Geography', 'French', 'English', 'Islamic Education',
    'Civic Education', 'Computer Science', 'Art Education',
    'Physical Education and Sports'
  ],
  
  // High School - Experimental Sciences
  [
    'Arabic Language', 'Tamazight Language (region dependent)', 'Philosophy',
    'Mathematics', 'Life and Earth Sciences',
    'Physics Sciences', 'History - Geography', 'French', 'English',
    'Islamic Education', 'Physical Education and Sports'
  ],
  
  // High School - Mathematics
  [
    'Arabic Language', 'Tamazight Language (region dependent)', 'Philosophy',
    'Advanced Mathematics', 'Physics Sciences',
    'Life and Earth Sciences', 'History - Geography', 'French',
    'English', 'Islamic Education', 'Physical Education and Sports'
  ],
  
  // High School - Technical Mathematics
  [
    'Arabic Language', 'Tamazight Language (region dependent)', 'Philosophy',
    'Mathematics', 'Physics Sciences', 'Industrial Technology',
    'Engineering (specialty dependent)', 'Technical Drawing', 'History - Geography',
    'French', 'English', 'Islamic Education', 'Physical Education and Sports'
  ],
  
  // High School - Management and Economics
  [
    'Arabic Language', 'Tamazight Language (region dependent)', 'Philosophy',
    'Applied Mathematics', 'General Economics', 'Management and Accounting',
    'Law', 'History - Geography', 'French', 'English',
    'Islamic Education', 'Physical Education and Sports'
  ],
  
  // High School - Letters and Philosophy
  [
    'Advanced Arabic Language', 'Tamazight Language (region dependent)',
    'Advanced Philosophy', 'History - Geography', 'Islamic Sciences',
    'French', 'English', 'Light Mathematics', 'Physical Education and Sports'
  ],
  
  // High School - Foreign Languages
  [
    'Arabic Language', 'Tamazight Language (region dependent)', 'Philosophy',
    'Advanced French', 'Advanced English', 'Third Foreign Language',
    'History - Geography', 'Light Mathematics', 'Islamic Education',
    'Physical Education and Sports'
  ],
  
  // Higher Education - 1CP (Engineering 1st Year)
  [
    'Electricity', 'Office Automation and Web', 'English 1', 'Mathematical Analysis 1',
    'Algorithms and Static Data Structures', 'Computer Architecture 1',
    'Algebra 1', 'Introduction to Operating Systems 1', 'Written Expression Techniques',
    'Algorithms and Dynamic Data Structures',
    'Introduction to Operating Systems 2', 'English 1',
    'Oral Expression Techniques', 'Algebra 2', 'Mathematical Analysis 2',
    'Fundamental Electronics 1', 'Point Mechanics'
  ],
  
 
  
  // Higher Education - 2CP (Engineering 2nd Year)
  [
    'Business Economics', 'Mathematical Analysis 3',
    'Computer Architecture 2', 'Fundamental Electronics 2',
    'English 2', 'Algebra 3', 'File Structures and Data Structures',
    'Probability & Statistics 1','English 3', 'Mathematical Logic', 'Optics and Electromagnetic Waves',
    'Probability & Statistics 2', 'Object-Oriented Programming',
    'Mathematical Analysis 4', 'Information Systems', 'Project 2CPI'
  ],
  
 
  
  // Higher Education - 1CS  (Engineering 3rd Year)
  [
    'Centralized Operating Systems 1', 'Introduction to Software Engineering',
    'Operational Research', 'Programming Language Theory',
    'Organizational Analysis', 'Networks 1', 'Numerical Analysis', 'English',
    'Computer Architecture 3', 'Project Management', 'Networks 2',
    'Databases', 'IS Design Methodology',
    'Computer Security', 'Centralized Operating Systems 2',
    'Project 1CS'
  ],
  
  // Higher Education - 2CS Main Modules (Engineering 4th Year)
  [
    'High Performance Computing', 'Machine Learning', 'Data Analysis',
    'Advanced Databases', 'Signal Processing',
    'Complexity and Problem Solving', 'Information Visualization',
    'Advanced Mathematics for Data Science', 'Smart Government'
  ],
  
  // Higher Education - 3CS Master (Engineering 5th Year/Master)
  [
    'Artificial Intelligence', 'Information System Architectures',
    'Research Valorization', 'Distributed Systems', 'Agent Technology',
    'Machine Learning', 'Research Methodology', 'IT Master Plan',
    'Advanced Networks and Simulation', 'Information Visualization',
    'Information Retrieval'
  ]
];

  List<String> selectedSubjects = [];

  void _showSubjectPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => ListView(
          children: subjectLists[widget.i].map((subject) => ListTile(
            title: Text(subject),
            trailing: selectedSubjects.contains(subject)
                ? const Icon(Icons.check, color: Color(0xFF000080))
                : null,
            onTap: () {
              setState(() {
                if (selectedSubjects.contains(subject)) {
                  selectedSubjects.remove(subject);
                } else {
                  selectedSubjects.add(subject);
                }
              });
              setModalState(() {}); // updates checkmarks inside sheet
            },
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Container(
                margin: const EdgeInsets.only(left: 10),
                child:
              const Text(
                "Interests / Subjects of Focus",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1f2937),
                  height: 14 / 18,
                ),
              ),),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // selected chips
            ...selectedSubjects.map((subject) => Chip(
              label: Text(
                subject,
                style: const TextStyle(
                  color: Color(0xFF000080),
                  fontWeight: FontWeight.w700,
                ),
              ),
              deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF000080)),
              onDeleted: () => setState(() => selectedSubjects.remove(subject)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            )),

            // Add more button
            GestureDetector(
              onTap: () => _showSubjectPicker(context),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 10, 10),
                child:
              const Text(
                "Add more...",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF94A3B8),
                  height: 14 / 18,
                ),
              ),),
            ),
          ],
        ),
      ],
    ),);
  }
}

