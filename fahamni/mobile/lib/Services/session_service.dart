import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/session_model.dart';

class SessionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'sessions';

  // 1. REAL-TIME READ 
  Stream<List<SessionModel>> streamSessions(String studentId) {
    return _db.collection(_collection)
        .where('student_ids', arrayContains: studentId)
        .snapshots()
        .map((snap) {
          final sessions = snap.docs.map((doc) => SessionModel.fromMap(doc.data())).toList();
          
          // Trigger the auto-sync for every session in the background
          for (var session in sessions) {
            _syncStatusWithFirestore(session);
          }
          
          return sessions;
        });
  }

  // --- 2. AUTO-SYNC LOGIC  ---
  void _syncStatusWithFirestore(SessionModel session) async {
    
    if (session.status == SessionStatus.Canceled) return;

    final now = DateTime.now();
    SessionStatus detectedStatus;

    if (now.isAfter(session.endTime)) {
      detectedStatus = SessionStatus.Completed;
    } else if (now.isAfter(session.startTime)) {
      detectedStatus = SessionStatus.Ongoing;
    } else {
      detectedStatus = SessionStatus.Planned;
    }

    
    if (session.status != detectedStatus) {
      try {
        await _db.collection(_collection).doc(session.sessionId).update({
          'status': detectedStatus.name,
        });
      } catch (e) {
        debugPrint("Firestore Sync Error: $e");
      }
    }
  }

  // --- 3. MANUAL UPDATES (CRUD) ---

  // Manual Status Change (e.g., for the Cancel button)
  Future<void> updateStatus(String sessionId, SessionStatus newStatus) async {
    await _db.collection(_collection).doc(sessionId).update({
      'status': newStatus.name,
    });
  }

  // Create a new session
  Future<void> createSession(SessionModel session) async {
    await _db.collection(_collection).doc(session.sessionId).set(session.toMap());
  }

  // Update the entire session document
  Future<void> updateSession(SessionModel session) async {
    await _db.collection(_collection).doc(session.sessionId).update(session.toMap());
  }

  // Delete a session
  Future<void> deleteSession(String sessionId) async {
    await _db.collection(_collection).doc(sessionId).delete();
  }
}