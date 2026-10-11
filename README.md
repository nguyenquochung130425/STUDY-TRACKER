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
  - Thiết lập mục tiêu học tập theo ngày, tuần hoặc tháng (ví dụ: 10 giờ/tuần cho môn Toán).
  - Theo dõi tỷ lệ phần trăm hoàn thành mục tiêu.

- 📊 **Thống kê & Báo cáo trực quan**
  - Biểu đồ thời gian học theo ngày, tuần, tháng và năm.
  - Phân tích tỷ trọng thời gian giữa các môn học.
  - Đánh giá chuỗi ngày học tập liên tục (Study Streak) tạo động lực duy trì thói quen.

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

---

## 🗺️ Lộ trình phát triển (Roadmap)

- [x] Khởi tạo kho mã nguồn và tài liệu dự án
- [ ] Thiết lập kiến trúc mã nguồn Flutter (Clean Architecture)
- [ ] Xây dựng màn hình Home & Đồng hồ đếm giờ Pomodoro
- [ ] Quản lý môn học và lưu trữ dữ liệu phiên học cục bộ
- [ ] Màn hình thống kê biểu đồ trực quan
- [ ] Quản lý danh sách nhiệm vụ & deadline
- [ ] Đồng bộ dữ liệu đám mây (Cloud Backup qua Firebase/Supabase)

---

## 📄 Giấy phép (License)

Dự án được phân phối dưới giấy phép [MIT License](LICENSE). Xem tệp [LICENSE](file:///d:/STUDY%20TRACKER/LICENSE) để biết thêm chi tiết.
