#!/usr/bin/env python3
"""Export planning markdown docs to simple DOCX and CSV files.

The DOCX output is intentionally lightweight so it can be opened by
Google Docs and edited further. Markdown tables are also exported as
standalone CSV files for Google Sheets import.
"""

from __future__ import annotations

import csv
import re
import shutil
import zipfile
from dataclasses import dataclass
from pathlib import Path
from xml.sax.saxutils import escape


ROOT = Path(__file__).resolve().parents[1]
PLANNING_DIR = ROOT / "docs" / "planning"
EXPORT_DIR = PLANNING_DIR / "export"
DOCX_DIR = EXPORT_DIR / "docx"
CSV_DIR = EXPORT_DIR / "csv"
SHEETS_DIR = EXPORT_DIR / "sheets"


@dataclass
class Table:
    rows: list[list[str]]


@dataclass
class TableContext:
    document: str
    section: str
    table_index: int
    table: Table


def clean_cell(value: str) -> str:
    value = value.strip()
    value = re.sub(r"`([^`]*)`", r"\1", value)
    value = re.sub(r"<br\s*/?>", "\n", value)
    return value


def split_table_row(line: str) -> list[str]:
    stripped = line.strip().strip("|")
    return [clean_cell(cell) for cell in stripped.split("|")]


def is_separator_row(line: str) -> bool:
    stripped = line.strip().strip("|").strip()
    return bool(stripped) and all(
        re.fullmatch(r":?-{3,}:?", part.strip()) for part in stripped.split("|")
    )


def is_table_start(lines: list[str], index: int) -> bool:
    return (
        index + 1 < len(lines)
        and lines[index].lstrip().startswith("|")
        and lines[index + 1].lstrip().startswith("|")
        and is_separator_row(lines[index + 1])
    )


def extract_frontmatter(lines: list[str]) -> tuple[list[str], list[str]]:
    if not lines or lines[0].strip() != "---":
        return [], lines
    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            return lines[1:index], lines[index + 1 :]
    return [], lines


def parse_markdown(lines: list[str]) -> list[tuple[str, object]]:
    blocks: list[tuple[str, object]] = []
    frontmatter, body_lines = extract_frontmatter(lines)
    if frontmatter:
        blocks.append(("paragraph", "문서 정보"))
        for line in frontmatter:
            blocks.append(("paragraph", line.strip()))
        blocks.append(("paragraph", ""))

    index = 0
    in_code = False
    code_lines: list[str] = []

    while index < len(body_lines):
        line = body_lines[index].rstrip("\n")

        if line.strip().startswith("```"):
            if in_code:
                blocks.append(("code", "\n".join(code_lines)))
                code_lines = []
                in_code = False
            else:
                in_code = True
            index += 1
            continue

        if in_code:
            code_lines.append(line)
            index += 1
            continue

        if is_table_start(body_lines, index):
            table_rows = [split_table_row(body_lines[index])]
            index += 2
            while index < len(body_lines) and body_lines[index].lstrip().startswith("|"):
                table_rows.append(split_table_row(body_lines[index]))
                index += 1
            blocks.append(("table", Table(table_rows)))
            continue

        stripped = line.strip()
        if not stripped:
            blocks.append(("paragraph", ""))
        elif stripped.startswith("#"):
            level = len(stripped) - len(stripped.lstrip("#"))
            text = stripped[level:].strip()
            blocks.append((f"heading{min(level, 3)}", text))
        elif stripped.startswith("- "):
            blocks.append(("bullet", stripped[2:].strip()))
        elif re.match(r"^\d+\.\s+", stripped):
            blocks.append(("number", re.sub(r"^\d+\.\s+", "", stripped)))
        else:
            blocks.append(("paragraph", stripped))
        index += 1

    return blocks


def extract_tables_with_context(source: Path, lines: list[str]) -> list[TableContext]:
    _, body_lines = extract_frontmatter(lines)
    contexts: list[TableContext] = []
    heading_stack: dict[int, str] = {}
    table_index = 1
    index = 0
    in_code = False

    while index < len(body_lines):
        line = body_lines[index].rstrip("\n")
        stripped = line.strip()

        if stripped.startswith("```"):
            in_code = not in_code
            index += 1
            continue

        if in_code:
            index += 1
            continue

        if stripped.startswith("#"):
            level = len(stripped) - len(stripped.lstrip("#"))
            heading_stack[level] = stripped[level:].strip()
            for stale_level in list(heading_stack):
                if stale_level > level:
                    del heading_stack[stale_level]
            index += 1
            continue

        if is_table_start(body_lines, index):
            table_rows = [split_table_row(body_lines[index])]
            index += 2
            while index < len(body_lines) and body_lines[index].lstrip().startswith("|"):
                table_rows.append(split_table_row(body_lines[index]))
                index += 1
            section = " > ".join(
                heading_stack[level] for level in sorted(heading_stack)
            )
            contexts.append(
                TableContext(
                    document=source.stem,
                    section=section,
                    table_index=table_index,
                    table=Table(table_rows),
                )
            )
            table_index += 1
            continue

        index += 1

    return contexts


