# Glow-up Tracker (Flutter)

Ứng dụng cá nhân theo dõi **tập luyện, dinh dưỡng, giấc ngủ, chăm sóc da, chăm sóc tóc và ngân sách**.
Toàn bộ dữ liệu lưu **cục bộ trên máy** — không có backend, không đăng nhập, không analytics.

> Ứng dụng chỉ hỗ trợ theo dõi thói quen và thông tin bạn đã xác nhận, **không thay thế bác sĩ**.

---

## 1. Yêu cầu

- Flutter **3.22 trở lên** (Dart ≥ 3.4). Kiểm tra: `flutter --version`
- Android Studio / Xcode / Visual Studio tùy nền tảng muốn chạy.

## 2. Cài đặt & chạy

Thư mục này chỉ chứa `lib/`, `test/` và `pubspec.yaml`. Lần đầu cần sinh các thư mục nền tảng (android, ios, windows…):

```bash
cd glowup_flutter
flutter create . --project-name glowup_tracker --org com.glowup --platforms=android,ios,windows,macos,linux
flutter pub get
flutter run            # chọn thiết bị khi được hỏi
```

`flutter create .` **không ghi đè** các file đã có (`lib/`, `pubspec.yaml`, `test/widget_test.dart`).

Kiểm thử logic:

```bash
flutter test
```

Build bản phát hành Android:

```bash
flutter build apk --release
```

### Cấu hình thêm theo nền tảng

**iOS** — thêm vào `ios/Runner/Info.plist` (để chụp/chọn ảnh):

```xml
<key>NSCameraUsageDescription</key>
<string>Chụp ảnh da/tóc để theo dõi tiến triển (ảnh chỉ lưu trên máy).</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Chọn ảnh da/tóc để theo dõi tiến triển (ảnh chỉ lưu trên máy).</string>
```

**macOS** — thêm vào `macos/Runner/DebugProfile.entitlements` và `Release.entitlements`
(để lưu/mở file sao lưu và chọn ảnh):

```xml
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

**Android** — không cần cấu hình thêm (dùng trình chọn ảnh hệ thống).

**Web** — chạy được nhưng không hỗ trợ lưu ảnh; nên dùng Android/iOS/desktop.

## 3. Cấu trúc thư mục

```
lib/
├── main.dart                 # Khởi động, nạp dữ liệu
├── app.dart                  # Theme sáng/tối, điều hướng (thanh dưới trên điện thoại, rail trên desktop)
├── models/models.dart        # Kiểu dữ liệu + toJson/fromJson
├── data/defaults.dart        # Dữ liệu khởi tạo: nhiệm vụ, lịch, bài tập, thực đơn, thông tin đơn cũ
├── logic/
│   ├── date_utils.dart       # Ngày địa phương 'yyyy-MM-dd', tuần/tháng, thời lượng ngủ
│   ├── format.dart           # VNĐ, số, %, uid
│   └── logic.dart            # Nghiệp vụ: tiến độ, chuỗi, kcal/protein, báo cáo, tuân thủ thuốc
├── services/storage_service.dart  # SharedPreferences (JSON) + file ảnh, xuất/nhập/sao lưu
├── state/app_state.dart      # ChangeNotifier + InheritedNotifier, tự lưu sau mỗi thay đổi
├── widgets/                  # Thành phần dùng chung, biểu đồ tự vẽ, ảnh, thuốc, routine
└── pages/                    # Dashboard, Lịch trình, Tập luyện, Dinh dưỡng, Giấc ngủ,
                              # Da, Tóc, Báo cáo, Ngân sách, Cài đặt, Onboarding, Nhiệm vụ
