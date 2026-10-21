import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../providers/study_provider.dart';
import 'cloud_sync_screen.dart';
import '../widgets/daily_stats_card.dart';
import '../widgets/pomodoro_timer_widget.dart';
import '../widgets/subject_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showAddSubjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final targetController = TextEditingController(text: '5');
    int selectedColor = 0xFF2196F3;

    final colors = [
      0xFF2196F3, // Blue
      0xFF4CAF50, // Green
      0xFFE91E63, // Pink
      0xFFFF9800, // Orange
      0xFF9C27B0, // Purple
      0xFF00BCD4, // Cyan
      0xFFFF5722, // Deep Orange
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Thêm môn học mới'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên môn học',
                      hintText: 'Ví dụ: Hóa học, Triết học...',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Mục tiêu (giờ / tuần)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Chọn màu đại diện:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: colors.map((c) {
                      final isSelected = selectedColor == c;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.black87, width: 3)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
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
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final target = double.tryParse(targetController.text) ?? 5.0;

                  final newSubject = Subject(
                    id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    colorValue: selectedColor,
                    weeklyTargetHours: target,
                  );

                  context.read<StudyProvider>().addSubject(newSubject);
                  Navigator.pop(ctx);
                },
                child: const Text('Lưu'),
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
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(now);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Study Tracker 🎯',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              formattedDate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync_outlined),
            tooltip: 'Tài khoản và đồng bộ',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CloudSyncScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Thêm môn học',
            onPressed: () => _showAddSubjectDialog(context),
          ),
        ],
      ),
      body: study.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thống kê nhanh trong ngày
                  const DailyStatsCard(),

                  const SizedBox(height: 20),

                  // Bộ đếm Pomodoro
                  const PomodoroTimerWidget(),

                  const SizedBox(height: 24),

                  // Tiêu đề danh sách môn học
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Môn học & Mục tiêu',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddSubjectDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Thêm môn'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Danh sách môn học
                  if (study.subjects.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Chưa có môn học nào. Nhấn "Thêm môn" để bắt đầu!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ...study.subjects.map(
                      (subject) => SubjectCard(
                        subject: subject,
                        onTap: () {
                          // Xem chi tiết môn học hoặc đổi mục tiêu
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
