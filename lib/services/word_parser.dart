import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

class ParsedExam {
  final String title;
  final String? code;
  final int? timeMinutes;
  final List<ParsedQuestion> questions;

  ParsedExam({
    required this.title,
    this.code,
    this.timeMinutes,
    required this.questions,
  });
}

class ParsedQuestion {
  final int number;
  final String content;
  final String? passage;
  final List<ParsedChoice> choices;
  final String? explanation;

  ParsedQuestion({
    required this.number,
    required this.content,
    this.passage,
    required this.choices,
    this.explanation,
  });

  ParsedQuestion copyWith({
    int? number,
    String? content,
    String? passage,
    List<ParsedChoice>? choices,
    String? explanation,
  }) {
    return ParsedQuestion(
      number: number ?? this.number,
      content: content ?? this.content,
      passage: passage ?? this.passage,
      choices: choices ?? this.choices,
      explanation: explanation ?? this.explanation,
    );
  }
}

class ParsedChoice {
  final String label; // A, B, C, D
  final String content;
  final bool isCorrect;

  ParsedChoice({
    required this.label,
    required this.content,
    required this.isCorrect,
  });

  ParsedChoice copyWith({
    String? label,
    String? content,
    bool? isCorrect,
  }) {
    return ParsedChoice(
      label: label ?? this.label,
      content: content ?? this.content,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

class WordParser {
  /// Trích xuất văn bản thô (Plain Text) từ file Word .docx
  static String extractTextFromDocx(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        if (file.name == 'word/document.xml') {
          final content = utf8.decode(file.content as List<int>);
          return _xmlToPlainText(content);
        }
      }
    } catch (_) {}
    return '';
  }

  /// Chuyển đổi XML của Word sang chuỗi văn bản sạch
  static String _xmlToPlainText(String xml) {
    // Thay thế ngắt dòng đoạn văn <w:p> bằng ký tự xuống dòng
    var text = xml.replaceAll(RegExp(r'<\/w:p>'), '\n');
    // Thay thế ngắt dòng <w:br/>
    text = text.replaceAll(RegExp(r'<w:br[^>]*>'), '\n');
    // Trích xuất các nội dung văn bản <w:t>...</w:t>
    final buffer = StringBuffer();
    final regex = RegExp(r'<w:t[^>]*>(.*?)<\/w:t>', dotAll: true);
    final matches = regex.allMatches(text);

    int lastIndex = 0;
    for (final match in matches) {
      final precedingText = text.substring(lastIndex, match.start);
      if (precedingText.contains('\n')) {
        buffer.writeln();
      }
      buffer.write(match.group(1));
      lastIndex = match.end;
    }

    var result = buffer.toString();
    // Giải mã các thực thể HTML/XML
    result = result
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
    return result.trim();
  }

  /// Engine Regex Bóc Tách Đề Thi & Bài Tập Trắc Nghiệm
  static ParsedExam parseText(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).toList();

    String examTitle = 'Bài tập trắc nghiệm mới';
    String? examCode;
    int? examDuration;

    // 1. Quét thông tin đề (ĐỀ THI:, MÃ ĐỀ:, THỜI GIAN:)
    for (int i = 0; i < lines.length && i < 15; i++) {
      final line = lines[i];
      final titleMatch = RegExp(
        r'^(?:ĐỀ THI|BÀI TẬP|TÊN ĐỀ|ĐỀ BÀI|EXAM):\s*(.*)',
        caseSensitive: false,
      ).firstMatch(line);
      if (titleMatch != null && titleMatch.group(1)!.trim().isNotEmpty) {
        examTitle = titleMatch.group(1)!.trim();
        continue;
      }

      final codeMatch = RegExp(
        r'^(?:MÃ ĐỀ|MÃ BÀI TẬP|CODE):\s*([A-Za-z0-9_-]+)',
        caseSensitive: false,
      ).firstMatch(line);
      if (codeMatch != null) {
        examCode = codeMatch.group(1);
        continue;
      }

      final timeMatch = RegExp(
        r'^(?:THỜI GIAN|TIME):\s*(\d+)',
        caseSensitive: false,
      ).firstMatch(line);
      if (timeMatch != null) {
        examDuration = int.tryParse(timeMatch.group(1)!);
        continue;
      }
    }

    // 2. Quét Bảng Đáp Án Tổng Hợp ở cuối đề nếu có (ví dụ: "BẢNG ĐÁP ÁN: 1.A, 2.B..." hoặc "1-A 2-B")
    final Map<int, String> answerKeyTable = _extractAnswerKeyTable(rawText);

    // 3. Tách các khối câu hỏi & bài đọc
    final questions = <ParsedQuestion>[];
    String? currentPassage;

    // Regex phát hiện bắt đầu câu hỏi (Câu 1:, Question 1:, 1., 101., Câu 1.)
    final questionHeaderRegex = RegExp(
      r'^(?:Câu|Question|\b)\s*(\d+)[\.:\)]\s*(.*)',
      caseSensitive: false,
    );

    // Regex phát hiện bài đọc: [Passage], Đoạn văn:, Questions X-Y:
    final passageHeaderRegex = RegExp(
      r'^(?:\[Passage\]|Bài đọc:|Đoạn văn:|Questions?\s*\d+\s*-\s*\d+[:\.])\s*(.*)',
      caseSensitive: false,
    );

    int lineIdx = 0;
    while (lineIdx < lines.length) {
      final line = lines[lineIdx];

      // Bỏ qua dòng trống
      if (line.isEmpty) {
        lineIdx++;
        continue;
      }

      // Kiểm tra xem có bắt đầu bảng đáp án tổng hợp không thì dừng
      if (RegExp(r'^(?:BẢNG ĐÁP ÁN|ĐÁP ÁN TỔNG HỢP|ANSWER KEY)', caseSensitive: false)
          .hasMatch(line)) {
        break;
      }

      // Kiểm tra xem có phải là bài đọc / passage không
      final passageMatch = passageHeaderRegex.firstMatch(line);
      if (passageMatch != null) {
        final passageBuffer = StringBuffer();
        if (passageMatch.group(1) != null && passageMatch.group(1)!.isNotEmpty) {
          passageBuffer.writeln(passageMatch.group(1));
        }
        lineIdx++;
        // Thu thập các dòng tiếp theo cho bài đọc cho tới khi gặp câu hỏi đầu tiên
        while (lineIdx < lines.length &&
            !questionHeaderRegex.hasMatch(lines[lineIdx]) &&
            !lines[lineIdx].startsWith('BẢNG ĐÁP ÁN')) {
          passageBuffer.writeln(lines[lineIdx]);
          lineIdx++;
        }
        currentPassage = passageBuffer.toString().trim();
        continue;
      }

      // Kiểm tra câu hỏi
      final qMatch = questionHeaderRegex.firstMatch(line);
      if (qMatch != null) {
        final qNum = int.tryParse(qMatch.group(1)!) ?? (questions.length + 1);
        final qContentBuffer = StringBuffer(qMatch.group(2) ?? '');

        lineIdx++;
        // Đọc các dòng tiếp theo của nội dung câu hỏi cho tới khi gặp đáp án A, B, C, D
        while (lineIdx < lines.length &&
            !_isChoiceLine(lines[lineIdx]) &&
            !questionHeaderRegex.hasMatch(lines[lineIdx])) {
          if (lines[lineIdx].isNotEmpty) {
            qContentBuffer.write(' ${lines[lineIdx]}');
          }
          lineIdx++;
        }

        // Bóc tách các phương án lựa chọn A, B, C, D
        final choices = <ParsedChoice>[];
        String? inlineAnswer;
        String? explanation;

        while (lineIdx < lines.length &&
            !questionHeaderRegex.hasMatch(lines[lineIdx]) &&
            !passageHeaderRegex.hasMatch(lines[lineIdx]) &&
            !RegExp(r'^(?:BẢNG ĐÁP ÁN|ĐÁP ÁN TỔNG HỢP)', caseSensitive: false)
                .hasMatch(lines[lineIdx])) {
          final choiceLine = lines[lineIdx];

          // Kiểm tra dòng đáp án: "Đáp án: B" hoặc "Key: B"
          final ansMatch = RegExp(
            r'^(?:Đáp án|Key|Answer):\s*([A-D])',
            caseSensitive: false,
          ).firstMatch(choiceLine);
          if (ansMatch != null) {
            inlineAnswer = ansMatch.group(1)!.toUpperCase();
            lineIdx++;
            continue;
          }

          // Kiểm tra dòng giải thích: "Giải thích: ..." hoặc "Explanation: ..."
          final expMatch = RegExp(
            r'^(?:Giải thích|Explanation|Lời giải):\s*(.*)',
            caseSensitive: false,
          ).firstMatch(choiceLine);
          if (expMatch != null) {
            explanation = expMatch.group(1);
            lineIdx++;
            continue;
          }

          // Phân tách các lựa chọn trên dòng (có thể 1 dòng chứa 1 hoặc nhiều lựa chọn A. B. C. D.)
          final parsedChoicesOnLine = _parseChoicesFromLine(choiceLine);
          if (parsedChoicesOnLine.isNotEmpty) {
            choices.addAll(parsedChoicesOnLine);
          }

          lineIdx++;
        }

        // Xác định đáp án đúng qua 3 cách
        String? finalCorrectLabel = inlineAnswer ?? answerKeyTable[qNum];

        // Chuẩn hóa danh sách lựa chọn
        final finalChoices = choices.map((c) {
          bool isCorrect = c.isCorrect;
          if (finalCorrectLabel != null) {
            isCorrect = (c.label.toUpperCase() == finalCorrectLabel.toUpperCase());
          }
          return c.copyWith(isCorrect: isCorrect);
        }).toList();

        // Mặc định nếu chưa có đáp án đúng, chọn đáp án A làm mặc định an toàn
        if (!finalChoices.any((c) => c.isCorrect) && finalChoices.isNotEmpty) {
          finalChoices[0] = finalChoices[0].copyWith(isCorrect: true);
        }

        questions.add(
          ParsedQuestion(
            number: qNum,
            content: qContentBuffer.toString().trim(),
            passage: currentPassage,
            choices: finalChoices,
            explanation: explanation,
          ),
        );
        continue;
      }

      lineIdx++;
    }

    return ParsedExam(
      title: examTitle,
      code: examCode,
      timeMinutes: examDuration,
      questions: questions,
    );
  }