test/widget_test.dart         # Kiểm thử logic (ngày giờ, tiến độ, thuốc, xuất/nhập)
```

Không dùng thư viện quản lý state hay biểu đồ bên ngoài để giảm rủi ro lệch phiên bản.

## 4. Tính năng

| Module | Có gì |
|---|---|
| **Onboarding** | 10 câu hỏi, câu nào cũng bỏ qua được; không tự đánh dấu thuốc đang dùng |
| **Dashboard** | Lời chào, % hoàn thành hôm nay, chuỗi duy trì, tiến độ tuần/tháng, giờ ngủ mục tiêu, lịch tập, bữa ăn, routine da/tóc, thuốc đã xác nhận, nhắc nhở việc quan trọng chưa làm |
| **Nhiệm vụ** | Checkbox thật; menu *Bỏ qua / Không áp dụng / Sửa*; thêm, sửa, xóa, sắp xếp, chọn ngày áp dụng |
| **Lịch trình** | Lịch 07:00–23:00 sửa giờ được, đánh dấu theo ngày, gợi ý điều chỉnh nhẹ nhàng khi bỏ lỡ, dời buổi tập |
| **Tập luyện** | Kế hoạch tuần (2 hoặc 3 buổi sức mạnh), hướng dẫn, số hiệp/lần, nghỉ, độ khó, phiên bản dễ hơn, phương án gym; ghi số lần thực tế từng hiệp, đồng hồ nghỉ, cảm nhận, ghi chú, lịch sử, gợi ý tăng tiến; nhắc khởi động & dấu hiệu cần dừng |
| **Dinh dưỡng** | Ước tính kcal/protein (Mifflin–St Jeor, ghi rõ là ước tính, tự đặt được), nước uống, thực đơn ngày/tuần đổi món được, ghi bữa thực tế + chi phí, danh sách đi chợ, thư viện món, hướng dẫn |
| **Giấc ngủ** | Ghi lên giường / bắt đầu ngủ / thức dậy, chất lượng 1–5, lý do ngủ muộn; biểu đồ tuần/tháng; tỷ lệ đúng giờ; gợi ý dịch giờ ngủ 15–30 phút |
| **Da** | Xác nhận tình trạng trước; routine sáng/tối từng bước; nhật ký dầu/mụn/kích ứng 1–5, số mụn mới, sản phẩm, ghi chú; cảnh báo kích ứng nặng; xu hướng; ảnh so sánh; quản lý thuốc |
| **Tóc** | Routine theo kế hoạch đã xác nhận, lịch gội theo hướng dẫn, ghi ngứa/đỏ/bong tróc/kích ứng, mức rụng tự đánh giá, ảnh 4 góc cố định so sánh 4/8/12 tuần, tuân thủ thuốc |
| **Thuốc** | Chỉ mục người dùng **xác nhận** mới vào nhắc nhở; thông tin đơn cũ chỉ để tham khảo; cảnh báo finasteride / Morr F5 / minoxidil / adapalene / CANOVA; không tự đề xuất liều |
| **Ngân sách** | Chi theo danh mục, thiết yếu/không thiết yếu, so với ngân sách, cảnh báo gần vượt, nhắc không tự giảm thuốc để tiết kiệm |
| **Báo cáo** | Tuần/tháng, so sánh kỳ trước, biểu đồ; mỗi chỉ số hiển thị riêng, ghi rõ phần tự đánh giá |
| **Cài đặt** | Hồ sơ, mục tiêu, sáng/tối, xuất JSON (có/không kèm ảnh), nhập JSON có kiểm tra định dạng, sao lưu/khôi phục nhanh trong máy, xóa toàn bộ dữ liệu (xác nhận 2 bước) |

## 5. Dữ liệu & quyền riêng tư

- Dữ liệu có cấu trúc: JSON trong `SharedPreferences` (khóa `glowup.v1`).
- Ảnh: file JPEG trong thư mục tài liệu riêng của app (`glowup_photos/`), **không** lưu dạng chuỗi trong JSON.
- Ngày theo giờ địa phương dạng `yyyy-MM-dd` để không lệch ngày.
- Nếu dữ liệu lưu bị hỏng, app giữ lại bản cũ (`glowup.v1.corrupted`) thay vì ghi đè.
- File xuất có chứa thông tin sức khỏe — hãy cất ở nơi riêng tư.

## 6. Giới hạn hiện tại

- Chưa có **thông báo đẩy** (nhắc giờ ngủ, giờ thuốc) — nhắc nhở hiện chỉ hiển thị trong app. Bước tiếp theo hợp lý: thêm `flutter_local_notifications`.
- kcal/protein của món mẫu là ước tính thô; chưa có cơ sở dữ liệu dinh dưỡng.
- Bản web không lưu được ảnh.
- File sao lưu kèm ảnh có thể lớn (ảnh mã hóa base64).
- Chưa đồng bộ giữa nhiều thiết bị (theo yêu cầu bản đầu: không backend).
