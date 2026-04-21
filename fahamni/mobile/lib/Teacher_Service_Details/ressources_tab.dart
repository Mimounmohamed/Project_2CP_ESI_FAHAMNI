import 'package:flutter/material.dart';
import '../models/resource_model.dart';
import 'ressource_item.dart';
import 'service_details_service.dart';

class ResourcesTab extends StatefulWidget {
  final String serviceId;

  const ResourcesTab({super.key, required this.serviceId});

  @override
  State<ResourcesTab> createState() => _ResourcesTabState();
}

class _ResourcesTabState extends State<ResourcesTab> {
  final _service = CourseDetailsService();
  List<ResourceModel> _resources = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getResources(widget.serviceId);
    setState(() {
      _resources = data;
      _loading = false;
    });
  }

  void _showAddResourceSheet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Add resource is available from the session workflow for now.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Expanded(
          child: _resources.isEmpty
              ? const Center(
                  child: Text('No resources yet',
                      style: TextStyle(
                          fontFamily: 'Nunito', color: Color(0xFF94A3B8))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  itemCount: _resources.length,
                  itemBuilder: (_, i) => ResourceItem(
                    resource: _resources[i],
                    onDelete: () async {
                      await _service.deleteResource(_resources[i].resourceId);
                      _load();
                    },
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _showAddResourceSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add Resource',
                  style: TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
