# Hướng Dẫn Quy Trình Làm Việc Với Git & Nhánh `nexus`

Tài liệu này hướng dẫn chi tiết cách phát triển tính năng mới trên nhánh **`nexus`** thuộc bản fork của bạn, đảm bảo code độc lập với repository gốc và cách đồng bộ cập nhật từ tác giả khi cần.

---

## 1. Cấu Hình Remote Hiện Tại

Kiểm tra cấu hình remote trong dự án:
```powershell
git remote -v
```

* **`origin`**: `https://github.com/duynguyentdmu/WAZE-HUD-ES3C28P-S3`  
  *(Repository fork cá nhân của bạn trên GitHub - nơi bạn toàn quyền push/pull code)*
* **`upstream`**: `https://github.com/haint14/Waze-Hud-ES3C28P-S3.git`  
  *(Repository gốc của tác giả - chỉ dùng để tải về/cập nhật bản vá và tính năng mới)*

---

## 2. Lần Đầu Tiên Đẩy Nhánh `nexus` Lên GitHub

Vì nhánh `nexus` hiện mới chỉ có ở máy tính cục bộ (local), bạn cần đẩy nhánh này lên repo GitHub của mình:

```powershell
# 1. Đảm bảo bạn đang đứng ở nhánh nexus
git checkout nexus

# 2. Đẩy nhánh nexus lên origin và thiết lập liên kết theo dõi (tracking)
git push -u origin nexus
```

> **Ghi chú về cờ `-u` (`--set-upstream`):**  
> Lệnh này chỉ cần chạy **1 lần duy nhất** lúc khởi tạo nhánh trên GitHub. Nó giúp Git ghi nhớ rằng nhánh `nexus` ở máy tính gắn liền với nhánh `origin/nexus`.

---

## 3. Quy Trình Làm Việc & Push Code Hàng Ngày

Khi bạn code tính năng mới, chỉnh sửa giao diện hoặc sửa lỗi:

### Bước 1: Kiểm tra trạng thái các file đã thay đổi
```powershell
git status
```

### Bước 2: Thêm các thay đổi vào danh sách chuẩn bị lưu (Staging)
```powershell
# Thêm tất cả thay đổi
git add .

# Hoặc chỉ thêm các file cụ thể:
# git add waze-hud/main/display/hud_renderer.cpp
```

### Bước 3: Tạo commit lưu lại trạng thái
```powershell
git commit -m "feat: mo ta ngan gon ve tinh nang vua lam"
```

### Bước 4: Đẩy code lên GitHub
Nhờ đã thiết lập `-u` ở bước trước, bạn chỉ cần gõ:
```powershell
git push
```
*(Code sẽ được đẩy thẳng lên `https://github.com/duynguyentdmu/WAZE-HUD-ES3C28P-S3/tree/nexus`)*

---

## 4. Cách Nhận Code Mới Nhất Từ Tác Giả Gốc (`upstream`)

Khi tác giả gốc (`haint14`) cập nhật các bản sửa lỗi hoặc tính năng mới trên nhánh `ES3C28P-S3`, bạn có thể kéo về nhánh `nexus` của mình theo các bước:

### Cách nhanh: Gộp trực tiếp vào nhánh `nexus`
```powershell
# 1. Đứng ở nhánh nexus
git checkout nexus

# 2. Tải toàn bộ thay đổi mới nhất từ upstream
git fetch upstream

# 3. Gộp cập nhật của tác giả vào nhánh nexus của bạn
git merge upstream/ES3C28P-S3

# 4. Đẩy nhánh nexus đã tích hợp code mới lên GitHub của bạn
git push
```

### Cách tiêu chuẩn: Giữ nhánh `ES3C28P-S3` luôn đồng bộ với gốc
```powershell
# 1. Chuyển sang nhánh ES3C28P-S3
git checkout ES3C28P-S3

# 2. Kéo code mới từ tác giả về
git pull upstream ES3C28P-S3

# 3. Đẩy lên nhánh ES3C28P-S3 trên GitHub của bạn để đồng bộ
git push origin ES3C28P-S3

# 4. Quay lại nhánh nexus và gộp code mới vào
git checkout nexus
git merge ES3C28P-S3
git push origin nexus
```

---

## 5. Những Nguyên Tắc & Lưu Ý An Toàn

1. **Tuyệt đối không push vào `upstream`:**  
   Chỉ dùng lệnh `git push` hoặc `git push origin ...`. Không bao giờ gõ `git push upstream ...`.
2. **Không bấm tạo "Pull Request" trên giao diện Web:**  
   Sau khi push nhánh `nexus` lên GitHub, web có thể hiện gợi ý màu xanh *"Compare & pull request"*. Hãy bỏ qua nó nếu bạn không muốn gửi code sang repo của tác giả.
3. **Không commit file build nhị phân (.bin, .elf):**  
   Các thư mục build (`build/`, `dist/`) và firmware `.bin` nên được giữ trong `.gitignore` để tránh làm nặng repository.

