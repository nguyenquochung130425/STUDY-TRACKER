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

 feature/auth-security
### 2. 🛡️ Cơ Chế Bảo Mật Ứng Dụng (Security - Chức năng 3.10)
- **Khóa ứng dụng bằng mã PIN (App Lock):** Mã PIN gồm 4 số được băm một chiều kèm chuỗi Salt bí mật (`Salted Hashing`) an toàn.
- **Bàn phím ảo chuyên dụng (`PinLockScreen`):** Giao diện Numpad cảm ứng mượt mà, hỗ trợ quy trình 2 bước khi thiết lập/đổi PIN.
- **Tự động khóa màn hình khi app chạy ngầm (Background Auto-Lock):** Giám sát trạng thái vòng đời ứng dụng qua `WidgetsBindingObserver`. Khi người dùng ẩn app hoặc chuyển ứng dụng, hệ thống lập tức khóa lại để bảo vệ thông tin học tập.

### 3. 🎨 Kiến Trúc Nền Tảng & Hệ Thống Thiết Kế (Base Architecture & Design System)
- **Kiến trúc Feature-first kết hợp Core-shared:** Tách bạch rõ ràng `core/`, `models/`, `providers/`, `screens/`, `widgets/`.
- **Hệ thống bảng màu (`AppColors`) & Typography (`AppTypography`):** Hỗ trợ đầy đủ **Light Mode** & **Dark Mode**.
- **Chuyển đổi giao diện linh hoạt:** Cho phép chọn giữa Sáng, Tối hoặc Tự động theo hệ điều hành qua `ThemeProvider`.
- **Bộ UI Components dùng chung:** `CustomButton`, `CustomTextField`, `CustomDialog`, `AppLockWrapper`.

- 📖 **Quản lý môn học & Mục tiêu**
  - Thêm, sửa, xóa môn học với màu sắc và biểu tượng nhận diện riêng biệt.
  - Thiết lập mục tiêu học tập hàng tuần và theo dõi thời lượng, tỷ lệ hoàn thành theo từng môn.

- 📊 **Thống kê & Báo cáo trực quan**
  - Tổng hợp thời lượng và số phiên học trong tuần, biểu đồ thời gian học theo từng ngày trong tuần.
  - Xem lịch sử phiên học gần đây và tiến độ mục tiêu của từng môn.
  - Quản lý đầu điểm: thêm, sửa, xóa; tính điểm trung bình có trọng số trên thang 10 và xem biểu đồ điểm.
  - Theo dõi chuỗi ngày học liên tục (Study Streak). main

### 4. ⏱️ Đồng Hồ Pomodoro & Thống Kê Học Tập
- **Phương pháp Pomodoro:** 25 phút tập trung, 5 phút nghỉ ngắn, 15 phút nghỉ dài.
- **Biểu đồ thống kê:** Trực quan hóa dữ liệu học tập trong tuần với `fl_chart`.
- **Quản lý danh sách nhiệm vụ (Tasks):** Thêm, đánh dấu hoàn thành, phân loại việc cần làm kèm hạn nộp.

- ☁️ **Đồng bộ dữ liệu đám mây**
  - Đăng ký/đăng nhập bằng email và Google khi đã cấu hình Firebase.
  - Đồng bộ môn học, phiên học, nhiệm vụ và điểm với Firestore; dữ liệu vẫn được lưu cục bộ khi offline.

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

 feature/auth-security
4. **Khởi chạy ứng dụng:**
   ```bash
   flutter run
   ```
### Cấu hình Firebase cho Cloud Sync

Cloud Sync cần một Firebase project riêng. Khi chưa cấu hình, ứng dụng vẫn hoạt
động và lưu dữ liệu cục bộ; đăng nhập và đồng bộ cloud sẽ không khả dụng.

1. Tạo project tại [Firebase Console](https://console.firebase.google.com/) và
   thêm ứng dụng cho từng nền tảng cần chạy (Android, iOS, Web hoặc macOS).
2. Trong **Authentication → Sign-in method**, bật **Email/Password**. Có thể bật
   thêm **Google** để dùng đăng nhập Google trên Web, Android và iOS.
3. Tạo Firestore database. Trong **Firestore → Rules**, giới hạn mỗi người dùng
   chỉ đọc/ghi dữ liệu trong đường dẫn của chính họ:

   ```text
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null
                            && request.auth.uid == userId;
       }
     }
   }
   ```

4. Sao chép [firebase_config.example.json](./firebase_config.example.json) thành
   `firebase_config.json` ở thư mục gốc. Điền giá trị từ phần cài đặt ứng dụng
   trong Firebase Console:
   - Các giá trị chung: API key, Project ID, Messaging Sender ID và Storage
     bucket (nếu project có bucket).
   - Web: Web App ID và Auth domain.
   - Android: Android App ID; package name phải khớp với ứng dụng Android.
   - iOS: iOS App ID và Bundle ID; Bundle ID phải khớp với ứng dụng iOS.
   - macOS: MacOS App ID.

   Chỉ điền các trường của nền tảng bạn sử dụng. `firebase_config.json` đã được
   thêm vào `.gitignore`; không commit tệp cấu hình cục bộ hoặc service-account
   key/private key vào Git.

5. Chạy ứng dụng từ thư mục gốc để truyền cấu hình lúc build:

   ```powershell
   flutter run --dart-define-from-file=firebase_config.json
   ```

   Dùng cùng tùy chọn `--dart-define-from-file=firebase_config.json` khi build
   ứng dụng. Nếu thiếu cấu hình bắt buộc cho nền tảng hiện tại, màn hình Cloud
   Sync sẽ thông báo; sau khi đăng nhập, dữ liệu môn học, phiên học, nhiệm vụ và
   điểm sẽ đồng bộ với Firestore.

---

## 🗺️ Lộ trình phát triển (Roadmap)

- [x] Khởi tạo kho mã nguồn và tài liệu dự án
- [ ] Thiết lập kiến trúc mã nguồn Flutter (Clean Architecture)
- [ ] Xây dựng màn hình Home & Đồng hồ đếm giờ Pomodoro
- [ ] Quản lý môn học và lưu trữ dữ liệu phiên học cục bộ
- [ ] Màn hình thống kê biểu đồ trực quan
- [x] Quản lý đầu điểm và thống kê điểm trung bình có trọng số (lưu cục bộ)
- [ ] Quản lý danh sách nhiệm vụ & deadline
- [x] Quản lý điểm số, trung bình có trọng số và biểu đồ điểm
- [x] Theo dõi tiến độ mục tiêu, thống kê tuần và biểu đồ học tập
- [x] Triển khai Cloud Sync Engine với Firebase Authentication và Firestore
- [x] Cấu hình Firebase Web project riêng để sử dụng đồng bộ cloud thực tế
- [ ] Cấu hình App ID Firebase cho Android/iOS/macOS nếu cần triển khai các nền tảng này
 main

---

## 🔑 Tài Khoản Demo Mặc Định
- **Email:** `demo@studytracker.com`
- **Mật khẩu:** `password123`
*(Hoặc nhấn nút "Dùng thử tài khoản Demo" trên màn hình Đăng nhập để trải nghiệm ngay).*
