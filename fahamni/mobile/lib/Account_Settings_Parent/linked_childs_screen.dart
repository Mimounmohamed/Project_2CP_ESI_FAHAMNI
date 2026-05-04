import 'package:flutter/material.dart';

import 'package:fahamni/Account_Settings_Parent/child_form_screen.dart';
import 'package:fahamni/Services/parent_child_service.dart';
import 'package:fahamni/models/child_model.dart';

class LinkedChildsScreen extends StatefulWidget {
  const LinkedChildsScreen({super.key});

  @override
  State<LinkedChildsScreen> createState() => _LinkedChildsScreenState();
}

class _LinkedChildsScreenState extends State<LinkedChildsScreen> {
  final ParentChildService _childService = ParentChildService();

  List<ChildModel> _children = <ChildModel>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<ChildModel> children = await _childService.fetchLinkedChildren();
      if (!mounted) {
        return;
      }
      setState(() {
        _children = children;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _subtitle(ChildModel child) {
    final List<String> parts = <String>[
      if (child.grade.isNotEmpty) child.grade,
      if (child.level.isNotEmpty) child.level,
      if (child.speciality.isNotEmpty) child.speciality,
    ];

    if (parts.isEmpty) {
      return 'Child profile';
    }

    return parts.join(' - ');
  }

  Future<void> _openCreateChild() async {
    final bool? created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ChildFormScreen()),
    );

    if (created == true) {
      await _loadChildren();
    }
  }

  Future<void> _openEditChild(ChildModel child) async {
    final bool? updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ChildFormScreen(child: child)),
    );

    if (updated == true) {
      await _loadChildren();
    }
  }

  Future<void> _deleteChild(ChildModel child) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Delete Child',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to remove ${child.name}?',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _childService.deleteChild(child.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Child removed successfully.')),
      );
      await _loadChildren();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Linked Childs',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF000080)),
            )
          : RefreshIndicator(
              color: const Color(0xFF000080),
              onRefresh: _loadChildren,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
                children: [
                  if (_children.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      alignment: Alignment.center,
                      child: const Text(
                        'No linked children yet.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    )
                  else
                    ..._children.map(
                      (ChildModel child) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    child.name,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _subtitle(child),
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF000080),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            _actionButton(
                              icon: Icons.edit_outlined,
                              onTap: () => _openEditChild(child),
                            ),
                            const SizedBox(width: 8),
                            _actionButton(
                              icon: Icons.delete_outline,
                              onTap: () => _deleteChild(child),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _openCreateChild,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000080),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Add Child',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: const Color(0xFF000080), size: 20),
      ),
    );
  }
}