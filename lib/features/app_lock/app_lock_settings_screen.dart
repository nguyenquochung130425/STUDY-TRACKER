import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_lock_provider.dart';

class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key});

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  Future<void> _save(AppLockProvider appLock) async {
    final currentPin = _currentPinController.text;
    final newPin = _newPinController.text;
    final confirmPin = _confirmPinController.text;

    if (appLock.isEnabled && !AppLockProvider.isValidPin(currentPin)) {
      setState(() => _error = 'Nhập PIN hiện tại gồm 6 chữ số.');
      return;
    }
    if (!AppLockProvider.isValidPin(newPin)) {
      setState(() => _error = 'PIN mới phải gồm đúng 6 chữ số.');
      return;
    }
    if (newPin != confirmPin) {
      setState(() => _error = 'Hai mã PIN mới không khớp.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      if (appLock.isEnabled) {
        final changed = await appLock.changePin(
          currentPin: currentPin,
          newPin: newPin,
        );
        if (!changed) {
          setState(
            () => _error = appLock.isTemporarilyLocked
                ? 'PIN đang tạm khóa. Thử lại sau '
                      '${appLock.lockoutRemaining.inSeconds + 1} giây.'
                : 'PIN hiện tại không chính xác. Còn '
                      '${appLock.attemptsRemaining} lần thử.',
          );
          return;
        }
      } else {
        await appLock.enable(newPin);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã lưu cài đặt mã PIN.')));
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Không thể lưu mã PIN: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _disable(AppLockProvider appLock) async {
    final currentPin = _currentPinController.text;
    if (!AppLockProvider.isValidPin(currentPin)) {
      setState(() => _error = 'Nhập PIN hiện tại gồm 6 chữ số.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final disabled = await appLock.disable(currentPin);
      if (!disabled) {
        setState(
          () => _error = appLock.isTemporarilyLocked
              ? 'PIN đang tạm khóa. Thử lại sau '
                    '${appLock.lockoutRemaining.inSeconds + 1} giây.'
              : 'PIN hiện tại không chính xác. Còn '
                    '${appLock.attemptsRemaining} lần thử.',
        );
        return;
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = 'Không thể tắt khóa PIN: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLock = context.watch<AppLockProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Khóa ứng dụng bằng PIN')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Khi ứng dụng chuyển xuống nền, màn hình sẽ tự khóa. PIN được '
            'lưu trong vùng lưu trữ bảo mật của thiết bị và không dùng để '
            'đăng nhập Firebase.',
          ),
          const SizedBox(height: 20),
          if (appLock.isEnabled) ...[
            TextField(
              controller: _currentPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN hiện tại',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _newPinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: appLock.isEnabled ? 'PIN mới' : 'Tạo PIN 6 chữ số',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Xác nhận PIN',
              counterText: '',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSaving ? null : () => _save(appLock),
            child: Text(appLock.isEnabled ? 'Đổi mã PIN' : 'Bật khóa ứng dụng'),
          ),
          if (appLock.isEnabled) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _isSaving ? null : () => _disable(appLock),
              child: const Text('Tắt khóa ứng dụng'),
            ),
          ],
        ],
      ),
    );
  }
}
