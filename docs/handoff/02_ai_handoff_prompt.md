# 다른 AI에 붙여넣는 인계 프롬프트

아래 프롬프트를 새 AI 세션에 그대로 붙여넣으면 된다.

```text
당신은 지금부터 Flutter 앱 "쿠왕(Couwang)" 프로젝트를 이어받아 작업하는 AI입니다.

먼저 아래 규칙을 따르세요.

1. 바로 코드를 수정하지 말고 현재 상태를 먼저 파악하세요.
2. 가장 먼저 `git status`를 확인해 워크트리가 깨끗한지, 미커밋 변경이 있는지 요약하세요.
3. 그 다음 아래 파일을 읽고 프로젝트 문맥을 파악하세요.

- docs/handoff/01_project_handoff.md
- docs/README.md
- docs/notes/decision_log.md
- docs/operations/run_and_release_guide.md
- docs/store/04_release_notes.md
- app/pubspec.yaml

4. 갤러리 자동 감지 기능을 이어서 작업해야 하는 경우에는 아래 파일도 읽으세요.

- app/lib/services/gallery_scan_service.dart
- app/lib/utils/scanned_image_store.dart
- app/lib/features/settings/presentation/screens/settings_screen.dart
- app/lib/features/coupons/presentation/screens/coupon_list_screen.dart
- app/lib/features/coupons/presentation/screens/coupon_create_screen.dart
- app/lib/app/app.dart
- app/lib/main.dart

5. 프로젝트의 핵심 원칙은 아래와 같습니다.

- 로그인/서버 저장 없음
- 데이터는 로컬 저장
- MVP는 갤러리 이미지 기반 OCR/바코드 인식 중심
- 세로 화면 고정
- release 빌드에서는 내부 테스트 도구 숨김
- Firebase 활성화 빌드는 ENABLE_FIREBASE=true 사용
- 상태관리는 가능한 한 setState 기반 유지
- 기존 구조를 깨지 않는 최소 변경 선호

6. 첫 응답은 아래 형식으로 해주세요.

- 현재 워크트리 상태 요약
- 현재 앱 버전
- 핵심 문서/핵심 코드 파악 결과 요약
- 이어서 할 작업 계획 (짧게)

7. 사용자가 바로 구현을 원하면, 분석만 하지 말고 실제 수정까지 진행하세요.
8. 문서 정리 요청이 있으면 `docs/notes/YYYY-MM-DD_*.md`와 `docs/notes/decision_log.md`의 역할을 구분해서 반영하세요.
9. 출시노트는 `docs/store/04_release_notes.md`를 기준 문서로 사용하세요.

추가 배경:
- 최신 릴리즈 기준 버전은 1.1.7+10 입니다.
- 최근 주요 작업은 iOS Crashlytics 정리, Android/iOS 업데이트 빌드, 그리고 갤러리 자동 감지 기능 추가입니다.
- Codex 환경에서는 `~/.codex/skills/couwang-release/SKILL.md`라는 전역 매뉴얼이 있었지만, 지금 세션에서는 위 문서들을 기준으로 같은 수준으로 맥락을 이어받아야 합니다.
```
