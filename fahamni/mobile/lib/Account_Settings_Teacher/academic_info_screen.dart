import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Subject pools per level ────────────────────────────────────────────────
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

const Map<String, String> _levelLabel = {
  'Primary':    'Primary School',
  'Middle':     'Middle School',
  'High':       'High School',
  'University': 'University',
};

const List<String> _teachingModes    = ['Online', 'In-person', 'Hybrid'];
const List<String> _homeTutoringOpts = ['Yes', 'No'];

// ─────────────────────────────────────────────────────────────────────────────

class AcademicInfoScreen extends StatefulWidget {
  const AcademicInfoScreen({super.key});

  @override
  State<AcademicInfoScreen> createState() => _AcademicInfoScreenState();
}

class _AcademicInfoScreenState extends State<AcademicInfoScreen> {
  List<String> _selectedLevels  = [];
  List<String> _selectedDomains = [];
  String? _teachingMode;
  String? _homeTutoring;
  final _descController = TextEditingController();

  bool    _isLoading = true;
  bool    _isSaving  = false;
  String? _errorMessage;
  String? _uid;

  // originals for dirty tracking
  List<String> _origLevels  = [];
  List<String> _origDomains = [];
  String? _origTeachingMode;
  String? _origHomeTutoring;
  String  _origDesc = '';

  bool get _isDirty {
    if (_descController.text.trim() != _origDesc) return true;
    if (_teachingMode != _origTeachingMode)         return true;
    if (_homeTutoring != _origHomeTutoring)          return true;
    if (!_listEq(_selectedLevels,  _origLevels))    return true;
    if (!_listEq(_selectedDomains, _origDomains))   return true;
    return false;
  }

  bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = [...a]..sort();
    final sb = [...b]..sort();
    for (int i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }

