# 📋 Báo Cáo Công Việc Đã Hoàn Thành - Study Tracker

- **Dự án:** Study Tracker (Ứng dụng di động theo dõi thời gian học tập & quản lý môn học)
- **Kho lưu trữ:** [https://github.com/nguyenquochung130425/STUDY-TRACKER.git](https://github.com/nguyenquochung130425/STUDY-TRACKER.git)
- **Nhánh chính:** `main` | **Nhánh phát triển:** `develop` | **Nhánh chức năng:** `feature/auth-security`
- **Công nghệ nền tảng:** Flutter 3.47.5 & Dart 3.13.4
 phan4
- **Cập nhật ngày:** 24/10/2026

 feature/auth-security
- **Cập nhật ngày:** 12/10/2026

- **Cập nhật ngày:** 21/10/2026
 main
 main

---

## 👑 Vai Trò Phụ Trách: Quản Lý Dự Án, Kiến Trúc Chung, Xác Thực (Auth) & Bảo Mật (Security)

### 1. Khởi tạo Kiến Trúc Nền Tảng (Base Architecture & Design System)
- [x] Thiết lập cấu trúc thư mục chuẩn **Feature-first kết hợp Core-shared** (`lib/core/`, `lib/models/`, `lib/providers/`, `lib/screens/`, `lib/widgets/`).
- [x] Cấu hình hệ thống Bảng màu (`AppColors`) chuẩn WCAG, hỗ trợ đầy đủ **Light Mode & Dark Mode**.
- [x] Định nghĩa hệ thống Typography chuẩn Material 3 (`AppTypography`) từ Display, Title, Body đến Label.
- [x] Cấu hình hoàn chỉnh `AppTheme` (Light/Dark ThemeData) với `CardTheme`, `InputDecorationTheme`, `ElevatedButtonTheme`, `NavigationBarTheme`.
- [x] Xây dựng `ThemeProvider` hỗ trợ người dùng chuyển đổi 3 chế độ (Theo hệ thống / Sáng / Tối) lưu trữ qua `SharedPreferences`.
- [x] Xây dựng bộ UI Components dùng chung cho toàn bộ dự án (`lib/core/widgets/`):
  - `CustomButton`: Hỗ trợ 5 kiểu dáng (`primary`, `secondary`, `outline`, `text`, `danger`), trạng thái tải spinner `isLoading`, hỗ trợ Icon.
  - `CustomTextField`: Hỗ trợ icon đầu/cuối, toggle ẩn/hiện mật khẩu dạng icon mắt, validation chuẩn FormState.
  - `CustomDialog`: Hộp thoại xác nhận thao tác nguy hiểm `CustomDialog.showConfirm()` và thông báo `CustomDialog.showAlert()`.

### 2. Chức Năng 3.1: Đăng Ký, Đăng Nhập & Quản Lý Hồ Sơ (Auth)
- [x] Thiết kế model người dùng `UserModel` (id, email, displayName, createdAt, avatar).
- [x] Triển khai dịch vụ xác thực `AuthService`: Lưu trữ dữ liệu an toàn trong `SharedPreferences`, hỗ trợ tài khoản demo mặc định, thiết kế sẵn mô hình để hoán đổi sang Firebase Auth / REST API.
- [x] Triển khai `AuthProvider`: Quản lý các trạng thái `AuthStatus` (authenticated, unauthenticated, loading), xử lý login, register, updateProfile, logout.
- [x] Thiết kế giao diện Đăng nhập `LoginScreen`: Giao diện hiện đại, validate email/password, nút "Dùng thử tài khoản Demo" giúp test ngay lập tức.
- [x] Thiết kế giao diện Đăng ký `RegisterScreen`: Đăng ký tài khoản mới với họ tên, email, mật khẩu, xác nhận mật khẩu.
- [x] Thiết kế giao diện Hồ sơ cá nhân `ProfileScreen`: Hiển thị avatar ký tự viết tắt, thông tin tài khoản, chỉnh sửa tên hiển thị, tùy chỉnh theme Sáng/Tối, nút Đăng xuất an toàn.
- [x] Mở rộng thanh điều hướng `MainNavigationScreen` với Tab thứ 4 "Hồ sơ" (Profile).

### 3. Chức Năng 3.10: Cơ Chế Bảo Mật (App Lock PIN & Background Auto-Lock)
- [x] Triển khai dịch vụ bảo mật `SecurityService`: Băm mã PIN một chiều bằng kỹ thuật Salted Hash (`StudyTracker_Secure_Salt_2026`) chống lộ dữ liệu.
- [x] Triển khai `SecurityProvider`: Quản lý trạng thái khóa `isLocked`, cờ kích hoạt PIN `isPinEnabled`, cờ tự động khóa ngầm `autoLockOnBackground`, đếm số lần thử sai.
- [x] Thiết kế màn hình khóa `PinLockScreen`: Bàn phím số Numpad cảm ứng mượt mà, chấm tròn PIN đổi màu theo tiến trình nhập, hỗ trợ 2 chế độ:
  - `PinLockMode.unlock`: Mở khóa ứng dụng.
  - `PinLockMode.setup`: Tạo mới hoặc thay đổi mã PIN (quy trình 2 bước: Nhập lần 1 -> Xác nhận lại lần 2).
- [x] **Cơ chế tự động khóa màn hình khi app chuyển sang chạy ngầm (Background Auto-Lock):**
  - Xây dựng `AppLockWrapper` bọc ở tầng cao nhất của ứng dụng, lắng nghe sự kiện vòng đời `WidgetsBindingObserver`.
  - Khi ứng dụng chuyển sang chế độ chạy ngầm (`AppLifecycleState.paused` / `inactive`), tự động kích hoạt `lockApp()`.
  - Khi người dùng mở lại app (`AppLifecycleState.resumed`), giao diện lập tức bị khóa và yêu cầu nhập mã PIN bảo mật.

### 4. Tài Liệu, Quản Lý Dự Án & Phân Nhánh Git (Git Flow)
- [x] Soạn thảo tài liệu kiến trúc & bảo mật chi tiết: `docs/ARCHITECTURE_AND_SECURITY.md`.
- [x] Soạn thảo hướng dẫn chiến lược phân nhánh Git Flow & làm việc nhóm: `docs/GIT_FLOW_AND_TEAM_GUIDE.md`.
- [x] Xây dựng bảng theo dõi tiến độ công việc và phân chia trách nhiệm cho các thành viên trong nhóm.
- [x] Quy ước Commit Messages chuẩn Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`).

### 5. Kiểm Thử & Đảm Bảo Chất Lượng
- [x] Viết bộ Unit Test toàn diện `test/auth_and_security_test.dart` kiểm tra `AuthService`, `AuthProvider`, `SecurityService`, `SecurityProvider`.
- [x] Đảm bảo vượt qua 100% test cases: `flutter test` (5/5 tests passed).
- [x] Phân tích tĩnh mã nguồn `flutter analyze`: **No issues found** (0 errors, 0 warnings).

### 7. Quản lý Điểm số (Chức năng 3.5)
- [x] Lưu nhiều đầu điểm cho từng môn học trên thiết bị.
- [x] Thêm, sửa, xóa đầu điểm; tính điểm trung bình có trọng số trên thang 10.
- [x] Hiển thị biểu đồ điểm trung bình theo môn và xu hướng điểm theo thời gian.

### 8. Theo dõi tiến độ & Thống kê (Chức năng 3.6 và 3.7)
- [x] Theo dõi thời lượng và tỷ lệ hoàn thành mục tiêu hàng tuần theo từng môn.
- [x] Tổng hợp thời lượng, số phiên trong tuần; hiển thị biểu đồ thời gian học theo ngày.
- [x] Lọc phiên học tương lai khỏi số liệu tiến độ tuần và hiển thị lịch sử học gần đây.

### 9. Cloud Sync Engine (Chức năng 3.11)
- [x] Thêm đăng ký/đăng nhập Firebase bằng email/mật khẩu và Google.
- [x] Đồng bộ môn học, phiên học, nhiệm vụ và điểm theo tài khoản Firestore.
- [x] Hỗ trợ đồng bộ thủ công, khi có mạng trở lại và sau khi dữ liệu cục bộ thay đổi.
- [x] Gộp dữ liệu theo thời điểm cập nhật và lưu dấu xóa để không khôi phục bản ghi đã xóa.
- [x] Cấu hình Firebase Web project trong `firebase_config.json` cục bộ; xác minh build Web thành công.
- [ ] Bổ sung Firebase App ID cho Android/iOS/macOS nếu cần dùng đồng bộ trên các nền tảng này.

### 10. Kiến trúc, Auth, Security & Git Flow
- [x] Thiết lập Provider, theme Light/Dark, bảng màu, typography và shared widgets.
- [x] Tạo feature service cho Auth và tích hợp vào `CloudSyncProvider`.
- [x] Bổ sung xác minh email, chặn cloud sync khi email chưa xác minh và đặt lại mật khẩu.
- [x] Tách Flutter App Lock PIN khỏi Firebase Auth; lưu PIN bằng secure storage và tự khóa khi ứng dụng không còn active.
- [x] Thêm Firestore rules giới hạn dữ liệu theo UID và cấu hình `firebase.json`.
- [x] Thêm PR template, task issue template, Git Flow guide và CI cho analyzer/tests.
- [x] Bổ sung unit tests cho analytics và logic quyết định ghi cloud.
- [ ] Triển khai Firestore rules vào Firebase project và xác minh bằng Emulator Suite.
- [ ] Bật branch protection cho `main`/`develop` và tạo GitHub Project board.
- [ ] Chuyển toàn bộ màn hình/provider cũ sang feature-first; hiện app vẫn dùng cấu trúc chuyển tiếp.

---

## 💾 Vai Trò 2: Cơ Sở Dữ Liệu Cục Bộ & Quản Lý Học Tập Cốt Lõi (SQLite Database, Môn Học & Lịch Học)

### 1. Kiến Tạo Hệ Thống Database (SQLite) & Data Access Layer
- [x] Xây dựng `DatabaseHelper` singleton (`lib/core/database/database_helper.dart`), cấu hình đường dẫn cơ sở dữ liệu `study_tracker.db` với `sqflite` và `sqflite_common_ffi`.
- [x] Kích hoạt ràng buộc khóa ngoại nghiêm ngặt: `PRAGMA foreign_keys = ON;`.
- [x] Định nghĩa toàn bộ cấu trúc 4 bảng cốt lõi:
  - `subjects`: id, code, name, credits, lecturer, semester, color_value, icon_code_point, weekly_target_hours, created_at, updated_at.
  - `assignments`: id, subject_id, title, description, due_date, is_completed, priority, created_at, updated_at (Khóa ngoại `ON DELETE CASCADE`).
  - `schedules`: id, subject_id, day_of_week, start_time, end_time, room, building, note, created_at, updated_at (Khóa ngoại `ON DELETE CASCADE`).
  - `grades`: id, subject_id, title, score, max_score, weight, created_at, updated_at (Khóa ngoại `ON DELETE CASCADE`).
- [x] Xây dựng Data Access Layer (DAL) tổng quát: `insert`, `query`, `update`, `delete`, `transaction`, cùng các DAO phương thức nghiệp vụ cho từng thực thể.
- [x] Cơ chế nạp sẵn dữ liệu mẫu ban đầu (Seed initial data) giúp trải nghiệm ngay lập tức.

### 2. Chức Năng 3.2: Quản Lý Môn Học (CRUD Chính & Ràng Buộc)
- [x] Màn hình danh sách môn học `SubjectListScreen` (`lib/screens/subject_list_screen.dart`):
  - Hiển thị danh sách thẻ môn học trực quan với huy hiệu mã môn, tên môn, số tín chỉ, giảng viên, mục tiêu học tuần.
  - Bộ lọc thông minh theo học kỳ (Semester Filter Chips: "Tất cả", "Học kỳ 1", "Học kỳ 2",...).
  - Thanh tìm kiếm realtime theo tên môn, mã môn, tên giảng viên.
  - Thẻ tóm tắt đầu trang: Tổng số môn học, tổng số tín chỉ tích lũy.
- [x] Màn hình thêm và sửa chi tiết môn học `SubjectFormScreen` (`lib/screens/subject_form_screen.dart`):
  - Nhập tên môn học, mã môn học (code), số tín chỉ (credits), giảng viên phụ trách (lecturer), học kỳ (semester).
  - Bảng chọn màu đại diện (Palette) và bộ chọn biểu tượng môn học (Icon Picker).
  - Thiết lập số giờ tự học mục tiêu hàng tuần (weeklyTargetHours) và form validation đầy đủ.
- [x] **Logic ràng buộc & Cascade Delete:**
  - Khi người dùng yêu cầu xóa môn học, hệ thống tự động kiểm tra số lượng bản ghi liên quan qua `getSubjectRelatedCounts(subjectId)`.
  - Nếu có dữ liệu liên kết (buổi học, bài tập, điểm số), hiển thị hộp thoại cảnh báo chi tiết về nguy cơ mất dữ liệu và yêu cầu xác nhận Cascade Delete.
  - Xóa sạch dữ liệu con phụ thuộc đồng thời trong SQLite và cập nhật in-memory state.

### 3. Chức Năng 3.4: Quản Lý Lịch Học & Thời Khóa Biểu
- [x] Model `Schedule` (`lib/models/schedule.dart`) với các phương thức xác định trạng thái buổi học (`ongoing`, `upcoming`, `completed`), tính toán thời lượng, quy đổi thứ trong tuần.
- [x] `ScheduleProvider` (`lib/providers/schedule_provider.dart`) quản lý trạng thái thời khóa biểu, nạp và lưu trữ trực tiếp với SQLite.
- [x] Màn hình thời khóa biểu `ScheduleScreen` (`lib/screens/schedule_screen.dart`):
  - **Chế độ xem theo ngày (Day View):** Thanh chọn thứ trong tuần (T2 - CN), highlight ngày hiện tại, timeline buổi học theo thứ tự giờ, gắn badge trạng thái "Đang diễn ra", "Sắp tới", "Đã xong".
  - **Chế độ xem theo tuần (Week View):** Hiển thị tổng quan toàn bộ các buổi học trong tuần theo từng ngày.
  - **Chức năng Thêm / Sửa / Xóa buổi học:** Form chọn môn học từ danh sách, chọn thứ, TimePicker chọn giờ học (validate giờ kết thúc > giờ bắt đầu), nhập phòng học, tòa nhà, ghi chú.
  - **Tìm kiếm môn học trực tiếp trong lịch học:** Realtime SearchBar tìm kiếm nhanh chóng theo tên môn, mã môn, phòng học hoặc giảng viên.
- [x] Tích hợp lối tắt thời khóa biểu và quản lý môn học ngay trên `HomeScreen`.

### 4. Chức Năng: Quản Lý Bài Tập & Hệ Thống Đề Thi Trắc Nghiệm Từ Word (Flow F1 & Flow F2)
- [x] **Mở rộng SQLite Schema:**
  - Bảng `questions` (id, assignment_id, question_number, content, passage, explanation, created_at, updated_at) ràng buộc `ON DELETE CASCADE`.
  - Bảng `choices` (id, question_id, label, content, is_correct) ràng buộc `ON DELETE CASCADE`.
  - Thêm phương thức Transaction nguyên tử: `saveExamWithTransaction`, `getQuestionsByAssignment`, `updateQuestionAndChoices`, `setCorrectChoice`, `deleteQuestion`, `insertQuestionWithChoices`.
- [x] **Flow F1: Tạo đề từ File Word (.docx) hoặc Dán Text thô (`WordImportScreen` & `WordParser`):**
  - Engine bóc tách Regex tự động (`lib/services/word_parser.dart`): Trích xuất tiêu đề đề thi, mã đề, thời gian làm bài, danh sách câu hỏi, các phương án lựa chọn A/B/C/D, lời giải/giải thích.
  - Hỗ trợ 3 cách nhận diện đáp án đúng:
    - Ký tự `*` cạnh phương án lựa chọn (ví dụ: `*A. Nội dung` hoặc `A*. Nội dung`).
    - Dòng đáp án riêng biệt (ví dụ: `Đáp án: B` hoặc `Answer: C`).
    - Bảng đáp án ở cuối đề thi (ví dụ: `BẢNG ĐÁP ÁN: 1.A 2.B 3.C`).
  - Giao diện Xem trước & Nhập đề (`lib/screens/word_import_screen.dart`): Upload file `.docx` (dùng `archive` để trích xuất XML và chuyển đổi sang văn bản sạch) hoặc dán text trực tiếp, chỉnh sửa nhanh thông tin đề, chọn môn học và hạn nộp, lưu toàn bộ vào SQLite bằng Transaction an toàn.
- [x] **Flow F2: Chỉnh Sửa Nội Dung Đề Thi (`AssignmentEditScreen`):**
  - Dropdown chọn đề thi cần chỉnh sửa trực tiếp từ CSDL.
  - Tải và render động danh sách câu hỏi cùng các phương án lựa chọn.
  - Cho phép sửa trực tiếp văn bản câu hỏi, đoạn văn dẫn (passage), nội dung từng lựa chọn, lời giải.
  - **Đổi đáp án đúng tức thì:** Sử dụng Radio button kèm hiệu ứng highlight nền xanh lá và huy hiệu "Đáp án đúng" (`AppColors.success`).
  - Nút thêm mới câu hỏi trắc nghiệm và nút xóa câu hỏi.
- [x] **Màn hình Quản Lý Bài Tập Toàn Diện (`AssignmentManagementScreen`):**
  - Danh sách bài tập với thanh tìm kiếm realtime và bộ lọc theo môn học (ChoiceChips).
  - Huy hiệu hiển thị số câu hỏi trắc nghiệm (`x câu`) nếu bài tập là đề thi trắc nghiệm.
  - Checkbox đánh dấu hoàn thành bài tập, PopupMenu thao tác nhanh (Chỉnh sửa câu hỏi, Đổi trạng thái, Xóa bài tập).
  - Nút thêm mới dạng Floating Action Button (FAB) mở Action Sheet cho phép chọn "Tạo từ file Word" hoặc "Thêm thủ công".
- [x] **Cải tiến Màn Hình Chính (`HomeScreen`):**
  - Thay thế mục "Môn học & Mục tiêu" thành mục **"Bài Tập"**.
  - Hiển thị danh sách nhiệm vụ/bài tập với checkbox hoàn thành, tên môn học kèm màu nhận diện, hạn nộp.
  - Nút "Quản lý" chuyển sang `AssignmentManagementScreen`, nút "+" mở menu tạo bài tập nhanh hoặc nhập đề Word.

### 5. Kiểm Thử Chất Lượng (Quality Assurance)
- [x] Bộ Unit Test chuyên biệt cho SQLite và Lịch học `test/database_and_schedule_test.dart` (9/9 passed).
- [x] Bộ Unit Test cho Regex Engine bóc tách đề thi `test/word_parser_test.dart` (6/6 passed).
- [x] Toàn bộ test suite dự án đạt **38/38 tests passed**.
- [x] Phân tích tĩnh mã nguồn `flutter analyze`: **No issues found!** (0 errors, 0 warnings).

---

## 📁 Sơ Đồ Cấu Trúc Dự Án

```text
STUDY-TRACKER/
├── docs/
│   ├── ARCHITECTURE_AND_SECURITY.md
│   └── GIT_FLOW_AND_TEAM_GUIDE.md
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_constants.dart
│   │   │   └── app_typography.dart
│   │   ├── database/
│   │   │   └── database_helper.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   └── security_service.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── theme_provider.dart
│   │   └── widgets/
│   │       ├── app_lock_wrapper.dart
│   │       ├── custom_button.dart
│   │       ├── custom_dialog.dart
│   │       └── custom_text_field.dart
│   ├── models/
│   │   ├── exam_question.dart
│   │   ├── grade_entry.dart
│   │   ├── schedule.dart
│   │   ├── study_session.dart
│   │   ├── study_task.dart
│   │   ├── subject.dart
│   │   └── user_model.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── cloud_sync_provider.dart
│   │   ├── pomodoro_provider.dart
│   │   ├── schedule_provider.dart
│   │   ├── security_provider.dart
│   │   └── study_provider.dart
│   ├── screens/
│   │   ├── assignment_edit_screen.dart
│   │   ├── assignment_management_screen.dart
│   │   ├── cloud_sync_screen.dart
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── main_navigation_screen.dart
│   │   ├── pin_lock_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── register_screen.dart
│   │   ├── schedule_screen.dart
│   │   ├── statistics_screen.dart
│   │   ├── subject_form_screen.dart
│   │   ├── subject_list_screen.dart
│   │   ├── tasks_screen.dart
│   │   └── word_import_screen.dart
│   ├── services/
│   │   ├── firebase_configuration.dart
│   │   └── word_parser.dart
│   ├── widgets/
│   │   ├── daily_stats_card.dart
│   │   ├── pomodoro_timer_widget.dart
│   │   └── subject_card.dart
│   └── main.dart
├── test/
│   ├── app_lock_test.dart
│   ├── architecture_services_test.dart
│   ├── auth_and_security_test.dart
│   ├── cloud_sync_test.dart
│   ├── database_and_schedule_test.dart
│   ├── pomodoro_provider_test.dart
│   ├── study_provider_test.dart
│   ├── widget_test.dart
│   └── word_parser_test.dart
├── COMPLETED_TASKS.md
└── README.md
```
