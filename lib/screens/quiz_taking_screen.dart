import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/database/database_helper.dart';
import '../models/exam_question.dart';
import '../models/grade_entry.dart';
import '../models/study_task.dart';
import '../providers/study_provider.dart';

/// Màn hình Làm bài tập & Đề thi trắc nghiệm
/// Hỗ trợ:
/// - Làm bài tập theo câu hỏi tuần tự, xem passage, chọn đáp án tương tác
/// - Đếm giờ làm bài (Elapsed Timer)
/// - Xem bảng câu hỏi (Question palette) nhảy đến câu bất kỳ
/// - Nộp bài thi có cảnh báo câu chưa làm
/// - Xem kết quả tổng kết (Điểm thang 10, tỉ lệ đúng, thời gian)
/// - Xem lại chi tiết từng câu hỏi, hiển thị rõ các câu sai & đáp án đúng kèm lời giải
/// - Làm lại toàn bộ đề thi hoặc chỉ làm lại các câu đã làm sai
class QuizTakingScreen extends StatefulWidget {
  final StudyTask assignment;
  final List<QuestionModel>? customQuestions; // Dùng khi làm lại các câu sai

  const QuizTakingScreen({
    super.key,
    required this.assignment,
    this.customQuestions,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isLoading = true;
  List<QuestionModel> _questions = [];
  int _currentIndex = 0;

  // Lưu lựa chọn đáp án: questionId -> choiceId
  final Map<String, String> _selectedAnswers = {};

  // Bộ đếm thời gian làm bài
  Timer? _timer;
  int _secondsElapsed = 0;

  // Trạng thái đã nộp bài
  bool _isSubmitted = false;

  // Bộ lọc xem lại sau khi nộp: 'all', 'wrong', 'correct'
  String _reviewFilter = 'all';

  // Đã lưu điểm vào CSDL chưa
  bool _isGradeSaved = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsElapsed++);
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);

