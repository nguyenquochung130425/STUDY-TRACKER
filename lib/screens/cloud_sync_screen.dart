import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/widgets/app_button.dart';
import '../core/widgets/app_text_field.dart';
import '../providers/cloud_sync_provider.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _isSubmitting = false;
  String? _authError;

  Future<void> _submitEmail(CloudSyncProvider cloud) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _authError = null;
    });

    try {
      if (_isRegistering) {
        await cloud.registerWithEmail(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        await cloud.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _authError = _messageFor(error.code));
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _authError = error.message ?? error.code);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signInWithGoogle(CloudSyncProvider cloud) async {
    setState(() {
      _isSubmitting = true;
      _authError = null;
    });

    try {
      await cloud.signInWithGoogle();
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _authError = _messageFor(error.code));
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _authError = error.message ?? error.code);
    } on UnsupportedError catch (error) {
      if (mounted) setState(() => _authError = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signOut(CloudSyncProvider cloud) async {
    try {
      await cloud.signOut();
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _authError = _messageFor(error.code));
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _authError = error.message ?? error.code);
    }
  }

  Future<void> _sendPasswordReset(CloudSyncProvider cloud) async {
    if (!(_emailFieldKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _authError = null;
    });

    try {
      await cloud.sendPasswordResetEmail(_emailController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã gửi liên kết đặt lại mật khẩu đến email của bạn.',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _authError = _messageFor(error.code));
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _authError = error.message ?? error.code);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resendVerification(CloudSyncProvider cloud) async {
    setState(() {
      _isSubmitting = true;
      _authError = null;
    });
    try {
      await cloud.resendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lại email xác minh.')),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _authError = _messageFor(error.code));
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _authError = error.message ?? error.code);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _refreshVerification(CloudSyncProvider cloud) async {
    setState(() {
      _isSubmitting = true;
      _authError = null;
    });
    try {
      await cloud.refreshUser();
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _authError = _messageFor(error.code));
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _authError = error.message ?? error.code);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _messageFor(String code) => switch (code) {
    'email-already-in-use' => 'Email này đã được đăng ký.',
    'invalid-email' => 'Địa chỉ email không hợp lệ.',
    'weak-password' => 'Mật khẩu cần có ít nhất 6 ký tự.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email hoặc mật khẩu không chính xác.',
    'network-request-failed' => 'Không thể kết nối mạng. Hãy thử lại.',
    'popup-closed-by-user' => 'Cửa sổ đăng nhập Google đã bị đóng.',
    'too-many-requests' => 'Bạn thao tác quá nhanh. Hãy thử lại sau.',
    'no-current-user' => 'Không tìm thấy tài khoản đang đăng nhập.',
    _ => 'Không thể đăng nhập ($code). Hãy thử lại.',
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cloud = context.watch<CloudSyncProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản & đồng bộ')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        cloud.isConfigured
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        color: cloud.isConfigured
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cloud.isConfigured
                              ? 'Firebase đã được cấu hình'
                              : 'Đang dùng dữ liệu cục bộ',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cloud.configurationError ??
                        (cloud.isConfigured
                            ? 'Dữ liệu được lưu trên thiết bị. Khi đăng nhập, '
                                  'môn học, phiên học, nhiệm vụ và điểm sẽ được '
                                  'đồng bộ với tài khoản Firebase.'
                            : 'Cấu hình Firebase để bật đăng nhập và đồng bộ. '
                                  'Dữ liệu hiện tại vẫn được lưu trên thiết bị.'),
                  ),
                  if (!cloud.isConfigured) ...[
                    const SizedBox(height: 12),
                    const SelectableText(
                      'Cần truyền FIREBASE_CONFIGURED=true cùng các dart-define '
                      'FIREBASE_API_KEY, FIREBASE_PROJECT_ID, '
                      'FIREBASE_MESSAGING_SENDER_ID và app ID của nền tảng '
                      'đang chạy. Xem README để biết đầy đủ tên cấu hình.',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (cloud.isConfigured && cloud.user != null) ...[
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(cloud.user!.email ?? 'Tài khoản Google'),
                subtitle: Text(
                  cloud.isEmailVerified
                      ? 'Đã đăng nhập'
                      : 'Đã đăng nhập · Email chưa được xác minh',
                ),
                trailing: IconButton(
                  tooltip: 'Đăng xuất',
                  onPressed: () => _signOut(cloud),
                  icon: const Icon(Icons.logout),
                ),
              ),
            ),
            if (!cloud.isEmailVerified) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Xác minh email để bật đồng bộ dữ liệu.'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _resendVerification(cloud),
                            child: const Text('Gửi lại email'),
                          ),
                          TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _refreshVerification(cloud),
                            child: const Text('Tôi đã xác minh'),
                          ),
                        ],
                      ),
                      if (_authError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _authError!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: cloud.isSyncing || !cloud.isEmailVerified
                  ? null
                  : cloud.syncNow,
              icon: cloud.isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(cloud.isSyncing ? 'Đang đồng bộ...' : 'Đồng bộ ngay'),
            ),
            if (cloud.syncError != null && cloud.isEmailVerified) ...[
              const SizedBox(height: 12),
              Text(
                'Đồng bộ thất bại: ${cloud.syncError}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ] else if (cloud.isConfigured) ...[
            Text(
              'Đăng nhập để đồng bộ dữ liệu của bạn trên các thiết bị.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    key: _emailFieldKey,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(email)) {
                        return 'Nhập địa chỉ email hợp lệ.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    validator: (value) {
                      if (_isRegistering && (value?.length ?? 0) < 8) {
                        return 'Mật khẩu cần có ít nhất 8 ký tự.';
                      }
                      if (!_isRegistering && (value?.isEmpty ?? true)) {
                        return 'Nhập mật khẩu.';
                      }
                      return null;
                    },
                  ),
                  if (_authError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _authError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppButton(
                    fullWidth: true,
                    loading: _isSubmitting,
                    icon: Icon(
                      _isRegistering ? Icons.person_add_alt_1 : Icons.login,
                    ),
                    label: _isRegistering ? 'Tạo tài khoản' : 'Đăng nhập',
                    onPressed: _isSubmitting ? null : () => _submitEmail(cloud),
                  ),
                  if (!_isRegistering)
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _sendPasswordReset(cloud),
                      child: const Text('Quên mật khẩu?'),
                    ),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                            _isRegistering = !_isRegistering;
                            _authError = null;
                          }),
                    child: Text(
                      _isRegistering
                          ? 'Đã có tài khoản? Đăng nhập'
                          : 'Chưa có tài khoản? Đăng ký',
                    ),
                  ),
                  if (cloud.canUseGoogleSignIn) ...[
                    const Divider(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _signInWithGoogle(cloud),
                        icon: const Icon(Icons.g_mobiledata),
                        label: const Text('Tiếp tục với Google'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
