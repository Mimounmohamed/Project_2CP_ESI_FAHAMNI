import 'package:fahamni/models/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'media_grid.dart';
import 'conversation_members.dart';
import 'conversation_attachements.dart';

class InsideConversationButtons extends StatefulWidget {
  final ConversationModel conversation;

  const InsideConversationButtons({super.key, required this.conversation});

  @override
  State<InsideConversationButtons> createState() =>
      _InsideConversationButtonsState();
}

class _InsideConversationButtonsState extends State<InsideConversationButtons>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAFA),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorColor: const Color(0xFF000080),
            indicatorWeight: 3.0,
            labelColor: const Color(0xFF000080),
            unselectedLabelColor: const Color(0xFF767C8C),
            labelStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/images/Vector.svg',
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          _tabController.index == 0
                              ? const Color(0xFF000080)
                              : const Color(0xFF767C8C),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text("Media"),
                    ],
                  ),
                ),
              ),
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.attach_file_outlined),
                      const SizedBox(width: 6),
                      const Text("Attach"),
                    ],
                  ),
                ),
              ),
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_outlined),
                      const SizedBox(width: 6),
                      const Text("Members"),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFECEFF1)),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                MediaGrid(images: widget.conversation.media),
                AttachmentsList(),
                ConversationMembers(participants: widget.conversation.participants),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