def xml_text(text: str) -> str:
    parts = escape(text).split("\n")
    rendered = []
    for index, part in enumerate(parts):
        if index:
            rendered.append("<w:br/>")
        rendered.append(part)
    return "".join(rendered)


def paragraph_xml(text: str, style: str | None = None) -> str:
    p_style = f"<w:pPr><w:pStyle w:val=\"{style}\"/></w:pPr>" if style else ""
    return f"<w:p>{p_style}<w:r><w:t xml:space=\"preserve\">{xml_text(text)}</w:t></w:r></w:p>"


def table_xml(table: Table) -> str:
    rows_xml = []
    for row in table.rows:
        cells_xml = []
        for cell in row:
            cells_xml.append(
                "<w:tc><w:tcPr><w:tcW w:w=\"2400\" w:type=\"dxa\"/></w:tcPr>"
                f"{paragraph_xml(cell)}</w:tc>"
            )
        rows_xml.append(f"<w:tr>{''.join(cells_xml)}</w:tr>")
    return (
        "<w:tbl><w:tblPr><w:tblStyle w:val=\"TableGrid\"/>"
        "<w:tblW w:w=\"0\" w:type=\"auto\"/></w:tblPr>"
        f"{''.join(rows_xml)}</w:tbl>"
    )


def document_xml(blocks: list[tuple[str, object]]) -> str:
    body = []
    for block_type, value in blocks:
        if block_type == "heading1":
            body.append(paragraph_xml(str(value), "Heading1"))
        elif block_type == "heading2":
            body.append(paragraph_xml(str(value), "Heading2"))
        elif block_type == "heading3":
            body.append(paragraph_xml(str(value), "Heading3"))
        elif block_type == "bullet":
            body.append(paragraph_xml(f"• {value}"))
        elif block_type == "number":
            body.append(paragraph_xml(f"- {value}"))
        elif block_type == "code":
            body.append(paragraph_xml(str(value), "NoSpacing"))
        elif block_type == "table":
            body.append(table_xml(value))
        else:
            body.append(paragraph_xml(str(value)))

    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    {''.join(body)}
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>
    </w:sectPr>
  </w:body>
</w:document>
"""


def write_docx(source: Path, blocks: list[tuple[str, object]]) -> None:
    output = DOCX_DIR / f"{source.stem}.docx"
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as docx:
        docx.writestr(
            "[Content_Types].xml",
            """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
""",
        )
        docx.writestr(
            "_rels/.rels",
            """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
""",
        )
        docx.writestr("word/document.xml", document_xml(blocks))
        docx.writestr(
            "word/styles.xml",
            """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style>
  <w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:pPr><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:b/><w:sz w:val="32"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:pPr><w:outlineLvl w:val="1"/></w:pPr><w:rPr><w:b/><w:sz w:val="28"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Heading3"><w:name w:val="heading 3"/><w:basedOn w:val="Normal"/><w:pPr><w:outlineLvl w:val="2"/></w:pPr><w:rPr><w:b/><w:sz w:val="24"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="NoSpacing"><w:name w:val="No Spacing"/><w:basedOn w:val="Normal"/></w:style>
  <w:style w:type="table" w:styleId="TableGrid"><w:name w:val="Table Grid"/><w:tblPr><w:tblBorders><w:top w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:left w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:bottom w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:right w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:insideH w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:insideV w:val="single" w:sz="4" w:space="0" w:color="auto"/></w:tblBorders></w:tblPr></w:style>
