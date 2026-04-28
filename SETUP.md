# Wines 앱 설정 가이드

## 1. Flutter 프로젝트 초기화

```bash
cd C:\Users\gateless\Documents\database
flutter create wines --org com.yourname --platforms android,ios
```

> 그런 다음 아래 파일들을 생성된 프로젝트에 덮어쓰세요:
> - `pubspec.yaml`
> - `lib/` 디렉토리 전체

## 2. Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 새 프로젝트 생성 (예: `wines-app`)
3. **Firestore Database** 활성화 → 테스트 모드로 시작
4. **Storage** 활성화
5. 결제 요금제: Spark(무료) 또는 Blaze(Gemini 사용 시 필요)

## 3. FlutterFire CLI 설치 및 설정

```bash
# CLI 설치
dart pub global activate flutterfire_cli

# 프로젝트 디렉토리에서 실행
cd wines
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```

이 명령이 `lib/firebase_options.dart` 파일을 자동으로 생성합니다.
Google Services 파일(`google-services.json`, `GoogleService-Info.plist`)도 자동 배치됩니다.

## 4. Gemini API 키 발급

1. [Google AI Studio](https://aistudio.google.com/) 접속
2. **Get API Key** → 새 키 생성
3. 키를 복사

### 개발 환경 실행

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
```

### VS Code launch.json 설정

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Wines",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=GEMINI_API_KEY=YOUR_KEY_HERE"]
    }
  ]
}
```

> ⚠️ API 키를 코드에 직접 하드코딩하지 마세요.
> 프로덕션에서는 Firebase Functions를 프록시로 사용하는 것을 권장합니다.

## 5. Android 권한 추가

`android/app/src/main/AndroidManifest.xml`의 `<manifest>` 내부에 추가:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

`android/app/build.gradle`에서 `minSdk` 확인:
```gradle
android {
    defaultConfig {
        minSdk 21
    }
}
```

## 6. iOS 권한 추가

`ios/Runner/Info.plist`에 추가:

```xml
<key>NSCameraUsageDescription</key>
<string>와인 라벨 촬영을 위해 카메라가 필요합니다.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>갤러리에서 와인 라벨 사진을 선택합니다.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>와인 라벨 사진을 저장합니다.</string>
```

## 7. 패키지 설치 및 실행

```bash
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
```

## Firestore 보안 규칙 (배포 전 필수)

Firebase Console → Firestore → 규칙:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /wines/{document=**} {
      allow read, write: if true; // MVP용 — 프로덕션에서는 auth 연동 필요
    }
  }
}
```

## 현재 설치 진행 상황 (2026-04-28 기준)

### 완료된 작업

- **puro** (Flutter 버전 관리자) winget으로 설치
  - 실행파일: `C:\Users\USER\AppData\Local\Microsoft\WinGet\Packages\pingbird.Puro_Microsoft.Winget.Source_8wekyb3d8bbwe\puro.exe`
- **Flutter 3.41.8** stable 설치: `C:\Users\USER\.puro\envs\stable\flutter\`
- PATH에 추가됨: `C:\Users\USER\.puro\bin`, `C:\Users\USER\.puro\envs\stable\flutter\bin`
- 환경변수 `FLUTTER_ROOT=C:\Users\USER\.puro\envs\stable\flutter` 설정
- `flutter doctor` — 정상 작동 확인 (Chrome/Edge 웹 실행 가능)
- 코드 수정 완료:
  - `dart:io` (File) → `dart:typed_data` (Uint8List) 전체 교체 (웹 호환)
  - `Content.user()` → `Content.text()` API 수정 (google_generative_ai 0.4.7)

### 막힌 문제

`flutter run -d chrome` 실행 시 아래 오류:

```
Error: SDK root directory not found: ../../../.puro/envs/stable/flutter/bin/cache/flutter_web_sdk/.
```

- `flutter_web_sdk` 폴더는 실제로 존재함
- puro를 우회해서 dart 직접 실행해도 동일 오류
- flutter_tools가 web SDK를 상대 경로로 계산할 때 경로가 틀어지는 것으로 추정

### 다음 시도할 것

**가장 확실한 해결책: Flutter를 puro 없이 직접 재설치**

1. [https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows) 접속
2. Flutter SDK zip 다운로드 → `C:\flutter`에 압축 해제
3. 사용자 환경변수 PATH에 `C:\flutter\bin` 추가
4. 기존 puro PATH 항목 제거 (혼선 방지)
5. 새 터미널에서 `flutter doctor` → `flutter run -d chrome`

---

## 프로젝트 구조

```
lib/
├── main.dart              # 앱 진입점 (Firebase 초기화)
├── app.dart               # MaterialApp
├── firebase_options.dart  # Firebase 설정 (flutterfire configure로 생성)
├── theme/
│   └── app_theme.dart     # Burgundy & White 테마
├── models/
│   └── wine.dart          # Wine, WineInfo 모델
├── services/
│   ├── firestore_service.dart  # Firestore CRUD
│   ├── storage_service.dart    # 이미지 업로드
│   └── gemini_service.dart     # AI 라벨 분석 + 소믈리에 채팅
├── screens/
│   ├── home_screen.dart        # 갤러리 그리드 (메인)
│   ├── scan_screen.dart        # 카메라/갤러리 + AI 분석
│   ├── add_wine_screen.dart    # 결과 확인 + 저장
│   ├── wine_detail_screen.dart # 와인 상세
│   └── chat_screen.dart        # AI 소믈리에 채팅
└── widgets/
    └── wine_grid_item.dart     # 갤러리 카드
```
