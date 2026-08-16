"""
Deep PDF Template Analyzer
==========================

Inspects an original resume PDF to extract every visual property needed
to faithfully re-render tailored content in the same design.

Extraction targets:
  • Page dimensions (from MediaBox)
  • Content bounding box → margins
  • Font names and sizes used at each vertical position
  • Text colors (from content stream)
  • Horizontal rule / line drawing operations → dividers
  • Section headings → section order
  • Bullet characters → bullet style
  • Contact separator patterns
"""

import io
import re
from collections import Counter
from typing import Dict, List, Optional, Tuple

from pypdf import PdfReader
from template_schema import DividerConfig, TemplateConfig


# ── Font name normalization ──────────────────────────────────────────────────

# PDF font names often contain subset prefixes like "ABCDEF+" or style
# suffixes like ",Bold".  Normalize to ReportLab-compatible base names.

_FONT_MAP: Dict[str, str] = {
    "calibri": "Helvetica",
    "arial": "Helvetica",
    "helvetica": "Helvetica",
    "times": "Times-Roman",
    "timesnewroman": "Times-Roman",
    "garamond": "Times-Roman",
    "georgia": "Times-Roman",
    "cambria": "Times-Roman",
    "verdana": "Helvetica",
    "tahoma": "Helvetica",
    "trebuchetms": "Helvetica",
    "segoeui": "Helvetica",
    "roboto": "Helvetica",
    "lato": "Helvetica",
    "opensans": "Helvetica",
    "sourcesanspro": "Helvetica",
    "inter": "Helvetica",
    "montserrat": "Helvetica",
    "raleway": "Helvetica",
    "poppins": "Helvetica",
    "ubuntu": "Helvetica",
    "nunito": "Helvetica",
    "couriernew": "Courier",
    "courier": "Courier",
    "consolas": "Courier",
}


def _normalize_font_name(raw_name: str) -> str:
    """Map a PDF font name to a ReportLab built-in font."""
    # Strip subset prefix (e.g. "BCDEEE+Calibri-Bold" → "Calibri-Bold")
    cleaned = re.sub(r"^[A-Z]{6}\+", "", raw_name)

    is_bold = any(t in cleaned.lower() for t in ["bold", "heavy", "black", "demi"])
    is_italic = any(t in cleaned.lower() for t in ["italic", "oblique", "slant"])

    # Extract base family name
    base = re.split(r"[-,]", cleaned)[0].strip()
    base_lower = re.sub(r"\s+", "", base.lower())

    mapped = _FONT_MAP.get(base_lower, "Helvetica")

    if mapped == "Helvetica":
        if is_bold and is_italic:
            return "Helvetica-BoldOblique"
        elif is_bold:
            return "Helvetica-Bold"
        elif is_italic:
            return "Helvetica-Oblique"
        return "Helvetica"
    elif mapped == "Times-Roman":
        if is_bold and is_italic:
            return "Times-BoldItalic"
        elif is_bold:
            return "Times-Bold"
        elif is_italic:
            return "Times-Italic"
        return "Times-Roman"
    elif mapped == "Courier":
        if is_bold and is_italic:
            return "Courier-BoldOblique"
        elif is_bold:
            return "Courier-Bold"
        elif is_italic:
            return "Courier-Oblique"
        return "Courier"

    return mapped


# ── Font extraction from PDF objects ─────────────────────────────────────────

def _extract_fonts_from_page(page) -> Dict[str, dict]:
    """
    Walk the page's /Resources → /Font dictionary and extract
    font base-names and any embedded size hints.

    Returns {pdf_internal_name: {"base_name": str, "mapped": str}}
    """
    fonts: Dict[str, dict] = {}
    try:
        resources = page.get("/Resources")
        if resources is None:
            return fonts
        font_dict = resources.get("/Font")
        if font_dict is None:
            return fonts

        for font_key in font_dict:
            font_obj = font_dict[font_key]
            if hasattr(font_obj, "get_object"):
                font_obj = font_obj.get_object()
            base_name = ""
            if "/BaseFont" in font_obj:
                base_name = str(font_obj["/BaseFont"]).lstrip("/")
            elif "/Name" in font_obj:
                base_name = str(font_obj["/Name"]).lstrip("/")

            fonts[font_key.lstrip("/")] = {
                "base_name": base_name,
                "mapped": _normalize_font_name(base_name),
            }
    except Exception:
        pass

    return fonts


