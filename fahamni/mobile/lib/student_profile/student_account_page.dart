/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fahamni/Login_Screen/LoginScreen.dart';
import 'package:fahamni/models/student_model.dart';
import 'package:fahamni/models/user_model.dart';
import 'package:fahamni/student_profile/student_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _navy = Color(0xFF000080);
const _bg = Color(0xFFFAFAFA);
const _darkText = Color(0xFF1F2937);
const _slateText = Color(0xFF64748B);
const _lightGray = Color(0xFFD9D9D9);
const _errorRed = Color(0xFFDC2626);

const List<String> _allSubjects = [
  'Mathematics',
  'Physics',
  'Chemistry',
  'Biology',
  'History',
  'Geography',
  'French',
  'Arabic',
  'English',
  'Islamic Studies',
  'Philosophy',
  'Computer Science',
  'Economics',
  'Accounting',
  'Civil Engineering',
  'Electrical Engineering',
  'Literature',
  'Arts',
  'Physical Education',
];

const List<String> _schoolLevels = ['primary', 'secondary', 'university'];

// ---------------------------------------------------------------------------
// Entry widget
// ---------------------------------------------------------------------------

class StudentAccountPage extends StatefulWidget {
  const StudentAccountPage({super.key});

  @override
  State<StudentAccountPage> createState() => _StudentAccountPageState();
}

class _StudentAccountPageState extends State<StudentAccountPage>
    with SingleTickerProviderStateMixin {
  final StudentProfileService _service = StudentProfileService();
  late TabController _tabController;

  StudentModel? _student;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final student = await _service.getStudentData();
      if (!mounted) return;
      setState(() {
        _student = student;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  void _onStudentUpdated(StudentModel updated) {
    setState(() => _student = updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _navy)),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: _errorRed, size: 48),
                const SizedBox(height: 12),
                Text(_loadError!, textAlign: TextAlign.center,
                    style: const TextStyle(color: _slateText)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _loadError = null;
                    });
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _navy),
                  child: const Text('Retry',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final student = _student!;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            _TopBar(studentName: '${student.firstName} ${student.lastName}'),

            // ── Profile hero ─────────────────────────────────────────────
            _ProfileHero(student: student, service: _service,
                onUpdated: _onStudentUpdated),

            const SizedBox(height: 8),

            // ── Stats row ─────────────────────────────────────────────────
            _StatsRow(student: student),

            const SizedBox(height: 8),

            // ── TabBar ───────────────────────────────────────────────────
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: _navy,
                unselectedLabelColor: _slateText,
                indicatorColor: _navy,
                labelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: 'Profile'),
                  Tab(text: 'Academic'),
                  Tab(text: 'Settings'),
                ],
              ),
            ),

            // ── Tab content ───────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ProfileTab(student: student, service: _service,
                      onUpdated: _onStudentUpdated),
                  _AcademicTab(student: student, service: _service,
                      onUpdated: _onStudentUpdated),
                  _SettingsTab(service: _service),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.studentName});
  final String studentName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _darkText,
                size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'My Account',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _darkText,
              ),
            ),
          ),
          const SizedBox(width: 48), // balance the back button
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile hero (avatar + name + badge)
// ---------------------------------------------------------------------------

class _ProfileHero extends StatefulWidget {
  const _ProfileHero({
    required this.student,
    required this.service,
    required this.onUpdated,
  });
  final StudentModel student;
  final StudentProfileService service;
  final ValueChanged<StudentModel> onUpdated;

