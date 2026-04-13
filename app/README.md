# couwang_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Android Release Signing

Play Console 내부 테스트용 AAB를 만들려면 release signing 설정이 필요합니다.

1. `app/android/key.properties.example`를 복사해서 `app/android/key.properties`를 만듭니다.
2. keystore 파일을 `app/android/keystore/couwang-release.jks` 위치에 둡니다.
3. `key.properties`에 실제 비밀번호와 alias를 입력합니다.

예시:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=couwang-release
storeFile=keystore/couwang-release.jks
```

그 다음 AAB 빌드:

```bash
cd app
flutter build appbundle
```
