# 쿠왕 실행 및 릴리즈 빌드 가이드

문서명: OS별 실행 명령어 및 릴리즈 빌드 가이드  
프로젝트: 쿠왕 (CouWang)  
작성일: 2026-04-17  
작성자: 개발팀

## 1. 기본 경로

쿠왕 Flutter 앱은 프로젝트 루트의 `app/` 폴더 안에 있습니다.

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
```

대부분의 Flutter 명령어는 위 경로에서 실행합니다.

한 번에 복사해서 쓰기:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
pwd
```

## 2. 공통 준비 명령어

의존성 설치 또는 갱신:

```bash
flutter pub get
```

정적 분석:

```bash
flutter analyze
```

연결 가능한 디바이스 확인:

```bash
flutter devices
```

캐시/빌드 산출물 정리:

```bash
flutter clean
flutter pub get
```

평소 실행 전 준비:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter pub get
flutter devices
```

코드 수정 후 확인:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter analyze
flutter devices
```

빌드가 꼬였을 때 정리:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter clean
flutter pub get
flutter analyze
```

## 3. Android 실행

### 3.1 USB 연결 실행

Android 기기를 USB로 연결한 뒤 디바이스 목록을 확인합니다.

```bash
adb devices
flutter devices
```

디바이스 ID를 확인한 뒤 실행합니다.

```bash
flutter run -d <device-id>
```

예시:

```bash
flutter run -d 192.168.14.25:44429
```

한 번에 복사해서 쓰기:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
adb devices
flutter devices
flutter run -d <device-id>
```

### 3.2 무선 ADB 연결 실행

이미 무선 디버깅 주소와 포트를 알고 있다면 먼저 연결합니다.

```bash
adb connect 192.168.14.25:44429
```

연결 확인:

```bash
adb devices
```

실행:

```bash
flutter run -d 192.168.14.25:44429
```

한 번에 복사해서 쓰기:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
adb connect 192.168.14.25:44429
adb devices
flutter run -d 192.168.14.25:44429
```

### 3.3 Android 로그 확인

```bash
flutter logs -d <device-id>
```

예시:

```bash
flutter logs -d 192.168.14.25:44429
```

한 번에 복사해서 쓰기:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter logs -d 192.168.14.25:44429
```

## 4. iOS 실행

### 4.1 iPhone 실기기 실행

Mac에 iPhone을 연결하고 신뢰 설정을 완료합니다.

```bash
flutter devices
flutter run -d <ios-device-id>
```

실기기 빌드에서 서명 문제가 있으면 Xcode에서 아래를 확인합니다.

- `app/ios/Runner.xcworkspace` 열기
- `Runner` 타겟 선택
- `Signing & Capabilities`에서 Team, Bundle Identifier 확인
- 실제 iPhone이 개발자 계정에 등록되어 있는지 확인

한 번에 복사해서 쓰기:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter devices
flutter run -d <ios-device-id>
```

### 4.2 iOS Simulator 실행

시뮬레이터 앱 열기:

```bash
open -a Simulator
```

디바이스 확인:

```bash
flutter devices
```

실행:

```bash
flutter run -d <simulator-device-id>
```

가능하면 iPhone 시뮬레이터 이름으로도 실행할 수 있습니다.

```bash
flutter run -d "iPhone 16"
```

한 번에 복사해서 쓰기:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
open -a Simulator
flutter devices
flutter run -d <simulator-device-id>
```

시뮬레이터 이름으로 바로 실행:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
open -a Simulator
flutter run -d "iPhone 16"
```

## 5. Chrome/Web 실행

Chrome 디바이스가 보이는지 확인합니다.

```bash
flutter devices
```

Chrome 실행:

```bash
flutter run -d chrome
```

웹에서 SQLite를 사용하는 경우 `app/web/` 안의 sqflite web 자산이 필요합니다. 관련 오류가 나오면 `sqlite3.wasm`, `sqflite_sw.js` 설정을 먼저 확인합니다.

한 번에 복사해서 쓰기:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter devices
flutter run -d chrome
```

## 6. VS Code에서 실행하는 방법

### 6.1 기본 실행 흐름

1. VS Code에서 프로젝트 루트 또는 `app/` 폴더를 엽니다.
2. 우측 하단의 디바이스 선택 영역을 클릭합니다.
3. 실행할 디바이스를 선택합니다.
4. `Run > Start Debugging` 또는 `F5`를 누릅니다.

Flutter 확장이 설치되어 있으면 별도 터미널 명령 없이 실행할 수 있습니다.

