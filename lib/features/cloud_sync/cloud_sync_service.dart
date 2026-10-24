import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CloudSyncService {
  static const List<String> collections = [
    'subjects',
    'sessions',
    'tasks',
    'grades',
  ];

  static Map<String, Map<String, DateTime>> extractRemoteModifiedAt(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents, {
    required String collectionName,
  }) {
    final result = <String, DateTime>{};

    for (final document in documents) {
      final data = document.data();
      final updatedAt = data['updatedAt'];
      if (updatedAt is Timestamp) {
        result[document.id] = updatedAt.toDate().toUtc();
      }
    }

    return {collectionName: result};
  }

  static Map<String, Map<String, dynamic>> normalizeRemoteRecords(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final result = <String, Map<String, dynamic>>{};

    for (final document in snapshot.docs) {
      final data = document.data();
      final body = data['data'];
      if (body is Map<String, dynamic>) {
        result[document.id] = body;
      }
    }

    return result;
  }

  static Map<String, DateTime> extractDeletionMarkers(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final result = <String, DateTime>{};

    for (final document in snapshot.docs) {
      final data = document.data();
      final collection = data['collection'];
      final recordId = data['recordId'];
      final deletedAt = data['deletedAt'];

      if (collection is String &&
          recordId is String &&
          deletedAt is Timestamp &&
          collections.contains(collection)) {
        result['$collection/$recordId'] = deletedAt.toDate().toUtc();
      }
    }

    return result;
  }

  static bool shouldWriteLocalRecord({
    required bool documentExists,
    required Map<String, dynamic>? currentBody,
    required Map<String, dynamic> localBody,
    required DateTime? localModifiedAt,
    required Timestamp? remoteUpdatedAt,
  }) {
    if (!documentExists) {
      return true;
    }

    if (currentBody is! Map<String, dynamic>) {
      return true;
    }

    if (!mapEquals(currentBody, localBody)) {
      return true;
    }

    if (localModifiedAt != null &&
        remoteUpdatedAt != null &&
        localModifiedAt.isAfter(remoteUpdatedAt.toDate())) {
      return true;
    }

    return false;
  }

  static bool isNewerOrEqual(DateTime? candidate, DateTime? reference) {
    if (candidate == null) {
      return false;
    }
    if (reference == null) {
      return true;
    }
    return !candidate.isBefore(reference);
  }
}
