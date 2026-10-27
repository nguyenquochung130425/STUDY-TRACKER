import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/widgets/custom_button.dart';
import '../core/widgets/custom_text_field.dart';
import '../models/subject.dart';
import '../providers/study_provider.dart';

class SubjectFormScreen extends StatefulWidget {
  final Subject? subject;

  const SubjectFormScreen({super.key, this.subject});

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _creditsController;
  late TextEditingController _lecturerController;
  late TextEditingController _semesterController;
  late TextEditingController _targetHoursController;

  late int _selectedColor;
  late int _selectedIconCode;
  bool _isLoading = false;

  final List<int> _colors = const [
    0xFF4F46E5, // Indigo Primary
    0xFF0D9488, // Teal Secondary
    0xFF2563EB, // Blue
    0xFF10B981, // Emerald Green
    0xFFE11D48, // Rose Red
    0xFFD97706, // Amber
    0xFF7C3AED, // Violet
    0xFF0891B2, // Cyan
    0xFFEA580C, // Orange
    0xFF64748B, // Slate
  ];

  final List<Map<String, dynamic>> _icons = const [
    {'icon': Icons.menu_book, 'code': 0xe120, 'name': 'Sách'},
    {'icon': Icons.calculate, 'code': 0xe158, 'name': 'Toán học'},
    {'icon': Icons.code, 'code': 0xe197, 'name': 'Lập trình'},
    {'icon': Icons.language, 'code': 0xe357, 'name': 'Ngoại ngữ'},
    {'icon': Icons.science, 'code': 0xe556, 'name': 'Khoa học'},
    {'icon': Icons.palette, 'code': 0xe463, 'name': 'Nghệ thuật'},
    {'icon': Icons.music_note, 'code': 0xe415, 'name': 'Âm nhạc'},
    {'icon': Icons.sports_basketball, 'code': 0xe5ef, 'name': 'Thể chất'},
    {'icon': Icons.psychology, 'code': 0xe4e2, 'name': 'Tâm lý / Triết'},
    {'icon': Icons.history_edu, 'code': 0xe306, 'name': 'Lịch sử / Xã hội'},
  ];

