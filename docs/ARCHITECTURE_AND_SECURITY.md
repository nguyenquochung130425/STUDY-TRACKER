# 🏛️ Tài Liệu Kiến Trúc Nền Tảng & Cơ Chế Bảo Mật (Architecture & Security)

- **Dự án:** Study Tracker
- **Vai trò phụ trách:** Quản lý dự án, Thiết kế kiến trúc chung, Phụ trách Xác thực (Auth) & Bảo mật (Security)
- **Phiên bản:** 1.1.0
- **Ngày cập nhật:** 12/10/2026

---

## 1. 🏗️ Kiến Trúc Nền Tảng (Base Architecture)

Dự án áp dụng mô hình **Feature-first kết hợp Core-shared Architecture**, phân tách rõ ràng giữa các thành phần dùng chung và các tính năng nghiệp vụ.

### Sơ đồ cấu trúc thư mục `lib/`:

```text
lib/
├── core/                                # Nền tảng dùng chung cho toàn bộ dự án
│   ├── constants/                       # Hằng số, màu sắc, font chữ
│   │   ├── app_colors.dart              # Bảng màu chuẩn Light & Dark
│   │   ├── app_constants.dart           # Key SharedPreferences, cấu hình PIN
│   │   └── app_typography.dart          # Kiểu chữ Material 3
│   ├── services/                        # Dịch vụ hạ tầng & bảo mật
│   │   ├── auth_service.dart            # Xác thực, lưu trữ tài khoản, session
│   │   └── security_service.dart        # Băm mã PIN (Salted Hash), lưu khóa
│   ├── theme/                           # Cấu hình giao diện hệ thống
│   │   ├── app_theme.dart               # ThemeData (Light/Dark Mode)
│   │   └── theme_provider.dart          # Quản lý đổi chủ đề giao diện
│   └── widgets/                         # Các UI Components tái sử dụng
│       ├── app_lock_wrapper.dart        # Bộ bọc kiểm soát vòng đời app & khóa ngầm
│       ├── custom_button.dart           # Button chuẩn (Primary, Secondary, Outline, Danger)
│       ├── custom_dialog.dart           # Dialog thông báo, xác nhận hành động nguy hiểm
│       └── custom_text_field.dart       # Ô nhập dữ liệu, toggle hiển thị mật khẩu
├── models/                              # Data Models
│   ├── study_session.dart               # Dữ liệu phiên học
│   ├── study_task.dart                  # Dữ liệu việc cần làm (Task)
│   ├── subject.dart                     # Dữ liệu môn học
│   └── user_model.dart                  # Dữ liệu người dùng (Họ tên, email, ngày tạo)
├── providers/                           # State Management (Provider Pattern)
│   ├── auth_provider.dart               # Trạng thái đăng nhập, hồ sơ người dùng
│   ├── pomodoro_provider.dart           # Logic đồng hồ Pomodoro
│   ├── security_provider.dart           # Logic khóa App, mã PIN, tự động khóa
│   └── study_provider.dart              # Quản lý môn học, phiên học, nhiệm vụ
├── screens/                             # Màn hình giao diện người dùng
│   ├── home_screen.dart                 # Màn hình chính (Đồng hồ, thẻ nhanh)
│   ├── login_screen.dart                # Màn hình đăng nhập tài khoản
│   ├── main_navigation_screen.dart      # Thanh điều hướng 4 Tab (Học tập, Thống kê, Nhiệm vụ, Hồ sơ)
│   ├── pin_lock_screen.dart             # Màn hình nhập / đổi mã PIN (Numpad)
│   ├── profile_screen.dart              # Màn hình hồ sơ cá nhân & cài đặt bảo mật
│   ├── register_screen.dart             # Màn hình đăng ký tài khoản mới
│   ├── statistics_screen.dart           # Thống kê biểu đồ học tập
│   └── tasks_screen.dart                # Quản lý danh sách việc cần làm
├── widgets/                             # Widget nghiệp vụ chuyên biệt
│   ├── daily_stats_card.dart
│   ├── pomodoro_timer_widget.dart
│   └── subject_card.dart
└── main.dart                            # Điểm khởi chạy MultiProvider & AppLockWrapper
```

---

## 2. 🎨 Hệ Thống Bảng Màu & Typography (Design System)

### Bảng màu (`AppColors`):
- **Primary Color:** `#4F46E5` (Indigo) - Màu thương hiệu đại diện cho sự tập trung và tri thức.
- **Secondary Color:** `#0D9488` (Teal) - Màu nhấn sinh động.
- **Semantic Colors:**
  - Success: `#10B981` (Xanh lá - Hoàn thành nhiệm vụ/phiên học).
  - Warning: `#F59E0B` (Vàng cam - Nghỉ ngơi/Deadline gần).
  - Error/Danger: `#EF4444` (Đỏ - Nhập sai PIN, xóa môn học, đăng xuất).
- **Hỗ trợ toàn diện 2 giao diện:** Light Mode (`#F8FAFC`) và Dark Mode (`#0F172A`).
- **Chuyển đổi giao diện linh hoạt:** Quản lý thông qua `ThemeProvider` với 3 chế độ: Theo hệ điều hành, Luôn sáng, Luôn tối.

