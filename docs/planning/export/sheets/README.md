# Google Sheets 업로드용 통합 CSV

이 폴더의 `*_combined.csv` 파일은 Google Sheets에 문서별로 가져오기 좋게 합친 파일입니다.
기존 `../csv/*_table_XX.csv` 파일은 Markdown 표 하나당 하나씩 생성된 원본 table export입니다.

## 추천 사용 순서

1. Google Sheets에서 새 스프레드시트를 만듭니다.
2. `파일 > 가져오기 > 업로드`를 선택합니다.
3. 필요한 `*_combined.csv`를 업로드합니다.
4. 가져오기 위치는 `새 시트 삽입`을 선택합니다.
5. 다른 통합 CSV도 같은 방식으로 추가합니다.

## 파일 목록

| 파일 | 설명 |
|---|---|
| `01_requirements_combined.csv` | 01_requirements 문서의 표를 섹션 기준으로 통합 |
| `03_screen_design_combined.csv` | 03_screen_design 문서의 표를 섹션 기준으로 통합 |
| `04_functional_spec_combined.csv` | 04_functional_spec 문서의 표를 섹션 기준으로 통합 |
| `05_storyboard_combined.csv` | 05_storyboard 문서의 표를 섹션 기준으로 통합 |
| `06_feature_definition_combined.csv` | 06_feature_definition 문서의 표를 섹션 기준으로 통합 |
| `08_policy_combined.csv` | 08_policy 문서의 표를 섹션 기준으로 통합 |
