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
   Trong phần password policy, đặt tối thiểu 8 ký tự để khớp với kiểm tra đăng ký
   trong ứng dụng.
3. Tạo Firestore database. Repository có sẵn [firestore.rules](./firestore.rules)
   để chỉ cho phép người dùng truy cập dữ liệu của chính họ và kiểm tra cấu trúc
   bản ghi. Đăng nhập Firebase CLI rồi triển khai rules từ thư mục gốc:

   ```powershell
   firebase login
   firebase deploy --only firestore:rules --project YOUR_FIREBASE_PROJECT_ID
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

5. Chạy ứng dụng từ thư mục gốc để truyền cấu hình lúc build. Có thể dùng lệnh
   trực tiếp hoặc chạy script tiện ích dưới thư mục `scripts/`:

   ```powershell
   flutter run --dart-define-from-file=firebase_config.json
   ```

   hoặc

   ```powershell
   ./scripts/run_with_firebase.ps1
   ```

   Script này sẽ kiểm tra xem `firebase_config.json` đã tồn tại chưa và quay lại
   hướng dẫn nếu thiếu thông tin cấu hình. Dùng cùng tùy chọn
   `--dart-define-from-file=firebase_config.json` khi build ứng dụng. Nếu thiếu
   cấu hình bắt buộc cho nền tảng hiện tại, màn hình Cloud Sync sẽ thông báo;
   sau khi đăng nhập, dữ liệu môn học, phiên học, nhiệm vụ và điểm sẽ đồng bộ
   với Firestore.

---

## 🧱 Kiến trúc nền tảng & Git Flow

Dự án đang chuyển dần sang `Feature-first`, dùng `core` cho thành phần dùng chung
và các feature service cho nghiệp vụ mới. Đây là kiến trúc chuyển tiếp: một số
màn hình và provider cũ vẫn nằm ở thư mục gốc `screens/` và `providers/`.

```text
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_theme.dart
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       └── app_dialog.dart
├── features/
│   ├── auth/
│   │   └── auth_service.dart
│   ├── analytics/
│   └── cloud_sync/
│       └── cloud_sync_service.dart
├── models/
├── providers/
├── screens/
├── services/
├── widgets/
└── main.dart
```

Các nguyên tắc hiện tại:
- `core/theme`: định nghĩa màu sắc, typography và theme Light/Dark.
- `core/widgets`: thành phần dùng chung như button, text field, dialog.
- `features`: tách service theo nghiệp vụ; Auth service đã được nối vào provider.
- `screens`, `providers`, `services`: phần legacy đang được chuyển dần, chưa phải Clean Architecture hoàn chỉnh.
- `main.dart`: bootstrap, cấu hình Firebase và đăng ký Provider.

### Trạng thái các hạng mục trong yêu cầu

| Hạng mục | Trạng thái |
|---|---|
| Provider, theme Light/Dark, bảng màu, typography | Đã cấu hình và app đang sử dụng |
| Button, text field, dialog dùng chung | Đã có; button và text field được dùng trong luồng Auth |
| Firebase Auth (đăng ký/đăng nhập email và Google) | Xác thực danh tính tài khoản với Firebase qua `StudyAuthService` |
| Bảo vệ tài khoản Firebase | Đặt lại mật khẩu, xác minh email; chỉ tài khoản đã xác minh mới đồng bộ cloud |
| Flutter App Lock (PIN 6 số, tự khóa khi app không còn active) | Lưu bằng secure storage trên thiết bị; là khóa giao diện cục bộ, không phải Firebase Auth |
| Firestore security rules | Có file triển khai; team cần deploy vào Firebase project |
| Git Flow, PR template, issue template, CI | Có trong repository |
| Branch protection / GitHub Project board | Cần bật/tạo trong GitHub Settings theo [docs/git-flow.md](./docs/git-flow.md) |

### Sử dụng khóa PIN trong Flutter

1. Mở ứng dụng và nhấn biểu tượng khóa ở màn hình Home.
2. Tạo PIN 6 chữ số và xác nhận để bật App Lock.
3. Khi mở lại ứng dụng hoặc ứng dụng chuyển khỏi trạng thái active, nhập PIN để
   tiếp tục. Dùng màn hình này để đổi hoặc tắt PIN; cần PIN hiện tại để đổi/tắt.

PIN được lưu bằng `flutter_secure_storage` trên thiết bị, tách biệt với Firebase
Auth. Nếu quên PIN, hiện chưa có chức năng khôi phục PIN; cần gỡ dữ liệu ứng dụng
để xóa thông tin cục bộ và có thể mất dữ liệu local chưa đồng bộ. Hãy đồng bộ
trước khi xóa dữ liệu. Sau 5 lần nhập sai liên tiếp, chức năng mở khóa tạm khóa
trong 30 giây; các lần khóa tiếp theo tăng dần thời gian chờ, tối đa 15 phút.
Trên web, App Lock chỉ bảo vệ giao diện phía client và không thay thế Firestore
rules.

### Git Flow cho cả nhóm

Chi tiết kiến trúc, auth, analytics và sync được mô tả trong [docs/architecture-and-cloud-sync.md](./docs/architecture-and-cloud-sync.md).

Để quản lý nhóm hiệu quả, nên dùng branch model sau:

- `main`: nhánh production ổn định.
- `develop`: nhánh tích hợp tính năng mới.
- `feature/<name>`: phát triển tính năng riêng.
- `bugfix/<name>`: sửa lỗi không release.
- `hotfix/<name>`: sửa lỗi khẩn cấp trên main.
- `release/<version>`: chuẩn bị release.

Quy tắc bắt buộc:
- Mỗi tính năng phải mở pull request về `develop`.
- Mỗi PR cần review bởi ít nhất 1 người.
- Mỗi bug fix cần có mô tả rõ: nguyên nhân, ảnh hưởng, cách kiểm tra.
- Không trực tiếp commit lên `main` nếu chưa có review.

Chi tiết đầy đủ về mô hình branch, thiết lập quyền nhánh trên GitHub và tiêu chí hoàn thành có trong [docs/git-flow.md](./docs/git-flow.md). Template PR chuẩn nằm ở [.github/pull_request_template.md](./.github/pull_request_template.md), template task ở [.github/ISSUE_TEMPLATE/task.md](./.github/ISSUE_TEMPLATE/task.md), và CI tự động check analyzer/test ở [.github/workflows/flutter_ci.yml](./.github/workflows/flutter_ci.yml).

---

## 🗺️ Lộ trình phát triển (Roadmap)

- [x] Khởi tạo kho mã nguồn và tài liệu dự án
- [x] Thiết lập kiến trúc mã nguồn Flutter (Base Architecture với `core/theme` và reusable widgets)
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
