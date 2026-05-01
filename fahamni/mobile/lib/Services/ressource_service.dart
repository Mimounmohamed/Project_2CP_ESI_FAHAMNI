import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/resource_model.dart';
import '../models/chat_model.dart';

class ResourceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- CREATE ---
  /// Uploads a file to Storage and saves the metadata to Firestore
  Future<void> uploadDocument({
    required File file,
    required DocumentResource resource,
    String? serviceId,
  }) async {
    try {
      // 1. Upload file to Cloud Storage
      // Path: resources/documents/{resourceId}/{fileName}
      Reference ref = _storage.ref().child('resources/documents/${resource.resourceId}/${resource.title}');
      
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      
      // 2. Get the Download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 3. Create a copy of the model with the real URL
      final updatedResource = DocumentResource(
        resourceId: resource.resourceId,
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
        fileUrl: downloadUrl, // The link from Storage
        docType: resource.docType,
      );

      // 4. Save metadata to Firestore
      final data = {
        ...updatedResource.toMap(),
      };
      if (serviceId != null && serviceId.isNotEmpty) {
        data['service_id'] = serviceId;
      }
      await _db.collection('resources').doc(updatedResource.resourceId).set(data);
    } catch (e) {
      throw Exception("Upload failed: $e");
    }
  }

  /// Uploads a file to Storage and returns an AttachmentModel for chat.
  Future<AttachmentModel> uploadChatAttachment({
    required File file,
    required String conversationId,
    required String userId,
  }) async {
    try {
      final String fileName = file.path.split('/').last;
      final String mimeType = _getMimeType(fileName);
      final int fileSize = await file.length();
      
      Reference ref = _storage.ref().child('chat_attachments/$conversationId/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
      
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return AttachmentModel(
        url: downloadUrl,
        name: fileName,
        size: fileSize,
        mimeType: mimeType,
      );
    } catch (e) {
      throw Exception("Chat attachment upload failed: $e");
    }
  }

  String _getMimeType(String fileName) {
    final String extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  // --- READ ---
  /// Stream of resources for a specific session (Teacher or Student)
  Stream<List<ResourceModel>> getSessionResources(String sessionId) {
    return _db
        .collection('resources')
        .where('session_id', isEqualTo: sessionId)
        .orderBy('added_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ResourceModel.fromMap(doc.data()))
            .toList());
  }

  // --- UPDATE ---
  /// Update metadata (like title or description) without re-uploading file
  Future<void> updateResourceMetadata(String resourceId, Map<String, dynamic> data) async {
    await _db.collection('resources').doc(resourceId).update(data);
  }

  // --- DELETE ---
  /// Deletes both the Firestore document and the Storage file
  Future<void> deleteResource(ResourceModel resource) async {
    try {
      // 1. Delete from Firestore
      await _db.collection('resources').doc(resource.resourceId).delete();

      // 2. Delete from Storage if it's a document/media (not a link)
      if (resource is DocumentResource) {
        await _storage.refFromURL(resource.fileUrl).delete();
      } else if (resource is MediaResource) {
        await _storage.refFromURL(resource.mediaUrl).delete();
      }
    } catch (e) {
      throw Exception("Delete failed: $e");
    }
  }
}