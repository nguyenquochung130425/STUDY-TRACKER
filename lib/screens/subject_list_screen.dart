import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/widgets/custom_button.dart';
import '../models/subject.dart';
import '../providers/schedule_provider.dart';
import '../providers/study_provider.dart';
import 'subject_form_screen.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  String _selectedSemester = 'Tất cả';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Xử lý xóa môn học kèm kiểm tra ràng buộc khóa ngoại và cảnh báo Cascade Delete
  Future<void> _handleDeleteSubject(BuildContext context, Subject subject) async {
    final studyProvider = context.read<StudyProvider>();
    final scheduleProvider = context.read<ScheduleProvider>();

    // 1. Kiểm tra số lượng bản ghi liên quan (lịch học, bài tập, điểm số)
    final counts = await studyProvider.getSubjectRelatedCounts(subject.id);
    final totalRelated = counts['total'] ?? 0;
    final schedulesCount = counts['schedules'] ?? 0;
    final assignmentsCount = counts['assignments'] ?? 0;
    final gradesCount = counts['grades'] ?? 0;

    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. Hiển thị hộp thoại cảnh báo ràng buộc dữ liệu
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Cảnh báo xóa môn học',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Bạn đang yêu cầu xóa môn học: '),
                    TextSpan(
                      text: subject.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (subject.code.isNotEmpty)
                      TextSpan(
                        text: ' (${subject.code})',
                        style: TextStyle(color: Color(subject.colorValue)),
                      ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (totalRelated > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.link_off, size: 16, color: AppColors.error),
                          SizedBox(width: 6),
                          Text(
                            'Dữ liệu liên quan sẽ bị xóa (Cascade):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (schedulesCount > 0)
                        _buildRelatedItem(
                          Icons.calendar_month,
                          '$schedulesCount buổi học trong thời khóa biểu',
                        ),
                      if (assignmentsCount > 0)
                        _buildRelatedItem(
                          Icons.assignment_outlined,
                          '$assignmentsCount bài tập / nhiệm vụ cần làm',
                        ),
                      if (gradesCount > 0)
                        _buildRelatedItem(
                          Icons.grade_outlined,
                          '$gradesCount đầu điểm số môn học',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hành động này sẽ thực hiện Cascade Delete tự động trong SQLite và không thể khôi phục lại.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.error,
                  ),
                ),
              ] else ...[
                const Text(
                  'Môn học này hiện chưa có dữ liệu liên quan. Bạn có chắc chắn muốn xóa không?',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                totalRelated > 0 ? 'Xóa tất cả (Cascade)' : 'Xóa môn học',
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      await studyProvider.deleteSubject(subject.id);
      await scheduleProvider.loadSchedules();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa môn học "${subject.name}" và dữ liệu liên quan!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Widget _buildRelatedItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studyProvider = context.watch<StudyProvider>();
    final allSubjects = studyProvider.subjects;

    // Danh sách học kỳ động từ các môn học
    final semestersSet = <String>{'Tất cả'};
    for (final s in allSubjects) {
      if (s.semester.trim().isNotEmpty) {
        semestersSet.add(s.semester.trim());
      }
    }
    final semesters = semestersSet.toList();

    // Lọc theo học kỳ & tìm kiếm
    final filteredSubjects = allSubjects.where((subject) {
      final matchesSemester =
          _selectedSemester == 'Tất cả' || subject.semester == _selectedSemester;

      if (!matchesSemester) return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatches = subject.name.toLowerCase().contains(query);
        final codeMatches = subject.code.toLowerCase().contains(query);
        final lecturerMatches = subject.lecturer.toLowerCase().contains(query);
        return nameMatches || codeMatches || lecturerMatches;
      }

      return true;
    }).toList();

    // Tính toán thống kê
    final totalCredits = filteredSubjects.fold<int>(
      0,
      (sum, s) => sum + s.credits,
    );
    final totalTargetHours = filteredSubjects.fold<double>(
      0,
      (sum, s) => sum + s.weeklyTargetHours,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Môn học'),
        actions: [
          IconButton(
            tooltip: 'Thêm môn học',
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubjectFormScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm môn học'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubjectFormScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // Header tóm tắt & Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên môn, mã môn, GV...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
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
                    setState(() => _searchQuery = val.trim());
                  },
                ),
                const SizedBox(height: 10),

                // Semester Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: semesters.map((sem) {
                      final isSelected = _selectedSemester == sem;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(sem),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withValues(alpha: 0.18),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                          onSelected: (selected) {
                            setState(() => _selectedSemester = sem);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Thống kê nhanh
                Row(
                  children: [
                    _buildStatBadge(
                      Icons.book_outlined,
                      '${filteredSubjects.length} môn',
                      AppColors.primary,
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildStatBadge(
                      Icons.school_outlined,
                      '$totalCredits tín chỉ',
                      AppColors.secondary,
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildStatBadge(
                      Icons.timer_outlined,
                      '${totalTargetHours.toStringAsFixed(1)}h / tuần',
                      AppColors.warning,
                      isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Danh sách môn học
          Expanded(
            child: filteredSubjects.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: filteredSubjects.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final subject = filteredSubjects[index];
                      return _buildSubjectCard(context, subject, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(
    IconData icon,
    String label,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, Subject subject, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(subject.colorValue).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(subject.colorValue).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubjectFormScreen(subject: subject),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(subject.colorValue),
                      child: Icon(
                        subject.icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (subject.code.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(subject.colorValue)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    subject.code.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(subject.colorValue),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${subject.credits} tín chỉ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subject.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action Popup Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (val) {
                        if (val == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubjectFormScreen(subject: subject),
                            ),
                          );
                        } else if (val == 'delete') {
                          _handleDeleteSubject(context, subject);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Xóa môn học',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Details footer
                Row(
                  children: [
                    if (subject.lecturer.isNotEmpty) ...[
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subject.lecturer,
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
                    ] else ...[
                      const Expanded(
                        child: Text(
                          'Chưa cập nhật GV',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.alarm, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Mục tiêu: ${subject.weeklyTargetHours.toStringAsFixed(1)}h/tuần',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (subject.semester.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        subject.semester,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                Icons.menu_book,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy môn học nào',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy thử thay đổi từ khóa tìm kiếm, chọn học kỳ khác hoặc thêm môn học mới vào hệ thống.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Thêm môn học ngay',
              icon: Icons.add,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubjectFormScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
