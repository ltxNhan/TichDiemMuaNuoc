# Supabase Setup Guide for dailycup

## 1. Tạo dự án Supabase

1. Vào [Supabase Dashboard](https://app.supabase.com/)
2. Click "New Project"
3. Điền thông tin:
   - **Project Name**: `brewpoint-dailycup`
   - **Database Password**: Tạo mật khẩu mạnh
   - **Region**: Chọn region gần bạn nhất (VD: `ap-southeast-1`)
4. Đợi cơ sở dữ liệu được khởi tạo (khoảng 2-3 phút)

## 2. Lấy Project URL và Anon Key

Sau khi tạo xong project:
1. Vào **Project Settings** → **API**
2. Copy **Project URL** (VD: `https://jllhazhtfxajebnssnrn.supabase.co`)
3. Copy **anon/public key** (VD: `sb_publishable_...`)

## 3. Tạo bảng `orders` và bật Realtime

Chạy SQL ở **SQL Editor** (Supabase Dashboard → SQL Editor):

```sql
-- Tạo bảng orders
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_code VARCHAR(50) UNIQUE NOT NULL,
    customer_phone VARCHAR(20) NOT NULL,
    order_type VARCHAR(20) NOT NULL, -- 'pickup' | 'delivery'
    pickup_time TIMESTAMP,
    delivery_address TEXT,
    recipient_name VARCHAR(100),
    payment_method VARCHAR(50), -- 'cash' | 'vietqr' | 'wallet'
    payment_status VARCHAR(20) NOT NULL, -- 'unpaid' | 'paid' | 'failed'
    order_status VARCHAR(30) NOT NULL, -- 'pending' | 'processing' | 'ready_for_pickup' | 'delivering' | 'completed' | 'cancelled'
    note TEXT,
    subtotal_amount NUMERIC(12, 2),
    shipping_fee NUMERIC(12, 2),
    points_used INTEGER,
    points_earned INTEGER,
    total_amount NUMERIC(12, 2) NOT NULL,
    is_vietqr BOOLEAN DEFAULT FALSE,
    vietqr_memo VARCHAR(100),
    vietqr_quick_link TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('Asia/Ho_Chi_Minh', NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('Asia/Ho_Chi_Minh', NOW()) NOT NULL
);

-- Tạo index để tăng tốc truy vấn
CREATE INDEX IF NOT EXISTS idx_orders_order_code ON orders(order_code);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_orders_order_status ON orders(order_status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_created_at_status ON orders(created_at, order_status);

-- Bật Realtime cho bảng orders (INSERT events)
ALTER PUBLICATION supabase_realtime ADD TABLE orders;

-- Bật Realtime cho tất cả thay đổi trên bảng orders
ALTER PUBLICATION supabase_realtime OWNER TO postgres;
```

## 4. Cấu hình RLS (Row Level Security)

```sql
-- Bật RLS cho bảng orders
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Cho phép tất cả người dùng đọc (dùng cho dashboard)
CREATE POLICY "Public read orders" ON orders
    FOR SELECT USING (true);

-- Cho phép tất cả người dùng viết (chỉ kiểm tra order_code)
CREATE POLICY "Public write orders" ON orders
    FOR INSERT WITH CHECK (true);

-- Bật Realtime cho tất cả operations
ALTER PUBLICATION supabase_realtime OWNER TO postgres;
```

## 5. Cấu hình Supabase Constants

Sửa file `lib/core/constants/supabase_constants.dart`:

```dart
class SupabaseConstants {
  SupabaseConstants._();

  static const String url = 'https://jllhazhtfxajebnssnrn.supabase.co';
  static const String anonKey = 'sb_publishable_8pkNAMT05KU0J38JwuBvGA_0UI3vx3Y';
}
```

## 6. Khởi tạo Supabase trong ứng dụng

Sửa `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/injection_container.dart';
import 'features/main_navigation_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Config Supabase
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  // Init dependency injection
  await initDependencies();

  // Theme
  await ThemeConfig.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const DailyCupApp());
}
```

## 7. Test connection

Triển khải ứng dụng, vào **Supabase Dashboard → Database → Table Editor**, kiểm tra bảng `orders` có dữ liệu mới xuất hiện khi đặt hàng.

## 8. Lưu ý an toàn

- **Không đăng ký tất cả quyền viết** (`FOR INSERT WITH CHECK (true)`) trong production.
- Nên giới hạn quyền write chỉ cho tài khoản có role phù hợp.
- Luôn validate dữ liệu trên backend trước khi lưu.
- Sử dụng `flutter_secure_storage` để lưu token truy cập.