# ── Content stream analysis ──────────────────────────────────────────────────

def _analyze_content_stream(page) -> dict:
    """
    Parse the raw page content stream to extract:
      • Font usage with sizes (Tf operators)
      • Text positioning (Td/Tm operators)
      • Line drawing (re/l/m operators) → dividers
      • Color changes (rg/RG/g/G/k/K operators)
      • Text strings (Tj/TJ operators)
    """
    info = {
        "font_uses": [],       # [(font_name, size, y_position)]
        "text_blocks": [],     # [(text, font_name, size, x, y)]
        "lines": [],           # [(x1, y1, x2, y2, width)]
        "colors": [],          # [(r, g, b)]
        "min_x": 9999.0,
        "max_x": 0.0,
        "min_y": 9999.0,
        "max_y": 0.0,
    }

    try:
        contents = page.get_contents()
        if contents is None:
            return info

        if hasattr(contents, "get_data"):
            raw_data = contents.get_data()
        elif hasattr(contents, "get_object"):
            obj = contents.get_object()
            if hasattr(obj, "get_data"):
                raw_data = obj.get_data()
            else:
                return info
        else:
            return info

        if isinstance(raw_data, bytes):
            stream_text = raw_data.decode("latin-1", errors="replace")
        else:
            stream_text = str(raw_data)

    except Exception:
        return info

    current_font = ""
    current_size = 10.0
    current_x = 0.0
    current_y = 0.0
    path_x = 0.0
    path_y = 0.0
    line_width = 0.5

    # Simple operator parser
    tokens = re.findall(
        r"""
        (                         # capture group
            /[A-Za-z0-9_]+        # name tokens like /F1
          | -?\d+\.?\d*           # numbers
          | \([^)]*\)             # literal strings
          | <[0-9a-fA-F]*>        # hex strings
          | [A-Za-z'"*]{1,3}      # operators (Tf, Td, Tj, TJ, re, l, m, rg, etc.)
        )
        """,
        stream_text,
        re.VERBOSE,
    )

    i = 0
    operand_stack = []
    while i < len(tokens):
        token = tokens[i].strip()

        # Operators
        if token == "Tf" and len(operand_stack) >= 2:
            # Set font: /FontName size Tf
            current_font = operand_stack[-2].lstrip("/")
            try:
                current_size = float(operand_stack[-1])
            except ValueError:
                pass
            info["font_uses"].append((current_font, current_size, current_y))
            operand_stack.clear()

        elif token == "Td" and len(operand_stack) >= 2:
            try:
                current_x += float(operand_stack[-2])
                current_y += float(operand_stack[-1])
            except ValueError:
                pass
            operand_stack.clear()

        elif token == "TD" and len(operand_stack) >= 2:
            try:
                current_x += float(operand_stack[-2])
                current_y += float(operand_stack[-1])
            except ValueError:
                pass
            operand_stack.clear()

        elif token == "Tm" and len(operand_stack) >= 6:
            try:
                current_x = float(operand_stack[-2])
                current_y = float(operand_stack[-1])
            except ValueError:
                pass
            operand_stack.clear()

        elif token == "BT":
            # Begin text — reset position tracking
            operand_stack.clear()

        elif token in ("Tj", "'", '"'):
            # Text showing operators
            for op in operand_stack:
                if op.startswith("(") and op.endswith(")"):
                    text = op[1:-1]
                    info["text_blocks"].append(
                        (text, current_font, current_size, current_x, current_y)
                    )
                    if current_x < info["min_x"]:
                        info["min_x"] = current_x
                    if current_x > info["max_x"]:
                        info["max_x"] = current_x
                    if current_y < info["min_y"]:
                        info["min_y"] = current_y
                    if current_y > info["max_y"]:
                        info["max_y"] = current_y
            operand_stack.clear()

        elif token == "TJ":
            # Array of text
            for op in operand_stack:
                if op.startswith("(") and op.endswith(")"):
                    text = op[1:-1]
                    info["text_blocks"].append(
                        (text, current_font, current_size, current_x, current_y)
                    )
                    if current_x < info["min_x"]:
                        info["min_x"] = current_x
                    if current_y < info["min_y"]:
                        info["min_y"] = current_y
                    if current_y > info["max_y"]:
                        info["max_y"] = current_y
            operand_stack.clear()

        elif token == "m" and len(operand_stack) >= 2:
            # moveto
            try:
                path_x = float(operand_stack[-2])
                path_y = float(operand_stack[-1])
            except ValueError:
                pass
            operand_stack.clear()

        elif token == "l" and len(operand_stack) >= 2:
            # lineto — record horizontal lines as potential dividers
            try:
                lx = float(operand_stack[-2])
                ly = float(operand_stack[-1])
                # Horizontal line check (same y within tolerance)
                if abs(ly - path_y) < 2.0:
                    info["lines"].append(
                        (path_x, path_y, lx, ly, line_width)
                    )
            except ValueError:
                pass
            operand_stack.clear()

        elif token == "re" and len(operand_stack) >= 4:
            # Rectangle — thin rectangles are often divider lines
            try:
                rx = float(operand_stack[-4])
                ry = float(operand_stack[-3])
                rw = float(operand_stack[-2])
                rh = float(operand_stack[-1])
                if rh < 3.0 and rw > 50:  # thin horizontal rect = divider
                    info["lines"].append((rx, ry, rx + rw, ry, rh))
            except ValueError:
                pass
            operand_stack.clear()

        elif token == "w" and len(operand_stack) >= 1:
            try:
                line_width = float(operand_stack[-1])
            except ValueError:
                pass
            operand_stack.clear()

        elif token == "rg" and len(operand_stack) >= 3:
            try:
                r = float(operand_stack[-3])
                g = float(operand_stack[-2])
                b = float(operand_stack[-1])
                info["colors"].append((r, g, b))
            except ValueError:
                pass
            operand_stack.clear()

        elif token == "g" and len(operand_stack) >= 1:
            try:
                gray = float(operand_stack[-1])
                info["colors"].append((gray, gray, gray))
            except ValueError:
                pass
            operand_stack.clear()

        elif token in ("S", "s", "f", "F", "B", "n", "ET", "Q", "q",
                        "cm", "cs", "CS", "sc", "SC", "Do", "gs"):
            operand_stack.clear()

        else:
            operand_stack.append(token)

        i += 1

    return info


