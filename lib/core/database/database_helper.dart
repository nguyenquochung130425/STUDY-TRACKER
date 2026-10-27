import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../models/exam_question.dart';
import '../../models/grade_entry.dart';
import '../../models/schedule.dart';
import '../../models/study_task.dart';
import '../../models/subject.dart';
import '../../services/word_parser.dart';

class DatabaseHelper {
  static const String dbName = 'study_tracker.db';
  static const int dbVersion = 1;

  // Tên các bảng
  static const String tableSubjects = 'subjects';
  static const String tableAssignments = 'assignments';
  static const String tableSchedules = 'schedules';
  static const String tableGrades = 'grades';
  static const String tableQuestions = 'questions';
  static const String tableChoices = 'choices';

  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._internal();
  Database? _database;

  DatabaseHelper._internal();

  /// Cho phép thiết lập Database tùy chỉnh (hữu ích cho unit test & in-memory test)
  @visibleForTesting
  void setDatabaseForTesting(Database? db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (isDesktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final factory = isDesktop ? databaseFactoryFfi : databaseFactory;
    final dbPath = await factory.getDatabasesPath();
    final path = p.join(dbPath, dbName);

    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
      ),
    );
  }

  /// Bật ràng buộc khóa ngoại (Foreign Keys) trong SQLite
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  /// Khởi tạo toàn bộ cấu trúc bảng và ràng buộc khóa ngoại
  Future<void> _onCreate(Database db, int version) async {
    // 1. Bảng Môn học (Subjects)
    await db.execute('''
      CREATE TABLE $tableSubjects (
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

    // 2. Bảng Bài tập / Nhiệm vụ (Assignments) - Khóa ngoại liên kết với Subjects
    await db.execute('''
      CREATE TABLE $tableAssignments (
        id TEXT PRIMARY KEY,
        subject_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        priority TEXT DEFAULT 'medium',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES $tableSubjects (id) ON DELETE CASCADE
      )
    ''');

    // 3. Bảng Lịch học / Thời khóa biểu (Schedules) - Khóa ngoại liên kết với Subjects
    await db.execute('''
      CREATE TABLE $tableSchedules (
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
        FOREIGN KEY (subject_id) REFERENCES $tableSubjects (id) ON DELETE CASCADE
      )
    ''');

    // 4. Bảng Điểm số (Grades) - Khóa ngoại liên kết với Subjects
    await db.execute('''
      CREATE TABLE $tableGrades (
        id TEXT PRIMARY KEY,
        subject_id TEXT NOT NULL,
        title TEXT NOT NULL,
        score REAL NOT NULL,
        max_score REAL NOT NULL DEFAULT 10.0,
        weight REAL NOT NULL DEFAULT 10.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES $tableSubjects (id) ON DELETE CASCADE
      )
    ''');

    // 5. Bảng Câu hỏi trắc nghiệm (Questions)
    await db.execute('''
      CREATE TABLE $tableQuestions (
        id TEXT PRIMARY KEY,
        assignment_id TEXT NOT NULL,
        question_number INTEGER DEFAULT 1,
        content TEXT NOT NULL,
        passage TEXT,
        explanation TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (assignment_id) REFERENCES $tableAssignments (id) ON DELETE CASCADE
      )
    ''');

    // 6. Bảng Lựa chọn đáp án (Choices)
    await db.execute('''
      CREATE TABLE $tableChoices (
        id TEXT PRIMARY KEY,
        question_id TEXT NOT NULL,
        choice_label TEXT NOT NULL,
        content TEXT NOT NULL,
        is_correct INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (question_id) REFERENCES $tableQuestions (id) ON DELETE CASCADE
      )
    ''');

    // Dữ liệu mẫu ban đầu (Seed data)
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaultSubjects = [
      {
        'id': 'sub_1',
        'code': 'MAT101',
        'name': 'Toán cao cấp',
        'credits': 4,
        'lecturer': 'TS. Trần Văn Toán',
        'semester': 'Học kỳ 1 2026-2027',
        'color_value': 0xFF2196F3,
        'icon_code_point': 0xe158,
        'weekly_target_hours': 6.0,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'sub_2',
        'code': 'IT201',
        'name': 'Lập trình Flutter & Mobile',
        'credits': 3,
        'lecturer': 'ThS. Nguyễn Mobile',
        'semester': 'Học kỳ 1 2026-2027',
        'color_value': 0xFF4CAF50,
        'icon_code_point': 0xe197,
        'weekly_target_hours': 10.0,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'sub_3',
        'code': 'ENG301',
        'name': 'Tiếng Anh chuyên ngành IT',
        'credits': 2,
        'lecturer': 'Cô Emily Jones',
        'semester': 'Học kỳ 1 2026-2027',
        'color_value': 0xFFE91E63,
        'icon_code_point': 0xe357,
        'weekly_target_hours': 5.0,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'sub_4',
        'code': 'SCI102',
        'name': 'Khoa học dữ liệu & AI',
        'credits': 3,
        'lecturer': 'PGS. Lê Dữ Liệu',
        'semester': 'Học kỳ 2 2026-2027',
        'color_value': 0xFFFF9800,
        'icon_code_point': 0xe556,
        'weekly_target_hours': 4.0,
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final s in defaultSubjects) {
      await db.insert(tableSubjects, s);
    }

    // Lịch học mặc định mẫu
    final defaultSchedules = [
      {
        'id': 'sch_1',
        'subject_id': 'sub_1',
        'day_of_week': 2, // Thứ Hai
        'start_time': '07:30',
        'end_time': '09:30',
        'room': 'A1-203',
        'building': 'Tòa nhà A',
        'note': 'Mang theo máy tính fx580',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'sch_2',
        'subject_id': 'sub_2',
        'day_of_week': 3, // Thứ Ba
        'start_time': '13:00',
        'end_time': '16:00',
        'room': 'Lab-04',
        'building': 'Khu thực hành CNTT',
        'note': 'Cài sẵn Flutter SDK và máy ảo',
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': 'sch_3',
        'subject_id': 'sub_3',
        'day_of_week': 5, // Thứ Sáu
        'start_time': '09:45',
        'end_time': '11:45',
        'room': 'B2-105',
        'building': 'Tòa nhà B',
        'note': 'Chuẩn bị bài thuyết trình nhóm',
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final sch in defaultSchedules) {
      await db.insert(tableSchedules, sch);
    }
  }

  // ==========================================
  // DATA ACCESS LAYER (GENERIC CRUD METHODS)
  // ==========================================

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(
      table,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> row, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, row, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // ==========================================
  // CHỨC NĂNG 3.2: SUBJECTS CRUD & CONSTRAINTS
  // ==========================================

  Future<int> insertSubject(Subject subject) async {
    return await insert(tableSubjects, subject.toDbMap());
  }

  Future<int> updateSubject(Subject subject) async {
    final db = await database;
    return await db.update(
      tableSubjects,
      subject.toDbMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  /// Đếm số lượng dữ liệu liên quan để cảnh báo người dùng trước khi xóa môn học
  Future<Map<String, int>> getSubjectRelatedCounts(String subjectId) async {
    final db = await database;

    final scheduleCountRes = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableSchedules WHERE subject_id = ?',
      [subjectId],
    );
    final assignmentCountRes = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableAssignments WHERE subject_id = ?',
      [subjectId],
    );
    final gradeCountRes = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableGrades WHERE subject_id = ?',
      [subjectId],
    );

    final schedules = (scheduleCountRes.first['count'] as num?)?.toInt() ?? 0;
    final assignments = (assignmentCountRes.first['count'] as num?)?.toInt() ?? 0;
    final grades = (gradeCountRes.first['count'] as num?)?.toInt() ?? 0;

    return {
      'schedules': schedules,
      'assignments': assignments,
      'grades': grades,
      'total': schedules + assignments + grades,
    };
  }

  /// Xóa môn học: Do bảng assignments, schedules, grades có `ON DELETE CASCADE`,
  /// toàn bộ các bản ghi con liên kết sẽ tự động được xóa an toàn khỏi SQLite.
  Future<int> deleteSubject(String id) async {
    final db = await database;
    return await db.delete(
      tableSubjects,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Subject?> getSubjectById(String id) async {
    final list = await query(
      tableSubjects,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (list.isNotEmpty) {
      return Subject.fromDbMap(list.first);
    }
    return null;
  }

  Future<List<Subject>> getAllSubjects({
    String? semester,
    String? searchQuery,
  }) async {
    final db = await database;
    String whereClause = '';
    final List<Object?> whereArgs = [];

    final conditions = <String>[];
    if (semester != null && semester.trim().isNotEmpty && semester != 'Tất cả') {
      conditions.add('semester = ?');
      whereArgs.add(semester.trim());
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      conditions.add('(name LIKE ? OR code LIKE ? OR lecturer LIKE ?)');
      final term = '%${searchQuery.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    if (conditions.isNotEmpty) {
      whereClause = conditions.join(' AND ');
    }

    final result = await db.query(
      tableSubjects,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
    );

    return result.map((row) => Subject.fromDbMap(row)).toList();
  }

  /// Lấy danh sách các học kỳ phân biệt hiện có
  Future<List<String>> getAllSemesters() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT semester FROM $tableSubjects WHERE semester IS NOT NULL AND semester != "" ORDER BY semester DESC',
    );
    return result
        .map((row) => row['semester'] as String)
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // ==========================================
  // CHỨC NĂNG 3.4: SCHEDULES CRUD
  // ==========================================

  Future<int> insertSchedule(Schedule schedule) async {
    return await insert(tableSchedules, schedule.toDbMap());
  }

  Future<int> updateSchedule(Schedule schedule) async {
    final db = await database;
    return await db.update(
      tableSchedules,
      schedule.toDbMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteSchedule(String id) async {
    final db = await database;
    return await db.delete(
      tableSchedules,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Schedule>> getSchedulesBySubject(String subjectId) async {
    final list = await query(
      tableSchedules,
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'day_of_week ASC, start_time ASC',
    );
    return list.map((m) => Schedule.fromDbMap(m)).toList();
  }

  /// Lấy danh sách lịch học kèm lọc theo thứ và tìm kiếm môn học trực tiếp
  Future<List<Schedule>> getAllSchedules({
    int? dayOfWeek,
    String? searchQuery,
  }) async {
    final db = await database;

    String sql = '''
      SELECT s.* 
      FROM $tableSchedules s
      LEFT JOIN $tableSubjects sub ON s.subject_id = sub.id
    ''';

    final List<String> conditions = [];
    final List<Object?> args = [];

    if (dayOfWeek != null && dayOfWeek > 0) {
      conditions.add('s.day_of_week = ?');
      args.add(dayOfWeek);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      conditions.add(
        '(sub.name LIKE ? OR sub.code LIKE ? OR sub.lecturer LIKE ? OR s.room LIKE ? OR s.note LIKE ?)',
      );
      final term = '%${searchQuery.trim()}%';
      args.addAll([term, term, term, term, term]);
    }

    if (conditions.isNotEmpty) {
      sql += ' WHERE ${conditions.join(' AND ')}';
    }

    sql += ' ORDER BY s.day_of_week ASC, s.start_time ASC';

    final result = await db.rawQuery(sql, args);
    return result.map((m) => Schedule.fromDbMap(m)).toList();
  }

  Future<List<Schedule>> getTodaySchedules() async {
    final todayVn = Schedule.fromDateTimeWeekday(DateTime.now().weekday);
    return await getAllSchedules(dayOfWeek: todayVn);
  }

  // ==========================================
  // ASSIGNMENTS & GRADES COMPATIBILITY CRUD
  // ==========================================

  Future<int> insertAssignment(StudyTask assignment) async {
    return await insert(tableAssignments, assignment.toDbMap());
  }

  Future<int> updateAssignment(StudyTask assignment) async {
    final db = await database;
    return await db.update(
      tableAssignments,
      assignment.toDbMap(),
      where: 'id = ?',
      whereArgs: [assignment.id],
    );
  }

  Future<int> deleteAssignment(String id) async {
    final db = await database;
    return await db.delete(
      tableAssignments,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<StudyTask>> getAllAssignments() async {
    final list = await query(tableAssignments, orderBy: 'due_date ASC');
    return list.map((m) => StudyTask.fromDbMap(m)).toList();
  }

  Future<int> insertGrade(GradeEntry grade) async {
    return await insert(tableGrades, grade.toDbMap());
  }

  Future<int> updateGrade(GradeEntry grade) async {
    final db = await database;
    return await db.update(
      tableGrades,
      grade.toDbMap(),
      where: 'id = ?',
      whereArgs: [grade.id],
    );
  }

  Future<int> deleteGrade(String id) async {
    final db = await database;
    return await db.delete(
      tableGrades,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<GradeEntry>> getAllGrades() async {
    final list = await query(tableGrades, orderBy: 'created_at DESC');
    return list.map((m) => GradeEntry.fromDbMap(m)).toList();
  }

  // ==========================================
  // WORD EXAM ENGINE & QUESTIONS & CHOICES CRUD
  // ==========================================

  /// Lưu đề thi/bài tập tuần tự an toàn bằng SQL Transaction:
  /// Assignments -> Questions -> Choices
  Future<void> saveExamWithTransaction({
    required StudyTask assignment,
    required List<ParsedQuestion> questions,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Lưu thông tin Bài tập / Đề thi cha
      await txn.insert(
        tableAssignments,
        assignment.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Lưu tuần tự từng câu hỏi và các lựa chọn đáp án con
      for (final pq in questions) {
        final qId = 'q_${DateTime.now().microsecondsSinceEpoch}_${pq.number}';
        final now = DateTime.now().toIso8601String();

        await txn.insert(
          tableQuestions,
          {
            'id': qId,
            'assignment_id': assignment.id,
            'question_number': pq.number,
            'content': pq.content,
            'passage': pq.passage,
            'explanation': pq.explanation,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (final pc in pq.choices) {
          final cId = 'c_${DateTime.now().microsecondsSinceEpoch}_${pc.label}';
          await txn.insert(
            tableChoices,
            {
              'id': cId,
              'question_id': qId,
              'choice_label': pc.label,
              'content': pc.content,
              'is_correct': pc.isCorrect ? 1 : 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  /// Lấy danh sách câu hỏi kèm các lựa chọn của bài tập / đề thi
  Future<List<QuestionModel>> getQuestionsByAssignment(String assignmentId) async {
    final db = await database;

    final qRows = await db.query(
      tableQuestions,
      where: 'assignment_id = ?',
      whereArgs: [assignmentId],
      orderBy: 'question_number ASC',
    );

    final List<QuestionModel> questions = [];
    for (final qMap in qRows) {
      final qId = qMap['id'] as String;
      final cRows = await db.query(
        tableChoices,
        where: 'question_id = ?',
        whereArgs: [qId],
        orderBy: 'choice_label ASC',
      );
      final choices = cRows.map((c) => ChoiceModel.fromDbMap(c)).toList();
      questions.add(QuestionModel.fromDbMap(qMap, choices: choices));
    }
    return questions;
  }

  /// Cập nhật câu hỏi và đổi đáp án đúng (Radio selection update)
  Future<void> updateQuestionAndChoices(QuestionModel question) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Cập nhật câu hỏi
      await txn.update(
        tableQuestions,
        question.toDbMap(),
        where: 'id = ?',
        whereArgs: [question.id],
      );

      // 2. Cập nhật các lựa chọn đáp án
      for (final choice in question.choices) {
        await txn.update(
          tableChoices,
          choice.toDbMap(),
          where: 'id = ?',
          whereArgs: [choice.id],
        );
      }
    });
  }

  /// Đổi đáp án đúng tức thì: Đặt is_correct = 1 cho choiceId và 0 cho các đáp án còn lại
  Future<void> setCorrectChoice(String questionId, String choiceId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Đặt tất cả đáp án của câu hỏi về 0
      await txn.update(
        tableChoices,
        {'is_correct': 0},
        where: 'question_id = ?',
        whereArgs: [questionId],
      );

      // Đặt đáp án được chọn thành 1
      await txn.update(
        tableChoices,
        {'is_correct': 1},
        where: 'id = ?',
        whereArgs: [choiceId],
      );
    });
  }

  /// Đếm số câu hỏi của bài tập
  Future<int> getQuestionCount(String assignmentId) async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableQuestions WHERE assignment_id = ?',
      [assignmentId],
    );
    return (res.first['count'] as num?)?.toInt() ?? 0;
  }

  /// Xóa câu hỏi khỏi đề
  Future<int> deleteQuestion(String questionId) async {
    final db = await database;
    return await db.delete(
      tableQuestions,
      where: 'id = ?',
      whereArgs: [questionId],
    );
  }

  /// Thêm câu hỏi mới vào đề
  Future<void> insertQuestionWithChoices(QuestionModel question) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        tableQuestions,
        question.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final choice in question.choices) {
        await txn.insert(
          tableChoices,
          choice.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Đóng kết nối cơ sở dữ liệu
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
