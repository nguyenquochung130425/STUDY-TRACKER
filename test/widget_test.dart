import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_tracker/main.dart';

void main() {
  testWidgets('StudyTrackerApp loads successfully test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const StudyTrackerApp());
    await tester.pumpAndSettle();

    // Xác nhận giao diện hiển thị đúng tiêu đề chính
    expect(find.textContaining('Study Tracker'), findsOneWidget);
    expect(find.text('Học tập'), findsOneWidget);
    expect(find.text('Thống kê'), findsOneWidget);
    expect(find.text('Nhiệm vụ'), findsOneWidget);
  });
}
