# 📚 Study Tracker - Ứng Dụng Quản Lý Học Tập & Bảo Mật Cá Nhân

Ứng dụng di động theo dõi thời gian học tập, quản lý môn học, phương pháp Pomodoro và bảo mật thông tin cá nhân, được xây dựng trên nền tảng **Flutter 3.47.5** & **Dart 3.13.4**.

---

## 🌟 Giới Thiệu Dự Án

**Study Tracker** là giải pháp toàn diện hỗ trợ học sinh, sinh viên và người tự học thiết lập kỷ luật, theo dõi tiến độ học tập và tối ưu hóa thời gian mỗi ngày. Ứng dụng kết hợp phương pháp học tập khoa học (Pomodoro) với hệ thống báo cáo trực quan và cơ chế bảo mật nâng cao (Khóa mã PIN & Tự động khóa khi chạy ngầm).

---

## ✨ Các Tính Năng Đã Triển Khai

### 1. 🔐 Xác Thực Người Dùng & Hồ Sơ Cá Nhân (Auth & Profile - Chức năng 3.1)
- **Đăng ký tài khoản mới (`RegisterScreen`):** Kiểm tra định dạng email, mật khẩu tối thiểu 6 ký tự, xác nhận mật khẩu.
- **Đăng nhập (`LoginScreen`):** Đăng nhập nhanh với tài khoản cá nhân hoặc nút **"Dùng thử tài khoản Demo"** tiện lợi để trải nghiệm ngay.
- **Quản lý hồ sơ (`ProfileScreen`):** Hiển thị avatar ký tự viết tắt, thông tin tài khoản, ngày tham gia, chỉnh sửa tên hiển thị.
- **Đăng xuất an toàn:** Hộp thoại `CustomDialog.showConfirm` cảnh báo trước khi đăng xuất.

### 2. 🛡️ Cơ Chế Bảo Mật Ứng Dụng (Security - Chức năng 3.10)
- **Khóa ứng dụng bằng mã PIN (App Lock):** Mã PIN gồm 4 số được băm một chiều kèm chuỗi Salt bí mật (`Salted Hashing`) an toàn.
- **Bàn phím ảo chuyên dụng (`PinLockScreen`):** Giao diện Numpad cảm ứng mượt mà, hỗ trợ quy trình 2 bước khi thiết lập/đổi PIN.
- **Tự động khóa màn hình khi app chạy ngầm (Background Auto-Lock):** Giám sát trạng thái vòng đời ứng dụng qua `WidgetsBindingObserver`. Khi người dùng ẩn app hoặc chuyển ứng dụng, hệ thống lập tức khóa lại để bảo vệ thông tin học tập.

### 3. 🎨 Kiến Trúc Nền Tảng & Hệ Thống Thiết Kế (Base Architecture & Design System)
- **Kiến trúc Feature-first kết hợp Core-shared:** Tách bạch rõ ràng `core/`, `models/`, `providers/`, `screens/`, `widgets/`.
- **Hệ thống bảng màu (`AppColors`) & Typography (`AppTypography`):** Hỗ trợ đầy đủ **Light Mode** & **Dark Mode**.
- **Chuyển đổi giao diện linh hoạt:** Cho phép chọn giữa Sáng, Tối hoặc Tự động theo hệ điều hành qua `ThemeProvider`.
- **Bộ UI Components dùng chung:** `CustomButton`, `CustomTextField`, `CustomDialog`, `AppLockWrapper`.

### 4. ⏱️ Đồng Hồ Pomodoro & Thống Kê Học Tập
- **Phương pháp Pomodoro:** 25 phút tập trung, 5 phút nghỉ ngắn, 15 phút nghỉ dài.
- **Biểu đồ thống kê:** Trực quan hóa dữ liệu học tập trong tuần với `fl_chart`.
- **Quản lý danh sách nhiệm vụ (Tasks):** Thêm, đánh dấu hoàn thành, phân loại việc cần làm kèm hạn nộp.

---

## 📖 Tài Liệu Hướng Dẫn Kỹ Thuật

- 🏛️ [Tài liệu Kiến trúc Nền tảng & Cơ chế Bảo mật](docs/ARCHITECTURE_AND_SECURITY.md)
- 🚀 [Chiến lược Phân nhánh Git Flow & Hướng dẫn Nhóm](docs/GIT_FLOW_AND_TEAM_GUIDE.md)
- 📋 [Báo cáo Công việc Đã hoàn thành](COMPLETED_TASKS.md)

---

## 📂 Sơ Đồ Cấu Trúc Thư Mục

```text
STUDY-TRACKER/
├── docs/                                # Tài liệu kỹ thuật & quản lý dự án
│   ├── ARCHITECTURE_AND_SECURITY.md
│   └── GIT_FLOW_AND_TEAM_GUIDE.md
├── lib/
│   ├── core/                            # Nền tảng dùng chung
│   │   ├── constants/                   # Colors, Typography, Constants
│   │   ├── services/                    # AuthService, SecurityService
│   │   ├── theme/                       # AppTheme, ThemeProvider
│   │   └── widgets/                     # CustomButton, CustomTextField, CustomDialog, AppLockWrapper
│   ├── models/                          # Data Models
│   ├── providers/                       # State Management (Provider)
│   ├── screens/                         # Màn hình (Login, Register, Profile, PinLock, Home, ...)
│   ├── widgets/                         # Các widget nghiệp vụ
│   └── main.dart                        # MultiProvider & Entrypoint
├── test/
│   ├── auth_and_security_test.dart      # Unit tests cho Auth & Security
│   └── widget_test.dart                 # Widget tests
├── pubspec.yaml
└── README.md
```

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

1. **Clone dự án:**
   ```bash
   git clone https://github.com/nguyenquochung130425/STUDY-TRACKER.git
   cd STUDY-TRACKER
   ```

2. **Cài đặt thư viện:**
   ```bash
   flutter pub get
   ```

3. **Chạy kiểm thử & phân tích mã nguồn:**
   ```bash
   flutter analyze   # Đạt: No issues found!
   flutter test      # Đạt: All tests passed! (5/5 tests)
   ```

4. **Khởi chạy ứng dụng:**
   ```bash
   flutter run
   ```

---

## 🔑 Tài Khoản Demo Mặc Định
- **Email:** `demo@studytracker.com`
- **Mật khẩu:** `password123`
*(Hoặc nhấn nút "Dùng thử tài khoản Demo" trên màn hình Đăng nhập để trải nghiệm ngay).*
