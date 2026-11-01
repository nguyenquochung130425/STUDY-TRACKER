import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/database/database_helper.dart';
import '../models/study_task.dart';
import '../providers/study_provider.dart';
import 'assignment_edit_screen.dart';
import 'quiz_taking_screen.dart';
import 'word_import_screen.dart';

/// Màn hình Quản lý Toàn diện Bài tập & Đề thi trắc nghiệm
class AssignmentManagementScreen extends StatefulWidget {
  const AssignmentManagementScreen({super.key});

  @override
  State<AssignmentManagementScreen> createState() =>
      _AssignmentManagementScreenState();
}

class _AssignmentManagementScreenState extends State<AssignmentManagementScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<StudyTask> _assignments = [];
  Map<String, int> _questionCounts = {};
  bool _isLoading = false;
  String _selectedSubjectFilter = 'Tất cả';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final allAssignments = await _db.getAllAssignments();

    final counts = <String, int>{};
    for (final a in allAssignments) {
      counts[a.id] = await _db.getQuestionCount(a.id);
    }

    if (!mounted) return;
    setState(() {
      _assignments = allAssignments;
      _questionCounts = counts;
      _isLoading = false;
    });
  }

  Future<void> _deleteAssignment(StudyTask assignment) async {
    final count = _questionCounts[assignment.id] ?? 0;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa "${assignment.title}"?'),
        content: Text(
          count > 0
              ? 'Bài tập này có $count câu hỏi trắc nghiệm. Khi xóa, toàn bộ câu hỏi và đáp án sẽ được xóa sạch khỏi hệ thống.'
              : 'Bạn có chắc chắn muốn xóa bài tập này?',
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
      await _db.deleteAssignment(assignment.id);
      // Đồng bộ provider nếu cần
      if (mounted) {
        context.read<StudyProvider>().deleteTask(assignment.id);
      }
      await _loadData();
    }
  }

  void _startQuiz(StudyTask assignment) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => QuizTakingScreen(assignment: assignment),
          ),
        )
        .then((_) => _loadData());
  }

  Future<void> _showAddManualAssignmentDialog() async {
    final study = context.read<StudyProvider>();
    if (study.subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tạo môn học trước khi thêm bài tập!')),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedSubId = study.subjects.first.id;
    DateTime dueDate = DateTime.now().add(const Duration(days: 3));

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Thêm bài tập thủ công'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề bài tập *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSubId,
                    decoration: const InputDecoration(
                      labelText: 'Môn học',
                      border: OutlineInputBorder(),
                    ),
                    items: study.subjects.map((sub) {
                      return DropdownMenuItem(
                        value: sub.id,
                        child: Text(sub.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedSubId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú / Mô tả',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final newTask = StudyTask(
                    id: 'task_${DateTime.now().millisecondsSinceEpoch}',
                    subjectId: selectedSubId,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    dueDate: dueDate,
                  );
                  await _db.insertAssignment(newTask);
                  if (ctx.mounted) {
                    ctx.read<StudyProvider>().addTask(newTask);
                    Navigator.pop(ctx);
                  }
                  await _loadData();
                },
                child: const Text('Thêm'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _assignments.where((a) {
      if (_selectedSubjectFilter != 'Tất cả' && a.subjectId != _selectedSubjectFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = a.title.toLowerCase().contains(query);
        final matchDesc = a.description.toLowerCase().contains(query);
        return matchTitle || matchDesc;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Quản lý Bài Tập & Đề Thi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.edit_note),
            tooltip: 'Chỉnh sửa nội dung đề',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AssignmentEditScreen(),
                ),
              );
              _loadData();
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.only(left: 4, right: 8),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.upload_file),
            tooltip: 'Tạo đề từ Word / Dán Text',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WordImportScreen(),
                ),
              );
              _loadData();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddActionSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm đề / bài tập'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Thanh tìm kiếm và bộ lọc môn học
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm bài tập, đề thi...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Filter chips theo môn
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Tất cả'),
                              selected: _selectedSubjectFilter == 'Tất cả',
                              onSelected: (_) =>
                                  setState(() => _selectedSubjectFilter = 'Tất cả'),
                            ),
                            const SizedBox(width: 6),
                            ...study.subjects.map((sub) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(sub.name),
                                  selected: _selectedSubjectFilter == sub.id,
                                  onSelected: (_) =>
                                      setState(() => _selectedSubjectFilter = sub.id),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Danh sách bài tập
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 12),
                              const Text(
                                'Chưa có bài tập nào.',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _showAddActionSheet(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Tạo bài tập mới'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final assignment = filtered[index];
                            final sub = study.getSubjectById(assignment.subjectId ?? '');
                            final qCount = _questionCounts[assignment.id] ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: qCount > 0
                                      ? AppColors.primary.withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  if (qCount > 0) {
                                    _startQuiz(assignment);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Bài tập này chưa có câu hỏi trắc nghiệm! Hãy bấm "..." -> Sửa nội dung để thêm câu hỏi.',
                                        ),
                                        backgroundColor: AppColors.info,
                                      ),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: sub != null
                                                ? Color(sub.colorValue).withValues(alpha: 0.2)
                                                : AppColors.primary.withValues(alpha: 0.2),
                                            child: Icon(
                                              qCount > 0 ? Icons.quiz : Icons.assignment,
                                              color: sub != null
                                                  ? Color(sub.colorValue)
                                                  : AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        assignment.title,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                          decoration: assignment.isCompleted
                                                              ? TextDecoration.lineThrough
                                                              : null,
                                                        ),
                                                      ),
                                                    ),
                                                    if (qCount > 0)
                                                      Container(
                                                        margin: const EdgeInsets.only(left: 6),
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.primary.withValues(alpha: 0.12),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          '$qCount câu',
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.primary,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    Text(
                                                      sub?.name ?? 'Môn học',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: sub != null
                                                            ? Color(sub.colorValue)
                                                            : Colors.grey,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      '•',
                                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                                    ),
                                                    Text(
                                                      'Hạn: ${assignment.formattedDueDate}',
                                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                    ),
                                                  ],
                                                ),
                                                if (assignment.description.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    assignment.description,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, size: 20),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onSelected: (val) {
                                              if (val == 'start_quiz') {
                                                _startQuiz(assignment);
                                              } else if (val == 'edit_questions') {
                                                Navigator.of(context)
                                                    .push(
                                                      MaterialPageRoute<void>(
                                                        builder: (_) => AssignmentEditScreen(
                                                          initialAssignmentId: assignment.id,
                                                        ),
                                                      ),
                                                    )
                                                    .then((_) => _loadData());
                                              } else if (val == 'toggle_status') {
                                                final updated = assignment.copyWith(
                                                  isCompleted: !assignment.isCompleted,
                                                );
                                                _db.updateAssignment(updated);
                                                context.read<StudyProvider>().updateTask(updated);
                                                _loadData();
                                              } else if (val == 'delete') {
                                                _deleteAssignment(assignment);
                                              }
                                            },
                                            itemBuilder: (ctx) => [
                                              if (qCount > 0)
                                                const PopupMenuItem(
                                                  value: 'start_quiz',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.play_circle_fill,
                                                          size: 18, color: AppColors.primary),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Bắt đầu làm bài',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.primary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              if (qCount > 0)
                                                const PopupMenuItem(
                                                  value: 'edit_questions',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit,
                                                          size: 18, color: AppColors.primary),
                                                      SizedBox(width: 8),
                                                      Text('Sửa nội dung câu hỏi'),
                                                    ],
                                                  ),
                                                ),
                                              PopupMenuItem(
                                                value: 'toggle_status',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      assignment.isCompleted
                                                          ? Icons.undo
                                                          : Icons.check_circle_outline,
                                                      size: 18,
                                                      color: AppColors.success,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      assignment.isCompleted
                                                          ? 'Đánh dấu chưa xong'
                                                          : 'Đánh dấu đã hoàn thành',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline,
                                                        size: 18, color: AppColors.error),
                                                    SizedBox(width: 8),
                                                    Text('Xóa bài tập'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (qCount > 0) ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            FilledButton.tonalIcon(
                                              style: FilledButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 4,
                                                ),
                                                visualDensity: VisualDensity.compact,
                                                backgroundColor:
                                                    AppColors.primary.withValues(alpha: 0.12),
                                                foregroundColor: AppColors.primary,
                                              ),
                                              icon: const Icon(Icons.play_arrow, size: 18),
                                              label: const Text(
                                                'Làm bài',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              onPressed: () => _startQuiz(assignment),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
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

  void _showAddActionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thêm Bài Tập / Đề Thi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.upload_file, color: AppColors.primary),
                ),
                title: const Text('Tạo từ File Word (.docx) hoặc Dán Text'),
                subtitle: const Text('Tự động bóc tách câu hỏi, đáp án, lời giải bằng Regex'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute<void>(
                          builder: (_) => const WordImportScreen(),
                        ),
                      )
                      .then((_) => _loadData());
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_calendar, color: AppColors.success),
                ),
                title: const Text('Thêm bài tập thông thường'),
                subtitle: const Text('Nhập nhanh tiêu đề, hạn chót và môn học'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddManualAssignmentDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
