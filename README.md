# WINES

마시는 와인의 라벨을 촬영해 두고, 맛·향·어울리는 음식과 메모를 가볍게 기록하는 개인 와인 노트 PWA입니다.

## 주요 기능

- **라벨 스캔 & AI 분석**: 카메라 촬영 또는 앨범 사진 선택 후 Gemini 2.0 Flash로 와인명·원산지·품종·특징·추천 페어링을 자동 추출 (AI 분석 없이 직접 입력도 가능)
- **맛 · 음식 페어링 메모 & 수정**: 어울리는 음식 태그 추가/삭제, 마신 날, 장소, 맛/조화 후기, 평점(1~5점) 기록 및 언제든 수정 가능
- **검색 & 정렬**: 와인명, 품종, 원산지, 어울리는 음식, 장소, 후기 실시간 검색 및 최근 등록순·마신 날순·평점 높은순 정렬
- **라벨 확대 보기**: 상세 화면에서 라벨 이미지를 탭해 전체 화면으로 확대 확인
- **경량 PWA**: Vite + TypeScript 기반의 빠른 모바일 웹 앱(홈 화면에 추가 지원)

## 기술 스택

- **Frontend**: TypeScript, Vite, Vanilla DOM/CSS (PWA)
- **Backend / Storage**: Firebase Firestore, Firebase Storage
- **AI**: Google Gemini 2.0 Flash (`generateContent` REST API)
- **Deploy**: GitHub Actions → GitHub Pages (`/wines/`)

## 시작하기

자세한 설정 방법은 [SETUP.md](SETUP.md)를 참고하세요.

```bash
npm install
npm run dev
```

프로덕션 빌드:

```bash
npm run build
```

## 기여자

- [@2gateless](https://github.com/2gateless)
