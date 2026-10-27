import 'package:flutter_test/flutter_test.dart';
import 'package:study_tracker/services/word_parser.dart';

void main() {
  group('WordParser Regex Engine Tests', () {
    test('parseText parses exam metadata (title, code, duration)', () {
      const text = '''
ĐỀ THI: Đề kiểm tra 15 phút Toán
MÃ ĐỀ: TOAN-101
THỜI GIAN: 15 phút

Câu 1: 1 + 1 bằng bao nhiêu?
*A. 2
B. 3
C. 4
D. 5
''';

      final exam = WordParser.parseText(text);
      expect(exam.title, 'Đề kiểm tra 15 phút Toán');
      expect(exam.code, 'TOAN-101');
      expect(exam.timeMinutes, 15);
      expect(exam.questions.length, 1);
      expect(exam.questions.first.content, '1 + 1 bằng bao nhiêu?');
      expect(exam.questions.first.choices.length, 4);
      expect(exam.questions.first.choices.first.label, 'A');
      expect(exam.questions.first.choices.first.isCorrect, isTrue);
    });

    test('parseText detects asterisk for correct choices (*A or A*)', () {
      const text = '''
Câu 1: Thủ đô của Việt Nam là gì?
*A. Hà Nội
B. Huế
C. TP. Hồ Chí Minh
D. Đà Nẵng

Câu 2: Đơn vị tiền tệ của Nhật Bản là gì?
A. USD
B*. Yên
C. Won
D. Euro
''';

      final exam = WordParser.parseText(text);
      expect(exam.questions.length, 2);

      // Câu 1: *A
      final q1 = exam.questions[0];
      final q1Correct = q1.choices.where((c) => c.isCorrect).toList();
      expect(q1Correct.length, 1);
      expect(q1Correct.first.label, 'A');
      expect(q1Correct.first.content, 'Hà Nội');

      // Câu 2: B*
      final q2 = exam.questions[1];
      final q2Correct = q2.choices.where((c) => c.isCorrect).toList();
      expect(q2Correct.length, 1);
      expect(q2Correct.first.label, 'B');
      expect(q2Correct.first.content, 'Yên');
    });

    test('parseText extracts inline answer and explanation', () {
      const text = '''
Câu 1: Nước sôi ở bao nhiêu độ C ở áp suất tiêu chuẩn?
A. 50
B. 80
C. 100
D. 120
Đáp án: C
Lời giải: Ở áp suất 1 atm tiêu chuẩn, nước nguyên chất sôi ở 100 độ C.
''';

      final exam = WordParser.parseText(text);
      expect(exam.questions.length, 1);
      final q = exam.questions.first;
      expect(q.number, 1);
      final correctChoice = q.choices.firstWhere((c) => c.isCorrect);
      expect(correctChoice.label, 'C');
      expect(q.explanation, contains('Ở áp suất 1 atm tiêu chuẩn'));
    });

    test('parseText matches answer table at the bottom', () {
      const text = '''
Câu 1: Đâu là ngôn ngữ lập trình di động của Google?
A. Swift
B. Kotlin
C. Dart
D. Ruby

Câu 2: Flutter được phát triển bởi công ty nào?
A. Facebook
B. Google
C. Microsoft
D. Apple

BẢNG ĐÁP ÁN:
1.C  2.B
''';

      final exam = WordParser.parseText(text);
      expect(exam.questions.length, 2);

      final q1Correct = exam.questions[0].choices.firstWhere((c) => c.isCorrect);
      expect(q1Correct.label, 'C');

      final q2Correct = exam.questions[1].choices.firstWhere((c) => c.isCorrect);
      expect(q2Correct.label, 'B');
    });

    test('parseText handles varied question numbering prefixes', () {
      const text = '''
Question 1: What is the capital of France?
A. Berlin
*B. Paris
C. Madrid
D. Rome

2. What is 2 x 3?
A. 5
*B. 6
C. 7
D. 8
''';

      final exam = WordParser.parseText(text);
      expect(exam.questions.length, 2);
      expect(exam.questions[0].number, 1);
      expect(exam.questions[0].content, 'What is the capital of France?');
      expect(exam.questions[1].number, 2);
      expect(exam.questions[1].content, 'What is 2 x 3?');
    });

    test('parseText handles empty or whitespace text gracefully', () {
      final exam = WordParser.parseText('   ');
      expect(exam.questions, isEmpty);
      expect(exam.title, isNotEmpty);
    });
  });
}
