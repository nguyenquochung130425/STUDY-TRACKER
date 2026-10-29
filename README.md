# 📚 Study Tracker - Ứng Dụng Quản Lý Học Tập, Luyện Thi & Bảo Mật Cá Nhân

[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.4-0175C2?logo=dart)](https://dart.dev)
[![Tests](https://img.shields.io/badge/Tests-45%2F45%20Passing-success)](file:///d:/STUDY%20TRACKER/test)
[![Analyzer](https://img.shields.io/badge/Analyzer-No%20Issues-brightgreen)](file:///d:/STUDY%20TRACKER/lib)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows-blue)](https://flutter.dev)

Ứng dụng quản lý học tập toàn diện được phát triển trên nền tảng **Flutter & Dart**, tích hợp công cụ lập kế hoạch học tập, thời khóa biểu, đồng hồ Pomodoro, thi trắc nghiệm trực tuyến (Quiz Engine), quản lý điểm số & tính toán mô phỏng GPA, cùng cơ chế bảo mật khóa ứng dụng bằng mã PIN an toàn.

---

## 🌟 Giới Thiệu Dự Án

**Study Tracker** ra đời với mục tiêu trở thành trợ thủ đắc lực cho học sinh, sinh viên và người tự học. Ứng dụng kết hợp hài hòa giữa:
1. **Quản lý học vụ:** Quản lý môn học, số tín chỉ, thời khóa biểu và tính điểm trung bình tích lũy GPA.
2. **Luyện thi & Làm bài tập:** Tải lên đề thi Word (`.docx`), làm bài trắc nghiệm có bấm giờ, chấm điểm tự động, xem lại các câu sai kèm lời giải chi tiết và luyện tập lại.
3. **Kỷ luật & Tập trung:** Đồng hồ học tập Pomodoro kết hợp theo dõi chuỗi ngày học liên tục (Study Streak).
4. **Bảo mật & Đồng bộ:** Khóa bảo mật PIN 6 số với cơ chế tự khóa khi chạy ngầm (Auto-Lock) và đồng bộ dữ liệu đám mây với Firebase Firestore.

---

## ✨ Các Tính Năng Nổi Bật

### 1. 🎯 Quản Lý Môn Học & Tính Toán / Mô Phỏng GPA Học Kỳ
- **Quản lý môn học chi tiết:** Lưu trữ tên môn, mã môn, số tín chỉ, giảng viên, mục tiêu giờ học hàng tuần, học kỳ và màu sắc/icon nhận diện.
- **Thẻ thống kê GPA (Stats Chip):** Hiển thị ngay trên thanh tổng quan học kỳ:
  $$\text{GPA} = \frac{\sum (\text{Điểm môn}_i \times \text{Số tín chỉ}_i)}{\sum \text{Số tín chỉ}_i}$$
  * Giúp người dùng nắm bắt điểm trung bình học kỳ ngay lập tức mà không cần chuyển màn hình.
- **Trường điểm số trên từng thẻ môn học (Subject Card):**
  * Hiển thị điểm hệ 4 (ví dụ: `Điểm: 3.8`), điểm hệ 10 và điểm chữ quy đổi (`A+`, `A`, `B+`, `B`, `C+`, `C`, `D+`, `D`, `F`).
  * Nút nhập/sửa điểm nhanh trực tiếp từ card môn học hoặc menu tùy chọn.
- **Bảng điểm chi tiết & Bộ mô phỏng GPA (What-If Simulator):**
  * Xem danh sách chi tiết các đầu điểm thành phần (Chuyên cần, Giữa kỳ, Cuối kỳ...) có trọng số `%`.
  * **Mô phỏng GPA dự kiến:** Kéo slider thử nghiệm điểm số từng môn để xem GPA học kỳ thay đổi theo thời gian thực ($\Delta$ GPA), hỗ trợ lưu điểm dự kiến làm điểm chính thức.

---

### 2. 📝 Quản Lý Bài Tập, Đề Thi & Làm Bài Trắc Nghiệm (Quiz Engine)
- **Word Exam Parser (`WordParser`):**
  * Tự động bóc tách đề thi từ tệp Word (`.docx`) hoặc văn bản thô.
  * Nhận diện thông minh: câu hỏi, đoạn văn đọc hiểu (passage), các đáp án A/B/C/D, đáp án đúng và lời giải chi tiết.
- **Giao diện Làm bài thi trắc nghiệm (`QuizTakingScreen`):**
  * Đồng hồ đếm giờ làm bài thực tế (Elapsed Timer).
  * Question Palette (dải số câu hỏi) nhảy nhanh đến câu bất kỳ, hiển thị trạng thái đã trả lời.
  * Hộp thoại nộp bài kiểm tra và cảnh báo số câu còn bỏ sót trước khi nộp.
- **Báo cáo kết quả & Xem lại câu sai:**
  * Thẻ điểm Hero Banner nổi bật: Điểm số thang 10, số câu đúng/tổng số câu, tỉ lệ phần trăm, xếp loại (Xuất sắc, Giỏi, Khá, Đạt yêu cầu, Cần cố gắng).
  * **Bộ lọc xem lại câu hỏi:** Chuyển đổi nhanh giữa *Tất cả*, *Câu sai*, *Câu đúng*.
  * **Đánh dấu trực quan:** Đánh dấu lựa chọn bạn đã làm (`❌ Bạn đã chọn`), đáp án chuẩn (`✅ Đáp án đúng`) và hiển thị hộp `💡 Lời giải chi tiết`.
  * Tự động đánh dấu bài tập hoàn thành và hỗ trợ nút **"Lưu điểm môn"** vào sổ điểm học tập.
- **Làm lại bài tập & Luyện tập câu sai:**
  * *Làm lại bài tập:* Reset toàn bộ câu trả lời và thời gian để làm lại đề thi từ đầu.
  * *Luyện tập lại các câu sai:* Tự động lọc ra riêng các câu đã làm sai để học sinh luyện lại cho đến khi thành thạo.

---

### 3. 📅 Thời Khóa Biểu & Lịch Học Thông Minh
- Quản lý lịch học theo tuần từ Thứ 2 đến Chủ nhật.
- Hiển thị ca học, phòng học, giảng viên phụ trách, phân loại trạng thái buổi học.
- Ràng buộc dữ liệu toàn vẹn: Kiểm tra và cảnh báo Cascade Delete khi xóa môn học có lịch học liên quan.

---

### 4. ⏱️ Đồng Hồ Pomodoro & Thống Kê Học Tập
- **Phương pháp Pomodoro khoa học:** 25 phút tập trung cao độ, 5 phút nghỉ ngắn, 15 phút nghỉ dài.
- **Báo cáo & Biểu đồ trực quan:**
  * Biểu đồ thời lượng học trong tuần sử dụng `fl_chart`.
  * Thống kê tổng số phút học hôm nay, tuần này và số phiên học hoàn thành.
  * Theo dõi chuỗi ngày học tập liên tục (Study Streak Days).

---

### 5. 🔐 Xác Thực & Bảo Mật Ứng Dụng (Auth & App Lock)
- **Xác thực người dùng:** Đăng ký, đăng nhập tài khoản bằng email/mật khẩu, hỗ trợ nút **"Dùng thử tài khoản Demo"** một chạm.
- **Bảo mật mã PIN (App Lock):**
  * Thiết lập mã PIN 6 số được bảo vệ bằng mã hóa an toàn trên thiết bị (`flutter_secure_storage`).
  * Bàn phím số Numpad cảm ứng chuyên dụng.
  * **Tự động khóa khi chạy ngầm (Background Auto-Lock):** Giám sát trạng thái ứng dụng qua `WidgetsBindingObserver`, tự động khóa màn hình ngay khi người dùng rời app.
  * Cơ chế chống brute-force: Tạm khóa sau nhiều lần nhập sai liên tiếp.

---

### 6. 💾 Cơ Sở Dữ Liệu Đa Nền Tảng (SQLite FFI & Web WASM)
- **Kiến trúc CSDL SQLite quan hệ:**
  * Lưu trữ cấu trúc bảng: `subjects`, `schedules`, `assignments`, `questions`, `choices`, `grades`.
  * Hỗ trợ lưu trữ transaction an toàn cho bộ đề thi nhiều câu hỏi.
- **Đa nền tảng thực sự:**
  * **Desktop / Mobile:** Chạy qua `sqflite` và `sqflite_common_ffi`.
  * **Web:** Tích hợp `sqflite_common_ffi_web` với file Web Worker `web/sqflite_sw.js` và WebAssembly `web/sqlite3.wasm`.

---

## 📂 Sơ Đồ Cấu Trúc Dự Án

```text
STUDY-TRACKER/
├── lib/
│   ├── core/                            # Nền tảng dùng chung
│   │   ├── constants/                   # AppColors, hằng số hệ thống
│   │   ├── database/                    # DatabaseHelper (SQLite FFI / WASM)
│   │   ├── services/                    # AuthService, SecurityService
│   │   ├── theme/                       # AppTheme, ThemeProvider, AppTypography
│   │   ├── utils/                       # GpaHelper, bộ tiện ích tính toán
│   │   └── widgets/                     # CustomButton, CustomTextField, CustomDialog
│   ├── features/                        # Module nghiệp vụ chuyên biệt
│   │   ├── analytics/                   # StudyAnalyticsService
│   │   └── cloud_sync/                  # CloudSyncService
│   ├── models/                          # Data Models
│   │   ├── exam_question.dart           # QuestionModel, ChoiceModel
│   │   ├── grade_entry.dart             # GradeEntry (đầu điểm môn học)
│   │   ├── schedule_entry.dart          # ScheduleEntry (thời khóa biểu)
│   │   ├── study_session.dart           # StudySession (phiên học Pomodoro)
│   │   ├── study_task.dart              # StudyTask (bài tập, đề thi)
│   │   └── subject.dart                 # Subject (môn học & tín chỉ)
│   ├── providers/                       # State Management (Provider)
│   │   ├── app_lock_provider.dart       # Quản lý khóa PIN & auto-lock
│   │   ├── schedule_provider.dart       # Quản lý thời khóa biểu
│   │   └── study_provider.dart          # Quản lý môn học, điểm số, Pomodoro
│   ├── screens/                         # Màn hình ứng dụng
│   │   ├── assignment_management_screen.dart # Quản lý bài tập & đề thi
│   │   ├── gpa_calculator_sheet.dart    # Bảng điểm chi tiết & Mô phỏng GPA
│   │   ├── quiz_taking_screen.dart      # Làm bài trắc nghiệm & Xem câu sai
│   │   ├── subject_list_screen.dart     # Quản lý môn học & Thẻ GPA
│   │   ├── statistics_screen.dart       # Thống kê & biểu đồ học tập
│   │   ├── pomodoro_screen.dart         # Đồng hồ Pomodoro
│   │   └── pin_lock_screen.dart         # Màn hình mở khóa PIN
│   ├── services/
│   │   └── word_parser.dart             # Bộ bóc tách đề thi Word (.docx)
│   └── main.dart                        # Điểm khởi chạy & Cấu hình Provider
├── test/                                # Bộ kiểm thử tự động (45 tests)
│   ├── gpa_management_test.dart         # Kiểm thử tính điểm GPA & What-If
│   ├── quiz_taking_test.dart            # Kiểm thử thi trắc nghiệm & Xem câu sai
│   ├── database_and_schedule_test.dart  # Kiểm thử CSDL SQLite & Cascade
│   ├── word_parser_test.dart            # Kiểm thử bóc tách đề thi Word
│   ├── app_lock_test.dart               # Kiểm thử bảo mật mã PIN
│   └── study_provider_test.dart         # Kiểm thử Provider học tập
├── web/                                 # Tài nguyên Web & SQLite WASM
│   ├── sqflite_sw.js                    # Web Worker cho SQLite
│   └── sqlite3.wasm                     # SQLite WebAssembly binary
├── pubspec.yaml                         # Cấu hình dependencies
└── README.md                            # Tài liệu dự án
```

---

## 🚀 Hướng Dẫn Cài Đặt & Khởi Chạy

### 1. Yêu cầu môi trường
- **Flutter SDK:** >= 3.47.0 (Khuyến nghị 3.47.5+)
- **Dart SDK:** >= 3.13.0
- **Hệ điều hành hỗ trợ:** Windows 10/11, macOS, Linux, Android, iOS, Chrome/Edge (Web)

### 2. Cài đặt các thư viện
```bash
git clone https://github.com/nguyenquochung130425/STUDY-TRACKER.git
cd STUDY-TRACKER
flutter pub get
```

### 3. Cấu hình SQLite cho Web (Nếu chạy Web)
Dự án đã tích hợp sẵn tệp WASM và Web Worker trong thư mục `web/`. Nếu cần cập nhật lại:
```bash
dart run sqflite_common_ffi_web:setup
```

### 4. Khởi chạy ứng dụng
- **Chạy trên Windows Desktop:**
  ```bash
  flutter run -d windows
  ```
- **Chạy trên Trình duyệt Web (Chrome):**
  ```bash
  flutter run -d chrome
  ```
- **Chạy trên Thiết bị di động (Android / iOS):**
  ```bash
  flutter run
  ```

---

## 🧪 Kiểm Thử & Đảm Bảo Chất Lượng Mã Nguồn

Dự án duy trì bộ kiểm thử tự động toàn diện bao quát tất cả các tính năng nghiệp vụ, CSDL, logic tính toán GPA và giao diện thi trắc nghiệm:

```bash
# Phân tích tĩnh mã nguồn (đạt 0 lỗi, 0 cảnh báo)
flutter analyze

# Chạy toàn bộ 45 unit & widget tests
flutter test
```

### Danh sách test suite:
| Tệp kiểm thử | Hạng mục kiểm tra |
|---|---|
| `gpa_management_test.dart` | Quy đổi điểm hệ 10 -> hệ 4, điểm chữ, xếp loại, Stats Chip GPA, Mô phỏng What-If |
| `quiz_taking_test.dart` | Làm bài trắc nghiệm, bấm giờ, nộp bài, xem câu sai kèm đáp án đúng, làm lại đề |
| `database_and_schedule_test.dart` | Lưu trữ đề thi SQLite Transaction, thời khóa biểu, Cascade Delete |
| `word_parser_test.dart` | Bóc tách câu hỏi, đáp án, lời giải từ đề thi Word |
| `app_lock_test.dart` | Tạo/đổi mã PIN, khóa bảo mật, tự khóa khi app chuyển trạng thái background |
| `study_provider_test.dart` | Quản lý môn học, phiên học Pomodoro, tính điểm trung bình môn có trọng số |

---

## 🔑 Tài Khoản Demo Trải Nghiệm Nhanh
- **Email:** `demo@studytracker.com`
- **Mật khẩu:** `password123`
- *(Hoặc bấm trực tiếp nút **"Dùng thử tài khoản Demo"** trên màn hình Đăng nhập để vào ngay ứng dụng).*

---

## 📄 Bản Quyền & Giấy Phép
Dự án được phát triển phục vụ mục đích học tập và quản lý năng suất cá nhân. Mọi đóng góp (Pull Requests) và phản hồi đều được hoan nghênh!
