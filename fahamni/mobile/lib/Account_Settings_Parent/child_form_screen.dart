import 'package:flutter/material.dart';

import 'package:fahamni/Services/parent_child_service.dart';
import 'package:fahamni/models/child_model.dart';
import 'package:fahamni/widgets/subject_picker_screenlisso.dart';

class ChildFormScreen extends StatefulWidget {
  const ChildFormScreen({super.key, this.child});

  final ChildModel? child;

  @override
  State<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends State<ChildFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ParentChildService _childService = ParentChildService();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  static const List<String> _levels = <String>['Primary', 'Middle', 'High'];
  static const Map<String, List<String>> _gradesMap = {
    'Primary': <String>[
      '1st year',
      '2nd year',
      '3rd year',
      '4th year',
      '5th year',
    ],
    'Middle': <String>['1st year', '2nd year', '3rd year', '4th year'],
    'High': <String>['1st year', '2nd year', '3rd year'],
  };

  static const Map<String, int> _levelOffsets = {
    'Primary': 0,
    'Middle': 5,
    'High': 9,
  };

  String _selectedLevel = _levels.last;
  String _selectedGrade = _gradesMap[_levels.last]!.first;
  List<String> _selectedSubjects = <String>[];
  bool _isSaving = false;

  bool get _isEditMode => widget.child != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final ChildModel? child = widget.child;
    if (child == null) {
      return;
    }

    final String rawName = child.name.trim();
    final List<String> parts = rawName.isEmpty
        ? <String>[]
        : rawName.split(RegExp(r'\s+'));

    _firstNameController.text = parts.isEmpty ? '' : parts.first;
    _lastNameController.text = parts.length > 1
        ? parts.sublist(1).join(' ')
        : '';

    if (_levels.contains(child.level)) {
      _selectedLevel = child.level;
    }

    final List<String> grades = _gradesMap[_selectedLevel] ?? <String>[];
    if (grades.contains(child.grade)) {
      _selectedGrade = child.grade;
    } else if (grades.isNotEmpty) {
      _selectedGrade = grades.first;
    }

    _selectedSubjects = List<String>.from(child.subjects);
  }

  int _subjectIndex() {
    final int offset = _levelOffsets[_selectedLevel] ?? 0;
    final int gradeIndex = (_gradesMap[_selectedLevel] ?? <String>[]).indexOf(
      _selectedGrade,
    );

    if (gradeIndex < 0) {
      return offset;
    }

    return offset + gradeIndex;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one subject.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();

    try {
      if (_isEditMode) {
        final ChildModel existing = widget.child!;
        await _childService.updateChild(
          childId: existing.id,
          firstName: firstName,
          lastName: lastName,
          level: _selectedLevel,
          grade: _selectedGrade,
          subjects: _selectedSubjects,
          speciality: existing.speciality.isNotEmpty
              ? existing.speciality
              : _selectedSubjects.first,
        );
      } else {
        await _childService.createChild(
          firstName: firstName,
          lastName: lastName,
          level: _selectedLevel,
          grade: _selectedGrade,
          subjects: _selectedSubjects,
          speciality: _selectedSubjects.first,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> grades = _gradesMap[_selectedLevel] ?? <String>[];

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
        title: Text(
          _isEditMode ? 'Edit Child' : 'New Child',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('First Name'),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _firstNameController,
                  hint: 'Enter first name',
                ),
                const SizedBox(height: 16),
                _buildLabel('Last Name'),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: _lastNameController,
                  hint: 'Enter last name',
                ),
                const SizedBox(height: 16),
                _buildLabel('School Level'),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: _selectedLevel,
                  hint: 'Select a level',
                  items: _levels,
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedLevel = value;
                      _selectedGrade =
                          (_gradesMap[_selectedLevel] ?? <String>[]).first;
                      _selectedSubjects = <String>[];
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildLabel('Grade'),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: _selectedGrade,
                  hint: 'Select a grade',
                  items: grades,
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedGrade = value;
                      _selectedSubjects = <String>[];
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildLabel('Subjects of Interest'),
                const SizedBox(height: 8),
                SubjectPickerlissoWidget(
                  _subjectIndex(),
                  key: ValueKey<String>('${_selectedLevel}_$_selectedGrade'),
                  initialSelected: _selectedSubjects,
                  onChanged: (List<String> values) {
                    setState(() {
                      _selectedSubjects = values;
                    });
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000080),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditMode ? 'Save Changes' : 'Add',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      validator: (String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 16,
          fontFamily: 'Inter',
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF000080), width: 1.2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF6B7280),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF000080), width: 1.2),
        ),
      ),
      hint: Text(
        hint,
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 16,
          fontFamily: 'Inter',
        ),
      ),
      items: items
          .map(
            (String item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}