# Green Loop Web App

Ứng dụng web Flutter cho nền tảng thời trang bền vững Green Loop, được thiết kế dựa trên giao diện website hiện đại.

## 📝 Lưu ý về Flutter & Dart

**Flutter sử dụng ngôn ngữ Dart, không phải TypeScript (TSX)!**

- ✅ Tất cả file code đều có extension `.dart`
- ✅ Không sử dụng `.tsx` hay `.ts` files
- ✅ Dart là ngôn ngữ lập trình chính của Flutter
- ✅ Syntax tương tự như JavaScript/TypeScript nhưng có một số khác biệt

## Tính năng

- 🎨 **Thiết kế hiện đại**: Giao diện đẹp mắt với màu sắc xanh lá chủ đạo
- 📱 **Responsive**: Tương thích với mọi kích thước màn hình
- 🏠 **Header Navigation**: Menu điều hướng với logo và các liên kết
- 🚀 **Hero Section**: Phần giới thiệu nổi bật với thống kê
- ⭐ **Features Section**: 6 tính năng chính của nền tảng
- 📞 **Call-to-Action**: Phần kêu gọi hành động với nút bấm
- 🔗 **Footer Menu**: Menu chân trang với 4 cột thông tin

## Cấu trúc dự án

```
lib/
├── main.dart                 # Entry point của ứng dụng
├── constants/
│   └── colors.dart          # Định nghĩa màu sắc
├── screens/
│   └── home_page.dart       # Trang chủ chính
└── widgets/
    ├── header.dart          # Header với navigation
    ├── hero_section.dart    # Phần hero với thống kê
    ├── features_section.dart # Phần tính năng
    ├── cta_section.dart     # Call-to-action section
    └── footer.dart          # Footer menu
```

## Cài đặt và chạy

1. **Cài đặt Flutter SDK** (nếu chưa có):
   - Tải về từ [flutter.dev](https://flutter.dev)
   - Cài đặt Flutter web support: `flutter config --enable-web`

2. **Cài đặt dependencies**:
```bash
flutter pub get
```

3. **Chạy ứng dụng web**:
```bash
flutter run -d chrome
```

4. **Build cho production**:
```bash
flutter build web
```

## Footer Menu

Footer được thiết kế với 4 cột thông tin:

### Cột 1: Green Loop
- Logo và tên thương hiệu
- Tagline: "Making fashion circular, one item at a time."

### Cột 2: Platform
- Marketplace
- Join
- How it Works

### Cột 3: Company
- About
- Contact
- Careers

### Cột 4: Support
- Help Center
- Privacy
- Terms

## Màu sắc chủ đạo

- **Primary**: #20B2AA (Teal/Green)
- **Background**: #FFFFFF (White)
- **Text**: #2C3E50 (Dark Blue)
- **Gray**: #7F8C8D (Light Gray)
- **Footer**: #2C3E50 (Dark)

## Responsive Design

Ứng dụng được thiết kế responsive với:
- Layout linh hoạt cho desktop và tablet
- Grid system cho features section
- Flexible navigation header
- Mobile-friendly footer menu

## Công nghệ sử dụng

- **Flutter**: Framework phát triển ứng dụng cross-platform
- **Dart**: Ngôn ngữ lập trình chính (không phải TypeScript!)
- **Material Design**: Hệ thống thiết kế của Google
- **Flutter Web**: Hỗ trợ chạy trên trình duyệt web

## Thư viện đã sử dụng

- **flutter_animate**: Tạo hiệu ứng animation mượt mà
- **google_fonts**: Sử dụng font Inter từ Google Fonts
- **font_awesome_flutter**: Icons đẹp từ Font Awesome
- **responsive_framework**: Responsive design cho mọi màn hình
- **provider**: State management đơn giản
- **http & dio**: Gọi API và xử lý HTTP requests
- **url_launcher**: Mở links và external apps
- **shared_preferences**: Lưu trữ dữ liệu local

## So sánh Dart vs TypeScript

| Dart (Flutter) | TypeScript (React) |
|----------------|-------------------|
| `.dart` files | `.tsx` files |
| `Widget` class | `Component` function |
| `build()` method | `return` JSX |
| `setState()` | `useState()` hook |
| `Provider` | `Context API` |