import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/study_session.dart';
import '../models/subject.dart';
import '../providers/study_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

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

    final maxVal = weeklyMinutes.isEmpty
        ? 60.0
        : weeklyMinutes.reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal > 40 ? maxVal * 1.2 : 60.0);

    const weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê học tập 📊'),
      ),
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
                          'Tổng phiên học',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${study.sessions.length}',
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
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                        final val = weeklyMinutes.length > i ? weeklyMinutes[i] : 0.0;
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
                itemCount: study.sessions.length > 10 ? 10 : study.sessions.length,
                itemBuilder: (context, index) {
                  final StudySession s = study.sessions[index];
                  final Subject? subject = study.getSubjectById(s.subjectId);
                  final timeStr = DateFormat('HH:mm - dd/MM').format(s.timestamp);

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
                      leading: CircleAvatar(
                        backgroundColor: (subject?.color ?? Colors.grey).withValues(alpha: 0.2),
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