</w:styles>
""",
        )


def write_csvs(source: Path, blocks: list[tuple[str, object]]) -> list[Path]:
    outputs: list[Path] = []
    table_index = 1
    for block_type, value in blocks:
        if block_type != "table":
            continue
        output = CSV_DIR / f"{source.stem}_table_{table_index:02d}.csv"
        with output.open("w", newline="", encoding="utf-8-sig") as file:
            writer = csv.writer(file)
            writer.writerows(value.rows)
        outputs.append(output)
        table_index += 1
    return outputs


def normalized_header(header: str, fallback: str) -> str:
    value = header.strip() or fallback
    return value.replace("\n", " ").strip()


def write_combined_sheet_csv(source: Path, contexts: list[TableContext]) -> Path | None:
    if not contexts:
        return None

    headers: list[str] = ["document", "section", "table_index"]
    for context in contexts:
        if not context.table.rows:
            continue
        for index, header in enumerate(context.table.rows[0], start=1):
            normalized = normalized_header(header, f"column_{index}")
            if normalized not in headers:
                headers.append(normalized)

    output = SHEETS_DIR / f"{source.stem}_combined.csv"
    with output.open("w", newline="", encoding="utf-8-sig") as file:
        writer = csv.DictWriter(file, fieldnames=headers)
        writer.writeheader()
        for context in contexts:
            if len(context.table.rows) <= 1:
                continue
            table_headers = [
                normalized_header(header, f"column_{index}")
                for index, header in enumerate(context.table.rows[0], start=1)
            ]
            for row in context.table.rows[1:]:
                record = {
                    "document": context.document,
                    "section": context.section,
                    "table_index": context.table_index,
                }
                for header, value in zip(table_headers, row):
                    record[header] = value
                writer.writerow(record)

    return output


def write_google_sheets_readme(summary_rows: list[list[str]]) -> None:
    lines = [
        "# Google Sheets 업로드용 통합 CSV",
        "",
        "이 폴더의 `*_combined.csv` 파일은 Google Sheets에 문서별로 가져오기 좋게 합친 파일입니다.",
        "기존 `../csv/*_table_XX.csv` 파일은 Markdown 표 하나당 하나씩 생성된 원본 table export입니다.",
        "",
        "## 추천 사용 순서",
        "",
        "1. Google Sheets에서 새 스프레드시트를 만듭니다.",
        "2. `파일 > 가져오기 > 업로드`를 선택합니다.",
        "3. 필요한 `*_combined.csv`를 업로드합니다.",
        "4. 가져오기 위치는 `새 시트 삽입`을 선택합니다.",
        "5. 다른 통합 CSV도 같은 방식으로 추가합니다.",
        "",
        "## 파일 목록",
        "",
        "| 파일 | 설명 |",
        "|---|---|",
    ]
    lines.extend(f"| `{row[0]}` | {row[1]} |" for row in summary_rows)
    (SHEETS_DIR / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if EXPORT_DIR.exists():
        shutil.rmtree(EXPORT_DIR)
    DOCX_DIR.mkdir(parents=True)
    CSV_DIR.mkdir(parents=True)
    SHEETS_DIR.mkdir(parents=True)

    md_files = sorted(
        path for path in PLANNING_DIR.glob("*.md") if path.name != "README.md"
    )
    summary_rows = [["source", "docx", "csv_count"]]
    sheet_summary_rows: list[list[str]] = []

    for source in md_files:
        lines = source.read_text(encoding="utf-8").splitlines()
        blocks = parse_markdown(lines)
        write_docx(source, blocks)
        csv_outputs = write_csvs(source, blocks)
        combined_csv = write_combined_sheet_csv(
            source,
            extract_tables_with_context(source, lines),
        )
        if combined_csv is not None:
            sheet_summary_rows.append(
                [
                    combined_csv.name,
                    f"{source.stem} 문서의 표를 섹션 기준으로 통합",
                ]
            )
        summary_rows.append(
            [
                str(source.relative_to(ROOT)),
                str((DOCX_DIR / f"{source.stem}.docx").relative_to(ROOT)),
                str(len(csv_outputs)),
            ]
        )

    with (EXPORT_DIR / "export_summary.csv").open(
        "w", newline="", encoding="utf-8-sig"
    ) as file:
        csv.writer(file).writerows(summary_rows)
    if sheet_summary_rows:
        write_google_sheets_readme(sheet_summary_rows)

    print(f"Exported {len(md_files)} DOCX files to {DOCX_DIR.relative_to(ROOT)}")
    print(f"Exported CSV tables to {CSV_DIR.relative_to(ROOT)}")
    print(f"Exported combined sheet CSVs to {SHEETS_DIR.relative_to(ROOT)}")
    print(f"Wrote summary to {(EXPORT_DIR / 'export_summary.csv').relative_to(ROOT)}")


if __name__ == "__main__":
    main()
