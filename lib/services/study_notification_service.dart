import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../models/study_task.dart';

class StudyNotificationService {
  StudyNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const deadlineReminderOffsets = <Duration>[
    Duration(days: 1),
    Duration(hours: 3),
    Duration(minutes: 30),
  ];
  static const studySessionReminderOffset = Duration(minutes: 15);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _available = false;

  bool get _supportsScheduling =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (_initialized) return;
    if (!_supportsScheduling) {
      _initialized = true;
      return;
    }

    try {
      timezone_data.initializeTimeZones();
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _available = true;
    } catch (error) {
      debugPrint('Local notifications unavailable: $error');
    } finally {
      _initialized = true;
    }
  }

  Future<void> requestPermissions() async {
    await initialize();
    if (!_supportsScheduling || !_available) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (error) {
      debugPrint('Could not request notification permission: $error');
    }
  }

  Future<void> syncTasks(Iterable<StudyTask> tasks) async {
    await initialize();
    if (!_supportsScheduling || !_available) return;
    for (final task in tasks) {
      await cancelTaskReminders(task.id);
      if (!task.isCompleted) {
        await _scheduleTaskReminders(task);
      }
    }
  }

  Future<void> scheduleTaskReminders(
    StudyTask task, {
    bool requestPermission = true,
  }) async {
    if (!_supportsScheduling) return;
    if (requestPermission && !task.isCompleted && task.dueDate != null) {
      await requestPermissions();
    } else {
      await initialize();
    }
    if (!_available) return;
    await cancelTaskReminders(task.id);
    if (!task.isCompleted) {
      await _scheduleTaskReminders(task);
    }
  }

  Future<void> _scheduleTaskReminders(StudyTask task) async {
    if (!_available) return;
    final dueDate = task.dueDate;
    if (dueDate == null) return;

    for (var index = 0; index < deadlineReminderOffsets.length; index++) {
      final offset = deadlineReminderOffsets[index];
      final reminderAt = dueDate.subtract(offset);
      if (!reminderAt.isAfter(DateTime.now())) continue;

      await _schedule(
        id: _notificationId('task:${task.id}', index),
        title: 'Sắp đến hạn: ${task.title}',
        body: 'Còn ${_offsetLabel(offset)} là đến hạn bài tập.',
        scheduledAt: reminderAt,
        payload: task.id,
      );
    }
  }

  Future<void> scheduleStudySessionReminder({
    required String id,
    required String title,
    required DateTime startsAt,
  }) async {
    await initialize();
    if (!_supportsScheduling || !_available) return;
    await cancelStudySessionReminder(id);
    await requestPermissions();
    if (!_available) return;
    final reminderAt = startsAt.subtract(studySessionReminderOffset);
    if (!reminderAt.isAfter(DateTime.now())) return;

    await _schedule(
      id: _notificationId('session:$id', 0),
      title: 'Sắp đến giờ học: $title',
      body: 'Buổi học sẽ bắt đầu sau 15 phút.',
      scheduledAt: reminderAt,
      payload: id,
    );
  }

  Future<void> cancelTaskReminders(String taskId) async {
    await initialize();
    if (!_supportsScheduling || !_available) return;
    for (var index = 0; index < deadlineReminderOffsets.length; index++) {
      await _cancel(_notificationId('task:$taskId', index));
    }
  }

  Future<void> cancelStudySessionReminder(String sessionId) async {
    await initialize();
    if (!_supportsScheduling || !_available) return;
    await _cancel(_notificationId('session:$sessionId', 0));
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: timezone.TZDateTime.from(scheduledAt, timezone.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_reminders',
            'Study reminders',
            channelDescription: 'Reminders for assignments and study sessions',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (error) {
      debugPrint('Could not schedule local notification: $error');
    }
  }

  Future<void> _cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (error) {
      debugPrint('Could not cancel local notification: $error');
    }
  }

  static int _notificationId(String key, int reminderIndex) {
    var hash = 0x811c9dc5;
    for (final codeUnit in key.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return ((hash * 4) + reminderIndex) & 0x7fffffff;
  }

  static String _offsetLabel(Duration offset) {
    if (offset.inDays > 0) return '1 ngày';
    if (offset.inHours > 0) return '${offset.inHours} giờ';
    return '${offset.inMinutes} phút';
  }
}
