import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'study_provider.dart';

class CloudSyncProvider extends ChangeNotifier {
  static const _collections = ['subjects', 'sessions', 'tasks', 'grades'];

  final StudyProvider _studyProvider;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<void>? _syncOperation;
  bool _syncAgain = false;
  User? _user;
  bool _isSyncing = false;
  String? _syncError;

  CloudSyncProvider({
    required StudyProvider studyProvider,
    required bool firebaseReady,
    String? initializationError,
  })  : // Keep the public named parameter while storing the provider privately.
        // ignore: prefer_initializing_formals
        _studyProvider = studyProvider,
        _auth = firebaseReady ? FirebaseAuth.instance : null,
        _firestore = firebaseReady ? FirebaseFirestore.instance : null,
        configurationError = initializationError {
    if (_auth != null) {
      _authSubscription = _auth.authStateChanges().listen(
        (user) {
          _user = user;
          _syncError = null;
          notifyListeners();
          if (user != null) {
            unawaited(syncNow());
          }
        },
        onError: (Object error) {
          _syncError = error.toString();
          notifyListeners();
        },
      );
      _connectivitySubscription =
          Connectivity().onConnectivityChanged.listen(
        (results) {
          if (_user != null &&
              results.any((result) => result != ConnectivityResult.none)) {
            unawaited(syncNow());
          }
        },
        onError: (Object error) {
          _syncError = 'Không thể theo dõi kết nối mạng: $error';
          notifyListeners();
        },
      );
      _studyProvider.setCloudSyncCallback(() => unawaited(syncNow()));
    }
  }

  final String? configurationError;

