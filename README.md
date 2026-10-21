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

---

## 📄 Giấy phép (License)

Dự án được phân phối dưới giấy phép [MIT License](LICENSE). Xem tệp [LICENSE](file:///d:/STUDY%20TRACKER/LICENSE) để biết thêm chi tiết.
