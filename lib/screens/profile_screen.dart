import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/theme_provider.dart';
import '../core/widgets/custom_button.dart';
import '../core/widgets/custom_dialog.dart';
import '../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';
import '../providers/security_provider.dart';
import 'pin_lock_screen.dart';

/// Màn hình Quản lý hồ sơ cá nhân và Cài đặt bảo mật (Profile & Security)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: user.displayName);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Chỉnh sửa thông tin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameController,
                label: 'Tên hiển thị',
                hintText: 'Nhập tên mới',
                prefixIcon: Icons.person_outline,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  await auth.updateProfile(displayName: newName);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _handlePinToggle(BuildContext context, bool value) async {
    final security = context.read<SecurityProvider>();

    if (value) {
      if (!security.hasPinSet) {
        // Chưa có mã PIN -> Mở màn hình thiết lập PIN
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => const PinLockScreen(mode: PinLockMode.setup),
          ),
        );
        if (result != true) {
          // Người dùng hủy thiết lập
          return;
        }
      } else {
        await security.setPinEnabled(true);
      }
    } else {
      // Xác nhận tắt mã PIN
      final confirmed = await CustomDialog.showConfirm(
        context: context,
        title: 'Tắt mã PIN bảo mật?',
        message: 'Ứng dụng sẽ không còn yêu cầu mã PIN khi mở lại hoặc chuyển sang chạy ngầm.',
        confirmText: 'Tắt bảo mật',
        cancelText: 'Giữ lại',
        isDanger: true,
        icon: Icons.lock_open,
      );

      if (confirmed) {
        await security.setPinEnabled(false);
      }
    }
  }

  void _changePin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PinLockScreen(mode: PinLockMode.setup),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await CustomDialog.showConfirm(
      context: context,
      title: 'Đăng xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
      confirmText: 'Đăng xuất',
      cancelText: 'Ở lại',
      isDanger: true,
      icon: Icons.logout,
    );

    if (confirmed && context.mounted) {
      final auth = context.read<AuthProvider>();
      await auth.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final security = context.watch<SecurityProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.currentUser;

    final createdAtFormatted = user != null
        ? DateFormat('dd/MM/yyyy').format(user.createdAt)
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ & Bảo mật'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Header Profile Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
                    child: Text(
                      user != null && user.displayName.isNotEmpty
                          ? user.displayName.substring(0, 1).toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Chưa đăng nhập',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Tham gia từ $createdAtFormatted',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showEditProfileDialog(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Security & App Lock
          _buildSectionHeader('Bảo mật & Khóa ứng dụng', isDark),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                  ),
                  title: const Text('Khóa ứng dụng bằng mã PIN', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    security.isPinEnabled
                        ? 'Đang bật bảo vệ mã PIN gồm 4 số'
                        : 'Bảo vệ dữ liệu học tập khỏi người lạ',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  value: security.isPinEnabled,
                  onChanged: (val) => _handlePinToggle(context, val),
                ),
                if (security.hasPinSet) ...[
                  const Divider(height: 1, indent: 64),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.password, color: AppColors.secondary, size: 20),
                    ),
                    title: const Text('Đổi mã PIN', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Cập nhật lại mã số bảo mật mới',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _changePin(context),
                  ),
                ],
                const Divider(height: 1, indent: 64),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phonelink_lock, color: AppColors.warning, size: 20),
                  ),
                  title: const Text('Tự động khóa khi chạy ngầm', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Khóa màn hình ngay khi ứng dụng bị ẩn xuống background',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  value: security.autoLockOnBackground,
                  onChanged: security.isPinEnabled
                      ? (val) => security.setAutoLockOnBackground(val)
                      : null,
                ),
                if (security.isPinEnabled) ...[
                  const Divider(height: 1, indent: 64),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_clock, color: AppColors.error, size: 20),
                    ),
                    title: const Text('Khóa ứng dụng ngay bây giờ', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Thử nghiệm kích hoạt trạng thái khóa tức thời',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    onTap: () => security.lockApp(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Theme & Appearance
          _buildSectionHeader('Giao diện & Chủ đề', isDark),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto, size: 18),
                    label: Text('Hệ thống', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode, size: 18),
                    label: Text('Sáng', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode, size: 18),
                    label: Text('Tối', style: TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {themeProvider.themeMode},
                onSelectionChanged: (newSelection) {
                  themeProvider.setThemeMode(newSelection.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Logout Button
          CustomButton(
            text: 'Đăng xuất tài khoản',
            variant: ButtonVariant.danger,
            icon: Icons.logout,
            onPressed: () => _handleLogout(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.primaryLight : AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
