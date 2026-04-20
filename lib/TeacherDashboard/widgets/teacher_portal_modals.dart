import 'package:fahamni/TeacherDashboard/models/teacher_portal_models.dart';
import 'package:fahamni/otp_verification_Screen/primarybutton.dart';
import 'package:flutter/material.dart';

class QuoteResponseModal extends StatefulWidget {
  const QuoteResponseModal({super.key, required this.request});

  final TeacherJoinRequestDetail request;

  static Future<TeacherQuoteResponseDraft?> show(
    BuildContext context,
    TeacherJoinRequestDetail request,
  ) {
    return showDialog<TeacherQuoteResponseDraft>(
      context: context,
      barrierDismissible: true,
      builder: (context) => QuoteResponseModal(request: request),
    );
  }

  @override
  State<QuoteResponseModal> createState() => _QuoteResponseModalState();
}

class _QuoteResponseModalState extends State<QuoteResponseModal> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Color(0xFF64748B)),
              ),
            ),
            CircleAvatar(
              radius: 40,
              backgroundImage: widget.request.studentAvatar.isNotEmpty
                  ? NetworkImage(widget.request.studentAvatar)
                  : null,
              child: widget.request.studentAvatar.isEmpty
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.request.studentName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              widget.request.studentLevel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Inter',
                ),
                children: [
                  TextSpan(
                    text: widget.request.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' requests to join the following service :\n'),
                  TextSpan(
                    text: widget.request.serviceTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You can accept the join request once the payment is done, or reject it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By Accepting the request, the new student can access all the service documents, group and sessions.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Accept',
                    onPressed: () {
                      Navigator.pop(
                        context,
                        const TeacherQuoteResponseDraft(
                          priceLabel: '',
                          sessionsCount: 0,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
