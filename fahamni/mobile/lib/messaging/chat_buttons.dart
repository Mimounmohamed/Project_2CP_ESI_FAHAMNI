import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatButtons extends StatefulWidget {
  const ChatButtons({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    this.tabs = const ['Teachers', 'Students', 'Groups'],
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<String> tabs;

  @override
  State<ChatButtons> createState() => _MyMessagesWidgetState();
}


class _MyMessagesWidgetState extends State<ChatButtons>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: widget.tabs.length, vsync: this);
    _tabController.index = widget.selectedIndex.clamp(0, widget.tabs.length - 1);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      widget.onChanged(_tabController.index);
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant ChatButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabs.length != oldWidget.tabs.length) {
      final int currentIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(length: widget.tabs.length, vsync: this);
      _tabController.index = widget.selectedIndex.clamp(0, widget.tabs.length - 1);
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) return;
        widget.onChanged(_tabController.index);
        setState(() {});
      });
      return;
    }

    final int newIndex = widget.selectedIndex.clamp(0, widget.tabs.length - 1);
    if (newIndex != _tabController.index) {
      _tabController.animateTo(newIndex);
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

            tabs: widget.tabs.map((String label) {
              return Tab(
                child: Text(label),
              );
            }).toList(),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFECEFF1)),
        ],
      ),
    );
  }
}


