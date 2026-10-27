import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/database/database_helper.dart';
import '../models/exam_question.dart';
import '../models/study_task.dart';
import '../providers/study_provider.dart';

/// Màn hình Chỉnh sửa Nội dung Đề Thi / Bài Tập Trắc Nghiệm (Luồng F2)
/// - Chọn Đề thi từ Dropdown
/// - Nạp danh sách câu hỏi từ SQLite
/// - Render form chỉnh sửa từng câu hỏi, passage, lời giải
/// - Chọn Radio button đổi đáp án đúng tức thì với highlight màu xanh
/// - Thêm câu mới / xóa câu hỏi
class AssignmentEditScreen extends StatefulWidget {
  final String? initialAssignmentId;

  const AssignmentEditScreen({
    super.key,
    this.initialAssignmentId,
  });

  @override
  State<AssignmentEditScreen> createState() => _AssignmentEditScreenState();
}

class _AssignmentEditScreenState extends State<AssignmentEditScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<StudyTask> _assignments = [];
  String? _selectedAssignmentId;

  bool _isLoading = false;
  List<QuestionModel> _questions = [];

  // Controllers cho từng câu hỏi để quản lý trạng thái form trực tiếp
  final Map<String, TextEditingController> _contentControllers = {};
  final Map<String, TextEditingController> _passageControllers = {};
  final Map<String, TextEditingController> _explanationControllers = {};
  final Map<String, Map<String, TextEditingController>> _choiceControllers = {};

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final c in _contentControllers.values) {
      c.dispose();
    }
    for (final c in _passageControllers.values) {
      c.dispose();
    }
    for (final c in _explanationControllers.values) {
      c.dispose();
    }
    for (final choiceMap in _choiceControllers.values) {
      for (final c in choiceMap.values) {
        c.dispose();
      }
    }
    _contentControllers.clear();
    _passageControllers.clear();
    _explanationControllers.clear();
    _choiceControllers.clear();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    final allAssignments = await _db.getAllAssignments();
    if (!mounted) return;

    setState(() {
      _assignments = allAssignments;
      if (widget.initialAssignmentId != null &&
          allAssignments.any((a) => a.id == widget.initialAssignmentId)) {
        _selectedAssignmentId = widget.initialAssignmentId;
      } else if (allAssignments.isNotEmpty) {
        _selectedAssignmentId = allAssignments.first.id;
      }
    });

    if (_selectedAssignmentId != null) {
      await _loadQuestionsForAssignment(_selectedAssignmentId!);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadQuestionsForAssignment(String assignmentId) async {
    setState(() => _isLoading = true);
    _disposeControllers();

    final questions = await _db.getQuestionsByAssignment(assignmentId);

    for (final q in questions) {
      _contentControllers[q.id] = TextEditingController(text: q.content);
      _passageControllers[q.id] = TextEditingController(text: q.passage ?? '');
      _explanationControllers[q.id] =
          TextEditingController(text: q.explanation ?? '');
      _choiceControllers[q.id] = {};
      for (final c in q.choices) {
        _choiceControllers[q.id]![c.id] =
            TextEditingController(text: c.content);
      }
    }

    if (!mounted) return;
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  /// Đổi đáp án đúng tức thì với highlight xanh lá
  Future<void> _setCorrectChoice(String questionId, String choiceId) async {
    await _db.setCorrectChoice(questionId, choiceId);

    setState(() {
      final qIndex = _questions.indexWhere((q) => q.id == questionId);
      if (qIndex != -1) {
        final updatedChoices = _questions[qIndex].choices.map((c) {
          return c.copyWith(isCorrect: c.id == choiceId);
        }).toList();
        _questions[qIndex] = _questions[qIndex].copyWith(choices: updatedChoices);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật đáp án đúng thành công!'),
          duration: Duration(milliseconds: 900),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// Lưu thay đổi một câu hỏi cụ thể
  Future<void> _saveSingleQuestion(QuestionModel question) async {
    final updatedContent =
        _contentControllers[question.id]?.text.trim() ?? question.content;
    final updatedPassage = _passageControllers[question.id]?.text.trim();
    final updatedExplanation =
        _explanationControllers[question.id]?.text.trim();

    final updatedChoices = question.choices.map((c) {
      final newContent =
          _choiceControllers[question.id]?[c.id]?.text.trim() ?? c.content;
      return c.copyWith(content: newContent);
    }).toList();

    final updatedQuestion = question.copyWith(
      content: updatedContent,
      passage: updatedPassage != null && updatedPassage.isNotEmpty
          ? updatedPassage
          : null,
      explanation: updatedExplanation != null && updatedExplanation.isNotEmpty
          ? updatedExplanation
          : null,
      choices: updatedChoices,
      updatedAt: DateTime.now(),
    );

    await _db.updateQuestionAndChoices(updatedQuestion);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu Câu ${question.questionNumber} thành công!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }

  /// Xóa câu hỏi khỏi đề
  Future<void> _deleteQuestion(String questionId, int questionNumber) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận xóa Câu $questionNumber?'),
        content: const Text(
          'Câu hỏi và toàn bộ các đáp án liên quan sẽ bị xóa vĩnh viễn khỏi CSDL.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteQuestion(questionId);
      if (_selectedAssignmentId != null) {
        await _loadQuestionsForAssignment(_selectedAssignmentId!);
      }
    }
  }

  /// Thêm câu hỏi mới vào đề thi hiện tại
  Future<void> _addNewQuestion() async {
    if (_selectedAssignmentId == null) return;

    final nextNumber = _questions.isEmpty
        ? 1
        : (_questions.map((q) => q.questionNumber).reduce((a, b) => a > b ? a : b) + 1);

    final qId = 'q_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();

    final newChoices = [
      ChoiceModel(
        id: 'c_${DateTime.now().microsecondsSinceEpoch}_A',
        questionId: qId,
        label: 'A',
        content: 'Phương án A',
        isCorrect: true,
      ),
      ChoiceModel(
        id: 'c_${DateTime.now().microsecondsSinceEpoch + 1}_B',
        questionId: qId,
        label: 'B',
        content: 'Phương án B',
        isCorrect: false,
      ),
      ChoiceModel(
        id: 'c_${DateTime.now().microsecondsSinceEpoch + 2}_C',
        questionId: qId,
        label: 'C',
        content: 'Phương án C',
        isCorrect: false,
      ),
      ChoiceModel(
        id: 'c_${DateTime.now().microsecondsSinceEpoch + 3}_D',
        questionId: qId,
        label: 'D',
        content: 'Phương án D',
        isCorrect: false,
      ),
    ];

    final newQuestion = QuestionModel(
      id: qId,
      assignmentId: _selectedAssignmentId!,
      questionNumber: nextNumber,
      content: 'Câu hỏi mới $nextNumber',
      choices: newChoices,
      createdAt: now,
      updatedAt: now,
    );

    await _db.insertQuestionWithChoices(newQuestion);
    await _loadQuestionsForAssignment(_selectedAssignmentId!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final study = context.watch<StudyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa Nội dung Đề thi'),
        actions: [
          if (_selectedAssignmentId != null)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Thêm câu hỏi mới',
              onPressed: _addNewQuestion,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Thanh chọn đề thi từ Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _assignments.isEmpty
                            ? const Text('Chưa có đề thi nào trong CSDL.')
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedAssignmentId,
                                  hint: const Text('Chọn đề thi / bài tập...'),
                                  items: _assignments.map((assignment) {
                                    final subject = study.getSubjectById(assignment.subjectId ?? '');
                                    return DropdownMenuItem<String>(
                                      value: assignment.id,
                                      child: Text(
                                        '${assignment.title} (${subject?.name ?? "Môn học"})',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newId) {
                                    if (newId != null && newId != _selectedAssignmentId) {
                                      setState(() => _selectedAssignmentId = newId);
                                      _loadQuestionsForAssignment(newId);
                                    }
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                // Danh sách câu hỏi
                Expanded(
                  child: _assignments.isEmpty
                      ? const Center(
                          child: Text('Hãy tạo bài tập từ file Word trước khi chỉnh sửa!'),
                        )
                      : _questions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Đề thi này chưa có câu hỏi trắc nghiệm nào.',
                                    style: TextStyle(fontSize: 15, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _addNewQuestion,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Thêm câu hỏi đầu tiên'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _questions.length,
                              itemBuilder: (context, index) {
                                final q = _questions[index];
                                return _buildQuestionCard(context, q, index, isDark);
                              },
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    QuestionModel q,
    int index,
    bool isDark,
  ) {
    final contentCtrl = _contentControllers[q.id];
    final passageCtrl = _passageControllers[q.id];
    final explanationCtrl = _explanationControllers[q.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề card câu hỏi + nút thao tác
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Câu ${q.questionNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.save_outlined, color: AppColors.primary),
                      tooltip: 'Lưu câu này',
                      onPressed: () => _saveSingleQuestion(q),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      tooltip: 'Xóa câu này',
                      onPressed: () => _deleteQuestion(q.id, q.questionNumber),
                    ),
                  ],
                ),
              ],
            ),

            // Đoạn văn đọc hiểu (Passage nếu có)
            if (q.passage != null && q.passage!.isNotEmpty) ...[
              const SizedBox(height: 10),
              TextField(
                controller: passageCtrl,
                maxLines: null,
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                decoration: InputDecoration(
                  labelText: 'Đoạn văn đọc hiểu (Passage):',
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Nội dung câu hỏi
            TextField(
              controller: contentCtrl,
              maxLines: null,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Nội dung câu hỏi:',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 14),
            const Text(
              'Các phương án lựa chọn (Click nút tròn để đổi đáp án đúng):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Danh sách choices kèm Radio button đổi đáp án đúng
            RadioGroup<String>(
              groupValue: q.choices.firstWhere(
                (c) => c.isCorrect,
                orElse: () => q.choices.first,
              ).id,
              onChanged: (newChoiceId) {
                if (newChoiceId != null) {
                  _setCorrectChoice(q.id, newChoiceId);
                }
              },
              child: Column(
                children: q.choices.map((choice) {
                  final isCorrect = choice.isCorrect;
                  final choiceCtrl = _choiceControllers[q.id]?[choice.id];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? AppColors.success.withValues(alpha: 0.12)
                          : (isDark ? AppColors.darkBackground : const Color(0xFFFAFAFA)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCorrect ? AppColors.success : Colors.grey.withValues(alpha: 0.3),
                        width: isCorrect ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Radio button chọn đáp án đúng tức thì
                        Radio<String>(
                          value: choice.id,
                          activeColor: AppColors.success,
                        ),
                        Text(
                          '${choice.label}.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isCorrect ? AppColors.success : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: choiceCtrl,
                            maxLines: null,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        if (isCorrect)
                          const Chip(
                            label: Text(
                              'Đáp án đúng',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: AppColors.success,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // Lời giải thích (Explanation)
            TextField(
              controller: explanationCtrl,
              maxLines: null,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Lời giải thích / Explanation (nếu có):',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(10),
                prefixIcon: const Icon(Icons.lightbulb_outline, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
