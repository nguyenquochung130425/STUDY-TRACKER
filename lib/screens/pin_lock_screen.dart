import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../providers/security_provider.dart';

enum PinLockMode { unlock, setup }

/// Màn hình khóa và thiết lập mã PIN bảo mật
class PinLockScreen extends StatefulWidget {
  final PinLockMode mode;
  final VoidCallback? onUnlocked;

  const PinLockScreen({
    super.key,
    this.mode = PinLockMode.unlock,
    this.onUnlocked,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredPin = '';
  String _firstEnteredPin = '';
  bool _isConfirming = false;
  String? _errorMessage;
  bool _isProcessing = false;

  void _onDigitPressed(String digit) {
    if (_isProcessing || _enteredPin.length >= AppConstants.pinLength) return;

    setState(() {
      _errorMessage = null;
      _enteredPin += digit;
    });

    if (_enteredPin.length == AppConstants.pinLength) {
      _handlePinCompleted();
    }
  }

  void _onBackspacePressed() {
    if (_isProcessing || _enteredPin.isEmpty) return;
    setState(() {
      _errorMessage = null;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _handlePinCompleted() async {
    setState(() {
      _isProcessing = true;
    });

    final security = context.read<SecurityProvider>();

    if (widget.mode == PinLockMode.unlock) {
      // Chế độ mở khóa
      final isValid = await security.verifyPin(_enteredPin);
      if (mounted) {
        if (isValid) {
          widget.onUnlocked?.call();
        } else {
          setState(() {
            _errorMessage = 'Mã PIN không đúng. Vui lòng thử lại!';
            _enteredPin = '';
            _isProcessing = false;
          });
        }
      }
    } else {
      // Chế độ tạo mới / Đổi PIN
      if (!_isConfirming) {
        // Lưu mã nhập lần 1 và chuyển sang xác nhận
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _firstEnteredPin = _enteredPin;
            _enteredPin = '';
            _isConfirming = true;
            _isProcessing = false;
          });
        }
      } else {
        // Kiểm tra khớp
        if (_enteredPin == _firstEnteredPin) {
          await security.setupNewPin(_enteredPin);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã thiết lập mã PIN bảo mật thành công!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(true);
          }
        } else {
          setState(() {
            _errorMessage = 'Mã PIN xác nhận không khớp. Hãy thử lại từ đầu!';
            _enteredPin = '';
            _firstEnteredPin = '';
            _isConfirming = false;
            _isProcessing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String title;
    String subtitle;

    if (widget.mode == PinLockMode.unlock) {
      title = 'Khóa ứng dụng';
      subtitle = 'Nhập mã PIN gồm ${AppConstants.pinLength} số để mở khóa';
    } else {
      if (_isConfirming) {
        title = 'Xác nhận mã PIN';
        subtitle = 'Nhập lại mã PIN vừa tạo một lần nữa';
      } else {
        title = 'Thiết lập mã PIN';
        subtitle = 'Tạo mã PIN gồm ${AppConstants.pinLength} số để bảo vệ dữ liệu';
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: widget.mode == PinLockMode.setup
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Biểu tượng bảo mật
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryLight.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.mode == PinLockMode.unlock ? Icons.lock_outline : Icons.security,
                size: 42,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Tiêu đề
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Mô tả
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Dãy chấm hiển thị PIN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                AppConstants.pinLength,
                (index) => _buildPinDot(index < _enteredPin.length, isDark),
              ),
            ),
            const SizedBox(height: 20),

            // Thông báo lỗi nếu có
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              const SizedBox(height: 18),

            const Spacer(flex: 1),

            // Bàn phím số Numpad
            _buildNumpad(isDark),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDot(bool isFilled, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled
            ? (isDark ? AppColors.primaryLight : AppColors.primary)
            : Colors.transparent,
        border: Border.all(
          color: isFilled
              ? (isDark ? AppColors.primaryLight : AppColors.primary)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildNumpad(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['1', '2', '3'].map((d) => _buildNumpadButton(d, isDark)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['4', '5', '6'].map((d) => _buildNumpadButton(d, isDark)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['7', '8', '9'].map((d) => _buildNumpadButton(d, isDark)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72, height: 72),
              _buildNumpadButton('0', isDark),
              _buildBackspaceButton(isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(String digit, bool isDark) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onDigitPressed(digit),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(bool isDark) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _onBackspacePressed,
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 24,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
