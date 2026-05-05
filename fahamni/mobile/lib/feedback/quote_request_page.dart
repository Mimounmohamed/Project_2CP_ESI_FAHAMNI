import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fahamni/Services/auth_.service.dart';
import 'package:fahamni/Services/student_tutor_action_service.dart';
import 'package:fahamni/StudentHomePage/studenthome_service.dart';
import 'package:fahamni/models/service_model.dart';
import 'package:fahamni/models/student_model.dart';
import 'package:fahamni/models/parent_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/models/user_model.dart';

class QuoteRequestPage extends StatefulWidget {
  const QuoteRequestPage({
    super.key,
    required this.tutor,
    required this.services,
  });

  final TutorModel tutor;
  final List<ServiceModel> services;

  @override
  State<QuoteRequestPage> createState() => _QuoteRequestPageState();
}

class _QuoteRequestPageState extends State<QuoteRequestPage> {
  final AuthService _authService = AuthService();
  final studenthomepage_service _studentHomeService = studenthomepage_service();
  final StudentTutorActionService _studentTutorActionService =
      StudentTutorActionService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _sessionsController = TextEditingController(
    text: '1',
  );

  final List<String> _subjectOptions = <String>[];
  final List<String> _modeOptions = <String>['Online', 'In person', 'Hybrid'];
  final List<int> _durationOptions = <int>[30, 45, 60, 90];

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedChildId;
  String? _selectedSubject;
  String? _selectedMode;
  int _selectedDuration = 30;
  String? _errorMessage;
  List<StudentModel> _children = <StudentModel>[];

  @override
  void initState() {
    super.initState();
    _loadCurrentStudentOrChildren();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _sessionsController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentStudentOrChildren() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.getCurrentUserProfile();
      if (user == null) {
        throw Exception('Unable to load user profile.');
      }

      if (user.role == UserRole.parent) {
        final ParentModel parent = user as ParentModel;
        List<StudentModel> children = await _studentHomeService
            .getLinkedChildren(parent.childrenUids);
        if (children.isEmpty) {
          children = await _studentHomeService.getChildrenForParent(parent.uid);
        }
        if (children.isNotEmpty) {
          _children = children;
          _selectedChildId = children.first.uid;
        }
      } else if (user.role == UserRole.student) {
        final StudentModel student = await _studentHomeService.getStudentData();
        _children = <StudentModel>[student];
        _selectedChildId = student.uid;
      }

      final List<String> tutorSubjects = widget.services
          .map((service) => service.subject.trim())
          .where((subject) => subject.isNotEmpty)
          .toSet()
          .toList();
      if (tutorSubjects.isNotEmpty) {
        _subjectOptions
          ..clear()
          ..addAll(tutorSubjects);
      } else if (widget.tutor.expertiseDomain.isNotEmpty) {
        _subjectOptions
          ..clear()
          ..add(widget.tutor.expertiseDomain);
      } else {
        _subjectOptions
          ..clear()
          ..add('General');
      }

      _selectedSubject = _subjectOptions.first;
      _selectedMode = _modeOptions.first;
      _selectedDuration = _durationOptions.first;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitQuoteRequest() async {
    FocusScope.of(context).unfocus();

    if (_selectedChildId == null || _selectedChildId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a child first.')),
      );
      return;
    }

    if (_selectedSubject == null || _selectedSubject!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please choose a subject.')));
      return;
    }

    if (_selectedMode == null || _selectedMode!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please choose a mode.')));
      return;
    }

    final String description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your request.')),
      );
      return;
    }

    final int sessionsCount = int.tryParse(_sessionsController.text) ?? 0;
    if (sessionsCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid sessions number.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _studentTutorActionService.createQuoteRequest(
        tutor: widget.tutor,
        studentId: _selectedChildId!,
        subject: _selectedSubject!,
        description: description,
        teachingMode: _selectedMode!,
        sessionsCount: sessionsCount,
        durationMinutes: _selectedDuration,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote request submitted successfully.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Quote Request',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCurrentStudentOrChildren,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedChildId,
                    items: _children
                        .map(
                          (child) => DropdownMenuItem<String>(
                            value: child.uid,
                            child: Text(
                              child.firstName.isNotEmpty
                                  ? '${child.firstName} ${child.lastName}'
                                        .trim()
                                  : child.uid,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedChildId = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Select a Child',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubject,
                    items: _subjectOptions
                        .map(
                          (subject) => DropdownMenuItem<String>(
                            value: subject,
                            child: Text(subject),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubject = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Choose Subject',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLength: 200,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe your request',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMode,
                    items: _modeOptions
                        .map(
                          (mode) => DropdownMenuItem<String>(
                            value: mode,
                            child: Text(mode),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMode = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Choose Mode',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sessionsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Sessions Number',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedDuration,
                          items: _durationOptions
                              .map(
                                (value) => DropdownMenuItem<int>(
                                  value: value,
                                  child: Text('$value min'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedDuration = value;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Session Duration',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitQuoteRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Submit',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
