import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/database/database_helper.dart';
import '../core/widgets/custom_button.dart';
import '../models/study_task.dart';
import '../models/subject.dart';
import '../providers/study_provider.dart';
import '../services/word_parser.dart';

class WordImportScreen extends StatefulWidget {
  const WordImportScreen({super.key});

  @override
  State<WordImportScreen> createState() => _WordImportScreenState();
}

class _WordImportScreenState extends State<WordImportScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController(text: 'Bài tập trắc nghiệm mới');
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));

  String? _selectedSubjectId;
  ParsedExam? _parsedExam;
  bool _isParsing = false;
  bool _isSaving = false;

  final String _sampleQuizText = '''
ĐỀ THI: Kiểm tra trắc nghiệm kiến thức tổng hợp
MÃ ĐỀ: EXAM-01
THỜI GIAN: 45 phút

[Passage]
Flutter is an open-source UI software development kit created by Google. It is used to develop cross-platform applications from a single codebase.

Câu 1: Flutter được phát triển bởi công ty công nghệ nào?
*A. Google
B. Microsoft
C. Apple
D. Meta
Giải thích: Flutter là framework đa nền tảng mã nguồn mở được phát triển bởi Google.

Câu 2: Ngôn ngữ lập trình chính được sử dụng để xây dựng ứng dụng Flutter là gì?
A. Java
B. Kotlin
C. Dart
D. Swift
Đáp án: C
Giải thích: Flutter sử dụng ngôn ngữ Dart do Google thiết kế.

Câu 3: Trong Flutter, widget nào được sử dụng để hiển thị một danh sách cuộn linh hoạt?
A. Container
B. ListView
C. Column
D. Stack
Đáp án: B

BẢNG ĐÁP ÁN: 1.A  2.C  3.B
''';

  @override
  void initState() {
    super.initState();
    _textController.text = _sampleQuizText;
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _runParser() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập hoặc dán nội dung văn bản đề thi!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isParsing = true);

    try {
      final parsed = WordParser.parseText(text);
      setState(() {
        _parsedExam = parsed;
        if (parsed.title.isNotEmpty && parsed.title != 'Bài tập trắc nghiệm mới') {
          _titleController.text = parsed.title;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã bóc tách thành công ${parsed.questions.length} câu hỏi trắc nghiệm!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi phân tích đề: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isParsing = false);
    }
  }

  Future<void> _saveExamToDatabase() async {
    if (_parsedExam == null || _parsedExam!.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có câu hỏi nào để lưu! Vui lòng bấm phân tích đề.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final study = context.read<StudyProvider>();
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : _parsedExam!.title;

    final subjectId = _selectedSubjectId ??
        (study.subjects.isNotEmpty ? study.subjects.first.id : null);

    setState(() => _isSaving = true);

    try {
      final assignmentId = 'task_${DateTime.now().millisecondsSinceEpoch}';
      final assignment = StudyTask(
        id: assignmentId,
        title: title,
        subjectId: subjectId,
        dueDate: _dueDate,
        isCompleted: false,
      );

      // Lưu tuần tự bằng SQL Transaction: Assignments -> Questions -> Choices
      await DatabaseHelper.instance.saveExamWithTransaction(
        assignment: assignment,
        questions: _parsedExam!.questions,
      );

      // Cập nhật StudyProvider state
      await study.addTask(assignment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã lưu đề thi "$title" (${_parsedExam!.questions.length} câu) thành công!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu CSDL: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final study = context.watch<StudyProvider>();
    final subjects = study.subjects;

    if (_selectedSubjectId == null && subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Đề Từ File Word / Dán Text'),
        elevation: 0,
        actions: [
          if (_parsedExam != null && _parsedExam!.questions.isNotEmpty)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: const Text('Lưu đề thi'),
              onPressed: _isSaving ? null : _saveExamToDatabase,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thông tin cơ bản đề thi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit_note, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Thông tin Đề / Bài tập',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề đề thi / Bài tập',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.assignment),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Môn học
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSubjectId,
                          decoration: const InputDecoration(
                            labelText: 'Môn học',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.book_outlined),
                          ),
                          items: subjects.map((Subject s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                s.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedSubjectId = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Hạn nộp
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Hạn nộp',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_dueDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Khối Dán văn bản hoặc xem trước
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Nội dung đề (Word hoặc Dán Text)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Mẫu đề'),
                        onPressed: () {
                          setState(() => _textController.text = _sampleQuizText);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Engine hỗ trợ nhận diện Part, Bài đọc [Passage], Câu 1:, các đáp án A/B/C/D, nhận diện đáp án đúng (*A, Đáp án: B, hoặc BẢNG ĐÁP ÁN ở cuối).',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _textController,
                    maxLines: 10,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Dán nội dung từ file Word hoặc văn bản tại đây...',
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Phân tích đề thi (Regex Engine)',
                    icon: Icons.auto_awesome,
                    isLoading: _isParsing,
                    onPressed: _runParser,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // GIAO DIỆN XEM TRƯỚC (PREVIEW)
            if (_parsedExam != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                            const SizedBox(width: 6),
                            Text(
                              'Đã nhận diện: ${_parsedExam!.questions.length} câu',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Xem trước - Preview',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Danh sách từng câu hỏi đã parse
              ..._parsedExam!.questions.map((q) => _buildQuestionPreviewCard(q, isDark)),

              const SizedBox(height: 24),
              CustomButton(
                text: 'Xác nhận & Lưu vào CSDL SQLite',
                icon: Icons.save,
                isLoading: _isSaving,
                onPressed: _saveExamToDatabase,
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPreviewCard(ParsedQuestion q, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề câu hỏi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Câu ${q.number}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  q.content,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          // Đoạn văn nếu có
          if (q.passage != null && q.passage!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                q.passage!,
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Các lựa chọn A, B, C, D
          Column(
            children: q.choices.map((c) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: c.isCorrect
                      ? AppColors.success.withValues(alpha: isDark ? 0.25 : 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: c.isCorrect
                        ? AppColors.success
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: c.isCorrect ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.isCorrect ? AppColors.success : Colors.grey.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        c.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: c.isCorrect ? Colors.white : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.content,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: c.isCorrect ? FontWeight.bold : FontWeight.normal,
                          color: c.isCorrect ? AppColors.success : null,
                        ),
                      ),
                    ),
                    if (c.isCorrect) ...[
                      const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),

          // Giải thích nếu có
          if (q.explanation != null && q.explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Giải thích: ${q.explanation}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