# ── Section order detection ──────────────────────────────────────────────────

_KNOWN_SECTIONS = {
    "summary": r"(?:professional\s+)?summary|objective|profile",
    "education": r"education|academic",
    "skills": r"(?:technical\s+)?skills|competenc",
    "projects": r"projects?|key\s+projects",
    "work_experience": r"(?:work\s+)?experience|employment|history",
    "extra_curricular": r"extra[\s\-]?curricular|achievements?|activities|certifications?|awards?",
}


def _detect_section_order(full_text: str) -> List[str]:
    """Detect section order from heading occurrences in extracted text."""
    positions = []
    for sec_key, pattern in _KNOWN_SECTIONS.items():
        match = re.search(pattern, full_text, re.IGNORECASE)
        if match:
            positions.append((match.start(), sec_key))

    positions.sort(key=lambda x: x[0])
    order = ["contact_info"] + [sec for _, sec in positions]

    # Fill missing defaults
    for sec in ["summary", "education", "skills", "projects",
                 "work_experience", "extra_curricular"]:
        if sec not in order:
            order.append(sec)

    return order


# ── Bullet character detection ───────────────────────────────────────────────

def _detect_bullet_char(full_text: str) -> str:
    """Determine the most common bullet character used."""
    candidates = {"•": 0, "●": 0, "◦": 0, "▪": 0, "■": 0, "-": 0, "–": 0, "▸": 0}
    for char in candidates:
        candidates[char] = full_text.count(char)

    # Also check for lines starting with "- " pattern
    dash_bullets = len(re.findall(r"^\s*-\s", full_text, re.MULTILINE))
    candidates["-"] = max(candidates["-"], dash_bullets)

    best = max(candidates, key=candidates.get)
    return best if candidates[best] > 0 else "•"


