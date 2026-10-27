import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/widgets/custom_button.dart';
import '../core/widgets/custom_text_field.dart';
import '../models/schedule.dart';
import '../models/subject.dart';
import '../providers/schedule_provider.dart';
import '../providers/study_provider.dart';
import 'subject_form_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // 0: Xem theo ngày, 1: Xem theo tuần
  int _viewMode = 0;
  late int _selectedDay;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _weekDays = const [
    {'day': 2, 'name': 'Thứ 2', 'fullName': 'Thứ Hai'},
    {'day': 3, 'name': 'Thứ 3', 'fullName': 'Thứ Ba'},
    {'day': 4, 'name': 'Thứ 4', 'fullName': 'Thứ Tư'},
    {'day': 5, 'name': 'Thứ 5', 'fullName': 'Thứ Năm'},
    {'day': 6, 'name': 'Thứ 6', 'fullName': 'Thứ Sáu'},
    {'day': 7, 'name': 'Thứ 7', 'fullName': 'Thứ Bảy'},
    {'day': 8, 'name': 'CN', 'fullName': 'Chủ Nhật'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = Schedule.fromDateTimeWeekday(DateTime.now().weekday);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Mở form thêm / sửa buổi học
  Future<void> _openScheduleForm(BuildContext context, {Schedule? schedule}) async {
    final studyProvider = context.read<StudyProvider>();
    final subjects = studyProvider.subjects;

    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Chưa có môn học nào! Vui lòng thêm môn học trước khi xếp lịch.',
          ),
          backgroundColor: AppColors.warning,
          action: SnackBarAction(
            label: 'Thêm môn',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubjectFormScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    final isEditing = schedule != null;
    String selectedSubjectId = schedule?.subjectId ?? subjects.first.id;
    int selectedDayOfWeek = schedule?.dayOfWeek ?? _selectedDay;
    String startTime = schedule?.startTime ?? '07:30';
    String endTime = schedule?.endTime ?? '09:30';

    final roomController = TextEditingController(text: schedule?.room ?? '');
    final buildingController = TextEditingController(text: schedule?.building ?? '');
    final noteController = TextEditingController(text: schedule?.note ?? '');
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            // Hàm chọn giờ
            Future<void> pickTime({required bool isStart}) async {
              final initialStr = isStart ? startTime : endTime;
              final parts = initialStr.split(':');
              final initialTime = TimeOfDay(
                hour: int.tryParse(parts[0]) ?? (isStart ? 7 : 9),
                minute: int.tryParse(parts[1]) ?? 30,
              );

              final picked = await showTimePicker(
                context: context,
                initialTime: initialTime,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                final formatted =
                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                setModalState(() {
                  if (isStart) {
                    startTime = formatted;
                  } else {
                    endTime = formatted;
                  }
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Sửa buổi học' : 'Thêm buổi học vào lịch',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Chọn môn học
                      const Text(
                        'Môn học *',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedSubjectId,
                            isExpanded: true,
                            items: subjects.map((s) {
                              return DropdownMenuItem<String>(
                                value: s.id,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Color(s.colorValue),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (s.code.isNotEmpty) ...[
                                      Text(
                                        '[${s.code}] ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(s.colorValue),
                                        ),
                                      ),
                                    ],
                                    Expanded(
                                      child: Text(
                                        s.name,
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedSubjectId = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Chọn thứ trong tuần
                      const Text(
                        'Thứ trong tuần *',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _weekDays.map((d) {
                            final isSel = selectedDayOfWeek == d['day'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(d['name'] as String),
                                selected: isSel,
                                selectedColor: AppColors.primary.withValues(alpha: 0.18),
                                checkmarkColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  color: isSel ? AppColors.primary : null,
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setModalState(() => selectedDayOfWeek = d['day'] as int);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Giờ học (Bắt đầu - Kết thúc)
                      const Text(
                        'Thời gian học *',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => pickTime(isStart: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 18),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Bắt đầu',
                                          style: TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                        Text(
                                          startTime,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                          ),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => pickTime(isStart: false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.alarm_off, size: 18),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Kết thúc',
                                          style: TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                        Text(
                                          endTime,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Phòng học & Tòa nhà
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: CustomTextField(
                              label: 'Phòng học *',
                              hintText: 'VD: A1-203, Lab 4',
                              controller: roomController,
                              prefixIcon: Icons.meeting_room_outlined,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nhập phòng học';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: CustomTextField(
                              label: 'Tòa nhà / Cơ sở',
                              hintText: 'VD: Tòa A',
                              controller: buildingController,
                              prefixIcon: Icons.apartment,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Ghi chú
                      CustomTextField(
                        label: 'Ghi chú buổi học',
                        hintText: 'Ví dụ: Mang laptop, kiểm tra bài tập...',
                        controller: noteController,
                        prefixIcon: Icons.notes,
                      ),
                      const SizedBox(height: 24),

                      // Nút lưu
                      CustomButton(
                        text: isEditing ? 'Lưu cập nhật' : 'Thêm vào lịch',
                        icon: isEditing ? Icons.save : Icons.add_circle,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          // Validate giờ kết thúc > giờ bắt đầu
                          if (startTime.compareTo(endTime) >= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Giờ kết thúc phải sau giờ bắt đầu!'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          final scheduleProvider = context.read<ScheduleProvider>();
                          final room = roomController.text.trim();
                          final building = buildingController.text.trim();
                          final note = noteController.text.trim();

                          if (isEditing) {
                            final updated = schedule.copyWith(
                              subjectId: selectedSubjectId,
                              dayOfWeek: selectedDayOfWeek,
                              startTime: startTime,
                              endTime: endTime,
                              room: room,
                              building: building.isNotEmpty ? building : null,
                              note: note.isNotEmpty ? note : null,
                              updatedAt: DateTime.now(),
                            );
                            await scheduleProvider.updateSchedule(updated);
                          } else {
                            final newSchedule = Schedule(
                              id: 'sch_${DateTime.now().millisecondsSinceEpoch}',
                              subjectId: selectedSubjectId,
                              dayOfWeek: selectedDayOfWeek,
                              startTime: startTime,
                              endTime: endTime,
                              room: room,
                              building: building.isNotEmpty ? building : null,
                              note: note.isNotEmpty ? note : null,
                            );
                            await scheduleProvider.addSchedule(newSchedule);
                          }

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Đã cập nhật buổi học thành công!'
                                      : 'Đã thêm buổi học vào thời khóa biểu!',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Xác nhận xóa buổi học
  Future<void> _handleDeleteSchedule(BuildContext context, Schedule schedule) async {
    final studyProvider = context.read<StudyProvider>();
    final subject = studyProvider.getSubjectById(schedule.subjectId);
    final subjectName = subject?.name ?? 'Môn học';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa buổi học'),
        content: Text(
          'Bạn có chắc chắn muốn xóa buổi học $subjectName (${schedule.timeSpan}, ${schedule.room}) khỏi thời khóa biểu không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final scheduleProvider = context.read<ScheduleProvider>();
      await scheduleProvider.deleteSchedule(schedule.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa buổi học khỏi thời khóa biểu.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheduleProvider = context.watch<ScheduleProvider>();
    final studyProvider = context.watch<StudyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thời khóa biểu & Lịch học'),
        actions: [
          IconButton(
            tooltip: 'Thêm buổi học',
            icon: const Icon(Icons.add),
            onPressed: () => _openScheduleForm(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm buổi học'),
        onPressed: () => _openScheduleForm(context),
      ),
      body: Column(
        children: [
          // Control Bar: Search & View Mode Switcher
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              children: [
                // Realtime Search Bar cho môn học & lịch học
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm môn học, phòng học, GV...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              scheduleProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    scheduleProvider.setSearchQuery(val.trim());
                  },
                ),
                const SizedBox(height: 10),

                // View Mode Switcher (Xem theo Ngày vs Xem theo Tuần)
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      icon: Icon(Icons.calendar_view_day),
                      label: Text('Xem theo ngày'),
                    ),
                    ButtonSegment(
                      value: 1,
                      icon: Icon(Icons.calendar_view_week),
                      label: Text('Xem theo tuần'),
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (newSelection) {
                    setState(() => _viewMode = newSelection.first);
                  },
                ),
              ],
            ),
          ),

          // Body Content
          Expanded(
            child: scheduleProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _viewMode == 0
                    ? _buildDayView(context, scheduleProvider, studyProvider, isDark)
                    : _buildWeekView(context, scheduleProvider, studyProvider, isDark),
          ),
        ],
      ),
    );
  }

  /// ==============================
  /// CHẾ ĐỘ XEM THEO NGÀY (DAY VIEW)
  /// ==============================
  Widget _buildDayView(
    BuildContext context,
    ScheduleProvider scheduleProvider,
    StudyProvider studyProvider,
    bool isDark,
  ) {
    final todayVn = Schedule.fromDateTimeWeekday(DateTime.now().weekday);
    final schedulesForDay = scheduleProvider.getSchedulesForDay(_selectedDay);

    return Column(
      children: [
        // Thanh chọn ngày trong tuần
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _weekDays.map((d) {
              final dayNum = d['day'] as int;
              final isSelected = _selectedDay == dayNum;
              final isToday = todayVn == dayNum;
              final dayCount = scheduleProvider.getSchedulesForDay(dayNum).length;

              return GestureDetector(
                onTap: () => setState(() => _selectedDay = dayNum),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isToday
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        d['name'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isToday
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dayCount > 0
                              ? (isSelected ? Colors.white : AppColors.secondary)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Timeline danh sách buổi học trong ngày
        Expanded(
          child: schedulesForDay.isEmpty
              ? _buildEmptyDayState(context, isDark)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: schedulesForDay.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final schedule = schedulesForDay[index];
                    final subject = studyProvider.getSubjectById(schedule.subjectId);
                    return _buildScheduleCard(
                      context,
                      schedule,
                      subject,
                      isDark,
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// ==============================
  /// CHẾ ĐỘ XEM THEO TUẦN (WEEK VIEW)
  /// ==============================
  Widget _buildWeekView(
    BuildContext context,
    ScheduleProvider scheduleProvider,
    StudyProvider studyProvider,
    bool isDark,
  ) {
    final todayVn = Schedule.fromDateTimeWeekday(DateTime.now().weekday);
    final allSchedules = scheduleProvider.schedules;

    if (allSchedules.isEmpty) {
      return _buildEmptyWeekState(context, isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _weekDays.length,
      itemBuilder: (context, index) {
        final d = _weekDays[index];
        final dayNum = d['day'] as int;
        final isToday = todayVn == dayNum;
        final daySchedules = scheduleProvider.getSchedulesForDay(dayNum);

        if (daySchedules.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isToday
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isToday ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header thứ trong tuần
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : (isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: isToday ? AppColors.primary : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          d['fullName'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isToday ? AppColors.primary : null,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Hôm nay',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${daySchedules.length} buổi học',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Danh sách buổi học trong ngày
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: daySchedules.map((schedule) {
                    final subject = studyProvider.getSubjectById(schedule.subjectId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildScheduleCard(
                        context,
                        schedule,
                        subject,
                        isDark,
                        compact: true,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Thẻ buổi học (Schedule Card)
  Widget _buildScheduleCard(
    BuildContext context,
    Schedule schedule,
    Subject? subject,
    bool isDark, {
    bool compact = false,
  }) {
    final color = subject != null ? Color(subject.colorValue) : AppColors.primary;
    final status = schedule.status;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openScheduleForm(context, schedule: schedule),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Column
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        schedule.startTime,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(width: 8, height: 1.5, color: color),
                      const SizedBox(height: 2),
                      Text(
                        schedule.endTime,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Row(
                        children: [
                          if (schedule.isToday) ...[
                            _buildStatusBadge(status),
                            const SizedBox(width: 6),
                          ],
                          if (subject?.code.isNotEmpty == true) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                subject!.code.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Tên môn học
                      Text(
                        subject?.name ?? 'Môn học không xác định',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Phòng học & Tòa nhà
                      Row(
                        children: [
                          Icon(Icons.meeting_room, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            schedule.room,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (schedule.building != null &&
                              schedule.building!.isNotEmpty) ...[
                            Text(
                              ' • ${schedule.building}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (subject?.lecturer.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 13,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                subject!.lecturer,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (schedule.note != null && schedule.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  schedule.note!,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Action Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openScheduleForm(context, schedule: schedule);
                    } else if (val == 'delete') {
                      _handleDeleteSchedule(context, schedule);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Xóa buổi học', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ScheduleStatus status) {
    String label;
    Color color;

    switch (status) {
      case ScheduleStatus.ongoing:
        label = 'Đang diễn ra';
        color = AppColors.success;
        break;
      case ScheduleStatus.upcoming:
        label = 'Sắp tới';
        color = AppColors.primary;
        break;
      case ScheduleStatus.completed:
        label = 'Đã xong';
        color = Colors.grey;
        break;
      case ScheduleStatus.otherDay:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không có lịch học trong ngày này',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hôm nay bạn không có tiết học nào hoặc chưa xếp lịch. Hãy tận dụng thời gian để ôn tập nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Xếp lịch buổi học',
              icon: Icons.add,
              onPressed: () => _openScheduleForm(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWeekState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thời khóa biểu đang trống',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chưa có buổi học nào được thêm vào thời khóa biểu trong tuần.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Thêm buổi học đầu tiên',
              icon: Icons.add,
              onPressed: () => _openScheduleForm(context),
            ),
          ],
        ),
      ),
    );
  }
}
