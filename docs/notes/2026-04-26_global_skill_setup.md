# 2026-04-26 쿠왕 전역 스킬 설정 정리

## 작업 개요

쿠왕 프로젝트의 반복 작업을 표준화하기 위해 Codex 전역 스킬 `couwang-release`를 생성했다. 이 스킬은 Android AAB 빌드, iOS IPA 빌드, 출시노트 갱신, 날짜별 작업 노트 정리, 해시 계산, 커밋/푸시 흐름을 하나의 매뉴얼로 묶는다.

## 1. 생성한 스킬

| 항목 | 내용 |
|---|---|
| 스킬 이름 | `couwang-release` |
| 스킬 파일 | `/Users/hwangdy-mac/.codex/skills/couwang-release/SKILL.md` |
| 참고 문서 | `/Users/hwangdy-mac/.codex/skills/couwang-release/references/couwang_release_reference.md` |

## 2. 왜 저장소 밖 전역 위치에 두는가

이번 스킬은 앱 코드나 스토어 제출 문서가 아니라, Codex가 앞으로 쿠왕 관련 작업을 수행할 때 참고하는 작업 매뉴얼이다. 따라서 프로젝트 내부 `docs/`보다 Codex 전역 스킬 루트인 `~/.codex/skills/`에 두는 편이 역할에 맞다.

| 구분 | 역할 |
|---|---|
| `docs/` 내부 문서 | 팀과 프로젝트를 위한 기록, 제출 산출물, 운영 문서 |
| `~/.codex/skills/` | Codex가 여러 세션에서 재사용하는 전역 작업 매뉴얼 |

## 3. 스킬에 담은 핵심 규칙

- Android release 빌드는 `flutter build appbundle --release --dart-define=ENABLE_FIREBASE=true` 기준으로 수행
- iOS release 빌드는 `flutter build ipa --release --dart-define=ENABLE_FIREBASE=true` 기준으로 수행
- release 빌드 전에는 가능하면 `flutter analyze` 수행
- 결과물 경로, 파일 크기, SHA-256을 함께 기록
- 스토어 노출용 문구는 `docs/store/04_release_notes.md`에 정리
- 날짜별 정리는 `docs/notes/YYYY-MM-DD_*.md`, 장기 규칙은 `docs/notes/decision_log.md`에 반영
- 운영용 release 빌드에서는 내부 테스트 도구를 노출하지 않음

## 4. 기대 효과

- 같은 작업을 매번 다른 방식으로 처리하는 흔들림 감소
- 릴리즈 빌드, 문서 정리, 체크섬 기록 절차 일관화
- 향후 쿠왕 관련 요청에서 Codex가 더 빠르게 동일한 기준으로 대응 가능
