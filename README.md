# 📚 Study Tracker

Ứng dụng di động theo dõi thời gian học tập, quản lý môn học và nâng cao hiệu suất cá nhân, được xây dựng trên nền tảng **Flutter** & **Dart**.

---

## 🌟 Giới thiệu

**Study Tracker** là công cụ đắc lực hỗ trợ học sinh, sinh viên và người tự học thiết lập kỷ luật, theo dõi tiến độ học tập và tối ưu hóa thời gian mỗi ngày. Ứng dụng kết hợp phương pháp học tập khoa học (Pomodoro) với hệ thống báo cáo trực quan giúp bạn nắm bắt rõ ràng mức độ tập trung và sự tiến bộ của bản thân.

---

## ✨ Tính năng nổi bật

- ⏱️ **Đồng hồ bấm giờ & Phương pháp Pomodoro**
  - Đồng hồ đếm xuôi (Stopwatch) và đếm ngược (Countdown) cho từng phiên học.
  - Chế độ Pomodoro chuẩn khoa học: 25 phút tập trung, 5 phút nghỉ ngắn, nghỉ dài sau 4 chu kỳ.
  - Ghi nhận tự động thời gian thực tế đã học vào lịch sử.

- 📖 **Quản lý môn học & Mục tiêu**
  - Thêm, sửa, xóa môn học với màu sắc và biểu tượng nhận diện riêng biệt.
  - Thiết lập mục tiêu học tập hàng tuần và theo dõi thời lượng, tỷ lệ hoàn thành theo từng môn.

- 📊 **Thống kê & Báo cáo trực quan**
  - Tổng hợp thời lượng và số phiên học trong tuần, biểu đồ thời gian học theo từng ngày trong tuần.
  - Xem lịch sử phiên học gần đây và tiến độ mục tiêu của từng môn.
  - Quản lý đầu điểm: thêm, sửa, xóa; tính điểm trung bình có trọng số trên thang 10 và xem biểu đồ điểm.
  - Theo dõi chuỗi ngày học liên tục (Study Streak).

- 📝 **Quản lý nhiệm vụ (Tasks & To-Do)**
  - Lên danh sách bài tập, đồ án cùng hạn nộp (Deadline).
  - Phân loại nhiệm vụ theo mức độ ưu tiên và môn học liên quan.

- 🔔 **Nhắc nhở & Thông báo**
  - Tự động thông báo nhắc nhở khi đến giờ học đã lên lịch.
  - Thông báo động viên duy trì chuỗi học tập hàng ngày.

- 🎨 **Giao diện & Trải nghiệm người dùng**
  - Thiết kế hiện đại theo chuẩn Material 3.
  - Hỗ trợ chế độ Sáng / Tối (Light Mode & Dark Mode).
  - Hoạt động mượt mà cả khi không có kết nối mạng (Offline-first).

- ☁️ **Đồng bộ dữ liệu đám mây**
  - Đăng ký/đăng nhập bằng email và Google khi đã cấu hình Firebase.
  - Đồng bộ môn học, phiên học, nhiệm vụ và điểm với Firestore; dữ liệu vẫn được lưu cục bộ khi offline.

---

## 🛠️ Công nghệ sử dụng

| Thành phần | Công nghệ / Thư viện đề xuất |
| :--- | :--- |
| **Nền tảng** | [Flutter](https://flutter.dev/) (Dart SDK >= 3.0) |
| **Quản lý trạng thái (State)** | `provider` / `flutter_riverpod` / `flutter_bloc` |
| **Cơ sở dữ liệu cục bộ** | `hive` / `isar` / `sqflite` |
| **Biểu đồ thống kê** | `fl_chart` |
| **Lưu cấu hình nhẹ** | `shared_preferences` |
| **Thông báo nội bộ** | `flutter_local_notifications` |

---

## 📂 Cấu trúc thư mục dự kiến

```text
study_tracker/
├── lib/
│   ├── core/                  # Tiện ích dùng chung, hằng số, chủ đề giao diện (Theme)
│   │   ├── constants/         # Màu sắc, chuỗi ký tự, kích thước
│   │   ├── theme/             # Cấu hình Light/Dark Theme
│   │   └── utils/             # Hàm tiện ích (định dạng ngày giờ, chuyển đổi dữ liệu)
│   ├── data/                  # Xử lý dữ liệu & lưu trữ
│   │   ├── models/            # Model: Subject, Session, Task, Goal
│   │   ├── providers/         # Database helper (Hive / SQLite)
│   │   └── repositories/      # Kho chứa dữ liệu trừu tượng
│   ├── logic/                 # Quản lý logic nghiệp vụ và trạng thái (State Management)
│   │   ├── timer/             # Logic đếm giờ, chu kỳ Pomodoro
│   │   ├── subject/           # Logic môn học
│   │   └── analytics/         # Logic tổng hợp số liệu
│   ├── presentation/          # Giao diện người dùng (UI)
│   │   ├── screens/           # Các màn hình chính (Home, Timer, Statistics, Tasks, Settings)
│   │   └── widgets/           # Các widget tái sử dụng (TimerCard, SubjectTile, ChartView, ...)
│   └── main.dart              # Điểm khởi chạy ứng dụng
├── assets/                    # Hình ảnh, biểu tượng, phông chữ
├── test/                      # Unit test & Widget test
├── pubspec.yaml               # Danh sách thư viện và cấu hình dự án
└── README.md
```

---

## 🚀 Hướng dẫn cài đặt & Khởi chạy

### Yêu cầu tiên quyết
- Đã cài đặt [Flutter SDK](https://docs.flutter.dev/get-started/install) (phiên bản `>= 3.10.0`).
- Đã cấu hình Android Studio, Xcode (nếu dùng macOS) hoặc VS Code với Flutter Extension.

### Các bước thực hiện

1. **Clone dự án về máy:**
   ```bash
   git clone https://github.com/nguyenquochung130425/STUDY-TRACKER.git
   cd "STUDY TRACKER"
   ```

2. **Cài đặt các gói phụ thuộc (Dependencies):**
   ```bash
   flutter pub get
   ```

3. **Chạy ứng dụng:**
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

---

## 📄 Giấy phép (License)

Dự án được phân phối dưới giấy phép [MIT License](LICENSE). Xem tệp [LICENSE](file:///d:/STUDY%20TRACKER/LICENSE) để biết thêm chi tiết.
