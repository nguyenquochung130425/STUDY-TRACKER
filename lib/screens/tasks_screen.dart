import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/study_task.dart';
import '../models/subject.dart';
import '../providers/study_provider.dart';

enum _TaskStatusFilter { all, active, completed }

enum _TaskTimeFilter { all, today, thisWeek, overdue }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  _TaskStatusFilter _statusFilter = _TaskStatusFilter.all;
  _TaskTimeFilter _timeFilter = _TaskTimeFilter.all;
  String? _subjectFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showTaskDialog(BuildContext context, {StudyTask? task}) async {
    final study = context.read<StudyProvider>();
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    final formKey = GlobalKey<FormState>();
    String? selectedSubjectId =
        task?.subjectId ??
        (study.subjects.isNotEmpty ? study.subjects.first.id : null);
    DateTime? selectedDate = task?.dueDate;
    TaskPriority selectedPriority = task?.priority ?? TaskPriority.medium;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(task == null ? 'Thêm bài tập' : 'Sửa bài tập'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề bài tập',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Nhập tiêu đề bài tập'
                          : null,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedSubjectId,
                      decoration: const InputDecoration(
                        labelText: 'Môn học',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Chưa gắn môn'),
                        ),
                        ...study.subjects.map(
                          (Subject subject) => DropdownMenuItem<String?>(
                            value: subject.id,
                            child: Text(subject.name),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => selectedSubjectId = value),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TaskPriority>(
                      initialValue: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Mức độ ưu tiên',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TaskPriority.low,
                          child: Text('Thấp'),
                        ),
                        DropdownMenuItem(
                          value: TaskPriority.medium,
                          child: Text('Trung bình'),
                        ),
                        DropdownMenuItem(
                          value: TaskPriority.urgent,
                          child: Text('Khẩn cấp'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedPriority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? 'Chưa đặt hạn chót'
                                : 'Hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(selectedDate!)}',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Chọn ngày và giờ',
                          onPressed: () async {
                            final now = DateTime.now();
                            final initialDate = selectedDate ?? now;
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: initialDate,
                              firstDate: DateTime(2000),
                              lastDate: now.add(const Duration(days: 3650)),
                            );
                            if (pickedDate == null || !context.mounted) return;
                            final initialTime = selectedDate == null
                                ? TimeOfDay.fromDateTime(now)
                                : TimeOfDay.fromDateTime(selectedDate!);
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: initialTime,
                            );
                            if (pickedTime == null) return;
                            setDialogState(() {
                              selectedDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          },
                          icon: const Icon(Icons.calendar_today),
                        ),
                        if (selectedDate != null)
                          IconButton(
                            tooltip: 'Xóa hạn chót',
                            onPressed: () =>
                                setDialogState(() => selectedDate = null),
                            icon: const Icon(Icons.clear),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final updatedTask = StudyTask(
                    id:
                        task?.id ??
                        'task_${DateTime.now().microsecondsSinceEpoch}',
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    subjectId: selectedSubjectId,
                    dueDate: selectedDate,
                    priority: selectedPriority,
                    isCompleted: task?.isCompleted ?? false,
                  );
                  if (task == null) {
                    await study.addTask(updatedTask);
                  } else {
                    await study.updateTask(updatedTask);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(task == null ? 'Thêm' : 'Lưu'),
              ),
            ],
          );
        },
      ),
    );
    titleController.dispose();
    descriptionController.dispose();
  }

  List<StudyTask> _filteredTasks(StudyProvider study) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final nextWeekStart = weekStart.add(const Duration(days: 7));
    final query = _searchController.text.trim().toLowerCase();

    final tasks = study.tasks.where((task) {
      if (_statusFilter == _TaskStatusFilter.active && task.isCompleted) {
        return false;
      }
      if (_statusFilter == _TaskStatusFilter.completed && !task.isCompleted) {
        return false;
      }
      if (_subjectFilter != null && task.subjectId != _subjectFilter) {
        return false;
      }

      final dueDate = task.dueDate;
      if (_timeFilter == _TaskTimeFilter.today &&
          (dueDate == null || !_sameDay(dueDate, today))) {
        return false;
      }
      if (_timeFilter == _TaskTimeFilter.thisWeek &&
          (dueDate == null ||
              dueDate.isBefore(weekStart) ||
              !dueDate.isBefore(nextWeekStart))) {
        return false;
      }
      if (_timeFilter == _TaskTimeFilter.overdue &&
          (task.isCompleted || dueDate == null || !dueDate.isBefore(now))) {
        return false;
      }

      if (query.isEmpty) return true;
      final subject = task.subjectId == null
          ? null
          : study.getSubjectById(task.subjectId!);
      return task.title.toLowerCase().contains(query) ||
          (subject?.name.toLowerCase().contains(query) ?? false) ||
          (subject?.id.toLowerCase().contains(query) ?? false);
    }).toList();

    tasks.sort((first, second) {
      if (first.dueDate == null) return second.dueDate == null ? 0 : 1;
      if (second.dueDate == null) return -1;
      return first.dueDate!.compareTo(second.dueDate!);
    });
    return tasks;
  }

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();
    final theme = Theme.of(context);
    final tasks = _filteredTasks(study);
    final completionRate = _subjectFilter == null
        ? null
        : study.getSubjectTaskCompletionRate(_subjectFilter!);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final overdueTasks = tasks.where(
      (task) =>
          !task.isCompleted &&
          task.dueDate != null &&
          task.dueDate!.isBefore(now),
    );
    final todayTasks = tasks.where(
      (task) =>
          !task.isCompleted &&
          task.dueDate != null &&
          !task.dueDate!.isBefore(now) &&
          _sameDay(task.dueDate!, today),
    );
    final upcomingTasks = tasks.where(
      (task) =>
          !task.isCompleted &&
          (task.dueDate == null || !task.dueDate!.isBefore(tomorrow)),
    );
    final completedTasks = tasks.where((task) => task.isCompleted);

    return Scaffold(
      appBar: AppBar(title: const Text('Bài tập')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm bài tập'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm bài tập hoặc môn học',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<_TaskStatusFilter>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _TaskStatusFilter.all,
                  label: Text('Tất cả'),
                ),
                ButtonSegment(
                  value: _TaskStatusFilter.active,
                  label: Text('Đang làm'),
                ),
                ButtonSegment(
                  value: _TaskStatusFilter.completed,
                  label: Text('Đã xong'),
                ),
              ],
              selected: {_statusFilter},
              onSelectionChanged: (value) =>
                  setState(() => _statusFilter = value.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<_TaskTimeFilter>(
                    initialValue: _timeFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Thời hạn',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: _TaskTimeFilter.all,
                        child: Text('Mọi thời điểm'),
                      ),
                      DropdownMenuItem(
                        value: _TaskTimeFilter.today,
                        child: Text('Hôm nay'),
                      ),
                      DropdownMenuItem(
                        value: _TaskTimeFilter.thisWeek,
                        child: Text('Tuần này'),
                      ),
                      DropdownMenuItem(
                        value: _TaskTimeFilter.overdue,
                        child: Text('Quá hạn'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _timeFilter = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _subjectFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Môn học',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tất cả môn'),
                      ),
                      ...study.subjects.map(
                        (subject) => DropdownMenuItem<String?>(
                          value: subject.id,
                          child: Text(
                            subject.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _subjectFilter = value),
                  ),
                ),
              ],
            ),
          ),
          if (completionRate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(value: completionRate),
                  ),
                  const SizedBox(width: 12),
                  Text('${(completionRate * 100).round()}% hoàn thành'),
                ],
              ),
            ),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      study.tasks.isEmpty
                          ? 'Chưa có bài tập nào.'
                          : 'Không tìm thấy bài tập phù hợp.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    children: [
                      _buildSection(context, 'Quá hạn', overdueTasks, study),
                      _buildSection(context, 'Hôm nay', todayTasks, study),
                      _buildSection(context, 'Sắp tới', upcomingTasks, study),
                      _buildSection(
                        context,
                        'Đã hoàn thành',
                        completedTasks,
                        study,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    Iterable<StudyTask> tasks,
    StudyProvider study,
  ) {
    final sectionTasks = tasks.toList();
    if (sectionTasks.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            '$title (${sectionTasks.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: title == 'Quá hạn'
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
        ),
        ...sectionTasks.map((task) => _buildTaskItem(context, task, study)),
      ],
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    StudyTask task,
    StudyProvider study,
  ) {
    final theme = Theme.of(context);
    final subject = task.subjectId == null
        ? null
        : study.getSubjectById(task.subjectId!);
    final isOverdue =
        !task.isCompleted &&
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now());

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        onTap: () => _showTaskDialog(context, task: task),
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => study.toggleTaskCompletion(task.id),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? theme.colorScheme.outline : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty)
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (subject != null)
                    _TaskLabel(text: subject.name, color: subject.color),
                  _TaskLabel(
                    text: switch (task.priority) {
                      TaskPriority.low => 'Thấp',
                      TaskPriority.medium => 'Trung bình',
                      TaskPriority.urgent => 'Khẩn cấp',
                    },
                    color: task.priority == TaskPriority.urgent
                        ? theme.colorScheme.error
                        : theme.colorScheme.secondary,
                  ),
                  if (task.dueDate != null)
                    Text(
                      DateFormat('dd/MM HH:mm').format(task.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Tùy chọn bài tập',
          onSelected: (value) async {
            if (value == 'edit') {
              await _showTaskDialog(context, task: task);
            } else if (value == 'delete') {
              await study.deleteTask(task.id);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Sửa')),
            PopupMenuItem(value: 'delete', child: Text('Xóa')),
          ],
        ),
      ),
    );
  }
}

class _TaskLabel extends StatelessWidget {
  const _TaskLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );
}
