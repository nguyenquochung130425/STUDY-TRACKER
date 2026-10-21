import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_tracker/models/grade_entry.dart';
import 'package:study_tracker/models/study_session.dart';
import 'package:study_tracker/models/study_task.dart';
import 'package:study_tracker/models/subject.dart';
import 'package:study_tracker/providers/cloud_sync_provider.dart';
import 'package:study_tracker/providers/study_provider.dart';

Future<void> waitForProvider(StudyProvider provider) async {
  await provider.ready;
}

Map<String, Map<String, Map<String, dynamic>>> emptyRemoteRecords() => {
  'subjects': {},
  'sessions': {},
  'tasks': {},
  'grades': {},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'merges remote records for all sync collections and persists them',
    () async {
      final provider = StudyProvider();
      await waitForProvider(provider);
      final updatedAt = DateTime.utc(2026, 10, 20, 12);
      final subject = Subject(
        id: 'remote_subject',
        name: 'Vật lý',
        colorValue: 0xFF2196F3,
      );
      final session = StudySession(
        id: 'remote_session',
        subjectId: subject.id,
        durationSeconds: 1800,
        timestamp: updatedAt,
      );
      final task = StudyTask(
        id: 'remote_task',
        title: 'Ôn chương 1',
        subjectId: subject.id,
        dueDate: updatedAt,
      );
      final grade = GradeEntry(
        id: 'remote_grade',
        subjectId: subject.id,
        title: 'Kiểm tra',
        score: 8,
        maxScore: 10,
        weight: 30,
        createdAt: updatedAt,
      );
      final records = emptyRemoteRecords()
        ..['subjects']![subject.id] = subject.toJson()
        ..['sessions']![session.id] = session.toJson()
        ..['tasks']![task.id] = task.toJson()
        ..['grades']![grade.id] = grade.toJson();
      final modifiedAt = {
        'subjects/${subject.id}': updatedAt,
        'sessions/${session.id}': updatedAt,
        'tasks/${task.id}': updatedAt,
        'grades/${grade.id}': updatedAt,
      };

      await provider.mergeCloudData(
        remoteRecords: records,
        remoteModifiedAt: modifiedAt,
        remoteDeletedRecords: {},
      );

      expect(provider.getSubjectById(subject.id)?.toJson(), subject.toJson());
      expect(provider.sessions.single.toJson(), session.toJson());
      expect(
        provider.tasks.firstWhere((item) => item.id == task.id).toJson(),
        task.toJson(),
      );
      expect(provider.grades.single.toJson(), grade.toJson());

      final restoredProvider = StudyProvider();
      await waitForProvider(restoredProvider);
      expect(
        restoredProvider.getSubjectById(subject.id)?.toJson(),
        subject.toJson(),
      );
      expect(restoredProvider.sessions.single.toJson(), session.toJson());
      expect(
        restoredProvider.tasks
            .firstWhere((item) => item.id == task.id)
            .toJson(),
        task.toJson(),
      );
      expect(restoredProvider.grades.single.toJson(), grade.toJson());
    },
  );

  test('remote updates win only when newer than the local version', () async {
    final provider = StudyProvider();
    await waitForProvider(provider);
    final grade = GradeEntry(
      id: 'conflicted_grade',
      subjectId: 'sub_1',
      title: 'Local',
      score: 6,
      maxScore: 10,
      weight: 20,
      createdAt: DateTime.utc(2026, 10, 20),
    );
    await provider.addGrade(grade);

    final remoteVersion = GradeEntry(
      id: grade.id,
      subjectId: grade.subjectId,
      title: 'Cloud mới',
      score: 9,
      maxScore: 10,
      weight: grade.weight,
      createdAt: grade.createdAt,
    );
    final newerThanLocal = DateTime.now().toUtc().add(
      const Duration(minutes: 1),
    );
    final records = emptyRemoteRecords()
      ..['grades']![grade.id] = remoteVersion.toJson();

    await provider.mergeCloudData(
      remoteRecords: records,
      remoteModifiedAt: {'grades/${grade.id}': newerThanLocal},
      remoteDeletedRecords: {},
    );
    expect(provider.grades.single.title, 'Cloud mới');

    final staleVersion = GradeEntry(
      id: grade.id,
      subjectId: grade.subjectId,
      title: 'Cloud cũ',
      score: 4,
      maxScore: 10,
      weight: grade.weight,
      createdAt: grade.createdAt,
    );
    await provider.mergeCloudData(
      remoteRecords: emptyRemoteRecords()
        ..['grades']![grade.id] = staleVersion.toJson(),
      remoteModifiedAt: {
        'grades/${grade.id}': newerThanLocal.subtract(
          const Duration(seconds: 1),
        ),
      },
      remoteDeletedRecords: {},
    );
    expect(provider.grades.single.title, 'Cloud mới');
    expect(provider.grades.single.score, 9);
  });

  test(
    'remote tombstones remove stale records and persist across restarts',
    () async {
      final provider = StudyProvider();
      await waitForProvider(provider);
      final subject = provider.getSubjectById('sub_1')!;
      await provider.deleteSubject(subject.id);
      final deletedAt = provider.deletedRecords['subjects/${subject.id}']!;

      await provider.mergeCloudData(
        remoteRecords: emptyRemoteRecords()
          ..['subjects']![subject.id] = subject.toJson(),
        remoteModifiedAt: {
          'subjects/${subject.id}': deletedAt.subtract(
            const Duration(seconds: 1),
          ),
        },
        remoteDeletedRecords: {},
      );

      expect(provider.getSubjectById(subject.id), isNull);
      expect(provider.deletedRecords['subjects/${subject.id}'], deletedAt);

      final restoredProvider = StudyProvider();
      await waitForProvider(restoredProvider);
      expect(restoredProvider.getSubjectById(subject.id), isNull);
      expect(
        restoredProvider.deletedRecords['subjects/${subject.id}'],
        deletedAt,
      );
    },
  );

  test('a newer remote record can be recreated after a tombstone', () async {
    final provider = StudyProvider();
    await waitForProvider(provider);
    final subject = provider.getSubjectById('sub_1')!;
    await provider.deleteSubject(subject.id);
    final deletedAt = provider.deletedRecords['subjects/${subject.id}']!;
    final recreated = subject.copyWith(name: 'Môn học đã khôi phục');

    await provider.mergeCloudData(
      remoteRecords: emptyRemoteRecords()
        ..['subjects']![subject.id] = recreated.toJson(),
      remoteModifiedAt: {
        'subjects/${subject.id}': deletedAt.add(const Duration(seconds: 1)),
      },
      remoteDeletedRecords: {},
    );

    expect(provider.getSubjectById(subject.id)?.name, recreated.name);
    expect(provider.deletedRecords, isNot(contains('subjects/${subject.id}')));
  });

  test(
    'configured-out provider stays offline and reports auth as unavailable',
    () async {
      final studyProvider = StudyProvider();
      await waitForProvider(studyProvider);
      final cloud = CloudSyncProvider(
        studyProvider: studyProvider,
        firebaseReady: false,
      );
      addTearDown(cloud.dispose);

      expect(cloud.isConfigured, isFalse);
      await expectLater(cloud.syncNow(), completes);
      expect(cloud.isSyncing, isFalse);
      expect(cloud.syncError, isNull);

      await expectLater(
        cloud.signInWithEmail('student@example.com', 'password'),
        throwsA(
          isA<FirebaseException>().having(
            (error) => error.code,
            'code',
            'not-configured',
          ),
        ),
      );
    },
  );
}
