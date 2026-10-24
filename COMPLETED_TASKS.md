# 📋 Báo Cáo Công Việc Đã Hoàn Thành - Study Tracker

- **Dự án:** Study Tracker (Ứng dụng di động theo dõi thời gian học tập & quản lý môn học)
- **Kho lưu trữ:** [https://github.com/nguyenquochung130425/STUDY-TRACKER.git](https://github.com/nguyenquochung130425/STUDY-TRACKER.git)
- **Nhánh chính:** `main` | **Nhánh phát triển:** `develop` | **Nhánh chức năng:** `feature/auth-security`
- **Công nghệ nền tảng:** Flutter 3.47.5 & Dart 3.13.4
 feature/auth-security
- **Cập nhật ngày:** 12/10/2026

- **Cập nhật ngày:** 21/10/2026
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
│   │   ├── grade_entry.dart
│   │   ├── study_session.dart
│   │   ├── study_task.dart
│   │   ├── subject.dart
│   │   └── user_model.dart
│   ├── providers/feature/auth-security
│   │   ├── auth_provider.dart
│   │   ├── cloud_sync_provider.dart
 main
│   │   ├── pomodoro_provider.dart
│   │   ├── security_provider.dart
│   │   └── study_provider.dart
│   ├── screens/
│   │   ├── cloud_sync_screen.dart
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── main_navigation_screen.dart
│   │   ├── pin_lock_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── register_screen.dart
│   │   ├── statistics_screen.dart
│   │   └── tasks_screen.dart
│   ├── services/
│   │   └── firebase_configuration.dart
│   ├── widgets/
│   │   ├── daily_stats_card.dart
│   │   ├── pomodoro_timer_widget.dart
│   │   └── subject_card.dart
│   └── main.dart
├── test/
│   ├── auth_and_security_test.dart
│   └── widget_test.dart
├── COMPLETED_TASKS.md
└── README.md
```
 feature/auth-security


---

## 📌 Lịch Sử Commit

1. `04b2549` - `Initial commit`
2. `85bb8e1` - `docs: update README with project overview and architecture`
3. `b6ec0a7` - `feat: initialize Flutter project template for study_tracker`
4. `25b0467` - `feat: add models, providers, widgets, Pomodoro timer, and screens`

---

## 🚀 Kế Hoạch Tiếp Theo (Roadmap)
- [ ] Tích hợp thông báo đẩy nội bộ (`flutter_local_notifications`) khi hết giờ Pomodoro.
- [ ] Tùy chỉnh độ dài thời gian tập trung & thời gian nghỉ theo ý thích người dùng.
- [x] Triển khai Cloud Sync Engine qua Firebase (cần cấu hình Firebase project để sử dụng).
- [ ] Xuất báo cáo học tập định dạng PDF / Excel.
 main
