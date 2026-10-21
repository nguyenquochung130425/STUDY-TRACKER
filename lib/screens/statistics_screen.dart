import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/grade_entry.dart';
import '../models/study_session.dart';
import '../models/subject.dart';
import '../providers/study_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  Future<void> _showAddGradeDialog(
    BuildContext context,
    Subject subject, {
    GradeEntry? grade,
  }) async {
    final titleController = TextEditingController(text: grade?.title ?? '');
    final scoreController = TextEditingController(
      text: grade?.score.toString() ?? '',
    );
    final maxScoreController = TextEditingController(
      text: grade?.maxScore.toString() ?? '10',
    );
    final weightController = TextEditingController(
      text: grade?.weight.toString() ?? '100',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${grade == null ? 'Thêm' : 'Sửa'} điểm - ${subject.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên đầu điểm',
                  hintText: 'Ví dụ: Giữa kỳ',
                ),
                autofocus: true,
              ),
              TextField(
                controller: scoreController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Điểm đạt được'),
              ),
              TextField(
                controller: maxScoreController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Thang điểm tối đa',
                ),
              ),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Trọng số (%)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final score = double.tryParse(scoreController.text.trim());
              final maxScore = double.tryParse(maxScoreController.text.trim());
              final weight = double.tryParse(weightController.text.trim());

              if (title.isEmpty ||
                  score == null ||
                  maxScore == null ||
                  weight == null ||
                  !score.isFinite ||
                  !maxScore.isFinite ||
                  !weight.isFinite ||
                  maxScore <= 0 ||
                  score < 0 ||
                  score > maxScore ||
                  weight <= 0 ||
                  weight > 100) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Vui lòng nhập tên hợp lệ, điểm trong thang điểm '
                      'và trọng số từ 0 đến 100%.',
                    ),
                  ),
                );
                return;
              }

              final provider = context.read<StudyProvider>();
              final updatedGrade = GradeEntry(
                id:
                    grade?.id ??
                    'grade_${DateTime.now().microsecondsSinceEpoch}',
                subjectId: subject.id,
                title: title,
                score: score,
                maxScore: maxScore,
                weight: weight,
                createdAt: grade?.createdAt ?? DateTime.now(),
              );
              if (grade == null) {
                await provider.addGrade(updatedGrade);
              } else {
                await provider.updateGrade(updatedGrade);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(grade == null ? 'Lưu điểm' : 'Cập nhật'),
          ),
        ],
      ),
    );

    titleController.dispose();
    scoreController.dispose();
    maxScoreController.dispose();
    weightController.dispose();
  }

  Future<void> _confirmDeleteGrade(
    BuildContext context,
    GradeEntry grade,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa đầu điểm?'),
        content: Text('Bạn có chắc muốn xóa "${grade.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      await context.read<StudyProvider>().deleteGrade(grade.id);
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes phút';
  }

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();
    final theme = Theme.of(context);
    final weeklyMinutes = study.weeklyMinutes;
    final gradedSubjects = study.subjects
        .map(
          (subject) => (
            subject: subject,
            average: study.getSubjectWeightedAverage(subject.id),
          ),
        )
        .where((entry) => entry.average != null)
        .toList();
    final gradeTrend = study.grades.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final maxVal = weeklyMinutes.isEmpty
        ? 60.0
        : weeklyMinutes.reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal > 40 ? maxVal * 1.2 : 60.0);

    const weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê học tập 📊')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tổng kết tuần
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Tổng giờ học tuần này',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDuration(study.thisWeekSeconds),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    Column(
                      children: [
                        Text(
                          'Phiên học tuần này',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${study.thisWeekSessionsCount}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Điểm số theo môn',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  study.overallWeightedAverage == null
                      ? 'Chưa có điểm'
                      : 'TB các môn: '
                            '${study.overallWeightedAverage!.toStringAsFixed(2)} / 10',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (gradedSubjects.isNotEmpty) ...[
              Text(
                'Điểm trung bình theo môn',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
                  child: SizedBox(
                    height: 190,
                    child: BarChart(
                      BarChartData(
                        minY: 0,
                        maxY: 10,
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 2,
                              getTitlesWidget: (value, _) => Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              getTitlesWidget: (value, _) {
                                final index = value.toInt();
                                if (index < 0 ||
                                    index >= gradedSubjects.length) {
                                  return const SizedBox.shrink();
                                }
                                final name = gradedSubjects[index].subject.name;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    name.length > 8
                                        ? '${name.substring(0, 8)}…'
                                        : name,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (
                            var index = 0;
                            index < gradedSubjects.length;
                            index++
                          )
                            BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: gradedSubjects[index].average!,
                                  color: gradedSubjects[index].subject.color,
                                  width: 22,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (gradeTrend.length >= 2) ...[
              const SizedBox(height: 16),
              Text(
                'Tiến độ điểm theo thời gian',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
                  child: SizedBox(
                    height: 190,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (gradeTrend.length - 1).toDouble(),
                        minY: 0,
                        maxY: 10,
                        gridData: FlGridData(
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 2,
                              getTitlesWidget: (value, _) => Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              getTitlesWidget: (value, _) {
                                final index = value.toInt();
                                if (index < 0 || index >= gradeTrend.length) {
                                  return const SizedBox.shrink();
                                }
                                final step = (gradeTrend.length / 4)
                                    .ceil()
                                    .clamp(1, 1000);
                                if (index != gradeTrend.length - 1 &&
                                    index % step != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('dd/MM')
                                        .format(gradeTrend[index].createdAt),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (
                                var index = 0;
                                index < gradeTrend.length;
                                index++
                              )
                                FlSpot(
                                  index.toDouble(),
                                  gradeTrend[index].normalizedScore,
                                ),
                            ],
                            isCurved: true,
                            color: theme.colorScheme.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (study.subjects.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Hãy thêm môn học để bắt đầu nhập điểm.'),
                ),
              )
            else
              ...study.subjects.map((subject) {
                final subjectGrades = study.grades
                    .where((grade) => grade.subjectId == subject.id)
                    .toList();
                final average = study.getSubjectWeightedAverage(subject.id);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subject.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              average == null
                                  ? 'Chưa có điểm'
                                  : '${average.toStringAsFixed(2)} / 10',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Thêm điểm',
                              onPressed: () =>
                                  _showAddGradeDialog(context, subject),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                        if (subjectGrades.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Chưa có đầu điểm',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          ...subjectGrades.map(
                            (grade) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(grade.title),
                              subtitle: Text(
                                'Trọng số ${grade.weight}% · '
                                '${DateFormat('dd/MM/yyyy').format(grade.createdAt)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${grade.score.toStringAsFixed(grade.score % 1 == 0 ? 0 : 1)}'
                                    ' / '
                                    '${grade.maxScore.toStringAsFixed(grade.maxScore % 1 == 0 ? 0 : 1)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: 'Thao tác đầu điểm',
                                    onSelected: (action) {
                                      if (action == 'edit') {
                                        _showAddGradeDialog(
                                          context,
                                          subject,
                                          grade: grade,
                                        );
                                      } else if (action == 'delete') {
                                        _confirmDeleteGrade(context, grade);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Sửa đầu điểm'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Xóa đầu điểm'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 14),

            // Biểu đồ cột thời gian học trong tuần
            Text(
              'Thời gian học trong tuần (Phút)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < weekDays.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    weekDays[idx],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox();
                              return Text(
                                '${value.toInt()}p',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(7, (i) {
                        final val = weeklyMinutes.length > i
                            ? weeklyMinutes[i]
                            : 0.0;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: val,
                              color: theme.colorScheme.primary,
                              width: 18,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Lịch sử phiên học gần đây
            Text(
              'Lịch sử học tập gần đây',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            if (study.sessions.isEmpty)
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Chưa có phiên học nào được ghi lại.\nHãy hoàn thành một phiên Pomodoro!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: study.sessions.length > 10
                    ? 10
                    : study.sessions.length,
                itemBuilder: (context, index) {
                  final StudySession s = study.sessions[index];
                  final Subject? subject = study.getSubjectById(s.subjectId);
                  final timeStr = DateFormat('HH:mm - dd/MM')
                      .format(s.timestamp);

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (subject?.color ?? Colors.grey)
                            .withValues(alpha: 0.2),
                        child: Icon(
                          subject?.icon ?? Icons.timer,
                          color: subject?.color ?? Colors.grey,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        subject?.name ?? 'Môn học khác',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(timeStr),
                      trailing: Text(
                        _formatDuration(s.durationSeconds),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