  List<String> get _availableDomains {
    final pool = <String>{};
    for (final l in _selectedLevels) { pool.addAll(_subjectsByLevel[l] ?? []); }
    return pool.toList()..sort();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadData();
    _descController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      _uid = user.uid;

      final doc = await FirebaseFirestore.instance
          .collection('tutors').doc(_uid).get();
      if (!mounted) return;

      final data = doc.data() ?? {};

      final levels = List<String>.from(data['levels_taught'] ?? []);

      final domainsRaw = (data['expertise_domain'] as String?) ?? '';
      final domains = domainsRaw.isNotEmpty
          ? domainsRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : <String>[];

      final teachingMode  = (data['teaching_mode']  as String?) ?? '';
      final homeTutoring  = (data['home_tutoring']  as String?) ?? '';
      final desc          = (data['academic_description'] as String?) ?? '';

      setState(() {
        _selectedLevels  = levels;
        _selectedDomains = domains;
        _teachingMode    = teachingMode.isNotEmpty  ? teachingMode  : null;
        _homeTutoring    = homeTutoring.isNotEmpty  ? homeTutoring  : null;
        _descController.text = desc;

        _origLevels        = List.from(levels);
        _origDomains       = List.from(domains);
        _origTeachingMode  = _teachingMode;
        _origHomeTutoring  = _homeTutoring;
        _origDesc          = desc;
      });
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_uid == null) return;
    setState(() { _isSaving = true; _errorMessage = null; });
    try {
      await FirebaseFirestore.instance.collection('tutors').doc(_uid).update({
        'levels_taught':        _selectedLevels,
        'expertise_domain':     _selectedDomains.join(', '),
        'teaching_mode':        _teachingMode    ?? '',
        'home_tutoring':        _homeTutoring    ?? '',
        'academic_description': _descController.text.trim(),
      });

      setState(() {
        _origLevels       = List.from(_selectedLevels);
        _origDomains      = List.from(_selectedDomains);
        _origTeachingMode = _teachingMode;
        _origHomeTutoring = _homeTutoring;
        _origDesc         = _descController.text.trim();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Academic info updated successfully!'),
          backgroundColor: Color(0xFF000080),
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Pickers ───────────────────────────────────────────────────────────────
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
            _sheetHandle(),
            const SizedBox(height: 8),
            const Text('Select School Levels',
                style: TextStyle(fontFamily: 'Inter', fontSize: 16,
                    fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            const Divider(),
            ..._levels.map((level) {
              final selected = _selectedLevels.contains(level);
              return CheckboxListTile(
                value: selected,
                activeColor: const Color(0xFF000080),
                title: Text(_levelLabel[level] ?? level,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 15,
                        fontWeight: FontWeight.w500)),
                onChanged: (_) {
                  setState(() {
                    if (selected) {
                      _selectedLevels.remove(level);
                      final avail = _availableDomains;
                      _selectedDomains.removeWhere((d) => !avail.contains(d));
                    } else {
                      _selectedLevels.add(level);
                    }
                  });
                  setModal(() {});
                },
              );
            }),
            _sheetDoneButton(ctx),
          ],
        ),
      ),
    );
  }

  void _showDomainPicker() {
    if (_selectedLevels.isEmpty) return;
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
              _sheetHandle(),
              const SizedBox(height: 8),
              const Text('Select Expertise Domains',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 16,
                      fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: domains.map((domain) {
                    final sel = _selectedDomains.contains(domain);
                    return CheckboxListTile(
                      value: sel,
                      activeColor: const Color(0xFF000080),
                      title: Text(domain,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
                      onChanged: (_) {
                        setState(() {
                          if (sel) {
                            _selectedDomains.remove(domain);
                          } else {
                            _selectedDomains.add(domain);
                          }
                        });
                        setModal(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              _sheetDoneButton(ctx),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      bottomNavigationBar: _isDirty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_errorMessage!,
                            style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 13,
                                fontFamily: 'Inter')),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF000080),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text('Confirm Changes',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Academic Info',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937))),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF000080)))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── School Level ───────────────────────────────────────
                    _label('School Level'),
                    const SizedBox(height: 6),
                    _tapField(
                      text: _selectedLevels.isEmpty
                          ? 'Select levels'
                          : _selectedLevels
                              .map((l) => _levelLabel[l] ?? l)
                              .join(' - '),
                      isEmpty: _selectedLevels.isEmpty,
                      onTap: _showLevelPicker,
                    ),
                    const SizedBox(height: 16),

                    // ── Expertise Domain ───────────────────────────────────
                    _label('Expertise Domain'),
                    const SizedBox(height: 6),
                    _tapField(
                      text: _selectedDomains.isEmpty
                          ? (_selectedLevels.isEmpty
                              ? 'Select a level first'
                              : 'Select domains')
                          : _selectedDomains.join(', '),
                      isEmpty: _selectedDomains.isEmpty,
                      enabled: _selectedLevels.isNotEmpty,
                      onTap: _showDomainPicker,
                    ),
                    if (_selectedLevels.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: _showDomainPicker,
                          child: const Text(
                            'Add a new Expertise Domain',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF000080)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // ── Teaching Mode ──────────────────────────────────────
                    _label('Teaching Mode'),
                    const SizedBox(height: 6),
                    _dropdownField(
                      value: _teachingMode,
                      hint: 'Select',
                      items: _teachingModes,
                      onChanged: (v) => setState(() => _teachingMode = v),
                    ),
                    const SizedBox(height: 16),

                    // ── Home Tutoring ──────────────────────────────────────
                    _label('Home Tutoring'),
                    const SizedBox(height: 6),
                    _dropdownField(
                      value: _homeTutoring,
                      hint: 'Select',
                      items: _homeTutoringOpts,
                      onChanged: (v) => setState(() => _homeTutoring = v),
                    ),
                    const SizedBox(height: 16),

                    // ── Academic Description ───────────────────────────────
                    _label('Academic Description'),
                    const SizedBox(height: 6),
                    _descriptionField(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────
  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937)),
      );

  Widget _tapField({
    required String text,
    required bool isEmpty,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: enabled
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFFCBD5E1)),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.04),
                      offset: Offset(0, 1),
                      blurRadius: 2)
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 15,
                    color: isEmpty || !enabled
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF1F2937)),
              ),
            ),
            Icon(Icons.keyboard_arrow_down,
                color: enabled
                    ? const Color(0xFF6B7280)
                    : const Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.04),
              offset: Offset(0, 1),
              blurRadius: 2)
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 15,
                  fontFamily: 'Lexend')),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFF6B7280)),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 15,
              fontFamily: 'Lexend'),
          onChanged: (v) {
            onChanged(v);
            setState(() {});
          },
          items: items
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
        ),
      ),
    );
  }

  Widget _descriptionField() {
    const int maxChars = 200;
    final int count = _descController.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04),
                  offset: Offset(0, 1),
                  blurRadius: 2)
            ],
          ),
          child: TextField(
            controller: _descController,
            maxLines: 4,
            maxLength: maxChars,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                const SizedBox.shrink(),
            decoration: const InputDecoration(
              hintText: 'Write something about you...',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text('$count/$maxChars',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF9CA3AF))),
        ),
      ],
    );
  }

  Widget _sheetHandle() => Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(2)),
      );

  Widget _sheetDoneButton(BuildContext ctx) => Padding(
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
      );
}


