import 'package:fahamni/models/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../Services/chat_service.dart';
import '../repositories/firestore_chat_repository.dart';
import 'media_grid.dart';
import 'conversation_members.dart';
import 'conversation_attachements.dart';

class InsideConversationButtons extends StatefulWidget {
  final ConversationModel conversation;
  final ChatService? chatService;

  const InsideConversationButtons({
    super.key,
    required this.conversation,
    this.chatService,
  });

  @override
  State<InsideConversationButtons> createState() =>
      _InsideConversationButtonsState();
}

class _InsideConversationButtonsState extends State<InsideConversationButtons>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = widget.chatService ?? ChatService(FirestoreChatRepository());
    _tabController = TabController(length: 4, vsync: this);
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
                      const Icon(Icons.link_outlined),
                      const SizedBox(width: 6),
                      const Text("Links"),
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
                // Media Tab
                StreamBuilder<List<String>>(
                  stream: _chatService.getConversationMediaUrls(
                    widget.conversation.conversationId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    final mediaUrls = snapshot.data ?? [];
                    return MediaGrid(images: mediaUrls);
                  },
                ),
                // Attachments Tab
                StreamBuilder<List<AttachmentModel>>(
                  stream: _chatService.getConversationFileAttachments(
                    widget.conversation.conversationId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    final attachments = snapshot.data ?? [];
                    return AttachmentsList(attachments: attachments);
                  },
                ),
                // Links Tab
                StreamBuilder<List<AttachmentModel>>(
                  stream: _chatService.getConversationLinkAttachments(
                    widget.conversation.conversationId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    final links = snapshot.data ?? [];
                    return AttachmentsList(attachments: links);
                  },
                ),
                // Members Tab
                ConversationMembers(
                  participants: widget.conversation.participants,
                ),


              ],
            ),
          ),
        ],
      ),
    );
  }
}