# ── Color conversion ────────────────────────────────────────────────────────

def _rgb_to_hex(r: float, g: float, b: float) -> str:
    """Convert 0.0–1.0 RGB to hex color string."""
    ri = max(0, min(255, int(r * 255)))
    gi = max(0, min(255, int(g * 255)))
    bi = max(0, min(255, int(b * 255)))
    return f"#{ri:02X}{gi:02X}{bi:02X}"


# ── Main Analyzer ───────────────────────────────────────────────────────────

def analyze_template(
    pdf_bytes: bytes, source_filename: str = "", template_id: str = ""
) -> TemplateConfig:
    """
    Analyze a template PDF to extract a complete visual configuration.

    This performs deep inspection of the PDF structure to determine:
    - Page dimensions and content margins
    - Font families and sizes used at different hierarchy levels
    - Text colors
    - Section divider properties
    - Section ordering
    - Bullet styles
    """
    reader = PdfReader(io.BytesIO(pdf_bytes))

    # ── Page dimensions ──
    page_width = 612.0
    page_height = 792.0

    if reader.pages:
        first_page = reader.pages[0]
        page_width = float(first_page.mediabox.width)
        page_height = float(first_page.mediabox.height)

    # ── Extract text for section ordering and bullet detection ──
    full_text = "\n".join(page.extract_text() or "" for page in reader.pages)

    section_order = _detect_section_order(full_text)
    bullet_char = _detect_bullet_char(full_text)

    # ── Deep content stream analysis ──
    fonts_catalog: Dict[str, dict] = {}
    content_info = {
        "font_uses": [],
        "text_blocks": [],
        "lines": [],
        "colors": [],
        "min_x": 9999.0,
        "max_x": 0.0,
        "min_y": 9999.0,
        "max_y": 0.0,
    }

    if reader.pages:
        first_page = reader.pages[0]
        fonts_catalog = _extract_fonts_from_page(first_page)
        content_info = _analyze_content_stream(first_page)

    # ── Determine font families and sizes from usage ──

    # Group font uses by size to identify hierarchy
    size_counter: Counter = Counter()
    font_by_size: Dict[float, str] = {}

    for font_name, size, y_pos in content_info["font_uses"]:
        size_counter[size] += 1
        if size not in font_by_size:
            # Map internal font name to base name
            if font_name in fonts_catalog:
                font_by_size[size] = fonts_catalog[font_name]["mapped"]
            else:
                font_by_size[size] = _normalize_font_name(font_name)

    # Sort sizes descending — largest is name, next is heading, most common is body
    sorted_sizes = sorted(size_counter.keys(), reverse=True)

    name_font_size = sorted_sizes[0] if len(sorted_sizes) > 0 else 20.0
    heading_font_size = sorted_sizes[1] if len(sorted_sizes) > 1 else 11.0

    # Body font = most frequently used size
    if size_counter:
        body_font_size = size_counter.most_common(1)[0][0]
    else:
        body_font_size = 9.5

    # Ensure heading is between name and body
    if heading_font_size <= body_font_size and len(sorted_sizes) > 2:
        heading_font_size = sorted_sizes[1] if sorted_sizes[1] > body_font_size else body_font_size + 1.0

    # Subheading size — between heading and body
    subheading_font_size = body_font_size + 0.5
    for s in sorted_sizes:
        if body_font_size < s < heading_font_size:
            subheading_font_size = s
            break

    # Contact font — usually smallest or near-body
    contact_font_size = body_font_size
    for s in sorted_sizes:
        if s < body_font_size:
            contact_font_size = s
            break

    # ── Map font families ──
    name_font = font_by_size.get(name_font_size, "Helvetica-Bold")
    heading_font = font_by_size.get(heading_font_size, "Helvetica-Bold")
    body_font = font_by_size.get(body_font_size, "Helvetica")
    subheading_font = font_by_size.get(subheading_font_size, "Helvetica-Bold")
    contact_font = font_by_size.get(contact_font_size, "Helvetica")

    # ── Margins from content bounds ──
    # Content stream coordinates: origin at bottom-left
    margin_left = max(36.0, content_info["min_x"]) if content_info["min_x"] < 9000 else 54.0
    margin_right = max(36.0, page_width - content_info["max_x"]) if content_info["max_x"] > 0 else 54.0
    margin_bottom = max(24.0, content_info["min_y"]) if content_info["min_y"] < 9000 else 36.0
    margin_top = max(24.0, page_height - content_info["max_y"]) if content_info["max_y"] > 0 else 36.0

    # ── Colors ──
    primary_color = "#000000"
    text_color = "#000000"

    if content_info["colors"]:
        # Most common color is body text
        color_counter = Counter()
        for r, g, b in content_info["colors"]:
            hex_col = _rgb_to_hex(r, g, b)
            color_counter[hex_col] += 1

        most_common_color = color_counter.most_common(1)[0][0]
        text_color = most_common_color
        primary_color = most_common_color

        # If there are multiple distinct colors, the less-common one is likely headings
        if len(color_counter) > 1:
            colors_ranked = color_counter.most_common()
            # If a non-black color exists, it might be accent
            for col, count in colors_ranked:
                if col != "#000000" and col != most_common_color:
                    primary_color = col
                    break

    # ── Divider lines ──
    show_dividers = len(content_info["lines"]) > 0
    divider_thickness = 0.75
    if content_info["lines"]:
        thicknesses = [line[4] for line in content_info["lines"]]
        divider_thickness = max(0.25, min(3.0, sum(thicknesses) / len(thicknesses)))

    # ── Contact separator detection ──
    contact_sep = " | "
    if " | " in full_text[:500]:
        contact_sep = " | "
    elif " • " in full_text[:500]:
        contact_sep = " • "
    elif " · " in full_text[:500]:
        contact_sep = " · "
    elif "  |  " in full_text[:500]:
        contact_sep = "  |  "

    # ── Name alignment detection ──
    name_alignment = 1  # default center
    # Check first text block position relative to page center
    if content_info["text_blocks"]:
        first_x = content_info["text_blocks"][0][3]
        page_center = page_width / 2.0
        if first_x < page_center * 0.4:
            name_alignment = 0  # left-aligned
        elif first_x > page_center * 1.2:
            name_alignment = 2  # right-aligned
        else:
            name_alignment = 1  # centered

    # ── Detect if name is uppercase ──
    name_uppercase = False
    lines = full_text.strip().split("\n")
    if lines:
        first_line = lines[0].strip()
        if first_line and first_line == first_line.upper() and len(first_line) > 2:
            name_uppercase = True

    return TemplateConfig(
        template_id=template_id,
        source_filename=source_filename,
        page_width=page_width,
        page_height=page_height,
        margin_top=margin_top,
        margin_bottom=margin_bottom,
        margin_left=margin_left,
        margin_right=margin_right,
        name_font_family=name_font,
        heading_font_family=heading_font,
        subheading_font_family=subheading_font,
        body_font_family=body_font,
        contact_font_family=contact_font,
        name_font_size=name_font_size,
        heading_font_size=heading_font_size,
        subheading_font_size=subheading_font_size,
        body_font_size=body_font_size,
        contact_font_size=contact_font_size,
        title_font_size=name_font_size,  # backward compat
        name_letter_spacing=0.0,
        name_alignment=name_alignment,
        name_uppercase=name_uppercase,
        primary_color=primary_color,
        text_color=text_color,
        accent_color=primary_color,
        contact_color=text_color,
        heading_color=primary_color,
        show_divider_lines=show_dividers,
        divider=DividerConfig(
            thickness=divider_thickness,
            color=primary_color,
        ),
        bullet_char=bullet_char,
        contact_separator=contact_sep,
        contact_alignment=name_alignment,
        section_order=section_order,
    )