  @override
  State<_ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<_ProfileHero> {
  bool _saving = false;

  Future<void> _pickAvatar() async {
    final isMale = widget.student.gender == Gender.male;
    final options = [
      if (isMale) ...[
        _AvatarOption('assets/images/studentmale.png', 'Default Male'),
      ] else ...[
        _AvatarOption('assets/images/studentfemale.png', 'Default Female'),
      ],
      _AvatarOption('assets/images/studentmale.png', 'Male Avatar'),
      _AvatarOption('assets/images/studentfemale.png', 'Female Avatar'),
    ];

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AvatarPickerSheet(
        options: options,
        currentPicture: widget.student.picture,
        onSelect: (path) async {
          Navigator.of(context).pop();
          setState(() => _saving = true);
          try {
            await widget.service.updateProfile({'picture': path});
            final updated = await widget.service.getStudentData();
            widget.onUpdated(updated);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          } finally {
            if (mounted) setState(() => _saving = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final hasCustomPic = student.picture.isNotEmpty;
    final isMale = student.gender == Gender.male;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: hasCustomPic
                    ? AssetImage(student.picture)
                    : AssetImage(isMale
                        ? 'assets/images/studentmale.png'
                        : 'assets/images/studentfemale.png'),
                backgroundColor: Colors.white,
              ),
              GestureDetector(
                onTap: _saving ? null : _pickAvatar,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _navy,
                    shape: BoxShape.circle,
                  ),
                  child: _saving
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt,
                          color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${student.firstName} ${student.lastName}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Badge(
                label: student.schoolLevel.isEmpty
                    ? 'Student'
                    : _capitalize(student.schoolLevel),
                color: _navy,
              ),
              const SizedBox(width: 8),
              _AccountStatusBadge(status: student.accountStatus),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarOption {
  const _AvatarOption(this.path, this.label);
  final String path;
  final String label;
}

class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet({
    required this.options,
    required this.currentPicture,
    required this.onSelect,
  });
  final List<_AvatarOption> options;
  final String currentPicture;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Avatar',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: options.map((opt) {
              final isSelected = currentPicture == opt.path;
              return GestureDetector(
                onTap: () => onSelect(opt.path),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? _navy : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundImage: AssetImage(opt.path),
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? _navy : _slateText,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.student});
  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
              value: '${student.Courses.length}', label: 'Sessions'),
          _VertDivider(),
          _StatItem(
              value: '${student.favoriteTeachers.length}', label: 'Favorites'),
          _VertDivider(),
          _StatItem(
              value: '${student.preferredSubjects.length}', label: 'Subjects'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _slateText,
          ),
        ),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: _lightGray);
  }
}

// ---------------------------------------------------------------------------
// Badge helpers
// ---------------------------------------------------------------------------

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _AccountStatusBadge extends StatelessWidget {
  const _AccountStatusBadge({required this.status});
  final AccountStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status) {
      case AccountStatus.validated:
        color = const Color(0xFF16A34A);
        label = 'Verified';
        break;
      case AccountStatus.pending:
        color = const Color(0xFFF59E0B);
        label = 'Pending';
        break;
      case AccountStatus.rejected:
        color = _errorRed;
        label = 'Rejected';
        break;
    }
    return _Badge(label: label, color: color);
  }
}

