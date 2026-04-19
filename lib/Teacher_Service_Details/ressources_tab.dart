import 'package:flutter/material.dart';
import '../course_details_service.dart';
import '../models/resource_model.dart';
import '../widgets/resource_item.dart';

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
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final sizeController = TextEditingController();
    ResourceType selectedType = ResourceType.pdf;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Resource',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
              const SizedBox(height: 16),
              // Type selector
              Row(
                children: ResourceType.values.map((t) {
                  final selected = selectedType == t;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedType = t),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF000080)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t.name.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: selected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _field(titleController, 'Title'),
              const SizedBox(height: 8),
              _field(urlController, 'URL / Drive Link'),
              const SizedBox(height: 8),
              if (selectedType != ResourceType.link)
                _field(sizeController, 'Size (e.g. 1.8 MB)'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty ||
                        urlController.text.isEmpty) return;
                    final resource = ResourceModel(
                      resourceId: '',
                      serviceId: widget.serviceId,
                      title: titleController.text.trim(),
                      type: selectedType,
                      url: urlController.text.trim(),
                      size: sizeController.text.trim(),
                      createdAt: DateTime.now(),
                    );
                    await _service.addResource(resource);
                    Navigator.pop(ctx);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Add Resource',
                      style: TextStyle(
                          fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint) => TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );

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