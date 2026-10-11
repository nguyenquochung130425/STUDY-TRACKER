import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/study_task.dart';
import '../models/subject.dart';
import '../providers/study_provider.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final study = context.read<StudyProvider>();
    String? selectedSubId = study.subjects.isNotEmpty ? study.subjects.first.id : null;
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Thêm nhiệm vụ mới'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung nhiệm vụ / Bài tập',
                      hintText: 'Ví dụ: Làm bài tập toán trang 45',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  if (study.subjects.isNotEmpty) ...[
                    const Text('Môn học:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubId,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: study.subjects.map((Subject s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedSubId = val),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Chưa chọn hạn chót'
                              : 'Hạn: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}',
                          style: TextStyle(
                            color: selectedDate == null ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Chọn ngày'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;

                  final task = StudyTask(
                    id: 'task_${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    subjectId: selectedSubId,
                    dueDate: selectedDate,
                    isCompleted: false,
                  );

                  study.addTask(task);
                  Navigator.pop(ctx);
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
    final theme = Theme.of(context);

    final pendingTasks = study.tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = study.tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhiệm vụ & Bài tập 📝'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm việc'),
      ),
      body: study.tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có nhiệm vụ nào!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Nhấn "Thêm việc" để ghi lại bài tập cần làm.'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                if (pendingTasks.isNotEmpty) ...[
                  Text(
                    'Cần hoàn thành (${pendingTasks.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pendingTasks.map((t) => _buildTaskItem(context, t, study)),
                  const SizedBox(height: 16),
                ],
                if (completedTasks.isNotEmpty) ...[
                  Text(
                    'Đã hoàn thành (${completedTasks.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...completedTasks.map((t) => _buildTaskItem(context, t, study)),
                ],
              ],
            ),
    );
  }

  Widget _buildTaskItem(BuildContext context, StudyTask task, StudyProvider study) {
    final theme = Theme.of(context);
    final subject = task.subjectId != null ? study.getSubjectById(task.subjectId!) : null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          onChanged: (_) => study.toggleTaskCompletion(task.id),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? theme.colorScheme.outline : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            if (subject != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: subject.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subject.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subject.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (task.dueDate != null)
              Text(
                'Hạn: ${DateFormat('dd/MM').format(task.dueDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: task.dueDate!.isBefore(DateTime.now()) && !task.isCompleted
                      ? Colors.red
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => study.deleteTask(task.id),
        ),
      ),
    );
  }
}
