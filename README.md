# In Mác Giá

App in mác giá cho cửa hàng potraviny, chạy trên Windows, in bằng máy in
nhãn nhiệt cuộn 80 mm. Nhập sản phẩm 1 lần, lưu lại dùng tiếp, in mác
80×30 mm gắn thanh nẹp giá, nhiều mẫu để chọn.

## Tính năng

- **Danh sách sản phẩm**: tên tiếng Séc, tên tiếng Anh, mã vạch EAN-13,
  giá, giá giảm + ngày hết hạn giảm giá, đơn vị (ks, kg, l...), khối
  lượng/dung tích để tính đơn giá (100 g / 1 kg). Hỗ trợ giá từ–đến
  (ví dụ từ 70 đến 100 Kč).
- **Tìm nhanh**: gõ tên hoặc quét mã vạch là ra sản phẩm để in.
- **Dùng chung 2 cửa hàng**: danh sách sản phẩm đồng bộ cloud qua
  Firebase project gio-lam (đăng nhập ẩn danh), mất mạng vẫn dùng
  bình thường nhờ lưu local.
- **In hàng loạt**: tick nhiều sản phẩm, nhập số lượng từng loại, in
  1 lần. Xem trước đúng khổ thật trước khi in.
- **Khổ mác chỉnh được**: mặc định 80×30 mm, đổi trong Cài đặt.
- **8 mẫu mác** (chọn lúc in, app nhớ lựa chọn):
  1. Thường — tên to, giá lớn, mã vạch, đơn giá 100 g.
  2. Giảm giá — nhãn AKCE, giá cũ gạch ngang, giá mới to, ngày hết hạn.
  3. Gọn — chỉ tên và giá lớn, không mã vạch.
  4. Chỉ mã vạch — tên nhỏ, mã vạch to, số mã ở dưới.
  5. Song ngữ – Hiện đại — 2 tên song song, giá 1 lần to ở dưới.
  6. Song ngữ – Dải đen — dải đen chữ trắng, 2 tên song song, giá 1 lần to.
  7. Song ngữ – Cổ điển — chữ serif, khung đôi, giá 1 lần to ở dưới.
  8. Song ngữ – Nhẹ nhàng — mỗi dòng 1 ngôn ngữ kèm luôn giá của dòng đó.
- **Chỉnh cỡ chữ theo từng mẫu** (70%–130%): tên hoặc giá dài thì thu
  nhỏ lại cho vừa 1 dòng. Kéo thanh trượt là xem trước đổi ngay, thả
  tay ra là app tự lưu để lần sau khỏi chỉnh lại.
- **Công tắc lúc in** (như phần mềm cũ): in chữ đậm, in chữ hoa,
  in cả mã vạch, in riêng mã vạch, in mác giá đang giảm giá, in ngày
  hết hạn giảm giá, in giá bình thường trên mác giá giảm giá,
  in giá không thuế.

## Chạy app

```bat
flutter pub get
flutter run -d windows
```

Build bản cài (chạy trên GitHub Actions, xem workflow của repo):

```bat
flutter build windows --release --dart-define=APP_BUILD_NUMBER=<số bản>
```

## Bật đồng bộ cloud (làm 1 lần)

1. **Dán mã API Firebase** vào `lib/firebase_options.dart` (chỗ `apiKey`
   đang để trống). Lấy mã ở Firebase Console > Cài đặt project
   (Project settings) > mục "Your apps" > app web "gio-lam-windows" >
   trường `apiKey`. Chưa có mã này thì app vẫn chạy bình thường, chỉ
   lưu trên máy.
2. **Bật đăng nhập ẩn danh**: Firebase Console > Authentication >
   Sign-in method > bật "Anonymous".
3. **Thêm rule Firestore**: mở file `firestore.rules` ở gốc repo,
   ghép phần collection `cenovky_products` vào rule hiện có rồi dán
   vào Firebase Console > Firestore Database > Rules > Publish.

## Ghi chú

- Font chữ Liberation Sans/Serif đóng gói trong app (giấy phép SIL Open
  Font License) để in đúng dấu tiếng Séc (č, ř, ž, š, ě...) cả khi
  máy offline.
- Mã vạch EAN-13 vẽ thật (tính đúng số kiểm tra, quét được). Nhập 12
  số thì app tự thêm số kiểm tra thành 13 số.
- Dữ liệu local lưu trong thư mục AppData của app
  (`san-pham.json`, `cai-dat.json`).
