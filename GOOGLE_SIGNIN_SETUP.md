# Google Sign-In Setup Guide

## Lỗi ApiException: 10 (DEVELOPER_ERROR)

Lỗi này xảy ra khi SHA-1 fingerprint chưa được thêm vào Google Cloud Console.

## Cách sửa:

### Bước 1: Lấy SHA-1 Fingerprint

SHA-1 fingerprint của bạn:
```
1A:3F:98:FB:F2:2B:3F:9F:77:ED:49:1E:AE:BD:69:C2:91:37:59:F8
```

Package name: `com.example.greenloop`

### Bước 2: Thêm SHA-1 vào Google Cloud Console

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Chọn project của bạn (hoặc tạo project mới)
3. Vào **APIs & Services** → **Credentials**
4. Tìm OAuth 2.0 Client ID của bạn (hoặc tạo mới cho Android)
5. Click vào OAuth Client ID
6. Trong phần **SHA-1 certificate fingerprints**, click **+ ADD FINGERPRINT**
7. Thêm SHA-1: `1A:3F:98:FB:F2:2B:3F:9F:77:ED:49:1E:AE:BD:69:C2:91:37:59:F8`
8. Package name: `com.example.greenloop`
9. Click **SAVE**

### Bước 3: Đợi vài phút

Sau khi thêm SHA-1, đợi 5-10 phút để Google cập nhật cấu hình.

### Bước 4: Test lại

Chạy lại app và thử đăng nhập Google.

## Lấy SHA-1 mới (nếu cần)

Nếu bạn có keystore khác (release keystore), chạy:

```bash
cd android
./gradlew signingReport
```

Hoặc với keystore cụ thể:

```bash
keytool -list -v -keystore <path-to-keystore> -alias <alias-name>
```

## Lưu ý

- Debug keystore: `~/.android/debug.keystore` (hoặc `C:\Users\<user>\.android\debug.keystore` trên Windows)
- Release keystore: Cần thêm SHA-1 của release keystore vào Google Cloud Console khi publish app
- Mỗi keystore có SHA-1 riêng, cần thêm tất cả vào Google Cloud Console

