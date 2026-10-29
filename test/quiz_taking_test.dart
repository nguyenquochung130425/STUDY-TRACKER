import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_tracker/models/exam_question.dart';
import 'package:study_tracker/models/study_task.dart';
import 'package:study_tracker/screens/quiz_taking_screen.dart';

void main() {
  testWidgets('QuizTakingScreen allows taking quiz, submitting, and viewing wrong answers and results', (WidgetTester tester) async {
    final assignment = StudyTask(
      id: 'quiz_task_1',
      subjectId: 'sub_math',
      title: 'Kiểm tra trắc nghiệm thử nghiệm',
      dueDate: DateTime.now().add(const Duration(days: 1)),
    );

    final questions = [
      QuestionModel(
        id: 'q1',
        assignmentId: 'quiz_task_1',
        questionNumber: 1,
        content: '1 + 1 bằng mấy?',
        explanation: '1 cộng 1 đương nhiên bằng 2.',
        choices: [
          ChoiceModel(id: 'c1_a', questionId: 'q1', label: 'A', content: 'Hai', isCorrect: true),
          ChoiceModel(id: 'c1_b', questionId: 'q1', label: 'B', content: 'Ba', isCorrect: false),
        ],
      ),
      QuestionModel(
        id: 'q2',
        assignmentId: 'quiz_task_1',
        questionNumber: 2,
        content: 'Thủ đô của Việt Nam là gì?',
        explanation: 'Thủ đô của Việt Nam là Hà Nội.',
        choices: [
          ChoiceModel(id: 'c2_a', questionId: 'q2', label: 'A', content: 'Đà Nẵng', isCorrect: false),
          ChoiceModel(id: 'c2_b', questionId: 'q2', label: 'B', content: 'Hà Nội', isCorrect: true),
        ],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: QuizTakingScreen(
          assignment: assignment,
          customQuestions: questions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify first question is shown
    expect(find.text('Câu 1 / 2'), findsWidgets);
    expect(find.text('1 + 1 bằng mấy?'), findsOneWidget);
    expect(find.text('Hai'), findsOneWidget);
    expect(find.text('Ba'), findsOneWidget);

    // Answer Q1 correctly (Choice A: 'Hai')
    await tester.tap(find.text('Hai'));
    await tester.pumpAndSettle();

    // Navigate to next question
    await tester.tap(find.text('Câu tiếp'));
    await tester.pumpAndSettle();

    expect(find.text('Câu 2 / 2'), findsWidgets);
    expect(find.text('Thủ đô của Việt Nam là gì?'), findsOneWidget);

    // Answer Q2 incorrectly (Choice A: 'Đà Nẵng')
    await tester.tap(find.text('Đà Nẵng'));
    await tester.pumpAndSettle();

    // Tap submit button in app bar or bottom bar
    final submitButton = find.text('Nộp bài').first;
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Nộp bài thi?'), findsOneWidget);
    await tester.tap(find.text('Nộp bài ngay'));
    await tester.pumpAndSettle();

    // Result screen should be visible
    expect(find.text('Chi Tiết Bài Làm & Lời Giải'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget); // Score 5.0 / 10
    expect(find.textContaining('1 câu đúng'), findsWidgets);
    expect(find.textContaining('1 câu sai'), findsWidgets);

    // Check wrong answer review is displayed
    expect(find.text('Bạn đã chọn'), findsOneWidget);
    expect(find.text('Đáp án đúng'), findsWidgets);
    expect(find.text('Thủ đô của Việt Nam là Hà Nội.'), findsOneWidget);

    // Check retry buttons
    expect(find.text('Làm lại bài tập'), findsOneWidget);
    expect(find.text('Luyện tập lại 1 câu sai'), findsOneWidget);

    // Test retry
    await tester.tap(find.text('Làm lại bài tập'));
    await tester.pumpAndSettle();

    // Should return to taking mode at Question 1
    expect(find.text('Câu 1 / 2'), findsWidgets);
    expect(find.text('1 + 1 bằng mấy?'), findsOneWidget);
  });
}
