# ☕ BrewPoint F&B (DailyCup) - Smart Drink Ordering & Loyalty App

Ứng dụng đặt đồ uống và tích điểm thưởng thông minh đa nền tảng (Flutter), tích hợp hệ thống quản lý ca trực pha chế KDS cho nhân viên và cổng quản trị doanh thu thời gian thực dành cho Admin, kết nối cơ sở dữ liệu **Supabase**.

---

## 🚀 Các Tính Năng Nổi Bật

### 1. 📱 Phân Hệ Khách Hàng (Customer App)
* **Tích điểm chào mừng:** Đăng ký tài khoản mới được tự động thưởng ngay **50 điểm**.
* **Thực đơn & Tùy biến chuyên sâu:** Lọc theo danh mục, chọn Size (S/M/L), tùy chỉnh mức đường (30%, 50%, 70%), mức đá và thêm topping yêu thích. Tự động tính giá real-time.
* **Giỏ hàng & Đặt món thông minh:** Hỗ trợ linh hoạt **Tự đến lấy tại quầy (Pickup)** và **Giao hàng tận nơi (Delivery)**.
* **Kho Voucher & Tích lũy:** Áp mã giảm giá, miễn phí vận chuyển hoặc gạt nút sử dụng điểm thưởng để trừ trực tiếp vào hóa đơn.
* **Thanh toán VietQR động:** Tự động tạo mã QR VietQR đúng chuẩn chuyển khoản ngân hàng với số tiền và nội dung đơn hàng.
* **Theo dõi đơn hàng Real-time:** Tiến trình 4 bước đồng bộ với nhân viên: *Đã nhận đơn ➔ Đang pha chế ➔ Sẵn sàng / Đang giao ➔ Hoàn tất*.
* **Đánh giá chất lượng CSAT:** Đánh giá 5 mức độ hài lòng và nhận thêm **+10 điểm thưởng**.
* **Ví thành viên & Thẻ Dynamic QR:** Quét mã QR tại quầy POS để tích điểm (10.000đ = 1 điểm) và đổi điểm lấy voucher ưu đãi.

### 2. 👨‍🍳 Phân Hệ Nhân Viên (Staff / Barista KDS & POS)
* **Màn hình pha chế KDS (Kitchen Display System):** Tiếp nhận đơn mới từ khách hàng, xem chi tiết công thức từng ly, tick hoàn thành ly và bấm hoàn tất pha chế.
* **Điều phối & Giao hàng (Dispatch):** Quản lý đơn lấy tại quầy và đơn giao hàng cho tài xế, bấm hoàn tất đơn.
* **Máy quét POS Scanner:** Quét mã QR trên điện thoại khách hàng ghé mua tại quầy để tích điểm nhanh.

### 3. 📊 Phân Hệ Quản Trị Viên (Admin / Owner Portal)
* **Báo cáo Doanh thu & KPI Real-time:** Tự động cộng dồn doanh thu hôm nay và số lượng đơn hàng ngay khi nhân viên hoàn tất đơn.
* **Chi tiết hóa đơn & Timeline:** Xem chi tiết từng đơn hàng, lọc theo kênh bán hàng (Tại quán POS, App Giao hàng, Mang đi) kèm lịch sử thời gian tạo và hoàn tất.
* **Quản lý Thực đơn & Danh mục (Supabase CRUD):** Thêm, sửa, xóa món ăn và danh mục; cập nhật giá, hình ảnh, icon và trạng thái còn hàng/hết hàng.
* **Quản lý Đánh giá CSAT & Nhân sự:** Thống kê mức độ hài lòng và danh sách ca trực nhân viên.

---

## 🏗️ Cấu Trúc Thư Mục (Feature-First Architecture)

```
lib/
├── core/                           # Các thành phần dùng chung toàn app
│   ├── constants/                  # Màu sắc, Typography, URL & Supabase Key
│   ├── network/                    # Dio Client & Error Handler
│   ├── utils/                      # Định dạng tiền tệ (Currency), Ngày tháng
│   ├── widgets/                    # Custom Button, Toast Notification
│   └── injection_container.dart    # Khởi tạo Dependency Injection (GetIt)
├── features/                       # Các module tính năng độc lập
│   ├── auth/                       # Đăng nhập, Đăng ký, Quản lý tài khoản
│   ├── home/                       # Màn hình Trang chủ, Banner, Tin tức
│   ├── menu/                       # Thực đơn, Danh mục, Tùy biến Size/Topping
│   ├── cart_checkout/              # Giỏ hàng, Thanh toán VietQR, Theo dõi đơn
│   ├── loyalty/                    # Thẻ thành viên QR, Đổi quà Voucher
│   ├── staff/                      # KDS Pha chế, Điều phối giao hàng, Quét POS
│   └── admin_dashboard/            # Báo cáo doanh thu, Quản trị Menu & CSAT
├── main_navigation_screen.dart     # Điều hướng thanh Bottom Navigation
└── main.dart                       # Điểm khởi chạy ứng dụng (Entry Point)
```

---

## 🛠️ Công Nghệ Sử Dụng

* **Framework:** [Flutter](https://flutter.dev/) (SDK 3.x) & [Dart](https://dart.dev/)
* **Backend Database:** [Supabase](https://supabase.com/) (PostgreSQL & Realtime Stream)
* **State Management:** [Provider](https://pub.dev/packages/provider)
* **Dependency Injection:** [GetIt](https://pub.dev/packages/get_it)
* **Networking:** [Dio](https://pub.dev/packages/dio) & [Supabase Flutter](https://pub.dev/packages/supabase_flutter)
* **Local Storage:** [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
* **QR Generation:** [qr_flutter](https://pub.dev/packages/qr_flutter)
