import 'package:flutter/material.dart';

class AppDialog {
  const AppDialog._();

  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Đồng ý',
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
