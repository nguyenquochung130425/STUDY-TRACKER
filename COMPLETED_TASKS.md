# 📋 Báo Cáo Công Việc Đã Hoàn Thành - Study Tracker

- **Dự án:** Study Tracker (Ứng dụng di động theo dõi thời gian học tập & quản lý môn học)
- **Kho lưu trữ:** [https://github.com/nguyenquochung130425/STUDY-TRACKER.git](https://github.com/nguyenquochung130425/STUDY-TRACKER.git)
- **Nhánh chính:** `main`
- **Công nghệ nền tảng:** Flutter 3.47.5 & Dart 3.13.4
- **Cập nhật ngày:** 11/10/2026

---

## ✅ Danh Mục Công Việc Đã Thực Hiện

### 1. Khởi tạo & Cấu hình Repository
- [x] Clone mã nguồn từ GitHub về thư mục làm việc cục bộ.
- [x] Cấu hình loại trừ các tệp IDE (`.idea/`, `*.iml`, `.metadata`) vào tệp `.gitignore`.
- [x] Biên soạn tài liệu chi tiết `README.md` bằng Tiếng Việt (mô tả tính năng, kiến trúc thư mục, công nghệ và hướng dẫn cài đặt).
- [x] Khởi tạo khung dự án Flutter `study_tracker` hỗ trợ đa nền tảng (Android, iOS, Web, Windows Desktop).

### 2. Quản lý Thư viện & Phụ thuộc (`pubspec.yaml`)
- [x] `provider: ^6.1.5+1`: Quản lý trạng thái và luồng dữ liệu ứng dụng.
- [x] `intl: ^0.20.3`: Định dạng hiển thị ngày tháng, giờ và số liệu.
- [x] `fl_chart: ^1.2.0`: Hiển thị biểu đồ cột thống kê thời gian học tập trong tuần.
- [x] `shared_preferences: ^2.5.6`: Lưu trữ cục bộ dữ liệu môn học, phiên học và nhiệm vụ.

### 3. Thiết kế & Triển khai Models (`lib/models/`)
- [x] `subject.dart`: Model quản lý thông tin môn học (ID, tên, mã màu, icon, mục tiêu giờ học hàng tuần).
- [x] `study_session.dart`: Model lưu trữ phiên học đã hoàn thành (môn học, thời lượng, thời gian hoàn thành, chế độ học).
- [x] `study_task.dart`: Model quản lý nhiệm vụ, bài tập cần làm kèm hạn nộp (Deadline) và trạng thái hoàn thành.

### 4. Triển khai Logic & Quản lý Trạng thái (`lib/providers/`)
- [x] `study_provider.dart`:
  - Đọc/ghi dữ liệu tự động với `SharedPreferences` dưới định dạng JSON.
  - Cung cấp sẵn các môn học mẫu ban đầu (Toán học, Lập trình, Tiếng Anh, Khoa học).
  - Tính toán số liệu thống kê: tổng thời gian học hôm nay, tuần này, chuỗi ngày liên tục (streak), thời gian học từng môn.
  - Xử lý thêm/sửa/xóa môn học, thêm phiên học, thêm/hoàn thành/xóa nhiệm vụ.
  - Tính mảng 7 ngày trong tuần cho biểu đồ `fl_chart`.
- [x] `pomodoro_provider.dart`:
  - Đồng hồ đếm ngược với 3 chế độ: **Tập trung** (25 phút), **Nghỉ ngắn** (5 phút), **Nghỉ dài** (15 phút sau mỗi 4 chu kỳ).
  - Tự động lưu phiên học vào `StudyProvider` khi hoàn thành phiên tập trung.
  - Đầy đủ các thao tác: Bắt đầu, Tạm dừng, Đặt lại (Reset), Bỏ qua (Skip).

### 5. Xây dựng Giao diện Người dùng (`lib/screens/` & `lib/widgets/`)
- [x] `pomodoro_timer_widget.dart`: Vòng tròn tiến độ trực quan, bộ đếm mm:ss, menu chọn môn học cần học, các nút điều khiển.
- [x] `daily_stats_card.dart`: Thẻ thống kê 3 chỉ số nhanh trong ngày (thời gian học hôm nay, số phiên Pomodoro, chuỗi ngày streak).
- [x] `subject_card.dart`: Thẻ môn học kèm thanh tiến độ % hoàn thành mục tiêu học tập theo tuần.
- [x] `home_screen.dart`: Màn hình trang chủ tích hợp thẻ thống kê, đồng hồ Pomodoro, danh sách môn học và hộp thoại thêm môn học mới.
- [x] `statistics_screen.dart`: Màn hình thống kê với biểu đồ cột thời gian học từng ngày trong tuần và lịch sử các phiên học gần nhất.
- [x] `tasks_screen.dart`: Màn hình quản lý danh sách việc cần làm, phân loại Đang làm / Đã hoàn thành, hộp thoại thêm việc mới.
- [x] `main_navigation_screen.dart`: Thanh điều hướng `NavigationBar` chuẩn Material 3 chuyển đổi mượt mà giữa 3 màn hình.
- [x] `main.dart`: Thiết lập `MultiProvider`, cấu hình chủ đề giao diện Sáng/Tối (Light & Dark Theme).

### 6. Kiểm thử & Đồng bộ Git
- [x] Chạy phân tích tĩnh `flutter analyze`: **No issues found** (0 warnings, 0 errors).
- [x] Chạy kiểm thử tự động `flutter test`: Toàn bộ test case trong `test/widget_test.dart` vượt qua thành công (**All tests passed**).
- [x] Lưu các commit có cấu trúc vào Git local.
- [x] Push toàn bộ mã nguồn lên kho chứa từ xa `origin/main` trên GitHub.

---

## 📁 Sơ Đồ Cấu Trúc Tệp Tin Dự Án

```text
STUDY TRACKER/
├── lib/
│   ├── models/
│   │   ├── study_session.dart
│   │   ├── study_task.dart
│   │   └── subject.dart
│   ├── providers/
│   │   ├── pomodoro_provider.dart
│   │   └── study_provider.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── main_navigation_screen.dart
│   │   ├── statistics_screen.dart
│   │   └── tasks_screen.dart
│   ├── widgets/
│   │   ├── daily_stats_card.dart
│   │   ├── pomodoro_timer_widget.dart
│   │   └── subject_card.dart
│   └── main.dart
├── test/
│   └── widget_test.dart
├── .gitignore
├── COMPLETED_TASKS.md
├── LICENSE
├── pubspec.yaml
└── README.md
```

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
- [ ] Đồng bộ hóa dữ liệu trực tuyến (Cloud Sync qua Firebase / Supabase).
- [ ] Xuất báo cáo học tập định dạng PDF / Excel.