  bool get isConfigured => _firestore != null;
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  User? get user => _user;
  bool get canUseGoogleSignIn =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> registerWithEmail(String email, String password) async {
    final auth = _requireAuth();
    await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    final auth = _requireAuth();
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signInWithGoogle() async {
    final auth = _requireAuth();
    final provider = GoogleAuthProvider();
    if (kIsWeb) {
      await auth.signInWithPopup(provider);
    } else if (canUseGoogleSignIn) {
      await auth.signInWithProvider(provider);
    } else {
      throw UnsupportedError(
        'Đăng nhập Google hiện chỉ hỗ trợ Android, iOS và trình duyệt web.',
      );
    }
  }

  Future<void> signOut() async {
    await _requireAuth().signOut();
  }

  FirebaseAuth _requireAuth() {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-configured',
        message: 'Firebase chưa được cấu hình cho ứng dụng.',
      );
    }
    return auth;
  }

  Future<void> syncNow() {
    if (_syncOperation != null) {
      _syncAgain = true;
      return _syncOperation!;
    }
    final operation = _synchronize();
    _syncOperation = operation.whenComplete(() {
      _syncOperation = null;
      if (_syncAgain) {
        _syncAgain = false;
        unawaited(syncNow());
      }
    });
    return _syncOperation!;
  }

  Future<void> _synchronize() async {
    final user = _user;
    final firestore = _firestore;
    if (user == null || firestore == null) return;

    _isSyncing = true;
    _syncError = null;
    notifyListeners();
    try {
      await _studyProvider.ready;
      final userRef = firestore.collection('users').doc(user.uid);
      final snapshots = await Future.wait<QuerySnapshot<Map<String, dynamic>>>(
        _collections.map(
          (name) => userRef.collection(name).get(),
        ),
      );
      final remoteRecords = <String, Map<String, Map<String, dynamic>>>{
        for (final name in _collections) name: <String, Map<String, dynamic>>{},
      };
      final remoteModifiedAt = <String, DateTime>{};
      final remoteDocuments = <
          String,
          Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>>{};

      for (var index = 0; index < _collections.length; index++) {
        final collection = _collections[index];
        final documents =
            <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
        for (final document in snapshots[index].docs) {
          final data = document.data();
          final body = data['data'];
          if (body is! Map<String, dynamic>) {
            throw FormatException(
              'Dữ liệu cloud không hợp lệ trong $collection/${document.id}.',
            );
          }
          remoteRecords[collection]![document.id] = body;
          documents[document.id] = document;
          final modified = data['updatedAt'];
          if (modified is Timestamp) {
            remoteModifiedAt['$collection/${document.id}'] =
                modified.toDate().toUtc();
          }
        }
        remoteDocuments[collection] = documents;
      }

      final deletionSnapshot = await userRef.collection('deletions').get();
      final remoteDeletedRecords = <String, DateTime>{};
      final remoteDeletionDocuments = <
          String,
          QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final document in deletionSnapshot.docs) {
        final data = document.data();
        final collection = data['collection'];
        final recordId = data['recordId'];
        final deletedAt = data['deletedAt'];
        if (collection is! String ||
            !_collections.contains(collection) ||
            recordId is! String ||
            deletedAt is! Timestamp) {
          throw FormatException(
            'Dữ liệu xóa cloud không hợp lệ tại ${document.reference.path}.',
          );
        }
        final key = '$collection/$recordId';
        remoteDeletedRecords[key] = deletedAt.toDate().toUtc();
        remoteDeletionDocuments[key] = document;
      }

      await _studyProvider.mergeCloudData(
        remoteRecords: remoteRecords,
        remoteModifiedAt: remoteModifiedAt,
        remoteDeletedRecords: remoteDeletedRecords,
      );

      final localRecords = _studyProvider.exportCloudData();
      final localDeletedRecords = _studyProvider.deletedRecords;
      final batchWriter = _FirestoreBatchWriter(firestore);
      for (final collection in _collections) {
        final records = localRecords[collection]!;
        for (final entry in records.entries) {
          final key = '$collection/${entry.key}';
          final deletedAt = localDeletedRecords[key];
          final document = remoteDocuments[collection]![entry.key];
          final remoteDeletedAt = remoteDeletedRecords[key];
          final modifiedAt = _studyProvider.modifiedAtFor(collection, entry.key);

          if (deletedAt != null &&
              (modifiedAt == null || !modifiedAt.isAfter(deletedAt))) {
            if (document != null) {
              await batchWriter.delete(document.reference);
            }
            continue;
          }

          if (remoteDeletedAt != null &&
              (modifiedAt == null || !modifiedAt.isAfter(remoteDeletedAt))) {
            continue;
          }

          final currentData = document?.data();
          final currentBody = currentData?['data'];
          final remoteUpdatedAt = currentData?['updatedAt'];
          final shouldWrite = document == null ||
              currentBody is! Map<String, dynamic> ||
              !mapEquals(currentBody, entry.value) ||
              (modifiedAt != null &&
                  remoteUpdatedAt is Timestamp &&
                  modifiedAt.isAfter(remoteUpdatedAt.toDate()));

          if (shouldWrite) {
            await batchWriter.set(
              userRef.collection(collection).doc(entry.key),
              {
                'data': entry.value,
                'updatedAt': Timestamp.fromDate(
                  modifiedAt ?? DateTime.now().toUtc(),
                ),
              },
            );
          }
        }
      }

      for (final entry in localDeletedRecords.entries) {
        final separator = entry.key.indexOf('/');
        if (separator < 0) continue;
        final collection = entry.key.substring(0, separator);
        final recordId = entry.key.substring(separator + 1);
        if (!_collections.contains(collection)) continue;

        final key = entry.key;
        final item = remoteDocuments[collection]![recordId];
        final remoteDeletedAt = remoteDeletedRecords[key];
        final deletionId =
            '${Uri.encodeComponent(collection)}_${Uri.encodeComponent(recordId)}';
        final deletionRef = userRef.collection('deletions').doc(deletionId);

        if (item != null) {
          await batchWriter.delete(item.reference);
        }
        if (remoteDeletedAt == null || entry.value.isAfter(remoteDeletedAt)) {
          await batchWriter.set(deletionRef, {
            'collection': collection,
            'recordId': recordId,
            'deletedAt': Timestamp.fromDate(entry.value),
          });
        }
      }

      for (final entry in remoteDeletedRecords.entries) {
        if (!localDeletedRecords.containsKey(entry.key)) {
          final separator = entry.key.indexOf('/');
          if (separator < 0) continue;
          final collection = entry.key.substring(0, separator);
          final recordId = entry.key.substring(separator + 1);
          final deletionId =
              '${Uri.encodeComponent(collection)}_${Uri.encodeComponent(recordId)}';
          final localModified =
              _studyProvider.modifiedAtFor(collection, recordId);
          final item = remoteDocuments[collection]![recordId];
          if (item != null &&
              (localModified == null ||
                  !localModified.isAfter(entry.value))) {
            await batchWriter.delete(item.reference);
          } else if (localModified != null &&
              localModified.isAfter(entry.value)) {
            await batchWriter.delete(
              userRef.collection('deletions').doc(deletionId),
            );
          }
        }
      }

      await batchWriter.commit();
      _syncError = null;
    } on FirebaseException catch (error) {
      _syncError = error.message ?? 'Firebase error: ${error.code}';
    } on FormatException catch (error) {
      _syncError = error.message;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _studyProvider.setCloudSyncCallback(null);
    unawaited(_authSubscription?.cancel());
    unawaited(_connectivitySubscription?.cancel());
    super.dispose();
  }
}

class _FirestoreBatchWriter {
  final FirebaseFirestore _firestore;
  WriteBatch _batch;
  int _operationCount = 0;

  _FirestoreBatchWriter(this._firestore) : _batch = _firestore.batch();

  Future<void> _prepare() async {
    if (_operationCount == 400) {
      await _batch.commit();
      _batch = _firestore.batch();
      _operationCount = 0;
    }
  }

  Future<void> set(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> data,
  ) async {
    await _prepare();
    _batch.set(reference, data);
    _operationCount++;
  }

  Future<void> delete(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    await _prepare();
    _batch.delete(reference);
    _operationCount++;
  }

  Future<void> commit() async {
    if (_operationCount > 0) await _batch.commit();
  }
}
