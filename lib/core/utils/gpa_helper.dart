import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Tiện ích tính toán quy đổi điểm và GPA theo thang điểm tín chỉ (Quy chế Đào tạo ĐH Việt Nam)
class GpaHelper {
  /// Chuyển đổi điểm thang 10 sang thang 4
  static double score10To4(double score10) {
    if (score10 >= 8.5) return 4.0;
    if (score10 >= 8.0) return 3.5;
    if (score10 >= 7.0) return 3.0;
    if (score10 >= 6.5) return 2.5;
    if (score10 >= 5.5) return 2.0;
    if (score10 >= 5.0) return 1.5;
    if (score10 >= 4.0) return 1.0;
    return 0.0;
  }

  /// Chuyển đổi điểm thang 10 sang điểm chữ (A+, A, B+, B, C+, C, D+, D, F)
  static String scoreToLetter(double score10) {
    if (score10 >= 9.0) return 'A+';
    if (score10 >= 8.5) return 'A';
    if (score10 >= 8.0) return 'B+';
    if (score10 >= 7.0) return 'B';
    if (score10 >= 6.5) return 'C+';
    if (score10 >= 5.5) return 'C';
    if (score10 >= 5.0) return 'D+';
    if (score10 >= 4.0) return 'D';
    return 'F';
  }

  /// Màu sắc phù hợp cho từng mức điểm chữ
  static Color getLetterColor(String letter) {
    switch (letter) {
      case 'A+':
      case 'A':
        return AppColors.success;
      case 'B+':
      case 'B':
        return const Color(0xFF4F46E5); // Indigo
      case 'C+':
      case 'C':
        return AppColors.warning;
      case 'D+':
      case 'D':
        return Colors.orangeAccent;
      case 'F':
      default:
        return AppColors.error;
    }
  }

  /// Phân loại học lực theo GPA hệ 4
  static String getGpaClassification(double gpa4) {
    if (gpa4 >= 3.6) return 'Xuất sắc';
    if (gpa4 >= 3.2) return 'Giỏi';
    if (gpa4 >= 2.5) return 'Khá';
    if (gpa4 >= 2.0) return 'Trung bình';
    return 'Cần cố gắng';
  }
}
