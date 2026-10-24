import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../screens/pin_lock_screen.dart';

/// Widget bọc toàn bộ ứng dụng để theo dõi vòng đời (Lifecycle)
/// Tự động khóa màn hình khi app chuyển sang chạy ngầm (Background)
class AppLockWrapper extends StatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final security = context.read<SecurityProvider>();

    // Khi ứng dụng bị đưa xuống chế độ chạy ngầm (Home, chuyển app khác)
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (security.isPinEnabled && security.autoLockOnBackground) {
        security.lockApp();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();

    if (security.isLoading) {
      return const Material(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Nếu ứng dụng đang bị khóa, hiển thị màn hình mở khóa PIN
    if (security.isLocked) {
      return PinLockScreen(
        mode: PinLockMode.unlock,
        onUnlocked: () {
          security.unlockApp();
        },
      );
    }

    // Nếu không bị khóa, hiển thị nội dung bình thường
    return widget.child;
  }
}
