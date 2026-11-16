# In Mác Giá

App in mác giá cho cửa hàng potraviny, chạy trên Windows, in bằng máy in
nhãn nhiệt cuộn 80 mm. Nhập sản phẩm 1 lần, lưu lại dùng tiếp, in mác
dọc rộng 80 mm gắn thanh nẹp giá, dài tự theo nội dung, máy in tự cắt,
nhiều mẫu để chọn.

## Tính năng

- **Danh sách sản phẩm**: tên tiếng Séc, tên tiếng Anh, mã vạch EAN-13,
  giá, giá giảm + ngày hết hạn giảm giá, đơn vị (ks, kg, l...), khối
  lượng/dung tích để tính đơn giá (100 g / 1 kg). Hỗ trợ giá từ–đến
  (hiện dạng "70 – 100 Kč").
- **Máy in mặc định**: đặt máy in + cỡ giấy/mác mặc định 1 lần trong
  Cài đặt, lần sau bấm in là in thẳng, không hiện hộp thoại chọn máy
  in mỗi lần. Muốn đổi máy in 1 lần thì bấm "Chọn máy in khác" ở
  màn hình in.
- **Tìm nhanh**: gõ tên hoặc quét mã vạch là ra sản phẩm để in.
- **Dùng chung 2 cửa hàng**: danh sách sản phẩm đồng bộ cloud qua
  Firebase project gio-lam (đăng nhập ẩn danh), mất mạng vẫn dùng
  bình thường nhờ lưu local.
- **In hàng loạt**: tick nhiều sản phẩm, nhập số lượng từng loại, in
  1 lần. Xem trước đúng khổ thật trước khi in.
- **In dọc, khổ rộng chỉnh được**: mặc định rộng 80 mm, đổi trong
  Cài đặt. Chiều dài mác tự theo nội dung, máy in nhiệt tự cắt nên
  không cần nhập chiều cao.
- **8 mẫu mác** (chọn lúc in, app nhớ lựa chọn):
  1. Thường — tên to, giá lớn, mã vạch, đơn giá 100 g.
  2. Giảm giá — nhãn AKCE, giá cũ gạch ngang, giá mới to, ngày hết hạn.
  3. Gọn — chỉ tên và giá lớn, không mã vạch.
  4. Chỉ mã vạch — tên nhỏ, mã vạch to, số mã ở dưới.
  5. Song ngữ – Hiện đại — 2 tên song song, giá 1 lần to ở dưới.
  6. Song ngữ – Dải đen — dải đen chữ trắng, 2 tên song song, giá 1 lần to.
  7. Song ngữ – Cổ điển — chữ serif, khung đôi, giá 1 lần to ở dưới.
  8. Song ngữ – Nhẹ nhàng — mỗi dòng 1 ngôn ngữ kèm luôn giá của dòng đó.
     Tên dài thì bật công tắc "In ngang" ở màn hình in để xoay mẫu
     ngang 90°, tên vừa 1 dòng.
- **Chỉnh cỡ chữ theo từng mẫu** (70%–130%): tên hoặc giá dài thì thu
  nhỏ lại cho vừa 1 dòng. Kéo thanh trượt là xem trước đổi ngay, thả
  tay ra là app tự lưu để lần sau khỏi chỉnh lại.
- **Công tắc lúc in** (như phần mềm cũ): in chữ đậm, in chữ hoa,
  in cả mã vạch, in riêng mã vạch, in mác giá đang giảm giá, in ngày
  hết hạn giảm giá, in giá bình thường trên mác giá giảm giá,
  in giá không thuế. Công tắc "In chữ đậm" áp cho mọi chữ trên mác
  (số mã vạch, đơn giá, giá cũ, ngày hết hạn, tên tiếng Anh, dòng
  "/ks · /pc", cả 2 dòng mẫu Nhẹ nhàng); riêng số giá + chữ Kč
  trong khối giá lớn, tiêu đề "CENA / PRICE" và nhãn "AKCE" luôn
  đậm theo thiết kế.

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

1. **Mã API Firebase** đã điền sẵn trong `lib/firebase_options.dart`
   (dự án "gio-lam"). Chỉ cần làm lại bước này nếu đổi sang dự án
   Firebase khác: lấy mã ở Firebase Console > Cài đặt project
   (Project settings) > mục "Your apps" > app web > trường `apiKey`.
   Chưa có mã này thì app vẫn chạy bình thường, chỉ lưu trên máy.
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
- **Nhật ký khởi động**: app ghi lại các bước mở app và lỗi (nếu có)
  vào file `nhat-ky-khoi-dong.log` trong thư mục AppData (đường dẫn
  hiện trong Cài đặt). Nếu app mở không lên hoặc tự tắt, gửi file
  này cho người làm app để xem lỗi.
- **Chạy cùng app chấm công HTHSHOP**: 2 app dùng chung project
  Firebase gio-lam nên app này tắt bộ nhớ đệm Firestore trên máy
  (chỉ lưu local bằng file JSON) để tránh kẹt khóa file khi 2 app
  cùng chạy. Lỗi khởi động (cloud, lưu trữ) không làm app tắt —
  app vẫn mở offline và ghi nhật ký.
