import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';
import '../providers/pomodoro_provider.dart';

class DailyStatsCard extends StatelessWidget {
  const DailyStatsCard({super.key});

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes phút';
  }

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();
    final pomodoro = context.watch<PomodoroProvider>();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.timer_outlined,
            iconColor: Colors.blue,
            label: 'Học hôm nay',
            value: _formatDuration(study.todaySeconds),
          ),
          _divider(theme),
          _StatItem(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            label: 'Pomodoro',
            value: '${pomodoro.completedPomodoros} phiên',
          ),
          _divider(theme),
          _StatItem(
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            label: 'Chuỗi ngày',
            value: '${study.currentStreakDays} ngày',
          ),
        ],
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Container(
      height: 36,
      width: 1,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
