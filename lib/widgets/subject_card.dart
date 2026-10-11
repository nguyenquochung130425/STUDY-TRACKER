import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../providers/study_provider.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;

  const SubjectCard({
    super.key,
    required this.subject,
    this.onTap,
  });

  String _formatHours(int seconds) {
    final hours = seconds / 3600.0;
    if (hours < 0.1) {
      final mins = seconds ~/ 60;
      return '$mins phút';
    }
    return '${hours.toStringAsFixed(1)} giờ';
  }

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyProvider>();
    final theme = Theme.of(context);

    final todaySeconds = study.getSubjectSecondsToday(subject.id);
    final weekSeconds = study.getSubjectSecondsThisWeek(subject.id);
    final weekHours = weekSeconds / 3600.0;
    final progress = (subject.weeklyTargetHours > 0)
        ? (weekHours / subject.weeklyTargetHours).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: subject.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      subject.icon,
                      color: subject.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hôm nay: ${_formatHours(todaySeconds)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: subject.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(subject.color),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đã học tuần này: ${weekHours.toStringAsFixed(1)}h',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Mục tiêu: ${subject.weeklyTargetHours.toStringAsFixed(0)}h/tuần',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
