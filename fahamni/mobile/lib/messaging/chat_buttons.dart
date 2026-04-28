import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatButtons extends StatefulWidget {
  const ChatButtons({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  State<ChatButtons> createState() => _MyMessagesWidgetState();
}


class _MyMessagesWidgetState extends State<ChatButtons>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 3, vsync: this);
    _tabController.index = widget.selectedIndex;

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      widget.onChanged(_tabController.index);
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant ChatButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _tabController.index) {
      _tabController.animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFFAFAFA),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Teachers"),
                    const SizedBox(width: 4),
                    // The dot
                    /*Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A237E),
                        shape: BoxShape.circle,
                      ),
                    ),*/
                  ],
                ),
              ),
              const Tab(text: "Students"),
              const Tab(text: "Groups"),
            ],
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFECEFF1)),
        ],
      ),
    );
  }
}


