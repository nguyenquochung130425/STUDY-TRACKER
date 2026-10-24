# Architecture & Cloud Sync responsibilities

## 1) Kiến trúc & Xác thực (Architecture & Auth)

### Mục tiêu
- Tạo base architecture rõ ràng cho app.
- Tách `core` khỏi `features`.
- Quản lý authentication và bảo mật theo một layer riêng.

### Các lớp chính
- `core/theme`: màu, typography, theme.
- `core/widgets`: các widget dùng chung.
- `features/auth`: logic xác thực, giao tiếp với FirebaseAuth.
- `features/app_lock`: PIN cục bộ, lưu bằng secure storage và tự khóa khi app
  chuyển khỏi trạng thái active.
- `features/cloud_sync`: quy trình sync dữ liệu và chuẩn hóa dữ liệu remote/local.
- `features/analytics`: tổng hợp số liệu học tập, tiến độ và thống kê.

### Nguyên tắc bảo mật
- Không lưu secret hoặc API key trực tiếp vào source code.
- Tất cả cấu hình Firebase phải được truyền qua `--dart-define-from-file`.
- `StudyAuthService` là ranh giới gọi Firebase Authentication, được dùng bởi
  `CloudSyncProvider` thay vì để giao diện gọi Firebase trực tiếp.
- Đăng ký email gửi thư xác minh; đặt lại mật khẩu qua Firebase Auth.
- Đồng bộ Firestore bị chặn cho đến khi email được xác minh.
- Firestore rules trong `firestore.rules` chỉ cho phép chủ tài khoản truy cập
  các collection hỗ trợ và kiểm tra cấu trúc bản ghi.
- Firebase quản lý vòng đời token/session; không lưu mật khẩu hoặc refresh token
  trong `SharedPreferences`.
- App Lock PIN hoàn toàn tách khỏi Firebase Auth: PIN chỉ mở khóa giao diện trên
  thiết bị, không đăng nhập tài khoản, không thay thế Firestore rules và không
  được gửi lên Firebase.
- Khóa ứng dụng được bật/tắt tại màn hình khóa PIN từ trang Home. Khi ứng dụng
  xuống nền hoặc mất trạng thái active, Flutter phủ màn hình khóa; lúc khởi động
  lại, PIN được yêu cầu nếu tính năng đang bật.
- Sau 5 lần nhập sai liên tiếp, mở khóa tạm ngưng 30 giây; các lần khóa tiếp
  theo tăng dần, tối đa 15 phút. Trạng thái này được lưu trong secure storage để
  không bị đặt lại chỉ bằng cách khởi động ứng dụng.
- Trên web, PIN chỉ là lớp che giao diện phía client; người dùng kiểm soát
  trình duyệt nên không thể xem đây là ranh giới bảo mật dữ liệu.

### Việc cần hoàn tất tại môi trường triển khai
- Bật Email/Password và Google provider trong Firebase Console.
- Triển khai `firestore.rules` bằng Firebase CLI và xác minh trên Firebase
  Emulator Suite trước khi đưa lên production.
- Bật branch protection/ruleset và tạo Project board trong GitHub Settings;
  các quyền repository này không thể được áp dụng chỉ bằng commit code.

## 2) Phân tích dữ liệu & Đồng bộ đám mây (Analytics & Cloud Sync)

### Mục tiêu
- Tổng hợp thời gian học, tiến độ môn học, chuỗi học tập và điểm số.
- Đồng bộ dữ liệu offline-first từ local storage sang Firestore.
- Khi user offline, app vẫn làm việc bình thường và tự đồng bộ khi có mạng.

### Quy trình sync
1. Load dữ liệu local từ `StudyProvider`.
2. Đọc dữ liệu remote từ Firestore theo collection `subjects`, `sessions`, `tasks`, `grades`.
3. So sánh `updatedAt` và dấu xóa (`deletions`).
4. Merge dữ liệu theo thời điểm cập nhật.
5. Ghi lại dữ liệu mới hoặc xóa các bản ghi không còn hợp lệ.

### Mục tiêu KPI
- Tổng thời gian học trong ngày / tuần.
- Tỷ lệ hoàn thành mục tiêu của từng môn.
- Chuỗi ngày học liên tục.
- Điểm trung bình có trọng số.
- Xác định thời điểm cần sync và xử lý conflict.

### Trạng thái trong code
- `CloudSyncProvider` điều phối Firebase auth state, connectivity và sync.
- `CloudSyncService` được gọi để quyết định ghi record cục bộ lên cloud.
- `StudyAnalyticsService` tổng hợp thời gian, streak, tiến độ tuần và điểm có
  trọng số; có unit tests riêng cho các phép tính.
