import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/study_provider.dart';

class PomodoroTimerWidget extends StatelessWidget {
  const PomodoroTimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final pomodoro = context.watch<PomodoroProvider>();
    final study = context.watch<StudyProvider>();
    final theme = Theme.of(context);

    Color accentColor;
    switch (pomodoro.mode) {
      case PomodoroMode.focus:
        accentColor = theme.colorScheme.primary;
        break;
      case PomodoroMode.shortBreak:
        accentColor = Colors.teal;
        break;
      case PomodoroMode.longBreak:
        accentColor = Colors.indigo;
        break;
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Mode Segmented Buttons
            SegmentedButton<PomodoroMode>(
              segments: const [
                ButtonSegment<PomodoroMode>(
                  value: PomodoroMode.focus,
                  label: Text('Tập trung'),
                  icon: Icon(Icons.psychology, size: 18),
                ),
                ButtonSegment<PomodoroMode>(
                  value: PomodoroMode.shortBreak,
                  label: Text('Nghỉ ngắn'),
                  icon: Icon(Icons.coffee, size: 18),
                ),
                ButtonSegment<PomodoroMode>(
                  value: PomodoroMode.longBreak,
                  label: Text('Nghỉ dài'),
                  icon: Icon(Icons.hotel, size: 18),
                ),
              ],
              selected: {pomodoro.mode},
              onSelectionChanged: (Set<PomodoroMode> newSelection) {
                pomodoro.setMode(newSelection.first);
              },
            ),

            const SizedBox(height: 20),

            // Subject Selector Dropdown (Chỉ hiện khi chế độ Tập trung)
            if (pomodoro.mode == PomodoroMode.focus && study.subjects.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: pomodoro.selectedSubjectId ?? study.subjects.first.id,
                    isDense: true,
                    borderRadius: BorderRadius.circular(16),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: study.subjects.map((Subject s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: s.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newId) {
                      if (newId != null) {
                        pomodoro.selectSubject(newId);
                      }
                    },
                  ),
                ),
              ),

            const SizedBox(height: 28),

            // Đồng hồ tròn
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 210,
                    height: 210,
                    child: CircularProgressIndicator(
                      value: pomodoro.progress,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pomodoro.formattedTime,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontFeatures: const [],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pomodoro.mode == PomodoroMode.focus
                            ? 'Phiên tập trung # ${(pomodoro.completedPomodoros + 1)}'
                            : 'Thời gian thư giãn',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Thanh nút điều khiển (Play/Pause, Reset, Skip)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: pomodoro.reset,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Đặt lại',
                  iconSize: 24,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(width: 20),
                FilledButton.icon(
                  onPressed: () {
                    if (pomodoro.isRunning) {
                      pomodoro.pause();
                    } else {
                      pomodoro.start();
                    }
                  },
                  icon: Icon(
                    pomodoro.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 28,
                  ),
                  label: Text(
                    pomodoro.isRunning ? 'Tạm dừng' : 'Bắt đầu',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                IconButton.filledTonal(
                  onPressed: pomodoro.skip,
                  icon: const Icon(Icons.skip_next),
                  tooltip: 'Bỏ qua',
                  iconSize: 24,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
