# 🚀 Quy Trình Phân Nhánh Git (Git Flow) & Hướng Dẫn Làm Việc Nhóm

- **Dự án:** Study Tracker
- **Kho lưu trữ:** [https://github.com/nguyenquochung130425/STUDY-TRACKER.git](https://github.com/nguyenquochung130425/STUDY-TRACKER.git)
- **Người thiết lập:** Quản lý dự án / Trưởng nhóm
- **Phiên bản:** 1.0.0
- **Ngày ban hành:** 12/10/2026

---

## 1. 🌿 Chiến Lược Phân Nhánh (Branching Strategy: Git Flow)

Toàn bộ các thành viên trong nhóm thống nhất tuân thủ mô hình phân nhánh Git Flow chuẩn công nghiệp:

```text
main (Nhánh chính thức, chỉ chứa phiên bản ổn định)
  ↑
develop (Nhánh tích hợp tính năng chung của nhóm)
  ↑
  ├── feature/auth-security       (Quản lý dự án, Base Architecture, Auth & Security PIN)
  ├── feature/pomodoro-timer      (Thành viên 2: Đồng hồ đếm ngược Pomodoro & Logic phiên)
  ├── feature/study-statistics    (Thành viên 3: Biểu đồ thời gian & Lịch sử học)
  └── feature/task-management     (Thành viên 4: Quản lý danh sách việc cần làm)
```

### Chi tiết các nhánh:
1. **`main`**:
   - Nhánh phản ánh phiên bản phát hành chính thức (Release).
   - Tuyệt đối **không được push code trực tiếp** lên nhánh `main`.
   - Chỉ được merge từ `develop` sau khi đã kiểm thử toàn diện.

2. **`develop`**:
   - Nhánh môi trường tích hợp (Integration branch).
   - Nơi tập hợp toàn bộ các tính năng từ các nhánh con `feature/*`.

3. **`feature/*`**:
   - Mỗi thành viên tạo nhánh riêng biệt từ `develop` để code tính năng được phân công.
   - Định dạng đặt tên nhánh:
     - `feature/auth-security`
     - `feature/pomodoro-timer`
     - `feature/study-statistics`
     - `feature/task-management`

4. **`hotfix/*`**:
   - Dùng để khắc phục sự cố khẩn cấp trên nhánh `main` khi có lỗi phát sinh nghiêm trọng.

---

## 2. 📝 Quy Ước Đặt Tên Commit (Conventional Commits)

Để lịch sử Git sạch đẹp và thuận tiện theo dõi tiến độ, toàn nhóm bắt buộc sử dụng tiền tố theo chuẩn:

| Tiền tố | Mục đích sử dụng | Ví dụ |
| :--- | :--- | :--- |
| `feat:` | Thêm tính năng mới | `feat: implement PIN lock screen with numpad` |
| `fix:` | Sửa lỗi chương trình | `fix: correct PIN verification hash logic` |
| `docs:` | Cập nhật tài liệu kỹ thuật | `docs: add Git Flow guide and architecture document` |
| `style:` | Chỉnh sửa giao diện, theme, CSS/layout | `style: update dark mode colors and card borders` |
| `refactor:` | Tái cấu trúc mã nguồn (không đổi tính năng) | `refactor: extract CustomButton into core widgets` |
| `test:` | Thêm mới hoặc cập nhật unit/widget test | `test: add unit tests for AuthService and SecurityProvider` |

---

## 3. 🔄 Quy Trình Làm Việc Hằng Ngày & Tạo Pull Request (PR)

### Bước 1: Cập nhật nhánh trước khi code
Trước khi bắt đầu làm việc, luôn pull code mới nhất từ `develop`:
```bash
git checkout develop
git pull origin develop
git checkout feature/<ten-tinh-nang-cua-ban>
git merge develop
```

### Bước 2: Commit và Push lên GitHub
```bash
git add .
git commit -m "feat: mo ta ngan gon cong viec da hoan thanh"
git push origin feature/<ten-tinh-nang-cua-ban>
```

### Bước 3: Kiểm tra chất lượng cục bộ trước khi tạo PR
Trước khi tạo PR, thành viên **bắt buộc** chạy 2 lệnh sau trong terminal:
```bash
flutter analyze  # Phải đạt: No issues found!
flutter test     # Phải đạt: All tests passed!
```

### Bước 4: Tạo Pull Request (PR) & Review Code
- Mở Pull Request từ `feature/<ten-tinh-nang>` vào `develop`.
- Người quản lý dự án (Trưởng nhóm) sẽ tiến hành review:
  1. Đảm bảo tuân thủ Design System (`AppColors`, `CustomButton`, `CustomTextField`).
  2. Không làm phá vỡ các tính năng sẵn có.
  3. Tất cả bài test đều vượt qua.
- Sau khi được phê duyệt (Approved), tiến hành merge vào `develop`.

---

## 4. 📊 Bảng Phân Công Nhiệm Vụ & Kiểm Soát Tiến Độ (Project Progress Tracking)

| STT | Thành viên phụ trách | Nhánh Git | Nhiệm vụ chính | Trạng thái |
| :---: | :--- | :--- | :--- | :---: |
| **1** | **Quản lý dự án (Bạn)** | `feature/auth-security` | - Base Architecture & Design System (Theme, Colors, Typography)<br>- Các Component dùng chung (Button, TextField, Dialog)<br>- Chức năng 3.1: Đăng ký, Đăng nhập, Quản lý hồ sơ (Profile)<br>- Chức năng 3.10: Khóa ứng dụng mã PIN & Tự động khóa khi chạy ngầm<br>- Quản lý dự án, tài liệu & Git Flow | **100% Hoàn thành** |
| **2** | Thành viên 2 | `feature/pomodoro-timer` | - Logic đồng hồ Pomodoro (25p tập trung, 5p nghỉ)<br>- Lưu phiên học tự động khi hoàn thành<br>- Widget đếm ngược và chọn môn học | **100% Hoàn thành** |
| **3** | Thành viên 3 | `feature/study-statistics` | - Thống kê số giờ học theo ngày, tuần, chuỗi ngày streak<br>- Biểu đồ cột tương tác `fl_chart`<br>- Lịch sử các phiên học gần nhất | **100% Hoàn thành** |
| **4** | Thành viên 4 | `feature/task-management` | - Quản lý việc cần làm (Study Tasks)<br>- Đánh dấu hoàn thành, phân loại theo trạng thái<br>- Hộp thoại thêm nhiệm vụ kèm Deadline | **100% Hoàn thành** |
