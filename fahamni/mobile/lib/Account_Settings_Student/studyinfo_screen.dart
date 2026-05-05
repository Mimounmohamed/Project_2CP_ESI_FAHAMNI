import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fahamni/Services/auth_.service.dart';
import 'package:fahamni/models/user_model.dart';
import '../widgets/subject_picker_screenlisso.dart';


class StudyInfoScreen extends StatefulWidget {
  const StudyInfoScreen({super.key});

  @override
  State<StudyInfoScreen> createState() => _StudyInfoScreenState();
}

class _StudyInfoScreenState extends State<StudyInfoScreen> {
  final _authService      = AuthService();
  final _schoolController = TextEditingController();

  // ── Data ──────────────────────────────────────────────────────────────────
  final List<String> levels = [
    "Primary School",
    "Middle School",
    "High School",
    "Higher Education",
  ];

  final Map<String, List<String>> gradesMap = {
    "Primary School":   ["1st year","2nd year","3rd year","4th year","5th year"],
    "Middle School":    ["1st year","2nd year","3rd year","4th year"],
    "High School":      ["1st year","2nd year","3rd year"],
    "Higher Education": ["1CP","2CP","1CS","2CS","3CS","Master"],
  };

  // Speciality options per High School year
  static const Map<String, List<String>> _hsSpecialityMap = {
    '1st year': ['Letters and Social Studies', 'Sciences and Technology'],
    '2nd year': [
      'Experimental Sciences','Mathematics',
      'Technical Mathematics (Mechanical)','Technical Mathematics (Electrical)',
      'Technical Mathematics (Civil)','Technical Mathematics (Chemistry)',
      'Management and Economics','Philosophy','Foreign Languages','Arts',
    ],
    '3rd year': [
      'Experimental Sciences','Mathematics',
      'Technical Mathematics (Mechanical)','Technical Mathematics (Electrical)',
      'Technical Mathematics (Civil)','Technical Mathematics (Chemistry)',
      'Management and Economics','Philosophy','Foreign Languages','Arts',
    ],
  };

  // Speciality options per ESI grade
  static const Map<String, List<String>> _esiSpecialityMap = {
    '2CS':    ['Information Systems (SIT)','Computer Systems (SIQ)','Software Engineering (SIL)','AI & Data Science (SID)'],
    '3CS':    ['Information Systems (SIT)','Computer Systems (SIQ)','Software Engineering (SIL)','AI & Data Science (SID)'],
    'Master': ['AI & Data Science','Cyber Security','Intelligent Systems','Mobile & Embedded Intelligent Systems'],
  };

  // Maps values stored by the registration widget → this screen's level names
  static const _levelAlias = {
    'Primary':    'Primary School',
    'Middle':     'Middle School',
    'High':       'High School',
    'University': 'Higher Education',
  };

  // Maps High School speciality names → SubjectPicker index (offset 9)
  static const Map<String, int> _hsSpecialityIndex = {
    'Experimental Sciences':               9,
    'Sciences and Technology':             9,
    'Mathematics':                         10,
    'Technical Mathematics (Mechanical)':  11,
    'Technical Mathematics (Electrical)':  11,
    'Technical Mathematics (Civil)':       11,
    'Technical Mathematics (Chemistry)':   11,
    'Management and Economics':            12,
    'Philosophy':                          13,
    'Letters and Social Studies':          13,
    'Foreign Languages':                   14,
    'Arts':                                14,
  };

  String  selectedLevel    = "High School";
  String  selectedGrade    = "1st year";
  String? selectedSpeciality;
  int     selectedIndex    = 9;

  // Originals to detect changes
  String  _origLevel       = '';
  String  _origGrade       = '';
  String  _origSpeciality  = '';
  String  _origSchool      = '';
  List<String> _origSubjects = [];

  List<String> selectedSubjects = [];

  String? _uid;
  bool    _isLoading        = true;
  bool    _isSaving         = false;
  bool    _specialityError  = false;
  String? _errorMessage;

