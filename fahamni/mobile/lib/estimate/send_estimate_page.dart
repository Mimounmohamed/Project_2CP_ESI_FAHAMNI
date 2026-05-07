import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../TeacherDashboard/models/teacher_portal_models.dart';
import 'estimate_model.dart';
import 'estimate_pdf_generator.dart';
import 'estimate_service.dart';

class SendEstimatePage extends StatefulWidget {
  const SendEstimatePage({super.key, required this.request});

  final TeacherJoinRequestDetail request;

  @override
  State<SendEstimatePage> createState() => _SendEstimatePageState();
}

class _SendEstimatePageState extends State<SendEstimatePage> {
  static const _navy = Color(0xFF000080);
  static const _bg = Color(0xFFF7F8FC);
  static const _card = Colors.white;
  static const _title = Color(0xFF1F2937);
  static const _label = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  final _estimateService = EstimateService();

  final _studentEmailCtrl = TextEditingController();
  final _studentPhoneCtrl = TextEditingController();
  final _teacherPhoneCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _sessionsCtrl = TextEditingController();

  bool _loading = true;
  bool _sending = false;
  String? _invoiceNumber;
  String _teacherName = '';
  String _teacherEmail = '';

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  @override
  void dispose() {
    _studentEmailCtrl.dispose();
    _studentPhoneCtrl.dispose();
    _teacherPhoneCtrl.dispose();
    _priceCtrl.dispose();
    _sessionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    setState(() => _loading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final tutorUid = currentUser.uid;
      _teacherEmail = currentUser.email ?? '';
      _teacherName = currentUser.displayName ?? widget.request.studentName;

      final results = await Future.wait([
        _estimateService.fetchStudentContact(widget.request.quote.studentId),
        _estimateService.fetchTeacherPhone(tutorUid),
        _estimateService.generateInvoiceNumber(),
      ]);

      final studentContact = results[0] as Map<String, String>;
      final teacherPhone = results[1] as String;
      final invoiceNumber = results[2] as String;

      _invoiceNumber = invoiceNumber;
      _studentEmailCtrl.text = studentContact['email'] ?? '';
      _studentPhoneCtrl.text = studentContact['phone'] ?? '';
      _teacherPhoneCtrl.text = teacherPhone;

      final rawPrice = widget.request.quote.responsePrice;
      final parsedPrice = double.tryParse(rawPrice) ?? 0.0;
      _priceCtrl.text = parsedPrice > 0 ? parsedPrice.toStringAsFixed(0) : '';

      final sessions = widget.request.quote.responseSessionsCount > 0
          ? widget.request.quote.responseSessionsCount
          : widget.request.sessionsCount;
      _sessionsCtrl.text = sessions.toString();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  EstimateData? _buildEstimateData() {
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final sessions = int.tryParse(_sessionsCtrl.text.trim()) ?? 0;

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price per session.')),
      );
      return null;
    }
    if (sessions <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid sessions count.')),
      );
      return null;
    }
    if (_studentEmailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student email is required to send.')),
      );
      return null;
    }

    return EstimateData(
      invoiceNumber: _invoiceNumber ?? 'EST-DRAFT',
      date: DateTime.now(),
      studentName: widget.request.studentName,
      studentEmail: _studentEmailCtrl.text.trim(),
      studentPhone: _studentPhoneCtrl.text.trim(),
      studentLevel: widget.request.studentLevel,
      teacherName: _teacherName,
      teacherEmail: _teacherEmail,
      teacherPhone: _teacherPhoneCtrl.text.trim(),
      subject: widget.request.subject,
      description: widget.request.description,
      teachingMode: widget.request.teachingMode,
      sessionsCount: sessions,
      sessionDuration: widget.request.sessionDurationLabel,
      pricePerSession: price,
    );
  }

  Future<void> _preview() async {
    final data = _buildEstimateData();
    if (data == null) return;

    await Printing.layoutPdf(
      onLayout: (_) async => EstimatePdfGenerator.generate(data),
      name: '${data.invoiceNumber}.pdf',
    );
  }

  Future<void> _send() async {
    final data = _buildEstimateData();
    if (data == null) return;

    setState(() => _sending = true);
    try {
      await _estimateService.sendEstimate(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Estimate ${data.invoiceNumber} sent to ${data.studentEmail}.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _title),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Send Estimate',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _title,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _navy))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_invoiceNumber != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _invoiceNumber!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _navy,
                              fontFamily: 'Nunito',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      _section(
                        title: 'Student Info',
                        children: [
                          _readOnlyField(
                            label: 'Name',
                            value: widget.request.studentName,
                          ),
                          const SizedBox(height: 12),
                          _editableField(
                            label: 'Email *',
                            controller: _studentEmailCtrl,
                            keyboard: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _editableField(
                            label: 'Phone',
                            controller: _studentPhoneCtrl,
                            keyboard: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          _readOnlyField(
                            label: 'Level',
                            value: widget.request.studentLevel.isNotEmpty
                                ? widget.request.studentLevel
                                : '—',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _section(
                        title: 'Teacher Info',
                        children: [
                          _readOnlyField(label: 'Name', value: _teacherName),
                          const SizedBox(height: 12),
                          _readOnlyField(
                            label: 'Email',
                            value: _teacherEmail,
                          ),
                          const SizedBox(height: 12),
                          _editableField(
                            label: 'Phone',
                            controller: _teacherPhoneCtrl,
                            keyboard: TextInputType.phone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _section(
                        title: 'Service',
                        children: [
                          _readOnlyField(
                            label: 'Subject',
                            value: widget.request.subject,
                          ),
                          const SizedBox(height: 12),
                          _readOnlyField(
                            label: 'Teaching Mode',
                            value: widget.request.teachingMode,
                          ),
                          const SizedBox(height: 12),
                          _readOnlyField(
                            label: 'Duration / Session',
                            value: widget.request.sessionDurationLabel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _section(
                        title: 'Pricing',
                        children: [
                          _editableField(
                            label: 'Sessions Count *',
                            controller: _sessionsCtrl,
                            keyboard: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 12),
                          _editableField(
                            label: 'Price per Session (DA) *',
                            controller: _priceCtrl,
                            keyboard: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _sending ? null : _preview,
                          icon: const Icon(
                            Icons.visibility_outlined,
                            size: 18,
                          ),
                          label: const Text('Preview PDF'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _navy,
                            side: const BorderSide(color: _navy),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Nunito',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label:
                              Text(_sending ? 'Sending…' : 'Send Estimate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _navy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Nunito',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_sending)
                  const ColoredBox(
                    color: Color(0x44000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000080).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _navy,
              fontFamily: 'Nunito',
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _readOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _label,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _title,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }

  Widget _editableField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _label,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _title,
            fontFamily: 'Nunito',
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: _bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _navy, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
