import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/database/database_helper.dart';
import '../core/utils/gpa_helper.dart';
import '../models/grade_entry.dart';
import '../models/subject.dart';
import '../providers/study_provider.dart';

/// Modal / BottomSheet xem Bảng điểm chi tiết & Mô phỏng tính GPA
class GpaCalculatorSheet extends StatefulWidget {
  final List<Subject> initialSubjects;
  final String currentSemester;

  const GpaCalculatorSheet({
    super.key,
    required this.initialSubjects,
    required this.currentSemester,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Subject> subjects,
    required String currentSemester,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GpaCalculatorSheet(
        initialSubjects: subjects,
        currentSemester: currentSemester,
      ),
    );
  }

  @override
  State<GpaCalculatorSheet> createState() => _GpaCalculatorSheetState();
}

class _GpaCalculatorSheetState extends State<GpaCalculatorSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedSemester;

  // Dữ liệu mô phỏng điểm (What-If simulation)
  // subjectId -> simulatedScore10 (0.0 .. 10.0)
  final Map<String, double> _simulatedScores10 = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedSemester = widget.currentSemester;
    _initSimulatedScores();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initSimulatedScores() {
    final study = context.read<StudyProvider>();
    for (final s in study.subjects) {
      final avg = study.getSubjectWeightedAverage(s.id);
      _simulatedScores10[s.id] = avg ?? 7.0; // Mặc định 7.0 nếu chưa có điểm
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final study = context.watch<StudyProvider>();

    // Danh sách học kỳ
    final semestersSet = <String>{'Tất cả'};
    for (final s in study.subjects) {
      if (s.semester.trim().isNotEmpty) {
        semestersSet.add(s.semester.trim());
      }
    }
    final semesters = semestersSet.toList();

    // Lọc môn theo học kỳ đã chọn trong modal
    final subjects = study.subjects.where((s) {
      if (_selectedSemester == 'Tất cả') return true;
      return s.semester == _selectedSemester;
    }).toList();

    // 1. Tính GPA thực tế hiện tại
    double currentWeightedSum4 = 0.0;
    double currentWeightedSum10 = 0.0;
    int currentGradedCredits = 0;
    int totalCredits = 0;

    for (final s in subjects) {
      totalCredits += s.credits;
      final avg10 = study.getSubjectWeightedAverage(s.id);
      if (avg10 != null && s.credits > 0) {
        final score4 = GpaHelper.score10To4(avg10);
        currentWeightedSum4 += score4 * s.credits;
        currentWeightedSum10 += avg10 * s.credits;
        currentGradedCredits += s.credits;
      }
    }

    final double? currentGpa4 =
        currentGradedCredits > 0 ? (currentWeightedSum4 / currentGradedCredits) : null;
    final double? currentGpa10 =
        currentGradedCredits > 0 ? (currentWeightedSum10 / currentGradedCredits) : null;

    // 2. Tính GPA mô phỏng (What-If)
    double simWeightedSum4 = 0.0;
    double simWeightedSum10 = 0.0;
    int simTotalCredits = 0;

    for (final s in subjects) {
      if (s.credits <= 0) continue;
      simTotalCredits += s.credits;
      final sim10 = _simulatedScores10[s.id] ?? 7.0;
      final sim4 = GpaHelper.score10To4(sim10);
      simWeightedSum4 += sim4 * s.credits;
      simWeightedSum10 += sim10 * s.credits;
    }

    final double simGpa4 =
        simTotalCredits > 0 ? (simWeightedSum4 / simTotalCredits) : 0.0;
    final double simGpa10 =
        simTotalCredits > 0 ? (simWeightedSum10 / simTotalCredits) : 0.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Thanh kéo drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Tiêu đề & Học kỳ dropdown
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calculate, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bảng Điểm & Tính GPA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _selectedSemester == 'Tất cả'
                                ? 'Tất cả học kỳ'
                                : _selectedSemester,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // Dropdown chọn học kỳ
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: semesters.contains(_selectedSemester)
                            ? _selectedSemester
                            : semesters.first,
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        items: semesters.map((sem) {
                          return DropdownMenuItem<String>(
                            value: sem,
                            child: Text(sem),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSemester = val);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Hero Banner tóm tắt GPA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: _buildGpaHeroCard(
                  currentGpa4: currentGpa4,
                  currentGpa10: currentGpa10,
                  gradedCredits: currentGradedCredits,
                  totalCredits: totalCredits,
                  isDark: isDark,
                ),
              ),

              // TabBar: "Bảng điểm chi tiết" vs "Mô phỏng GPA (What-If)"
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.list_alt, size: 18),
                      text: 'Bảng Điểm Môn Học',
                    ),
                    Tab(
                      icon: Icon(Icons.auto_graph, size: 18),
                      text: 'Mô Phỏng GPA (What-If)',
                    ),
                  ],
                ),
              ),

              // Nội dung Tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Danh sách chi tiết môn học & đầu điểm
                    _buildGradeDetailsTab(
                      context,
                      subjects,
                      study,
                      scrollController,
                      isDark,
                    ),

                    // Tab 2: Mô phỏng GPA
                    _buildGpaSimulatorTab(
                      context,
                      subjects,
                      study,
                      currentGpa4: currentGpa4 ?? 0.0,
                      simGpa4: simGpa4,
                      simGpa10: simGpa10,
                      scrollController: scrollController,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // HERO BANNER GPA
  // ==========================================
  Widget _buildGpaHeroCard({
    required double? currentGpa4,
    required double? currentGpa10,
    required int gradedCredits,
    required int totalCredits,
    required bool isDark,
  }) {
    final hasGrades = currentGpa4 != null;
    final classification = hasGrades ? GpaHelper.getGpaClassification(currentGpa4) : '--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                _selectedSemester == 'Tất cả'
                    ? '🎯 GPA Toàn Khóa'
                    : '🎯 GPA ${_selectedSemester.replaceAll('Học kỳ ', 'HK')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (hasGrades)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    classification,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // GPA Hệ 4
              Column(
                children: [
                  Text(
                    hasGrades ? currentGpa4.toStringAsFixed(2) : '--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Thang điểm 4.0',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              // Điểm Hệ 10
              Column(
                children: [
                  Text(
                    hasGrades ? currentGpa10!.toStringAsFixed(1) : '--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Thang điểm 10',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              // Tín chỉ
              Column(
                children: [
                  Text(
                    '$gradedCredits / $totalCredits',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tín chỉ có điểm',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: BẢNG ĐIỂM CHI TIẾT
  // ==========================================
  Widget _buildGradeDetailsTab(
    BuildContext context,
    List<Subject> subjects,
    StudyProvider study,
    ScrollController scrollController,
    bool isDark,
  ) {
    if (subjects.isEmpty) {
      return const Center(
        child: Text(
          'Không có môn học nào trong học kỳ này',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final subjectGrades = study.grades
            .where((g) => g.subjectId == subject.id)
            .toList();
        final avg10 = study.getSubjectWeightedAverage(subject.id);
        final hasGrade = avg10 != null;
        final score4 = hasGrade ? GpaHelper.score10To4(avg10) : null;
        final letter = hasGrade ? GpaHelper.scoreToLetter(avg10) : null;
        final letterColor = letter != null ? GpaHelper.getLetterColor(letter) : Colors.grey;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(subject.colorValue).withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(subject.colorValue).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ExpansionTile(
            shape: Border.all(color: Colors.transparent),
            collapsedShape: Border.all(color: Colors.transparent),
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: Color(subject.colorValue),
              child: Icon(subject.icon, color: Colors.white, size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    subject.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (hasGrade) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: letterColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: letterColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${score4!.toStringAsFixed(1)} ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: letterColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: letterColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            letter!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nhập điểm', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showAddOrEditGradeDialog(context, subject),
                  ),
                ],
              ],
            ),
            subtitle: Row(
              children: [
                Text(
                  '${subject.credits} tín chỉ',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (subject.code.isNotEmpty) ...[
                  const Text(' • ', style: TextStyle(color: Colors.grey)),
                  Text(
                    subject.code,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                if (hasGrade) ...[
                  const Text(' • ', style: TextStyle(color: Colors.grey)),
                  Text(
                    'Hệ 10: ${avg10.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            children: [
              // Danh sách đầu điểm thành phần
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Đầu điểm thành phần:',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text('Thêm điểm', style: TextStyle(fontSize: 12)),
                          onPressed: () => _showAddOrEditGradeDialog(context, subject),
                        ),
                      ],
                    ),
                    if (subjectGrades.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Chưa có đầu điểm nào. Hãy bấm "Thêm điểm" để cập nhật!',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      )
                    else
                      ...subjectGrades.map((g) {
                        return Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : Colors.grey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  g.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${g.score} / ${g.maxScore}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${g.weight.toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                onPressed: () => _showAddOrEditGradeDialog(
                                  context,
                                  subject,
                                  existingGrade: g,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                onPressed: () => _confirmDeleteGrade(context, g),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 2: MÔ PHỎNG TĂNG GIẢM GPA (WHAT-IF)
  // ==========================================
  Widget _buildGpaSimulatorTab(
    BuildContext context,
    List<Subject> subjects,
    StudyProvider study, {
    required double currentGpa4,
    required double simGpa4,
    required double simGpa10,
    required ScrollController scrollController,
    required bool isDark,
  }) {
    if (subjects.isEmpty) {
      return const Center(
        child: Text(
          'Không có môn học nào để mô phỏng',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final diff = simGpa4 - currentGpa4;
    final isIncrease = diff > 0.005;
    final isDecrease = diff < -0.005;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        // Card kết quả mô phỏng so sánh
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isIncrease
                  ? AppColors.success
                  : (isDecrease ? AppColors.error : AppColors.primary),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'GPA Dự Kiến Sau Mô Phỏng:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  if (isIncrease || isDecrease)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isIncrease ? AppColors.success : AppColors.error)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isIncrease ? Icons.trending_up : Icons.trending_down,
                            size: 16,
                            color: isIncrease ? AppColors.success : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${isIncrease ? '+' : ''}${diff.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isIncrease ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        currentGpa4 > 0 ? currentGpa4.toStringAsFixed(2) : '--',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text('Hiện tại', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.grey),
                  Column(
                    children: [
                      Text(
                        simGpa4.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isIncrease
                              ? AppColors.success
                              : (isDecrease ? AppColors.error : AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dự kiến (${GpaHelper.getGpaClassification(simGpa4)})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isIncrease
                              ? AppColors.success
                              : (isDecrease ? AppColors.error : AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 35, color: Colors.grey.withValues(alpha: 0.3)),
                  Column(
                    children: [
                      Text(
                        simGpa10.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text('Hệ 10 dự kiến', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kéo slider để thử nghiệm điểm môn học:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                setState(() => _initSimulatedScores());
              },
              child: const Text('Đặt lại ban đầu', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Danh sách môn học với Slider mô phỏng
        ...subjects.map((s) {
          final simScore = _simulatedScores10[s.id] ?? 7.0;
          final letter = GpaHelper.scoreToLetter(simScore);
          final letterColor = GpaHelper.getLetterColor(letter);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Color(s.colorValue).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(s.colorValue),
                      child: Icon(s.icon, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${s.credits} tín chỉ',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: letterColor.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: letterColor),
                      ),
                      child: Text(
                        '${simScore.toStringAsFixed(1)} [$letter]',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: letterColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: simScore,
                  min: 0.0,
                  max: 10.0,
                  divisions: 100,
                  activeColor: letterColor,
                  label: simScore.toStringAsFixed(1),
                  onChanged: (val) {
                    setState(() {
                      _simulatedScores10[s.id] = double.parse(val.toStringAsFixed(1));
                    });
                  },
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),
        // Nút lưu điểm mô phỏng thành điểm thực tế nếu muốn
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.save_as_outlined),
          label: const Text('Lưu các điểm dự kiến này làm điểm chính thức'),
          onPressed: () => _applySimulatedScoresToGrades(context, subjects),
        ),
      ],
    );
  }

  // ==========================================
  // THAO TÁC THÊM / SỬA / XÓA ĐẦU ĐIỂM
  // ==========================================
  Future<void> _showAddOrEditGradeDialog(
    BuildContext context,
    Subject subject, {
    GradeEntry? existingGrade,
  }) async {
    final titleController = TextEditingController(
      text: existingGrade?.title ?? (existingGrade == null ? 'Điểm tổng kết' : ''),
    );
    final scoreController = TextEditingController(
      text: existingGrade != null ? existingGrade.score.toString() : '',
    );
    final maxScoreController = TextEditingController(
      text: existingGrade != null ? existingGrade.maxScore.toString() : '10',
    );
    final weightController = TextEditingController(
      text: existingGrade != null ? existingGrade.weight.toString() : '100',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(
              existingGrade == null ? Icons.add_chart : Icons.edit_note,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${existingGrade == null ? 'Nhập điểm' : 'Sửa điểm'} - ${subject.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên đầu điểm',
                  hintText: 'Ví dụ: Điểm tổng kết, Giữa kỳ, Cuối kỳ...',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: scoreController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Điểm đạt được',
                  hintText: 'Ví dụ: 8.5',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: maxScoreController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Thang điểm',
                        hintText: '10',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Trọng số (%)',
                        hintText: '100',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final title = titleController.text.trim();
              final score = double.tryParse(scoreController.text.trim());
              final maxScore = double.tryParse(maxScoreController.text.trim()) ?? 10.0;
              final weight = double.tryParse(weightController.text.trim()) ?? 100.0;

              if (title.isEmpty || score == null || score < 0 || score > maxScore) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập điểm hợp lệ (từ 0 đến thang điểm tối đa)!'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final study = context.read<StudyProvider>();
              final grade = GradeEntry(
                id: existingGrade?.id ?? 'grade_${DateTime.now().microsecondsSinceEpoch}',
                subjectId: subject.id,
                title: title,
                score: score,
                maxScore: maxScore,
                weight: weight,
                createdAt: existingGrade?.createdAt ?? DateTime.now(),
              );

              if (existingGrade == null) {
                await DatabaseHelper.instance.insertGrade(grade);
                await study.addGrade(grade);
              } else {
                await DatabaseHelper.instance.updateGrade(grade);
                await study.updateGrade(grade);
              }

              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              setState(() {});
            },
            child: Text(existingGrade == null ? 'Lưu điểm' : 'Cập nhật'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteGrade(BuildContext context, GradeEntry grade) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa đầu điểm?'),
        content: Text('Bạn có chắc chắn muốn xóa "${grade.title}" không?'),
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
      final study = context.read<StudyProvider>();
      await DatabaseHelper.instance.deleteGrade(grade.id);
      await study.deleteGrade(grade.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _applySimulatedScoresToGrades(
    BuildContext context,
    List<Subject> subjects,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lưu điểm mô phỏng?'),
        content: const Text(
          'Hệ thống sẽ cập nhật điểm tổng kết của các môn học này theo giá trị bạn vừa điều chỉnh trong thanh slider.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final study = context.read<StudyProvider>();
      for (final s in subjects) {
        final simScore = _simulatedScores10[s.id];
        if (simScore == null) continue;

        // Tìm điểm tổng kết hiện tại nếu có
        final existing = study.grades.where((g) => g.subjectId == s.id).toList();
        if (existing.isNotEmpty) {
          final first = existing.first;
          final updated = GradeEntry(
            id: first.id,
            subjectId: s.id,
            title: first.title,
            score: simScore,
            maxScore: 10.0,
            weight: first.weight,
            createdAt: DateTime.now(),
          );
          await DatabaseHelper.instance.updateGrade(updated);
          await study.updateGrade(updated);
        } else {
          final newGrade = GradeEntry(
            id: 'grade_${DateTime.now().microsecondsSinceEpoch}',
            subjectId: s.id,
            title: 'Điểm tổng kết',
            score: simScore,
            maxScore: 10.0,
            weight: 100.0,
            createdAt: DateTime.now(),
          );
          await DatabaseHelper.instance.insertGrade(newGrade);
          await study.addGrade(newGrade);
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật điểm chính thức thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      setState(() {});
    }
  }
}
