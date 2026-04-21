import 'package:flutter/material.dart';
import 'file_uploader.dart';

// ── Subject pools per teaching level ─────────────────────────────────────────
const List<String> _primarySubjects = [
  'Arabic Language', 'Mathematics', 'Islamic Education', 'Civic Education',
  'Art Education', 'Physical Education and Sports', 'Science',
  'History - Geography', 'French', 'English',
  'Tamazight Language (region dependent)',
];

const List<String> _middleSubjects = [
  'Arabic Language', 'Tamazight Language (region dependent)', 'Mathematics',
  'Life and Earth Sciences', 'Physics Sciences and Technology', 'Physics Sciences',
  'History - Geography', 'French', 'English', 'Islamic Education',
  'Civic Education', 'Computer Science', 'Art Education',
  'Physical Education and Sports',
];

const List<String> _highSubjects = [
  'Arabic Language', 'Tamazight Language (region dependent)', 'Philosophy',
  'Mathematics', 'Advanced Mathematics', 'Life and Earth Sciences',
  'Physics Sciences', 'Industrial Technology', 'Engineering (specialty dependent)',
  'Technical Drawing', 'Applied Mathematics', 'General Economics',
  'Management and Accounting', 'Law', 'History - Geography', 'French', 'English',
  'Islamic Education', 'Physical Education and Sports', 'Advanced Arabic Language',
  'Advanced Philosophy', 'Islamic Sciences', 'Light Mathematics',
  'Advanced French', 'Advanced English', 'Third Foreign Language',
];

const List<String> _universitySubjects = [
  'Electricity', 'Office Automation and Web', 'Mathematical Analysis',
  'Algorithms and Static Data Structures', 'Computer Architecture',
  'Algebra', 'Introduction to Operating Systems', 'Written Expression Techniques',
  'Algorithms and Dynamic Data Structures', 'Oral Expression Techniques',
  'Fundamental Electronics', 'Point Mechanics', 'Business Economics',
  'File Structures and Data Structures', 'Probability & Statistics',
  'Mathematical Logic', 'Optics and Electromagnetic Waves',
  'Object-Oriented Programming', 'Information Systems',
  'Centralized Operating Systems', 'Introduction to Software Engineering',
  'Operational Research', 'Programming Language Theory',
  'Organizational Analysis', 'Networks', 'Numerical Analysis', 'English',
  'Project Management', 'Databases', 'IS Design Methodology', 'Computer Security',
  'High Performance Computing', 'Machine Learning', 'Data Analysis',
  'Advanced Databases', 'Signal Processing', 'Complexity and Problem Solving',
  'Information Visualization', 'Advanced Mathematics for Data Science',
  'Smart Government', 'Artificial Intelligence', 'Information System Architectures',
  'Research Valorization', 'Distributed Systems', 'Agent Technology',
  'Research Methodology', 'IT Master Plan', 'Advanced Networks and Simulation',
  'Information Retrieval',
];

const Map<String, List<String>> _subjectsByLevel = {
  'Primary':    _primarySubjects,
  'Middle':     _middleSubjects,
  'High':       _highSubjects,
  'University': _universitySubjects,
};

const List<String> _levels = ['Primary', 'Middle', 'High', 'University'];

// ─────────────────────────────────────────────────────────────────────────────

class TeacherDetailsWidget extends StatefulWidget {
  const TeacherDetailsWidget({super.key});

  @override
  State<TeacherDetailsWidget> createState() => TeacherDetailsWidgetState();
}

class TeacherDetailsWidgetState extends State<TeacherDetailsWidget> {
  final _formKey = GlobalKey<FormState>();
  final degreeController     = TextEditingController();
  final universityController = TextEditingController();
  final expController        = TextEditingController();
  final bioController        = TextEditingController();

  final fileKey = GlobalKey<FileUploadWidgetState>();

  List<String> selectedLevels  = [];
  List<String> selectedDomains = [];

  bool _levelError  = false;
  bool _domainError = false;

  List<String> get _availableDomains {
    final Set<String> pool = {};
    for (final level in selectedLevels) {
      pool.addAll(_subjectsByLevel[level] ?? []);
    }
    return pool.toList()..sort();
  }

  bool validate() {
    final formValid = _formKey.currentState!.validate();
    final fileValid = fileKey.currentState?.validate() ?? false;
    final levelValid  = selectedLevels.isNotEmpty;
    final domainValid = selectedDomains.isNotEmpty;
    setState(() {
      _levelError  = !levelValid;
      _domainError = !domainValid;
    });
    return formValid && fileValid && levelValid && domainValid;
  }

