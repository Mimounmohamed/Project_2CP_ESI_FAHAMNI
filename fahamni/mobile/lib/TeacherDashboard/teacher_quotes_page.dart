import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quote_model.dart';
import '../TeacherDashboard/teacher_dashboard_service.dart';
import '../TeacherDashboard/models/teacher_portal_models.dart';
import '../TeacherDashboard/teacher_quote_request_detail_page.dart';
import '../navigation/app_navigation.dart';

class TeacherQuotesPage extends StatefulWidget {
  const TeacherQuotesPage({super.key});

  @override
  State<TeacherQuotesPage> createState() => _TeacherQuotesPageState();
}

class _TeacherQuotesPageState extends State<TeacherQuotesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeacherDashboardService _service = TeacherDashboardService();
  bool _isLoading = true;
  List<TeacherJoinRequestDetail> _allRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() => _isLoading = true);
    try {
      final details = await _service.loadAllQuoteDetails();
      setState(() {
        _allRequests = details.map((request) {
          return TeacherJoinRequestDetail(
            quote: request.quote,
            studentName: request.studentName,
            studentLevel: request.studentLevel,
            studentAvatar: request.avatarPath,
            serviceTitle: request.quote.serviceName.isNotEmpty
                ? request.quote.serviceName
                : request.subtitle,
            description: request.objective.isNotEmpty
                ? request.objective
                : request.quote.description,
            subject: request.subject.isNotEmpty
                ? request.subject
                : request.quote.subject,
            teachingMode: request.quote.teachingMode,
            sessionsCount: request.quote.sessionsCount,
            sessionDurationLabel: request.duration.isNotEmpty
                ? request.duration
                : request.quote.duration,
            createdAtLabel: request.createdAtLabel,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading quotes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Quotes",
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1F2937),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  color: const Color(0xFF000080),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: "Waiting"),
                  Tab(text: "Accepted"),
                  Tab(text: "Rejected"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF000080)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _QuotesList(
                        requests: _allRequests
                            .where((r) => r.quote.status == QuoteStatus.pending)
                            .toList(),
                        onRefresh: _loadQuotes,
                      ),
                      _QuotesList(
                        requests: _allRequests
                            .where((r) => r.quote.status == QuoteStatus.accepted)
                            .toList(),
                        onRefresh: _loadQuotes,
                      ),
                      _QuotesList(
                        requests: _allRequests
                            .where((r) => r.quote.status == QuoteStatus.rejected)
                            .toList(),
                        onRefresh: _loadQuotes,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuotesList extends StatelessWidget {
  final List<TeacherJoinRequestDetail> requests;
  final VoidCallback onRefresh;

  const _QuotesList({required this.requests, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No requests found",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: request.studentAvatar.isNotEmpty
                    ? NetworkImage(request.studentAvatar)
                    : null,
                child: request.studentAvatar.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.studentName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.studentLevel} · ${request.serviceTitle}',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await NavigationService.instance.push(
                    TeacherQuoteRequestDetailPage(request: request),
                  );
                  onRefresh();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(80, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "See details",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