// ---------------------------------------------------------------------------
// Profile tab
// ---------------------------------------------------------------------------

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({
    required this.student,
    required this.service,
    required this.onUpdated,
  });
  final StudentModel student;
  final StudentProfileService service;
  final ValueChanged<StudentModel> onUpdated;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _locationCtrl;

  Gender? _gender;
  DateTime? _birthday;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _firstNameCtrl = TextEditingController(text: s.firstName);
    _lastNameCtrl = TextEditingController(text: s.lastName);
    _phoneCtrl = TextEditingController(text: s.phone);
    _locationCtrl = TextEditingController(text: s.location);
    _gender = s.gender;
    _birthday = s.birthday;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.updateProfile({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'gender': (_gender ?? Gender.male).name,
        'birthday': Timestamp.fromDate(_birthday ?? widget.student.birthday),
      });
      final updated = await widget.service.getStudentData();
      if (!mounted) return;
      widget.onUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _navy),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Personal Information'),
          const SizedBox(height: 16),

          // Email (read-only)
          _ReadOnlyField(
            label: 'Email',
            value: widget.student.email,
            icon: Icons.lock_outline,
          ),
          const SizedBox(height: 14),

          // First Name
          _FormField(
            label: 'First Name',
            controller: _firstNameCtrl,
          ),
          const SizedBox(height: 14),

          // Last Name
          _FormField(
            label: 'Last Name',
            controller: _lastNameCtrl,
          ),
          const SizedBox(height: 14),

          // Phone
          _FormField(
            label: 'Phone Number',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),

          // Location
          _FormField(
            label: 'City / Location',
            controller: _locationCtrl,
          ),
          const SizedBox(height: 14),

          // Birthday
          _FieldLabel(label: 'Date of Birth'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickBirthday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _lightGray),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _birthday != null
                          ? DateFormat('dd MMMM yyyy').format(_birthday!)
                          : 'Select date',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _birthday != null ? _darkText : _slateText,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined,
                      color: _navy, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Gender
          _FieldLabel(label: 'Gender'),
          const SizedBox(height: 6),
          Row(
            children: Gender.values.map((g) {
              final selected = _gender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                        right: g == Gender.male ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? _navy : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _navy : _lightGray,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          g == Gender.male ? Icons.male : Icons.female,
                          color: selected ? Colors.white : _slateText,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _capitalize(g.name),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : _slateText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          if (_error != null) ...[
            _ErrorBanner(message: _error!),
            const SizedBox(height: 12),
          ],

          _PrimaryButton(
            label: 'Save Changes',
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Academic tab
// ---------------------------------------------------------------------------

class _AcademicTab extends StatefulWidget {
  const _AcademicTab({
    required this.student,
    required this.service,
    required this.onUpdated,
  });
  final StudentModel student;
  final StudentProfileService service;
  final ValueChanged<StudentModel> onUpdated;

  @override
  State<_AcademicTab> createState() => _AcademicTabState();
}

class _AcademicTabState extends State<_AcademicTab> {
  late String _schoolLevel;
  late final TextEditingController _objectivesCtrl;
  late Set<String> _selectedSubjects;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _schoolLevel = s.schoolLevel.isEmpty ? 'secondary' : s.schoolLevel;
    _objectivesCtrl =
        TextEditingController(text: s.learningObjectives);
    _selectedSubjects = Set<String>.from(s.preferredSubjects);
  }

  @override
  void dispose() {
    _objectivesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.updateProfile({
        'school_level': _schoolLevel,
        'learning_objectives': _objectivesCtrl.text.trim(),
        'preferred_subjects': _selectedSubjects.toList(),
      });
      final updated = await widget.service.getStudentData();
      if (!mounted) return;
      widget.onUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Academic profile updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Education Level'),
          const SizedBox(height: 12),

          // School level selector
          Row(
            children: _schoolLevels.map((level) {
              final selected = _schoolLevel == level;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _schoolLevel = level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      right: level != _schoolLevels.last ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? _navy : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected ? _navy : _lightGray),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _levelIcon(level),
                          color: selected ? Colors.white : _slateText,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _capitalize(level),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : _slateText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          _SectionHeader(title: 'Learning Objectives'),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _lightGray),
            ),
            child: TextField(
              controller: _objectivesCtrl,
              maxLines: 4,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: _darkText,
              ),
              decoration: const InputDecoration(
                hintText:
                    'Describe your learning goals and what you want to achieve...',
                hintStyle: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: _slateText,
                ),
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 20),
          _SectionHeader(title: 'Preferred Subjects'),
          const SizedBox(height: 6),
          Text(
            '${_selectedSubjects.length} selected',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: _slateText,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allSubjects.map((subject) {
              final selected = _selectedSubjects.contains(subject);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedSubjects.remove(subject);
                    } else {
                      _selectedSubjects.add(subject);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? _navy
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: selected ? _navy : _lightGray),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _navy.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    subject,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : _slateText,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          if (_error != null) ...[
            _ErrorBanner(message: _error!),
            const SizedBox(height: 12),
          ],

          _PrimaryButton(
            label: 'Save Changes',
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

IconData _levelIcon(String level) {
  switch (level) {
    case 'primary':
      return Icons.school_outlined;
    case 'university':
      return Icons.account_balance_outlined;
    default:
      return Icons.menu_book_outlined;
  }
}

// ---------------------------------------------------------------------------
// Settings tab
// ---------------------------------------------------------------------------

class _SettingsTab extends StatefulWidget {
  const _SettingsTab({required this.service});
  final StudentProfileService service;

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _notifySessions = true;
  bool _notifyMessages = true;
  bool _notifyOffers = false;

  Future<void> _changePassword() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ChangePasswordSheet(service: widget.service),
    );
  }

  Future<void> _signOut() async {
    final confirm = await _showConfirmDialog(
      context: context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
      confirmColor: _navy,
    );
    if (!confirm) return;

    try {
      final navigator = Navigator.of(context);
      await widget.service.signOut();
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreenPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await _showConfirmDialog(
      context: context,
      title: 'Delete Account',
      message:
          'This action is irreversible. All your data will be permanently deleted. Are you sure?',
      confirmLabel: 'Delete',
      confirmColor: _errorRed,
    );
    if (!confirm) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DeleteAccountSheet(service: widget.service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Notifications ────────────────────────────────────────────────
          _SectionHeader(title: 'Notifications'),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _ToggleTile(
                icon: Icons.event_note_outlined,
                title: 'Session Reminders',
                subtitle: 'Get notified before upcoming sessions',
                value: _notifySessions,
                onChanged: (v) => setState(() => _notifySessions = v),
              ),
              _Divider(),
              _ToggleTile(
                icon: Icons.chat_bubble_outline,
                title: 'Messages',
                subtitle: 'New messages from tutors',
                value: _notifyMessages,
                onChanged: (v) => setState(() => _notifyMessages = v),
              ),
              _Divider(),
              _ToggleTile(
                icon: Icons.local_offer_outlined,
                title: 'Special Offers',
                subtitle: 'Promotions and new services',
                value: _notifyOffers,
                onChanged: (v) => setState(() => _notifyOffers = v),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Account ──────────────────────────────────────────────────────
          _SectionHeader(title: 'Account'),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _ActionTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: _changePassword,
              ),
              _Divider(),
              _ActionTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {},
              ),
              _Divider(),
              _ActionTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {},
              ),
              _Divider(),
              _ActionTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── App Info ─────────────────────────────────────────────────────
          _SectionHeader(title: 'App'),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _InfoTile(
                icon: Icons.info_outline,
                title: 'Version',
                trailing: '1.0.0',
              ),
              _Divider(),
              _InfoTile(
                icon: Icons.language,
                title: 'Language',
                trailing: 'English',
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Sign Out ─────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: _lightGray,
                foregroundColor: _darkText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.logout, size: 20),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Delete Account ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _deleteAccount,
              style: OutlinedButton.styleFrom(
                foregroundColor: _errorRed,
                side: const BorderSide(color: _errorRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text(
                'Delete Account',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Change password bottom sheet
// ---------------------------------------------------------------------------

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.service});
  final StudentProfileService service;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.service.changePassword(
        currentPassword: current,
        newPassword: newPass,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Change Password',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 20),
          _PasswordField(
            label: 'Current Password',
            controller: _currentCtrl,
            obscure: _obscureCurrent,
            onToggle: () =>
                setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 14),
          _PasswordField(
            label: 'New Password',
            controller: _newCtrl,
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 14),
          _PasswordField(
            label: 'Confirm New Password',
            controller: _confirmCtrl,
            obscure: _obscureConfirm,
            onToggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 20),
          _PrimaryButton(
            label: 'Update Password',
            loading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delete account bottom sheet
// ---------------------------------------------------------------------------

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet({required this.service});
  final StudentProfileService service;

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final navigator = Navigator.of(context);
      await widget.service.deleteAccount(_passwordCtrl.text.trim());
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreenPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: _errorRed, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Account',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _errorRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'This will permanently delete your account and all associated data. This action cannot be undone.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: _slateText,
            ),
          ),
          const SizedBox(height: 20),
          _PasswordField(
            label: 'Confirm your password',
            controller: _passwordCtrl,
            obscure: _obscure,
            onToggle: () => setState(() => _obscure = !_obscure),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _errorRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Delete My Account',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable small widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _darkText,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _slateText,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _lightGray),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              color: _darkText,
            ),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.icon,
  });
  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        const SizedBox(height: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _lightGray),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    color: _slateText,
                  ),
                ),
              ),
              if (icon != null)
                Icon(icon, color: _slateText, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _lightGray),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              color: _darkText,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: _slateText,
                  size: 20,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _navy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _navy, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _darkText,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: _slateText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _navy,
            activeTrackColor: _navy.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const c = _darkText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: c, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: _slateText, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });
  final IconData icon;
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _navy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _navy, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _darkText,
              ),
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: _slateText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE2E8F0));
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _errorRed.withOpacity(0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: _errorRed,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _navy.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 2,
          shadowColor: _navy.withOpacity(0.3),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

Future<bool> _showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required Color confirmColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          color: _darkText,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          color: _slateText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel',
              style: TextStyle(color: _slateText, fontFamily: 'Nunito')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
*/