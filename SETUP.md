# WINES 설정 가이드

## 1. 사전 요구 사항

- **Node.js** 20 이상 (권장: 22 LTS)
- **Firebase 프로젝트** (Firestore Database, Firebase Storage 활성화)
- **Gemini API 키** (선택 사항 — 라벨 AI 자동 분석 사용 시 필요)

## 2. 로컬 개발 환경 설정

```bash
git clone https://github.com/2gateless/wines.git
cd wines
npm install
```

### Gemini API 키 설정 (선택)

1. [Google AI Studio](https://aistudio.google.com/)에서 API 키를 발급받습니다.
2. 프로젝트 루트에 `.env.local` 파일을 생성하고 키를 입력합니다:

```env
VITE_GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

> `.env.local`은 `.gitignore`에 포함되어 있어 Git에 커밋되지 않습니다.

### 개발 서버 실행 & 빌드

```bash
# 로컬 개발 서버 실행
npm run dev

# 타입 체크 및 프로덕션 빌드 (dist/ 생성)
npm run build
```

## 3. Firebase 설정

현재 웹 설정은 `src/firebase.ts`에 연결되어 있습니다. 다른 Firebase 프로젝트를 사용하려면 `src/firebase.ts`의 `firebaseConfig`를 교체하세요.

### Firestore 보안 규칙

Firebase Console → Firestore Database → 규칙에서 필요에 맞게 설정합니다:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /wines/{document=**} {
      allow read, write: if true; // 개인용 MVP — 필요 시 Firebase Auth 연동 권장
    }
  }
}
```

## 4. GitHub Pages 자동 배포

`main` 브랜치에 푸시하면 `.github/workflows/deploy.yml`이 자동으로 `npm ci && npm run build`를 실행해 `dist/`를 GitHub Pages(`/wines/`)로 배포합니다.

- **GitHub Repository → Settings → Secrets and variables → Actions**에 `GEMINI_API_KEY` 시크릿을 등록해 두면 빌드 시 `VITE_GEMINI_API_KEY`로 주입됩니다.

## 5. 프로젝트 구조

```
├── index.html                  # PWA 진입 HTML
├── package.json                # 의존성 및 스크립트
├── tsconfig.json               # TypeScript 설정
├── vite.config.ts              # Vite 설정 (base: '/wines/')
├── public/
│   ├── icon.svg                # 앱 아이콘
│   └── manifest.webmanifest    # PWA 매니페스트
└── src/
    ├── main.ts                 # UI 라우팅 및 갤러리/스캔/기록/상세 화면
    ├── style.css               # 버건디 & 크림 테마 스타일
    ├── types.ts                # Wine, WineInfo, WineSort 타입
    ├── firebase.ts             # Firestore CRUD & Storage 이미지 업로드/삭제
    ├── gemini.ts               # Gemini 2.0 Flash 라벨 분석 REST 호출
    ├── image.ts                # 브라우저 Canvas 기반 JPEG 리사이즈(최대 800px)
    └── vite-env.d.ts           # Vite 환경변수 타입 선언
```