VS Code 터미널에서 같은 동작을 하는 명령어:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter devices
flutter run -d <device-id>
```

### 6.2 명령 팔레트 사용

1. `Cmd + Shift + P`를 누릅니다.
2. `Flutter: Select Device`를 실행합니다.
3. Android, iOS Simulator, Chrome 중 원하는 디바이스를 선택합니다.
4. `Flutter: Run Flutter App`을 실행합니다.

명령 팔레트 대신 터미널에서 실행:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter devices
flutter run -d <device-id>
```

### 6.3 VS Code 터미널에서 직접 실행

VS Code 하단 터미널에서 앱 폴더로 이동한 뒤 동일한 명령을 실행합니다.

```bash
cd app
flutter run -d <device-id>
```

자주 쓰는 실제 예시:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter run -d chrome
```

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter run -d 192.168.14.25:44429
```

## 7. Android 내부 테스트용 AAB 생성

### 7.1 버전 확인 및 증가

Flutter 버전은 `app/pubspec.yaml`의 `version`에서 관리합니다.

```yaml
version: 0.1.3+6
```

- `0.1.3`: 사용자에게 보이는 버전명
- `6`: Android versionCode / iOS build number
- Google Play에 이미 올린 versionCode는 재사용할 수 없으므로 매 업로드마다 `+숫자`를 올립니다.

예시:

```yaml
version: 0.1.4+7
```

현재 버전 확인:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
grep '^version:' pubspec.yaml
```

### 7.2 AAB 빌드

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter build appbundle --release
```

생성 위치:

```text
app/build/app/outputs/bundle/release/app-release.aab
```

한 번에 복사해서 쓰기:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter pub get
flutter analyze
flutter build appbundle --release
ls -lh build/app/outputs/bundle/release/app-release.aab
```

빌드가 꼬였을 때 클린 후 AAB 생성:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter clean
flutter pub get
flutter analyze
flutter build appbundle --release
ls -lh build/app/outputs/bundle/release/app-release.aab
```

### 7.3 Google Play Console 업로드

1. Google Play Console 접속
2. 앱 선택
3. `테스트 및 출시 > 테스트 > 내부 테스트`
4. 새 버전 만들기
5. `app-release.aab` 업로드
6. 출시 노트 입력
7. 검토 후 내부 테스트 트랙에 출시

AAB 위치 Finder에서 열기:

```bash
open /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app/build/app/outputs/bundle/release
```

### 7.4 콘솔 직접 업로드 외 대안

현재는 직접 업로드가 가장 단순합니다. 자동화가 필요해지면 아래 방식을 검토할 수 있습니다.

- Google Play Developer API
- `fastlane supply`
- GitHub Actions 또는 CI에서 AAB 생성 후 업로드

자동 업로드를 사용하려면 Google Cloud 서비스 계정, Play Console API 권한, 서명 키 관리 정책을 별도로 준비해야 합니다.

자동화 도입 전 확인 명령어:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter build appbundle --release
ls -lh build/app/outputs/bundle/release/app-release.aab
```

## 8. iOS Archive 및 TestFlight 업로드

### 8.1 버전 확인 및 증가

iOS도 기본적으로 `app/pubspec.yaml`의 `version` 값을 사용합니다.

```yaml
version: 0.1.3+6
```

- `0.1.3`: CFBundleShortVersionString
- `6`: CFBundleVersion

Xcode에서 직접 Identity 값을 바꿔도 Flutter 빌드 과정에서 `pubspec.yaml` 값이 다시 반영될 수 있으므로, 우선 `pubspec.yaml`을 기준으로 올리는 것을 권장합니다.

현재 버전 확인:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
grep '^version:' pubspec.yaml
```

### 8.2 CocoaPods 동기화

`Podfile.lock` 관련 오류가 나오면 아래를 실행합니다.

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app/ios
pod install
```

한 번에 복사해서 쓰기:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter pub get
cd ios
pod install
```

### 8.3 터미널에서 iOS IPA 생성

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter build ipa --release
```

생성 위치:

```text
app/build/ios/ipa/
```

생성된 `.ipa`는 Apple Transporter 앱에 드래그해서 업로드할 수 있습니다.

한 번에 복사해서 쓰기:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter pub get
flutter analyze
flutter build ipa --release
open build/ios/ipa
```

