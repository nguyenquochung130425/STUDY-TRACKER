# Git Flow cho Study Tracker

## Branch model

- `main`: production-ready code, protected branch.
- `develop`: active integration branch for new features.
- `feature/<short-name>`: each feature is developed in a dedicated branch.
- `bugfix/<short-name>`: fix for non-critical bugs.
- `hotfix/<short-name>`: urgent fix for production issues.
- `release/<version>`: prep before final release.

## Khởi tạo và bảo vệ nhánh trên GitHub

Quy trình Git Flow mới chỉ được mô tả trong repository; nhánh bảo vệ và quyền
review phải được bật trong GitHub repository settings. Không thể thiết lập các
quyền này chỉ bằng code trong repository.

1. Tạo `develop` một lần từ `main`, sau khi xác nhận `main` đang ổn định:

   ```bash
   git switch main
   git pull origin main
   git switch -c develop
   git push -u origin develop
   ```

2. Trong **Settings → Branches**, tạo ruleset cho `main` và `develop`:
   - yêu cầu pull request trước khi merge;
   - yêu cầu ít nhất một approval;
   - yêu cầu status check `analyze-and-test` thành công;
   - chặn force-push và xóa nhánh.
3. Trong **Settings → Rules → Rulesets** (hoặc Branch protection rules tùy giao
   diện), đặt `develop` làm nhánh mặc định nếu team muốn áp dụng luồng Git Flow.
4. Tạo GitHub Project dạng board với các cột `Backlog`, `Ready`, `In progress`,
   `Review`, `Done`; liên kết issue và PR để theo dõi tiến độ.

## Quy tắc làm việc

1. Tạo branch mới từ `develop` cho mỗi tính năng hoặc sửa lỗi.
2. Mỗi PR phải đến `develop` hoặc `release/*` tùy trường hợp.
3. Không trực tiếp push vào `main` và `develop` mà không có PR.
4. Mỗi PR cần có mô tả rõ: mục tiêu, thay đổi, kiểm thử và ảnh hưởng.
5. Reviewer phải xác nhận và merge bằng GitHub UI hoặc git merge --no-ff.
6. Release branch chỉ được tạo khi bản dựng sẵn sàng ra mắt.

Đặt tên commit theo dạng `feat:`, `fix:`, `docs:`, `test:` hoặc `refactor:`.
Mỗi issue nên có người phụ trách, mức ưu tiên, tiêu chí nghiệm thu và liên kết
đến PR.

## Ví dụ luồng làm việc

```bash
git checkout develop
git pull origin develop
git checkout -b feature/study-dashboard
git add .
git commit -m "feat: add study dashboard"
git push -u origin feature/study-dashboard
```

Sau đó tạo Pull Request về `develop` và yêu cầu review.

## Tiêu chí hoàn thành

Một task được đóng khi:
- code đã được review,
- tests và analyzer đã chạy thành công,
- PR đã được merge,
- release notes nếu cần đã được cập nhật.
