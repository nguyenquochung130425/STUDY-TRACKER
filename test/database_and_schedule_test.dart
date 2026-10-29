import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_tracker/core/database/database_helper.dart';
import 'package:study_tracker/models/grade_entry.dart';
import 'package:study_tracker/models/schedule.dart';
import 'package:study_tracker/models/study_task.dart';
import 'package:study_tracker/models/subject.dart';
import 'package:study_tracker/services/word_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late DatabaseHelper dbHelper;

  setUp(() async {
    dbHelper = DatabaseHelper.instance;
    // Sử dụng in-memory database cho mỗi test case độc lập
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (database, version) async {
          // 1. Subjects
          await database.execute('''
            CREATE TABLE subjects (
              id TEXT PRIMARY KEY,
              code TEXT,
              name TEXT NOT NULL,
              credits INTEGER DEFAULT 3,
              lecturer TEXT,
              semester TEXT,
              color_value INTEGER NOT NULL,
              icon_code_point INTEGER NOT NULL,
              weekly_target_hours REAL NOT NULL DEFAULT 5.0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          // 2. Assignments
          await database.execute('''
            CREATE TABLE assignments (
              id TEXT PRIMARY KEY,
              subject_id TEXT NOT NULL,
              title TEXT NOT NULL,
              description TEXT,
              due_date TEXT NOT NULL,
              is_completed INTEGER NOT NULL DEFAULT 0,
              priority TEXT DEFAULT 'medium',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
            )
          ''');

          // 3. Schedules
          await database.execute('''
            CREATE TABLE schedules (
              id TEXT PRIMARY KEY,
              subject_id TEXT NOT NULL,
              day_of_week INTEGER NOT NULL,
              start_time TEXT NOT NULL,
              end_time TEXT NOT NULL,
              room TEXT NOT NULL,
              building TEXT,
              note TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
            )
          ''');

          // 4. Grades
          await database.execute('''
            CREATE TABLE grades (
              id TEXT PRIMARY KEY,
              subject_id TEXT NOT NULL,
              title TEXT NOT NULL,
              score REAL NOT NULL,
              max_score REAL NOT NULL DEFAULT 10.0,
              weight REAL NOT NULL DEFAULT 10.0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
            )
          ''');

          // 5. Questions
          await database.execute('''
            CREATE TABLE questions (
              id TEXT PRIMARY KEY,
              assignment_id TEXT NOT NULL,
              question_number INTEGER DEFAULT 1,
              content TEXT NOT NULL,
              passage TEXT,
              explanation TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (assignment_id) REFERENCES assignments (id) ON DELETE CASCADE
            )
          ''');

          // 6. Choices
          await database.execute('''
            CREATE TABLE choices (
              id TEXT PRIMARY KEY,
              question_id TEXT NOT NULL,
              choice_label TEXT NOT NULL,
              content TEXT NOT NULL,
              is_correct INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
            )
          ''');
        },
      ),
    );

    dbHelper.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Kiến tạo hệ thống Database (SQLite) & Data Access Layer', () {
    test('Khởi tạo Database với cấu trúc 4 bảng và kích hoạt Foreign Keys', () async {
      final pragmaRes = await db.rawQuery('PRAGMA foreign_keys;');
      expect(pragmaRes.first.values.first, 1);

      // Kiểm tra sự tồn tại của 4 bảng
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
      );
      final tableNames = tables.map((t) => t['name'] as String).toSet();

      expect(tableNames.contains('subjects'), isTrue);
      expect(tableNames.contains('assignments'), isTrue);
      expect(tableNames.contains('schedules'), isTrue);
      expect(tableNames.contains('grades'), isTrue);
    });

    test('Data Access Layer (DAL): Generic CRUD hoạt động chính xác', () async {
      // Test insert generic
      final row = {
        'id': 'sub_generic',
        'code': 'GEN101',
        'name': 'Môn Tổng Quát',
        'credits': 3,
        'lecturer': 'Thầy A',
        'semester': 'HK1',
        'color_value': 0xFF0000FF,
        'icon_code_point': 0xe120,
        'weekly_target_hours': 5.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await dbHelper.insert('subjects', row);

      // Test query generic
      final queried = await dbHelper.query(
        'subjects',
        where: 'id = ?',
        whereArgs: ['sub_generic'],
      );
      expect(queried.length, 1);
      expect(queried.first['name'], 'Môn Tổng Quát');

      // Test update generic
      await dbHelper.update(
        'subjects',
        {'name': 'Môn Cập Nhật'},
        where: 'id = ?',
        whereArgs: ['sub_generic'],
      );
      final updated = await dbHelper.query('subjects', where: 'id = ?', whereArgs: ['sub_generic']);
      expect(updated.first['name'], 'Môn Cập Nhật');

      // Test delete generic
      await dbHelper.delete('subjects', where: 'id = ?', whereArgs: ['sub_generic']);
      final afterDelete = await dbHelper.query('subjects', where: 'id = ?', whereArgs: ['sub_generic']);
      expect(afterDelete.isEmpty, isTrue);
    });
  });

  group('Chức năng 3.2: Quản lý Môn học (CRUD & Logic ràng buộc)', () {
    test('Thêm môn học mới với đầy đủ thông tin chi tiết', () async {
      final subject = const Subject(
        id: 'sub_test_1',
        code: 'IT101',
        name: 'Nhập môn Lập trình',
        credits: 4,
        lecturer: 'TS. Nguyễn Văn A',
        semester: 'Học kỳ 1 2026-2027',
        colorValue: 0xFF4F46E5,
        weeklyTargetHours: 8.0,
      );

      await dbHelper.insertSubject(subject);

      final fetched = await dbHelper.getSubjectById('sub_test_1');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Nhập môn Lập trình');
      expect(fetched.code, 'IT101');
      expect(fetched.credits, 4);
      expect(fetched.lecturer, 'TS. Nguyễn Văn A');
      expect(fetched.semester, 'Học kỳ 1 2026-2027');
    });

    test('Sửa thông tin môn học', () async {
      final subject = const Subject(
        id: 'sub_test_2',
        code: 'MAT201',
        name: 'Đại số tuyến tính',
        credits: 3,
        lecturer: 'ThS. Lê Toán',
        semester: 'Học kỳ 1 2026-2027',
        colorValue: 0xFF2563EB,
      );
      await dbHelper.insertSubject(subject);

      final updated = subject.copyWith(
        name: 'Đại số tuyến tính & Hình học',
        credits: 4,
        lecturer: 'PGS. TS. Lê Toán',
      );
      await dbHelper.updateSubject(updated);

      final fetched = await dbHelper.getSubjectById('sub_test_2');
      expect(fetched!.name, 'Đại số tuyến tính & Hình học');
      expect(fetched.credits, 4);
      expect(fetched.lecturer, 'PGS. TS. Lê Toán');
    });

    test('Lọc môn học theo học kỳ và tìm kiếm theo từ khóa', () async {
      await dbHelper.insertSubject(
        const Subject(
          id: 'sub_a',
          code: 'CS1',
          name: 'Khoa học máy tính 1',
          lecturer: 'Thầy Bình',
          semester: 'Học kỳ 1',
          colorValue: 0xFF000000,
        ),
      );
      await dbHelper.insertSubject(
        const Subject(
          id: 'sub_b',
          code: 'CS2',
          name: 'Khoa học máy tính 2',
          lecturer: 'Thầy Cường',
          semester: 'Học kỳ 2',
          colorValue: 0xFF000000,
        ),
      );

      // Lọc theo học kỳ
      final hk1 = await dbHelper.getAllSubjects(semester: 'Học kỳ 1');
      expect(hk1.length, 1);
      expect(hk1.first.id, 'sub_a');

      // Tìm kiếm theo từ khóa mã môn
      final searchRes = await dbHelper.getAllSubjects(searchQuery: 'CS2');
      expect(searchRes.length, 1);
      expect(searchRes.first.name, 'Khoa học máy tính 2');

      // Tìm kiếm theo tên giảng viên
      final lecturerSearch = await dbHelper.getAllSubjects(searchQuery: 'Bình');
      expect(lecturerSearch.length, 1);
      expect(lecturerSearch.first.id, 'sub_a');
    });

    test('Logic ràng buộc: Cảnh báo số lượng liên quan và CASCADE DELETE khi xóa môn học', () async {
      final subject = const Subject(
        id: 'sub_cascade',
        name: 'Môn thử nghiệm Cascade',
        colorValue: 0xFFE11D48,
      );
      await dbHelper.insertSubject(subject);

      // Thêm 2 lịch học liên kết
      await dbHelper.insertSchedule(
        Schedule(
          id: 'sch_1',
          subjectId: 'sub_cascade',
          dayOfWeek: 2,
          startTime: '07:30',
          endTime: '09:30',
          room: 'A101',
        ),
      );
      await dbHelper.insertSchedule(
        Schedule(
          id: 'sch_2',
          subjectId: 'sub_cascade',
          dayOfWeek: 4,
          startTime: '09:45',
          endTime: '11:45',
          room: 'A102',
        ),
      );

      // Thêm 1 bài tập liên kết
      await dbHelper.insertAssignment(
        StudyTask(
          id: 'task_1',
          subjectId: 'sub_cascade',
          title: 'Bài tập lớn môn học',
          dueDate: DateTime.now().add(const Duration(days: 7)),
        ),
      );

      // Thêm 1 đầu điểm liên kết
      await dbHelper.insertGrade(
        GradeEntry(
          id: 'grade_1',
          subjectId: 'sub_cascade',
          title: 'Điểm chuyên cần',
          score: 10,
          maxScore: 10,
          weight: 10,
          createdAt: DateTime.now(),
        ),
      );

      // 1. Kiểm tra bộ đếm dữ liệu liên quan (phục vụ hiển thị cảnh báo cho người dùng)
      final counts = await dbHelper.getSubjectRelatedCounts('sub_cascade');
      expect(counts['schedules'], 2);
      expect(counts['assignments'], 1);
      expect(counts['grades'], 1);
      expect(counts['total'], 4);

      // 2. Thực hiện xóa môn học
      await dbHelper.deleteSubject('sub_cascade');

      // 3. Xác minh tính toàn vẹn: Môn học đã bị xóa
      final afterSubject = await dbHelper.getSubjectById('sub_cascade');
      expect(afterSubject, isNull);

      // 4. Xác minh CASCADE DELETE: Toàn bộ lịch học, bài tập, điểm số con cũng đã bị xóa tự động khỏi SQLite
      final schedulesAfter = await db.query(
        'schedules',
        where: 'subject_id = ?',
        whereArgs: ['sub_cascade'],
      );
      expect(schedulesAfter.isEmpty, isTrue);

      final assignmentsAfter = await db.query(
        'assignments',
        where: 'subject_id = ?',
        whereArgs: ['sub_cascade'],
      );
      expect(assignmentsAfter.isEmpty, isTrue);

      final gradesAfter = await db.query(
        'grades',
        where: 'subject_id = ?',
        whereArgs: ['sub_cascade'],
      );
      expect(gradesAfter.isEmpty, isTrue);
    });
  });

  group('Chức năng 3.4: Quản lý Lịch học & Thời khóa biểu', () {
    test('Thêm, sửa, xóa buổi học trong thời khóa biểu', () async {
      // Chuẩn bị môn học
      await dbHelper.insertSubject(
        const Subject(
          id: 'sub_sch_test',
          code: 'PHY101',
          name: 'Vật lý đại cương',
          colorValue: 0xFF10B981,
        ),
      );

      // Thêm buổi học
      final schedule = Schedule(
        id: 'sch_test_1',
        subjectId: 'sub_sch_test',
        dayOfWeek: 3, // Thứ Ba
        startTime: '08:00',
        endTime: '11:00',
        room: 'B3-204',
        building: 'Tòa nhà B',
        note: 'Làm bài thí nghiệm số 1',
      );
      await dbHelper.insertSchedule(schedule);

      final bySub = await dbHelper.getSchedulesBySubject('sub_sch_test');
      expect(bySub.length, 1);
      expect(bySub.first.room, 'B3-204');
      expect(bySub.first.dayName, 'Thứ Ba');
      expect(bySub.first.timeSpan, '08:00 - 11:00');

      // Sửa buổi học: đổi giờ và phòng học
      final updated = schedule.copyWith(
        startTime: '08:30',
        endTime: '11:30',
        room: 'B3-305',
        note: 'Đổi sang phòng thực hành 305',
      );
      await dbHelper.updateSchedule(updated);

      final fetchedUpdated = await dbHelper.getSchedulesBySubject('sub_sch_test');
      expect(fetchedUpdated.first.room, 'B3-305');
      expect(fetchedUpdated.first.timeSpan, '08:30 - 11:30');

      // Xóa buổi học
      await dbHelper.deleteSchedule('sch_test_1');
      final fetchedAfterDelete = await dbHelper.getSchedulesBySubject('sub_sch_test');
      expect(fetchedAfterDelete.isEmpty, isTrue);
    });

    test('Tìm kiếm môn học trực tiếp trong lịch học', () async {
      await dbHelper.insertSubject(
        const Subject(
          id: 'sub_ai',
          code: 'AI401',
          name: 'Trí tuệ nhân tạo nâng cao',
          lecturer: 'GS. Trí Tuệ',
          colorValue: 0xFF7C3AED,
        ),
      );
      await dbHelper.insertSubject(
        const Subject(
          id: 'sub_db',
          code: 'DB201',
          name: 'Cơ sở dữ liệu SQLite',
          lecturer: 'TS. Dữ Liệu',
          colorValue: 0xFF0891B2,
        ),
      );

      await dbHelper.insertSchedule(
        Schedule(
          id: 'sch_ai',
          subjectId: 'sub_ai',
          dayOfWeek: 2,
          startTime: '07:30',
          endTime: '09:30',
          room: 'Phòng AI Lab',
        ),
      );

      await dbHelper.insertSchedule(
        Schedule(
          id: 'sch_db',
          subjectId: 'sub_db',
          dayOfWeek: 4,
          startTime: '13:30',
          endTime: '15:30',
          room: 'Phòng Server C',
        ),
      );

      // Tìm kiếm theo tên môn học
      final resByName = await dbHelper.getAllSchedules(searchQuery: 'Trí tuệ');
      expect(resByName.length, 1);
      expect(resByName.first.id, 'sch_ai');

      // Tìm kiếm theo mã môn học
      final resByCode = await dbHelper.getAllSchedules(searchQuery: 'DB201');
      expect(resByCode.length, 1);
      expect(resByCode.first.id, 'sch_db');

      // Tìm kiếm theo phòng học
      final resByRoom = await dbHelper.getAllSchedules(searchQuery: 'Lab');
      expect(resByRoom.length, 1);
      expect(resByRoom.first.id, 'sch_ai');

      // Tìm kiếm theo giảng viên
      final resByLecturer = await dbHelper.getAllSchedules(searchQuery: 'Dữ Liệu');
      expect(resByLecturer.length, 1);
      expect(resByLecturer.first.id, 'sch_db');
    });

    test('Lọc lịch học theo thứ trong tuần', () async {
      await dbHelper.insertSubject(
        const Subject(
          id: 'sub_filter',
          name: 'Môn học kiểm tra thứ',
          colorValue: 0xFF000000,
        ),
      );

      await dbHelper.insertSchedule(
        Schedule(
          id: 'sch_t2',
          subjectId: 'sub_filter',
          dayOfWeek: 2, // Thứ 2
          startTime: '07:00',
          endTime: '09:00',
          room: '101',
        ),
      );
      await dbHelper.insertSchedule(
        Schedule(
          id: 'sch_t6',
          subjectId: 'sub_filter',
          dayOfWeek: 6, // Thứ 6
          startTime: '14:00',
          endTime: '16:00',
          room: '102',
        ),
      );

      final mondaySchedules = await dbHelper.getAllSchedules(dayOfWeek: 2);
      expect(mondaySchedules.length, 1);
      expect(mondaySchedules.first.id, 'sch_t2');

      final fridaySchedules = await dbHelper.getAllSchedules(dayOfWeek: 6);
      expect(fridaySchedules.length, 1);
      expect(fridaySchedules.first.id, 'sch_t6');

      final sundaySchedules = await dbHelper.getAllSchedules(dayOfWeek: 8);
      expect(sundaySchedules.isEmpty, isTrue);
    });
  });

  group('Lưu đề thi Word / Bài tập vào SQLite (saveExamWithTransaction)', () {
    test('Lưu đề thi với đầy đủ môn học, câu hỏi và lựa chọn đáp án', () async {
      await dbHelper.insertSubject(
        const Subject(
          id: 'sub_exam',
          name: 'Môn thi thử',
          colorValue: 0xFF123456,
        ),
      );

      final assignment = StudyTask(
        id: 'task_exam_1',
        title: 'Đề thi trắc nghiệm Toán',
        subjectId: 'sub_exam',
        dueDate: DateTime(2026, 12, 1),
      );

      final questions = [
        ParsedQuestion(
          number: 1,
          content: '1 + 1 bằng mấy?',
          choices: [
            ParsedChoice(label: 'A', content: '1', isCorrect: false),
            ParsedChoice(label: 'B', content: '2', isCorrect: true),
            ParsedChoice(label: 'C', content: '3', isCorrect: false),
            ParsedChoice(label: 'D', content: '4', isCorrect: false),
          ],
          explanation: '1 + 1 = 2',
        ),
        ParsedQuestion(
          number: 2,
          content: 'Thủ đô của Việt Nam là gì?',
          choices: [
            ParsedChoice(label: 'A', content: 'Hà Nội', isCorrect: true),
            ParsedChoice(label: 'B', content: 'TP.HCM', isCorrect: false),
          ],
        ),
      ];

      await dbHelper.saveExamWithTransaction(
        assignment: assignment,
        questions: questions,
      );

      // Kiểm tra đề thi đã được lưu vào bảng assignments
      final allAssignments = await dbHelper.getAllAssignments();
      expect(allAssignments.any((a) => a.id == 'task_exam_1'), isTrue);

      // Kiểm tra câu hỏi và các lựa chọn đáp án
      final savedQuestions = await dbHelper.getQuestionsByAssignment('task_exam_1');
      expect(savedQuestions.length, 2);
      expect(savedQuestions[0].content, '1 + 1 bằng mấy?');
      expect(savedQuestions[0].choices.length, 4);
      expect(savedQuestions[0].choices.firstWhere((c) => c.label == 'B').isCorrect, isTrue);

      expect(savedQuestions[1].content, 'Thủ đô của Việt Nam là gì?');
      expect(savedQuestions[1].choices.length, 2);
      expect(savedQuestions[1].choices.firstWhere((c) => c.label == 'A').isCorrect, isTrue);
    });

    test('Lưu đề thi an toàn khi không truyền subjectId (tự động tạo subject mặc định)', () async {
      final assignmentNoSubject = StudyTask(
        id: 'task_no_subject',
        title: 'Đề thi không gắn môn',
        subjectId: null,
      );

      final questions = [
        ParsedQuestion(
          number: 1,
          content: 'Câu hỏi mẫu',
          choices: [
            ParsedChoice(label: 'A', content: 'Đáp án A', isCorrect: true),
          ],
        ),
      ];

      // Không được ném lỗi FOREIGN KEY constraint failed
      await expectLater(
        dbHelper.saveExamWithTransaction(
          assignment: assignmentNoSubject,
          questions: questions,
        ),
        completes,
      );

      final count = await dbHelper.getQuestionCount('task_no_subject');
      expect(count, 1);
    });
  });
}