### Typography (`AppTypography`):
Định nghĩa hệ thống cấp bậc chuẩn Material 3:
- `displayLarge` (32px, bold): Tiêu đề chính.
- `titleLarge` (20px, w600): Tiêu đề phần tử thẻ/thanh điều hướng.
- `bodyLarge` / `bodyMedium`: Văn bản nội dung và chú thích rõ ràng.
- `labelLarge` (14px, w600): Chữ trên nút bấm và thẻ chức năng.

---

## 3. 🧩 Các Thành Phần Dùng Chung (Reusable Components)

Toàn bộ thành viên trong nhóm thống nhất sử dụng các Widget dùng chung trong `lib/core/widgets/`:

| Thành phần | Đường dẫn | Đặc tính kỹ thuật |
| :--- | :--- | :--- |
| **`CustomButton`** | `lib/core/widgets/custom_button.dart` | 5 biến thể: `primary`, `secondary`, `outline`, `text`, `danger`. Hỗ trợ trạng thái tải `isLoading`, icon, vô hiệu hóa tự động. |
| **`CustomTextField`** | `lib/core/widgets/custom_text_field.dart` | Tích hợp sẵn icon trước/sau, nút bấm ẩn/hiện mật khẩu dạng icon mắt, validation chuẩn FormState. |
| **`CustomDialog`** | `lib/core/widgets/custom_dialog.dart` | `CustomDialog.showConfirm()` xác nhận các thao tác quan trọng (Đăng xuất, xóa dữ liệu); `CustomDialog.showAlert()` hiển thị thông báo. |

---

## 4. 🔐 Chức Năng 3.1 & 3.10: Xác Thực & Bảo Mật

### 4.1. Luồng Xác Thực (Authentication Flow)
- **Đăng ký (`RegisterScreen`):** Kiểm tra tính hợp lệ của email (Regex), mật khẩu tối thiểu 6 ký tự, kiểm tra trùng khớp mật khẩu. Lưu trữ cục bộ an toàn và đồng bộ vào `SharedPreferences`.
- **Đăng nhập (`LoginScreen`):** Kiểm tra thông tin đăng nhập, hỗ trợ nút "Dùng thử tài khoản Demo" giúp chấm điểm và trải nghiệm tính năng tức thời mà không cần đăng ký.
- **Hồ sơ cá nhân (`ProfileScreen`):** Hiển thị avatar ký tự viết tắt, họ tên, email, ngày tham gia; cho phép cập nhật thông tin cá nhân.
- **Sẵn sàng tích hợp Backend:** Lớp `AuthService` được thiết kế theo Interface Pattern, sẵn sàng thay thế tầng lưu trữ cục bộ bằng Firebase Auth SDK hoặc REST API Backend bất cứ lúc nào mà không làm ảnh hưởng đến tầng giao diện.

### 4.2. Cơ Chế Khóa Ứng Dụng Bằng Mã PIN (App Lock)
- **Mã PIN chuẩn 4 số:** Nhập qua giao diện bàn phím số số ảo (Numpad) chuyên dụng `PinLockScreen` với phản hồi thị giác (PIN dots chuyển màu).
- **Mã hóa một chiều có Salt (Salted Hashing):** Mã PIN không bao giờ được lưu trữ dưới dạng văn bản gốc (plain text). `SecurityService` thực hiện trộn chuỗi muối bí mật `StudyTracker_Secure_Salt_2026` và băm đa tầng trước khi ghi vào bộ nhớ máy.
- **2 Chế độ hoạt động:**
  - `PinLockMode.unlock`: Bắt buộc nhập đúng mã PIN để vào ứng dụng.
  - `PinLockMode.setup`: Xác thực 2 bước (Nhập lần 1 -> Xác nhận lần 2) để kích hoạt hoặc đổi PIN.

### 4.3. Cơ Chế Tự Động Khóa Khi Chạy Ngầm (Background Auto-Lock)
- **Cơ chế triển khai:** Ứng dụng tích hợp `AppLockWrapper` ở cấp cao nhất bao bọc toàn bộ widget tree, thực thi `WidgetsBindingObserver`.
- **Bắt sự kiện vòng đời (Lifecycle):**
  - Khi ứng dụng chuyển sang trạng thái `AppLifecycleState.paused` hoặc `AppLifecycleState.inactive` (người dùng bấm phím Home, khóa máy, hoặc vuốt chuyển sang ứng dụng khác), `SecurityProvider` lập tức kích hoạt `lockApp()`.
  - Khi người dùng quay trở lại (`AppLifecycleState.resumed`), `AppLockWrapper` lập tức che giao diện bằng `PinLockScreen`, ngăn chặn hoàn toàn việc xem trộm dữ liệu học tập cá nhân.
- **Tùy biến người dùng:** Người dùng có thể tùy ý bật/tắt tính năng "Tự động khóa khi chạy ngầm" ngay trong màn hình `ProfileScreen`.