  /// Kiểm tra xem dòng có chứa bắt đầu phương án lựa chọn không
  static bool _isChoiceLine(String line) {
    return RegExp(r'(?:^|\s+)[\*]?[A-D][\.\)\*]\s+').hasMatch(line);
  }

  /// Trích xuất danh sách lựa chọn trên một dòng (hỗ trợ A. ..., B. ... trên cùng 1 dòng hoặc xuống dòng)
  static List<ParsedChoice> _parseChoicesFromLine(String line) {
    final choices = <ParsedChoice>[];
    // Regex tìm các khối đáp án: *A. hoặc A*. hoặc A. hoặc A)
    final choiceRegex = RegExp(
      r'([\*]?)([A-D])([\*]?)[.\)]\s*(.*?)(?=(?:[\*]?[A-D][\.\)][\s*]|$))',
    );
    final matches = choiceRegex.allMatches(line);

    for (final m in matches) {
      final hasStarPrefix = m.group(1) == '*';
      final label = m.group(2)!.toUpperCase();
      final hasStarSuffix = m.group(3) == '*';
      final text = m.group(4)?.trim() ?? '';

      final isCorrect = hasStarPrefix || hasStarSuffix;
      choices.add(
        ParsedChoice(
          label: label,
          content: text,
          isCorrect: isCorrect,
        ),
      );
    }
    return choices;
  }

  /// Quét bảng đáp án tổng hợp (ví dụ: BẢNG ĐÁP ÁN: 1. A, 2. B, 3. C...)
  static Map<int, String> _extractAnswerKeyTable(String text) {
    final result = <int, String>{};
    final tableHeaderRegex = RegExp(
      r'(?:BẢNG ĐÁP ÁN|ĐÁP ÁN TỔNG HỢP|ANSWER KEY)[\s:]*([\s\S]*)',
      caseSensitive: false,
    );
    final match = tableHeaderRegex.firstMatch(text);
    if (match != null) {
      final tableContent = match.group(1)!;
      final pairRegex = RegExp(r'(\d+)\s*[\.\-:\/]\s*([A-D])', caseSensitive: false);
      for (final pMatch in pairRegex.allMatches(tableContent)) {
        final qNum = int.tryParse(pMatch.group(1)!);
        final ans = pMatch.group(2)!.toUpperCase();
        if (qNum != null) {
          result[qNum] = ans;
        }
      }
    }
    return result;
  }
}
