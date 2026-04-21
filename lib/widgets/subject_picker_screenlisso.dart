import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class SubjectPickerlissoWidget extends StatefulWidget {
  final int i;
  final List<String> initialSelected;
  final ValueChanged<List<String>>? onChanged;

  const SubjectPickerlissoWidget(this.i, {super.key, this.initialSelected = const [], this.onChanged});

  @override
  State<SubjectPickerlissoWidget> createState() => _SubjectPickerlissoWidgetState();
}

class _SubjectPickerlissoWidgetState extends State<SubjectPickerlissoWidget> {
  final List<List<String>> subjectLists = [
    // 1st Year Primary
    [
      'Arabic Language',
      'Mathematics',
      'Islamic Education',
      'Civic Education',
      'Art Education',
      'Physical Education and Sports'
    ],

    // 2nd Year Primary
    [
      'Arabic Language',
      'Mathematics',
      'Islamic Education',
      'Civic Education',
      'Art Education',
      'Physical Education and Sports'
    ],

    // 3rd Year Primary
    [
      'Arabic Language',
      'Mathematics',
      'Science',
      'History - Geography',
      'French',
      'English',
      'Islamic Education',
      'Civic Education',
      'Art Education',
      'Physical Education and Sports'
    ],

    // 4th Year Primary
    [
      'Arabic Language',
      'Tamazight Language (region dependent)',
      'Mathematics',
      'Science',
      'History - Geography',
      'French',
      'English',
      'Islamic Education',
      'Civic Education',
      'Art Education',
      'Physical Education and Sports'
    ],

    // 5th Year Primary
    [
      'Arabic Language',
      'Tamazight Language (region dependent)',
      'Mathematics',
      'Science',
      'History - Geography',
      'French',
      'English',
      'Islamic Education',
      'Civic Education',
      'Art Education',
      'Physical Education and Sports'
    ],

    // 1st Year Middle
    [
      'Arabic Language',
      'Tamazight Language (region dependent)',
      'Mathematics',
      'Life and Earth Sciences',
      'Physics Sciences and Technology',
      'History - Geography',
      'French',
      'English',
      'Islamic Education',
      'Civic Education',
      'Computer Science',
      'Art Education',
      'Physical Education and Sports'
    ],

    // 2nd Year Middle
    [
      'Arabic Language',
      'Tamazight Language (region dependent)',
      'Mathematics',
      'Life and Earth Sciences',
      'Physics Sciences',
      'History - Geography',
      'French',
      'English',
      'Islamic Education',
      'Civic Education',
      'Computer Science',
      'Art Education',
      'Physical Education and Sports'
    ],

    // 3rd Year Middle
    [
      'Arabic Language',
      'Tamazight Language (region dependent)',
      'Mathematics',
      'Life and Earth Sciences',
      'Physics Sciences',
      'History - Geography',
      'French',
      'English',
      'Islamic Education',
      'Civic Education',
      'Computer Science',
      'Art Education',
      'Physical Education and Sports'
    ],

    // 4th Year Middle
    [
      'Arabic Language',
      'Tamazight Language (region dependent)',
      'Mathematics',
      'Life and Earth Sciences',
      'Physics Sciences',
      'History - Geography',
      'French',
      'English',
      'Islamic Education',
      'Civic Education',
      'Computer Science',
      'Art Education',
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

  @override
  void initState() {
    super.initState();
    selectedSubjects = List.from(widget.initialSelected);
  }

  @override
  void didUpdateWidget(SubjectPickerlissoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.i != widget.i) {
      setState(() => selectedSubjects = List.from(widget.initialSelected));
    }
  }

  void _showSubjectPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => ListView(
          children: subjectLists[widget.i]
              .map(
                (subject) => ListTile(
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
                    widget.onChanged?.call(List.from(selectedSubjects));
                    setModalState(() {});
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 92),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color.fromRGBO(0, 0, 128, 0.10),
        width: 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.05),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...selectedSubjects.map(
              (subject) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 0, 128, 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontFamily: "Inter",
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000080),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() => selectedSubjects.remove(subject));
                        widget.onChanged?.call(List.from(selectedSubjects));
                      },
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF000080),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// + Add Subject 
            GestureDetector(
              onTap: () => _showSubjectPicker(context),
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(20),
                dashPattern: const [4, 4],
                color: const Color.fromRGBO(0, 0, 128, 0.35),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.add,
                        size: 16,
                        color: Color.fromRGBO(0, 0, 128, 0.60),
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Add Subject",
                        style: TextStyle(
                          fontFamily: "Nunito",
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(0, 0, 128, 0.60),
                          height: 20 / 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
}