import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_lock_provider.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<AppLockProvider>().initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      context.read<AppLockProvider>().lock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLockProvider>(
      builder: (context, appLock, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (!appLock.initialized)
              const ColoredBox(
                color: Colors.black,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (appLock.initializationError != null)
              _AppLockStorageErrorScreen(
                error: appLock.initializationError!,
                onRetry: appLock.retryInitialize,
              )
            else if (appLock.isLocked)
              _PinUnlockScreen(appLock: appLock),
          ],
        );
      },
    );
  }
}

class _AppLockStorageErrorScreen extends StatelessWidget {
  const _AppLockStorageErrorScreen({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              const Text('Không thể tải cài đặt khóa ứng dụng.'),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinUnlockScreen extends StatefulWidget {
  const _PinUnlockScreen({required this.appLock});

  final AppLockProvider appLock;

  @override
  State<_PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<_PinUnlockScreen> {
  final _pinController = TextEditingController();
  bool _isChecking = false;
  String? _error;

  Future<void> _unlock() async {
    final pin = _pinController.text;
    if (!AppLockProvider.isValidPin(pin)) {
      setState(() => _error = 'Nhập đủ 6 chữ số.');
      return;
    }
    setState(() {
      _isChecking = true;
      _error = null;
    });
    try {
      final unlocked = await widget.appLock.verifyPin(pin);
      if (!unlocked && mounted) {
        _pinController.clear();
        setState(() {
          _error = widget.appLock.isTemporarilyLocked
              ? 'Nhập sai quá nhiều lần. Hãy thử lại sau '
                    '${widget.appLock.lockoutRemaining.inSeconds + 1} giây.'
              : 'PIN không chính xác. Còn '
                    '${widget.appLock.attemptsRemaining} lần thử trước khi tạm khóa.';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Không thể xác minh PIN: $error');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 52,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ứng dụng đã khóa',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Nhập mã PIN 6 chữ số để tiếp tục.'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _pinController,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _unlock(),
                    decoration: const InputDecoration(
                      labelText: 'Mã PIN',
                      counterText: '',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isChecking ? null : _unlock,
                      child: _isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Mở khóa'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