  @override
  void dispose() {
    degreeController.dispose();
    universityController.dispose();
    expController.dispose();
    bioController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  OutlineInputBorder _border([Color color = const Color(0xFFE0E0E0), double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  void _showLevelPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            const Text('Select Teaching Levels',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937))),
            const Divider(),
            ..._levels.map((level) {
              final selected = selectedLevels.contains(level);
              return CheckboxListTile(
                value: selected,
                activeColor: const Color(0xFF000080),
                title: Text(level,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                onChanged: (_) {
                  setState(() {
                    if (selected) {
                      selectedLevels.remove(level);
                      // remove domains no longer available
                      final stillAvailable = _availableDomains;
                      selectedDomains.removeWhere(
                          (d) => !stillAvailable.contains(d));
                    } else {
                      selectedLevels.add(level);
                    }
                    _levelError = false;
                  });
                  setModal(() {});
                },
              );
            }),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDomainPicker() {
    if (selectedLevels.isEmpty) return;
    final domains = _availableDomains;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              const Text('Select Expertise Domains',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937))),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: domains.map((domain) {
                    final selected = selectedDomains.contains(domain);
                    return CheckboxListTile(
                      value: selected,
                      activeColor: const Color(0xFF000080),
                      title: Text(domain,
                          style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 14)),
                      onChanged: (_) {
                        setState(() {
                          if (selected) {
                            selectedDomains.remove(domain);
                          } else {
                            selectedDomains.add(domain);
                          }
                          _domainError = false;
                        });
                        setModal(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000080),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Done',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _multiSelectField({
    required String label,
    required String hint,
    required List<String> selected,
    required bool enabled,
    required bool hasError,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 34),
          child: Text(label,
              style: const TextStyle(
                  fontFamily: "Inter",
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1f2937),
                  height: 14 / 18)),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? Colors.red
                    : enabled
                        ? const Color(0xFFE0E0E0)
                        : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.school_outlined,
                    size: 22,
                    color: enabled
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFFCBD5E1)),
                const SizedBox(width: 10),
                Expanded(
                  child: selected.isEmpty
                      ? Text(hint,
                          style: TextStyle(
                              color: enabled
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFFCBD5E1),
                              fontSize: 17,
                              fontFamily: 'Lexend'))
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: selected
                              .map((item) => Chip(
                                    label: Text(item,
                                        style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: Color(0xFF000080),
                                            fontWeight: FontWeight.w600)),
                                    deleteIcon: const Icon(Icons.close,
                                        size: 14, color: Color(0xFF000080)),
                                    onDeleted: () {
                                      setState(() {
                                        selected.remove(item);
                                      });
                                    },
                                    backgroundColor: const Color(0xFFEEF2FF),
                                    side: const BorderSide(
                                        color: Color(0xFFD0D5FF)),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: EdgeInsets.zero,
                                  ))
                              .toList(),
                        ),
                ),
                Icon(Icons.keyboard_arrow_down,
                    color: enabled
                        ? const Color(0xFF6B7280)
                        : const Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 6),
            child: Text(
              'Please select at least one ${label.toLowerCase()}',
              style: const TextStyle(
                  color: Colors.red, fontSize: 12, fontFamily: 'Inter'),
            ),
          ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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

          // ── Highest Degree ──────────────────────────────────────────────
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
              controller: degreeController,
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

          // ── University ──────────────────────────────────────────────────
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
              controller: universityController,
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

          // ── Level (multi-select) ────────────────────────────────────────
          _multiSelectField(
            label: 'Level',
            hint: 'Select a Level',
            selected: selectedLevels,
            enabled: true,
            hasError: _levelError,
            onTap: _showLevelPicker,
            onRemove: () {},
          ),
          const SizedBox(height: 12),

          // ── Expertise Domain (multi-select, locked until level chosen) ──
          _multiSelectField(
            label: 'Expertise Domain',
            hint: selectedLevels.isEmpty
                ? 'Select a level first'
                : 'Select a Domain',
            selected: selectedDomains,
            enabled: selectedLevels.isNotEmpty,
            hasError: _domainError,
            onTap: _showDomainPicker,
            onRemove: () {},
          ),
          const SizedBox(height: 12),

          // ── Experience ──────────────────────────────────────────────────
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
              controller: expController,
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

          // ── Bio ─────────────────────────────────────────────────────────
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
              controller: bioController,
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

          // ── Certifications ──────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(left: 34),
            child: const Text(
              "Certifications (PDF/JPG)",
              style: TextStyle(fontFamily: "Inter", fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xff1f2937), height: 14 / 18),
            ),
          ),
          const SizedBox(height: 8),
          FileUploadWidget(key: fileKey),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