  final List<String> _suggestedSemesters = [
    'Học kỳ 1 2026-2027',
    'Học kỳ 2 2026-2027',
    'Học kỳ Hè 2026-2027',
    'Học kỳ 1 2025-2026',
    'Học kỳ 2 2025-2026',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.subject;
    _nameController = TextEditingController(text: s?.name ?? '');
    _codeController = TextEditingController(text: s?.code ?? '');
    _creditsController = TextEditingController(text: s?.credits.toString() ?? '3');
    _lecturerController = TextEditingController(text: s?.lecturer ?? '');
    _semesterController = TextEditingController(
      text: s?.semester ?? 'Học kỳ 1 2026-2027',
    );
    _targetHoursController = TextEditingController(
      text: s != null ? s.weeklyTargetHours.toStringAsFixed(1) : '5.0',
    );
    _selectedColor = s?.colorValue ?? _colors[0];
    _selectedIconCode = s?.iconCodePoint ?? 0xe120;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _creditsController.dispose();
    _lecturerController.dispose();
    _semesterController.dispose();
    _targetHoursController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.subject != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final credits = int.tryParse(_creditsController.text.trim()) ?? 3;
    final lecturer = _lecturerController.text.trim();
    final semester = _semesterController.text.trim();
    final targetHours = double.tryParse(_targetHoursController.text.trim()) ?? 5.0;

    final studyProvider = context.read<StudyProvider>();

    try {
      if (_isEditing) {
        final updated = widget.subject!.copyWith(
          name: name,
          code: code,
          credits: credits,
          lecturer: lecturer,
          semester: semester,
          colorValue: _selectedColor,
          iconCodePoint: _selectedIconCode,
          weeklyTargetHours: targetHours,
        );
        await studyProvider.updateSubject(updated);
      } else {
        final newSubject = Subject(
          id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          code: code,
          credits: credits,
          lecturer: lecturer,
          semester: semester,
          colorValue: _selectedColor,
          iconCodePoint: _selectedIconCode,
          weeklyTargetHours: targetHours,
        );
        await studyProvider.addSubject(newSubject);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Đã cập nhật môn học "$name"'
                  : 'Đã thêm môn học "$name"',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa thông tin môn học' : 'Thêm môn học mới'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Preview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(_selectedColor).withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(_selectedColor).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(_selectedColor),
                      child: Icon(
                        _getIconData(_selectedIconCode),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_codeController.text.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(_selectedColor).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _codeController.text.toUpperCase(),
                                style: TextStyle(
                                  color: Color(_selectedColor),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            _nameController.text.isEmpty
                                ? 'Tên môn học'
                                : _nameController.text,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_creditsController.text} tín chỉ • ${_lecturerController.text.isEmpty ? "Chưa có GV" : _lecturerController.text}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Thông tin cơ bản
              _buildSectionHeader('Thông tin môn học', Icons.info_outline),
              const SizedBox(height: 12),

              CustomTextField(
                label: 'Tên môn học',
                hintText: 'Ví dụ: Cấu trúc dữ liệu & Giải thuật',
                controller: _nameController,
                prefixIcon: Icons.menu_book,
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên môn học';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: CustomTextField(
                      label: 'Mã môn học',
                      hintText: 'VD: IT001',
                      controller: _codeController,
                      prefixIcon: Icons.tag,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      label: 'Số tín chỉ',
                      hintText: 'VD: 3',
                      controller: _creditsController,
                      prefixIcon: Icons.school,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Bắt buộc';
                        final num = int.tryParse(val.trim());
                        if (num == null || num <= 0 || num > 30) {
                          return '1 - 30';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Giảng viên phụ trách',
                hintText: 'Ví dụ: TS. Nguyễn Văn A',
                controller: _lecturerController,
                prefixIcon: Icons.person_outline,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),

              // Học kỳ
              CustomTextField(
                label: 'Học kỳ',
                hintText: 'Ví dụ: Học kỳ 1 2026-2027',
                controller: _semesterController,
                prefixIcon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 8),

              // Gợi ý học kỳ nhanh
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _suggestedSemesters.map((sem) {
                  final isSelected = _semesterController.text == sem;
                  return ChoiceChip(
                    label: Text(sem, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _semesterController.text = sem);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Mục tiêu tự học (giờ / tuần)',
                hintText: 'Ví dụ: 5.0',
                controller: _targetHoursController,
                prefixIcon: Icons.hourglass_top,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final hours = double.tryParse(val.trim());
                    if (hours == null || hours < 0 || hours > 100) {
                      return '0 - 100 giờ';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section: Màu sắc & Icon
              _buildSectionHeader('Màu sắc & Biểu tượng', Icons.palette_outlined),
              const SizedBox(height: 12),

              const Text(
                'Màu đại diện:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: _colors.map((c) {
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: isDark ? Colors.white : Colors.black87,
                                width: 3.5,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(c).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              const Text(
                'Biểu tượng môn học:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _icons.map((item) {
                  final code = item['code'] as int;
                  final icon = item['icon'] as IconData;
                  final isSelected = _selectedIconCode == code;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconCode = code),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColor).withValues(alpha: 0.18)
                            : (isDark ? AppColors.darkCard : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Color(_selectedColor)
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 20,
                            color: isSelected ? Color(_selectedColor) : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item['name'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Color(_selectedColor) : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Nút lưu
              CustomButton(
                text: _isEditing ? 'Lưu thay đổi' : 'Tạo môn học',
                icon: _isEditing ? Icons.save : Icons.add_circle_outline,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getIconData(int codePoint) {
    for (final item in _icons) {
      if (item['code'] == codePoint) return item['icon'] as IconData;
    }
    return Icons.menu_book;
  }
}
