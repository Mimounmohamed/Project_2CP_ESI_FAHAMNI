import 'package:flutter/material.dart';
import '../models/resource_model.dart';
import 'ressource_item.dart';
import 'service_details_service.dart';
import '../Services/ressource_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/session_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResourcesTab extends StatefulWidget {
  final String serviceId;

  const ResourcesTab({super.key, required this.serviceId});

  @override
  State<ResourcesTab> createState() => _ResourcesTabState();
}

class _ResourcesTabState extends State<ResourcesTab> {
  final _service = CourseDetailsService();
  final _resourceService = ResourceService();
  final _auth = FirebaseAuth.instance;
  List<ResourceModel> _resources = [];
  List<SessionModel> _sessions = [];
  bool _loading = true;

  Future<String> _getTutorId() async {
    final user = await _auth.authStateChanges().first;
    return user?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final resources = await _service.getResources(widget.serviceId);
    final sessions = await _service.getSessions(widget.serviceId);
    setState(() {
      _resources = resources;
      _sessions = sessions;
      _loading = false;
    });
  }

  void _addDocument() async {
    final tutorId = await _getTutorId();
    if (tutorId.isEmpty) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final docType = fileName.split('.').last.toLowerCase();

      final sessionId = _sessions.isNotEmpty ? _sessions.first.sessionId : '';
      final resourceId = FirebaseFirestore.instance.collection('resources').doc().id;
      final resource = DocumentResource(
        resourceId: resourceId,
        tutorId: tutorId,
        sessionId: sessionId,
        title: fileName,
        subject: '',
        level: '',
        description: '',
        accessLevel: 'service',
        allowedUsers: [],
        isPublic: false,
        addedAt: DateTime.now(),
        fileUrl: '', // Will be set by upload
        docType: docType,
      );

      try {
        await _resourceService.uploadDocument(
          file: file,
          resource: resource,
          serviceId: widget.serviceId,
        );
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  void _addMedia() async {
    final tutorId = await _getTutorId();
    if (tutorId.isEmpty) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      final sessionId = _sessions.isNotEmpty ? _sessions.first.sessionId : '';
      final resourceId = FirebaseFirestore.instance.collection('resources').doc().id;
      final resource = MediaResource(
        resourceId: resourceId,
        tutorId: tutorId,
        sessionId: sessionId,
        title: fileName,
        subject: '',
        level: '',
        description: '',
        accessLevel: 'service',
        allowedUsers: [],
        isPublic: false,
        addedAt: DateTime.now(),
        mediaUrl: '', // Will be set by upload
        platform: 'upload',
      );

      try {
        // Upload to storage
        final Reference ref = FirebaseStorage.instance.ref().child('resources/media/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        final UploadTask uploadTask = ref.putFile(file);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        final updatedResource = MediaResource(
          resourceId: resourceId,
          tutorId: resource.tutorId,
          sessionId: resource.sessionId,
          title: resource.title,
          subject: resource.subject,
          level: resource.level,
          description: resource.description,
          accessLevel: resource.accessLevel,
          allowedUsers: resource.allowedUsers,
          isPublic: resource.isPublic,
          addedAt: DateTime.now(),
          mediaUrl: downloadUrl,
          platform: 'upload',
        );

        await _service.addResource(
          updatedResource,
          serviceId: widget.serviceId,
        );
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media uploaded successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  void _addLink() async {
    final tutorId = await _getTutorId();
    if (tutorId.isEmpty) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AddLinkDialog(),
    );

    if (result != null) {
      final sessionId = _sessions.isNotEmpty ? _sessions.first.sessionId : '';
      final resourceId = FirebaseFirestore.instance.collection('resources').doc().id;
      final resource = LinkResource(
        resourceId: resourceId,
        tutorId: tutorId,
        sessionId: sessionId,
        title: result['title']!,
        subject: '',
        level: '',
        description: '',
        accessLevel: 'service',
        allowedUsers: [],
        isPublic: false,
        addedAt: DateTime.now(),
        linkUrl: result['url']!,
      );
      await _service.addResource(
        resource,
        serviceId: widget.serviceId,
      );
      _load();
    }
  }

  void _showAddResourceSheet() {

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Resource',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Add Document'),
              onTap: () {
                Navigator.pop(context);
                _addDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Add Media'),
              onTap: () {
                Navigator.pop(context);
                _addMedia();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Add Link'),
              onTap: () {
                Navigator.pop(context);
                _addLink();
              },
            ),
          ],
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

class _AddLinkDialog extends StatefulWidget {
  @override
  State<_AddLinkDialog> createState() => _AddLinkDialogState();
}

class _AddLinkDialogState extends State<_AddLinkDialog> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Link Resource'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(labelText: 'URL'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty && _urlController.text.isNotEmpty) {
              Navigator.pop(context, {
                'title': _titleController.text,
                'url': _urlController.text,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}