  bool _needsSpeciality() {
    if (selectedLevel == 'High School') return true;
    if (selectedLevel == 'Higher Education') {
      return _esiSpecialityMap.containsKey(selectedGrade);
    }
    return false;
  }

  List<String> _specialityOptions() {
    if (selectedLevel == 'High School') {
      return _hsSpecialityMap[selectedGrade] ?? [];
    }
    if (selectedLevel == 'Higher Education') {
      return _esiSpecialityMap[selectedGrade] ?? [];
    }
    return [];
  }

  bool get _isDirty =>
      selectedLevel != _origLevel ||
      selectedGrade != _origGrade ||
      (selectedSpeciality ?? '') != _origSpeciality ||
      _schoolController.text.trim() != _origSchool ||
      !_listEquals(selectedSubjects, _origSubjects);

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = [...a]..sort();
    final sb = [...b]..sort();
    for (int i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }

  int _getSubjectIndex() {
    if (selectedLevel == "Primary School") {
      return gradesMap["Primary School"]!.indexOf(selectedGrade);
    }
    if (selectedLevel == "Middle School") {
      return 5 + gradesMap["Middle School"]!.indexOf(selectedGrade);
    }
    if (selectedLevel == "High School") {
      if (selectedSpeciality != null) {
        return _hsSpecialityIndex[selectedSpeciality] ?? 9;
      }
      return 9 + gradesMap["High School"]!.indexOf(selectedGrade);
    }
    if (selectedLevel == "Higher Education") {
      if (selectedGrade == 'Master') return 19;
      return 15 + gradesMap["Higher Education"]!.indexOf(selectedGrade);
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _schoolController.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      _uid = user.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(_uid).get();
      final role = UserRole.values.firstWhere(
        (r) => r.name == (userDoc['role'] ?? 'student'),
        orElse: () => UserRole.student,
      );
      final collection = role == UserRole.student ? 'students'
          : role == UserRole.tutor ? 'tutors' : 'parents';

      final doc  = await FirebaseFirestore.instance
          .collection(collection).doc(_uid).get();
      final data = doc.data()!;

      final rawLevel    = data['school_level'] as String? ?? '';
      final storedLevel = rawLevel.isNotEmpty
          ? (_levelAlias[rawLevel] ?? rawLevel)
          : 'High School';
      final storedGrade = data['grade'] as String? ?? '';
      final storedSpec  = data['speciality'] as String? ?? '';
      final school      = data['learning_objectives'] as String? ?? '';
      final subjects    = List<String>.from(data['preferred_subjects'] ?? []);

      final validLevel = levels.contains(storedLevel) ? storedLevel : 'High School';
      final validGrade = (gradesMap[validLevel] ?? []).contains(storedGrade)
          ? storedGrade
          : gradesMap[validLevel]!.first;

      // Validate stored speciality against valid options for this level+grade
      final specOptions = _specialityOptionsFor(validLevel, validGrade);
      final validSpec   = specOptions.contains(storedSpec) ? storedSpec : null;

      setState(() {
        selectedLevel      = validLevel;
        selectedGrade      = validGrade;
        selectedSpeciality = validSpec;
        selectedSubjects   = subjects;
        _schoolController.text = school;

        _origLevel      = validLevel;
        _origGrade      = validGrade;
        _origSpeciality = storedSpec;
        _origSchool     = school;
        _origSubjects   = List.from(subjects);

        selectedIndex = _getSubjectIndex();
      });

      _schoolController.addListener(() => setState(() {}));
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<String> _specialityOptionsFor(String level, String grade) {
    if (level == 'High School') return _hsSpecialityMap[grade] ?? [];
    if (level == 'Higher Education') return _esiSpecialityMap[grade] ?? [];
    return [];
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_uid == null) return;
    if (_needsSpeciality() && selectedSpeciality == null) {
      setState(() => _specialityError = true);
      return;
    }
    setState(() { _isSaving = true; _errorMessage = null; });
    try {
      await _authService.updateStudyInfo(
        uid:               _uid!,
        schoolLevel:       selectedLevel,
        grade:             selectedGrade,
        speciality:        selectedSpeciality ?? '',
        school:            _schoolController.text.trim(),
        preferredSubjects: selectedSubjects,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Study info updated successfully!'),
            backgroundColor: Color(0xFF000080),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    selectedIndex = _getSubjectIndex();
    final specOptions = _specialityOptions();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF000080)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── School Level ──────────────────────────────────────
                    _label("School Level"),
                    const SizedBox(height: 8),
                    _dropdown(
                      value: selectedLevel,
                      items: levels,
                      onChanged: (val) {
                        setState(() {
                          selectedLevel      = val!;
                          selectedGrade      = gradesMap[selectedLevel]!.first;
                          selectedSpeciality = null;
                          _specialityError   = false;
                          selectedIndex      = _getSubjectIndex();
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Grade ─────────────────────────────────────────────
                    _label("Grade"),
                    const SizedBox(height: 8),
                    _dropdown(
                      value: selectedGrade,
                      items: gradesMap[selectedLevel]!,
                      onChanged: (val) {
                        setState(() {
                          selectedGrade      = val!;
                          selectedSpeciality = null;
                          _specialityError   = false;
                          selectedIndex      = _getSubjectIndex();
                        });
                      },
                    ),

                    // ── Speciality (conditional) ───────────────────────────
                    if (_needsSpeciality()) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _label("Speciality"),
                          if (_specialityError) ...[
                            const SizedBox(width: 8),
                            const Text(
                              'Required',
                              style: TextStyle(
                                  color: Color(0xFFE53935),
                                  fontSize: 12,
                                  fontFamily: 'Inter'),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      _dropdown(
                        value: specOptions.contains(selectedSpeciality)
                            ? selectedSpeciality
                            : null,
                        hint: 'Select speciality',
                        items: specOptions,
                        onChanged: (val) {
                          setState(() {
                            selectedSpeciality = val;
                            _specialityError   = false;
                            selectedIndex      = _getSubjectIndex();
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── School name ───────────────────────────────────────
                    _label("School"),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: const [BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.05),
                          offset: Offset(0, 1), blurRadius: 2)],
                      ),
                      child: TextField(
                        controller: _schoolController,
                        decoration: const InputDecoration(
                          hintText: "Didouch Mourad",
                          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Subjects ──────────────────────────────────────────
                    _label("Subjects of Interest"),
                    const SizedBox(height: 12),

                    SubjectPickerlissoWidget(
                      selectedIndex,
                      initialSelected: selectedSubjects,
                      onChanged: (subjects) {
                        setState(() => selectedSubjects = subjects);
                      },
                    ),

                    const SizedBox(height: 24),

                    // ── Save button — only when dirty ─────────────────────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _isDirty
                          ? Column(
                              children: [
                                if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(_errorMessage!,
                                      style: const TextStyle(
                                        color: Color(0xFFE53935),
                                        fontSize: 13, fontFamily: "Inter")),
                                  ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _save,
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: const Color(0xFF000080),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30)),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(width: 22, height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2.5))
                                        : const Text("Save Changes",
                                            style: TextStyle(
                                              fontFamily: 'Inter', fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: "Nunito", fontSize: 14,
      fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
  );

  Widget _dropdown({
    required List<String> items,
    required Function(String?) onChanged,
    String? value,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.05),
          offset: Offset(0, 1), blurRadius: 2)],
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        hint: hint != null
            ? Text(hint, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontFamily: 'Nunito'))
            : null,
        style: const TextStyle(
          fontFamily: "Nunito", fontSize: 14, color: Color(0xFF111827)),
        items: items.map((e) => DropdownMenuItem(
          value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.keyboard_arrow_down),
      ),
    );
  }
}