빌드가 꼬였을 때 클린 후 IPA 생성:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter analyze
flutter build ipa --release
open build/ios/ipa
```

### 8.4 Xcode에서 Archive 생성

1. `app/ios/Runner.xcworkspace`를 엽니다.
2. 상단 Scheme이 `Runner`인지 확인합니다.
3. 대상 디바이스를 `Any iOS Device (arm64)` 또는 연결된 실제 iPhone으로 선택합니다.
4. `Product > Archive`를 실행합니다.
5. Organizer 창에서 생성된 Archive를 선택합니다.
6. `Distribute App`을 누릅니다.
7. `App Store Connect` 업로드 흐름을 진행합니다.

주의할 점:

- `.xcodeproj`가 아니라 `.xcworkspace`를 열어야 CocoaPods 의존성이 정상 연결됩니다.
- Archive 전에 `flutter clean`, `flutter pub get`, `pod install`을 수행하면 빌드 꼬임을 줄일 수 있습니다.
- App Store Connect에 업로드된 빌드는 처리 완료까지 시간이 걸릴 수 있습니다.

Xcode 열기 전 준비:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter pub get
cd ios
pod install
open Runner.xcworkspace
```

클린 후 Xcode 열기:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter clean
flutter pub get
cd ios
pod install
open Runner.xcworkspace
```

### 8.5 TestFlight 반영 흐름

1. App Store Connect에서 빌드 처리 완료 확인
2. TestFlight 탭에서 해당 빌드 선택
3. 내부 테스트 그룹 또는 외부 테스트 그룹에 빌드 추가
4. 테스트 정보 입력
5. 테스터가 TestFlight 앱에서 설치 또는 업데이트

내부 테스트는 보통 처리 완료 후 비교적 빠르게 반영됩니다. 외부 테스트는 Apple 베타 앱 심사가 추가될 수 있습니다.

App Store Connect에서 처리 대기 중일 때 로컬에서 확인할 것:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
grep '^version:' pubspec.yaml
ls -lh build/ios/ipa 2>/dev/null || true
```

## 9. VS Code에서 빌드하는 방법

VS Code 자체 버튼으로 AAB/Archive를 만드는 전용 메뉴는 제한적입니다. 일반적으로 VS Code의 내장 터미널에서 명령어를 실행합니다.

Android AAB:

```bash
cd app
flutter build appbundle --release
```

iOS IPA:

```bash
cd app
flutter build ipa --release
```

iOS Archive는 Xcode Organizer가 필요하므로 Xcode에서 진행하는 방식이 가장 안정적입니다.

VS Code 터미널에서 Android AAB 한 번에 생성:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter pub get
flutter analyze
flutter build appbundle --release
open build/app/outputs/bundle/release
```

VS Code 터미널에서 iOS IPA 한 번에 생성:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter pub get
flutter analyze
flutter build ipa --release
open build/ios/ipa
```

VS Code 터미널에서 Xcode Archive 준비:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter pub get
cd ios
pod install
open Runner.xcworkspace
```

## 10. 자주 쓰는 명령어 모음

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter pub get
flutter devices
flutter analyze
flutter run -d chrome
flutter run -d 192.168.14.25:44429
flutter logs -d 192.168.14.25:44429
flutter build appbundle --release
flutter build ipa --release
```

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app/ios
pod install
```

## 11. Firebase Analytics / Crashlytics 활성화

현재 앱에는 Firebase Analytics와 Crashlytics 코드가 연결되어 있지만, Firebase 프로젝트 설정 파일이 없으면 기본적으로 비활성화됩니다. 실제 수집을 켜려면 Firebase 프로젝트를 만든 뒤 플랫폼별 설정 파일을 추가하고 `ENABLE_FIREBASE=true` 값을 함께 전달합니다.

필요 파일:

```text
app/android/app/google-services.json
app/ios/Runner/GoogleService-Info.plist
```

권장 이벤트:

```text
coupon_created
coupon_used
notification_opened
image_extract_attempted
image_extract_succeeded
image_extract_failed
```

개인정보 보호를 위해 이벤트에는 쿠폰명, 바코드 번호, 메모, 이미지 경로 같은 사용자 입력값을 넣지 않습니다.

Firebase를 켠 상태로 Android 실행:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter run -d <device-id> --dart-define=ENABLE_FIREBASE=true
```

Firebase를 켠 상태로 Android AAB 생성:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter pub get
flutter analyze
flutter build appbundle --release --dart-define=ENABLE_FIREBASE=true
open build/app/outputs/bundle/release
```

Firebase를 켠 상태로 iOS IPA 생성:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter pub get
cd ios
pod install
cd ..
flutter analyze
flutter build ipa --release --dart-define=ENABLE_FIREBASE=true
open build/ios/ipa
```

Firebase를 끈 기본 상태로 실행:

```bash
cd /Users/hwangdy-mac/EXPLORER/Project4/CouWang/app
flutter run -d <device-id>
```