    if (widget.customQuestions != null && widget.customQuestions!.isNotEmpty) {
      _questions = List.from(widget.customQuestions!);
    } else {
      _questions = await _db.getQuestionsByAssignment(widget.assignment.id);
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _currentIndex = 0;
      _selectedAnswers.clear();
      _secondsElapsed = 0;
      _isSubmitted = false;
      _isGradeSaved = false;
      _reviewFilter = 'all';
    });

    if (_questions.isNotEmpty) {
      _startTimer();
    }
  }

  void _selectChoice(String questionId, String choiceId) {
    if (_isSubmitted) return;
    setState(() {
      _selectedAnswers[questionId] = choiceId;
    });
  }

  int get _correctCount {
    int count = 0;
    for (final q in _questions) {
      final selectedId = _selectedAnswers[q.id];
      if (selectedId != null) {
        final choice = q.choices.firstWhere(
          (c) => c.id == selectedId,
          orElse: () => ChoiceModel(id: '', questionId: '', label: '', content: ''),
        );
        if (choice.isCorrect) {
          count++;
        }
      }
    }
    return count;
  }

  int get _unansweredCount {
    int count = 0;
    for (final q in _questions) {
      if (!_selectedAnswers.containsKey(q.id)) {
        count++;
      }
    }
    return count;
  }

  int get _wrongCount => _questions.length - _correctCount;

  double get _scoreOnTen {
    if (_questions.isEmpty) return 0.0;
    return (_correctCount / _questions.length) * 10.0;
  }

  List<QuestionModel> get _incorrectQuestions {
    final list = <QuestionModel>[];
    for (final q in _questions) {
      final selectedId = _selectedAnswers[q.id];
      if (selectedId == null) {
        list.add(q);
      } else {
        final choice = q.choices.firstWhere(
          (c) => c.id == selectedId,
          orElse: () => ChoiceModel(id: '', questionId: '', label: '', content: ''),
        );
        if (!choice.isCorrect) {
          list.add(q);
        }
      }
    }
    return list;
  }

  Future<void> _confirmSubmit() async {
    final unanswered = _unansweredCount;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Nộp bài thi?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tổng số câu: ${_questions.length}'),
            const SizedBox(height: 6),
            Text('Đã trả lời: ${_questions.length - unanswered} câu'),
            if (unanswered > 0) ...[
              const SizedBox(height: 6),
              Text(
                '⚠️ Bạn còn $unanswered câu chưa trả lời!',
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text('Bạn có chắc chắn muốn kết thúc bài làm và nộp bài?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Xem lại bài làm'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Nộp bài ngay'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _timer?.cancel();
      setState(() {
        _isSubmitted = true;
      });

      // Tự động đánh dấu bài tập hoàn thành
      await _autoMarkAssignmentCompleted();
    }
  }

  Future<void> _autoMarkAssignmentCompleted() async {
    final updated = widget.assignment.copyWith(isCompleted: true);
    await _db.updateAssignment(updated);
    if (mounted) {
      context.read<StudyProvider>().updateTask(updated);
    }
  }

  Future<void> _saveScoreToGradebook() async {
    if (_isGradeSaved) return;

    final study = context.read<StudyProvider>();
    final subId = widget.assignment.subjectId ??
        (study.subjects.isNotEmpty ? study.subjects.first.id : 'sub_1');

    final grade = GradeEntry(
      id: 'grade_${DateTime.now().millisecondsSinceEpoch}',
      subjectId: subId,
      title: 'Đề: ${widget.assignment.title}',
      score: double.parse(_scoreOnTen.toStringAsFixed(1)),
      maxScore: 10.0,
      weight: 10.0,
      createdAt: DateTime.now(),
    );

    await _db.insertGrade(grade);
    await study.addGrade(grade);

    if (mounted) {
      setState(() => _isGradeSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu điểm ${_scoreOnTen.toStringAsFixed(1)} vào bảng điểm môn học!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _retryFullQuiz() {
    setState(() {
      _currentIndex = 0;
      _selectedAnswers.clear();
      _secondsElapsed = 0;
      _isSubmitted = false;
      _isGradeSaved = false;
      _reviewFilter = 'all';
    });
    _startTimer();
  }

  void _retryWrongQuestionsOnly() {
    final wrongList = _incorrectQuestions;
    if (wrongList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn đã trả lời đúng tất cả các câu hỏi!'),
          backgroundColor: AppColors.success,
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuizTakingScreen(
          assignment: widget.assignment,
          customQuestions: wrongList,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSubmitted
              ? 'Kết Quả: ${widget.assignment.title}'
              : 'Làm bài: ${widget.assignment.title}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!_isSubmitted && !_isLoading && _questions.isNotEmpty) ...[
            // Đồng hồ bấm giờ
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : AppColors.primaryContainer.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_secondsElapsed),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Nút nộp bài
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Nộp bài'),
              onPressed: _confirmSubmit,
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? _buildEmptyState()
              : _isSubmitted
                  ? _buildResultAndReviewView(isDark)
                  : _buildQuizTakingView(isDark),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Bài tập này chưa có câu hỏi trắc nghiệm nào!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại danh sách'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GIAO DIỆN LÀM BÀI TRẮC NGHIỆM
  // ==========================================
  Widget _buildQuizTakingView(bool isDark) {
    final currentQ = _questions[_currentIndex];
    final selectedChoiceId = _selectedAnswers[currentQ.id];

    return SafeArea(
      child: Column(
        children: [
          // Thanh tiến trình và bảng câu hỏi ngang
          _buildProgressAndPaletteHeader(isDark),

          // Nội dung câu hỏi và các lựa chọn đáp án
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card câu hỏi
                      _buildQuestionCard(currentQ, isDark),
                      const SizedBox(height: 16),

                      // Danh sách đáp án A, B, C, D
                      ...currentQ.choices.map((choice) {
                        final isSelected = selectedChoiceId == choice.id;
                        return _buildChoiceOptionCard(
                          choice: choice,
                          isSelected: isSelected,
                          isDark: isDark,
                          onTap: () => _selectChoice(currentQ.id, choice.id),
                        );
                      }),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Thanh điều hướng dưới đáy (Câu trước / Tiếp / Nộp bài)
          _buildBottomNavBar(isDark),
        ],
      ),
    );
  }

  Widget _buildProgressAndPaletteHeader(bool isDark) {
    final answeredCount = _questions.length - _unansweredCount;
    final progress = _questions.isEmpty ? 0.0 : answeredCount / _questions.length;

    return Container(
      color: isDark ? AppColors.darkCard : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ: $answeredCount / ${_questions.length} câu',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),

          // Danh sách các số câu hỏi để nhảy nhanh
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final q = _questions[index];
                final isCurrent = index == _currentIndex;
                final isAnswered = _selectedAnswers.containsKey(q.id);

                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: Container(
                    width: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.primary
                          : isAnswered
                              ? AppColors.primary.withValues(alpha: 0.18)
                              : (isDark ? AppColors.darkSurface : AppColors.lightBackground),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primary
                            : isAnswered
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isCurrent
                            ? Colors.white
                            : isAnswered
                                ? AppColors.primary
                                : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel q, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề câu hỏi & Badge số thứ tự
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Câu ${_currentIndex + 1} / ${_questions.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (_selectedAnswers.containsKey(q.id))
                const Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Đã chọn',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Đoạn văn bài đọc (Passage) nếu có
          if (q.passage != null && q.passage!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.article_outlined, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Đoạn văn đọc hiểu:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    q.passage!,
                    style: const TextStyle(fontSize: 14, height: 1.45),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          // Nội dung câu hỏi
          SelectableText(
            q.content,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceOptionCard({
    required ChoiceModel choice,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.1)
            : (isDark ? AppColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Nhãn chữ cái A, B, C, D
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkSurface
                            : AppColors.lightBackground),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    choice.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Nội dung câu trả lời
                Expanded(
                  child: Text(
                    choice.content,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected && !isDark ? AppColors.primary : null,
                    ),
                  ),
                ),

                // Radio icon
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppColors.primary : Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Nút quay lại câu trước
              OutlinedButton.icon(
                onPressed: isFirst
                    ? null
                    : () => setState(() => _currentIndex = _currentIndex - 1),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Câu trước'),
              ),

              Text(
                'Câu ${_currentIndex + 1} / ${_questions.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),

              // Nút sang câu kế hoặc Nộp bài
              isLast
                  ? FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: _confirmSubmit,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Nộp bài'),
                    )
                  : FilledButton.icon(
                      onPressed: () =>
                          setState(() => _currentIndex = _currentIndex + 1),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Câu tiếp'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // GIAO DIỆN BÁO CÁO KẾT QUẢ & XEM LẠI CÂU SAI
  // ==========================================
  Widget _buildResultAndReviewView(bool isDark) {
    final score = _scoreOnTen;
    final correct = _correctCount;
    final total = _questions.length;
    final wrong = _wrongCount;
    final wrongList = _incorrectQuestions;

    // Lọc danh sách câu hỏi xem lại
    List<QuestionModel> displayQuestions = _questions;
    if (_reviewFilter == 'wrong') {
      displayQuestions = wrongList;
    } else if (_reviewFilter == 'correct') {
      displayQuestions = _questions.where((q) {
        final selectedId = _selectedAnswers[q.id];
        if (selectedId == null) return false;
        final c = q.choices.firstWhere(
          (choice) => choice.id == selectedId,
          orElse: () => ChoiceModel(id: '', questionId: '', label: '', content: ''),
        );
        return c.isCorrect;
      }).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Thẻ tổng kết điểm số nổi bật (Hero Score Banner)
              _buildScoreHeroCard(score, correct, total, isDark),
              const SizedBox(height: 18),

              // 2. Thẻ hành động nhanh (Làm lại, Lưu điểm, Xem câu sai)
              _buildActionButtonsBar(wrongList.length),
              const SizedBox(height: 20),

              // 3. Thanh tiêu đề & Filter Tabs chi tiết câu hỏi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chi Tiết Bài Làm & Lời Giải',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${displayQuestions.length} câu',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('Tất cả ($total)'),
                      selected: _reviewFilter == 'all',
                      onSelected: (_) => setState(() => _reviewFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: const Icon(Icons.cancel, size: 16, color: AppColors.error),
                      label: Text('Câu sai ($wrong)'),
                      selected: _reviewFilter == 'wrong',
                      selectedColor: AppColors.error.withValues(alpha: 0.18),
                      onSelected: (_) => setState(() => _reviewFilter = 'wrong'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                      label: Text('Câu đúng ($correct)'),
                      selected: _reviewFilter == 'correct',
                      selectedColor: AppColors.success.withValues(alpha: 0.18),
                      onSelected: (_) => setState(() => _reviewFilter = 'correct'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Danh sách câu hỏi xem lại chi tiết
              if (displayQuestions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                      const SizedBox(height: 12),
                      Text(
                        _reviewFilter == 'wrong'
                            ? 'Tuyệt vời! Bạn không làm sai câu nào.'
                            : 'Không có câu hỏi phù hợp với bộ lọc.',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else
                ...displayQuestions.map((q) {
                  return _buildDetailedQuestionReviewCard(q, isDark);
                }),

              const SizedBox(height: 24),
              // Nút quay lại danh sách
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại Quản lý Bài Tập & Đề Thi'),
                onPressed: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreHeroCard(double score, int correct, int total, bool isDark) {
    final percentage = total > 0 ? (correct / total * 100).toInt() : 0;
    final isPassed = score >= 5.0;

    String ratingText = 'Cần cố gắng thêm!';
    IconData ratingIcon = Icons.sentiment_dissatisfied;

    if (score >= 9.0) {
      ratingText = 'Xuất sắc! 🎉';
      ratingIcon = Icons.emoji_events;
    } else if (score >= 8.0) {
      ratingText = 'Giỏi!';
      ratingIcon = Icons.sentiment_very_satisfied;
    } else if (score >= 6.5) {
      ratingText = 'Khá!';
      ratingIcon = Icons.sentiment_satisfied;
    } else if (score >= 5.0) {
      ratingText = 'Đạt yêu cầu!';
      ratingIcon = Icons.sentiment_neutral;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPassed
              ? [const Color(0xFF4F46E5), const Color(0xFF06B6D4)]
              : [const Color(0xFFE11D48), const Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPassed ? AppColors.primary : AppColors.error).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(ratingIcon, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Text(
                ratingText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_secondsElapsed),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Điểm số to ở giữa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    score.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Thang điểm 10',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              Column(
                children: [
                  Text(
                    '$correct / $total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Câu đúng ($percentage%)',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Thanh phân chia đúng - sai
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '✅ $correct câu đúng',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '❌ $_wrongCount câu sai',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsBar(int wrongCount) {
    return Column(
      children: [
        Row(
          children: [
            // Nút Làm lại bài tập
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.replay),
                label: const Text('Làm lại bài tập'),
                onPressed: _retryFullQuiz,
              ),
            ),
            const SizedBox(width: 10),

            // Nút Lưu điểm vào bảng điểm môn học
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: _isGradeSaved ? AppColors.success : AppColors.primary,
                  ),
                ),
                icon: Icon(
                  _isGradeSaved ? Icons.check : Icons.grade,
                  color: _isGradeSaved ? AppColors.success : AppColors.primary,
                ),
                label: Text(
                  _isGradeSaved ? 'Đã lưu điểm' : 'Lưu điểm môn',
                  style: TextStyle(
                    color: _isGradeSaved ? AppColors.success : AppColors.primary,
                  ),
                ),
                onPressed: _isGradeSaved ? null : _saveScoreToGradebook,
              ),
            ),
          ],
        ),

        // Nút Chỉ làm lại câu sai nếu có câu sai
        if (wrongCount > 0) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                foregroundColor: AppColors.error,
                backgroundColor: AppColors.error.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.rule),
              label: Text('Luyện tập lại $wrongCount câu sai'),
              onPressed: _retryWrongQuestionsOnly,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailedQuestionReviewCard(QuestionModel q, bool isDark) {
    final selectedId = _selectedAnswers[q.id];
    final selectedChoice = q.choices.firstWhere(
      (c) => c.id == selectedId,
      orElse: () => ChoiceModel(id: '', questionId: '', label: '', content: ''),
    );

    final isCorrect = selectedChoice.id.isNotEmpty && selectedChoice.isCorrect;
    final isUnanswered = selectedChoice.id.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.error.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header câu hỏi với trạng thái Đúng / Sai
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.success
                      : (isUnanswered ? Colors.grey : AppColors.error),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Câu ${q.questionNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isCorrect
                    ? Icons.check_circle
                    : (isUnanswered ? Icons.help_outline : Icons.cancel),
                size: 18,
                color: isCorrect
                    ? AppColors.success
                    : (isUnanswered ? Colors.grey : AppColors.error),
              ),
              const SizedBox(width: 4),
              Text(
                isCorrect
                    ? 'Chính xác'
                    : (isUnanswered ? 'Chưa trả lời' : 'Trả lời sai'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isCorrect
                      ? AppColors.success
                      : (isUnanswered ? Colors.grey : AppColors.error),
                ),
              ),
            ],
          ),

          // Đoạn văn nếu có
          if (q.passage != null && q.passage!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                q.passage!,
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          ],

          const SizedBox(height: 10),
          // Nội dung câu hỏi
          Text(
            q.content,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Danh sách các lựa chọn đáp án với đánh dấu đúng sai
          ...q.choices.map((choice) {
            final isUserChoice = choice.id == selectedChoice.id;
            final isRealCorrect = choice.isCorrect;

            Color? cardColor;
            Color borderColor = Colors.transparent;
            Widget? icon;

            if (isRealCorrect) {
              cardColor = AppColors.success.withValues(alpha: isDark ? 0.25 : 0.12);
              borderColor = AppColors.success;
              icon = const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  SizedBox(width: 4),
                  Text(
                    'Đáp án đúng',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              );
            } else if (isUserChoice && !isRealCorrect) {
              cardColor = AppColors.error.withValues(alpha: isDark ? 0.25 : 0.12);
              borderColor = AppColors.error;
              icon = const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel, size: 16, color: AppColors.error),
                  SizedBox(width: 4),
                  Text(
                    'Bạn đã chọn',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ],
              );
            } else {
              cardColor = isDark ? AppColors.darkSurface : AppColors.lightBackground;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isRealCorrect
                          ? AppColors.success
                          : (isUserChoice ? AppColors.error : Colors.grey.shade400),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      choice.label,
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
                      choice.content,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: (isRealCorrect || isUserChoice)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  ?icon,
                ],
              ),
            );
          }),

          // Lời giải chi tiết nếu có
          if (q.explanation != null && q.explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: isDark ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lời giải chi tiết:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          q.explanation!,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
