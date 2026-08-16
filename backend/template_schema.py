from typing import List, Optional, Dict
from pydantic import BaseModel, Field


class DividerConfig(BaseModel):
    """Visual properties of section divider lines."""
    thickness: float = 0.6          # 0.5–0.8 pt
    color: str = "#000000"
    width_percent: float = 100.0   # percent of content width
    space_above: float = 0.5       # points
    space_below: float = 2.5       # points


class TemplateConfig(BaseModel):
    """
    Complete visual blueprint extracted from the original resume PDF.
    Captures exact dimensions, fonts, colors, and layout metrics as specified in the exact resume spec.
    """
    template_id: str = ""
    source_filename: str = ""

    # ── Page Geometry (A4 Portrait) ──
    page_width: float = 595.28       # points (A4)
    page_height: float = 841.89      # points (A4)

    # ── Margins ──
    margin_top: float = 23.9        # ~0.8cm
    margin_bottom: float = 20.0     # ~0.6cm bottom margin
    margin_left: float = 28.35      # 1cm
    margin_right: float = 28.35     # 1cm

    # ── Typography — Font Families (Computer Modern / Times-Roman fallbacks) ──
    name_font_family: str = "Times-Bold"
    heading_font_family: str = "Times-Bold"
    subheading_font_family: str = "Times-Bold"
    body_font_family: str = "Times-Roman"
    contact_font_family: str = "Times-Roman"

    # ── Typography — Font Sizes (points) ──
    name_font_size: float = 26.4
    heading_font_size: float = 12.65
    subheading_font_size: float = 11.0
    body_font_size: float = 11.0
    contact_font_size: float = 9.68
    title_font_size: float = 26.4

    # ── Typography — Spacing ──
    body_line_spacing: float = 1.3    # ~14.5pt line height at 11pt font
    bullet_spacing: float = 1.0       # extra pts between bullets
    section_space_before: float = 9.5  # 9-10 pt gap before section
    section_space_after: float = 4.0   # 4-6 pt after section divider
    paragraph_space_after: float = 3.0 # pts after a paragraph block
    entry_space_after: float = 4.0     # pts after each entry

    # ── Typography — Name Header ──
    name_letter_spacing: float = 0.0
    name_alignment: int = 0            # 0=left alignment
    name_uppercase: bool = True

    # ── Colors ──
    primary_color: str = "#000000"     # headings, name
    text_color: str = "#333333"        # body text
    accent_color: str = "#1A0DAB"      # links (LinkedIn, GitHub, Repos)
    contact_color: str = "#333333"     # contact info text
    heading_color: str = "#000000"     # section headings

    # ── Section Dividers ──
    show_divider_lines: bool = True
    divider: DividerConfig = Field(default_factory=DividerConfig)

    # ── Indents & Bullet Style ──
    content_left_indent: float = 8.65  # 37.0 pt content left relative to 28.35 margin
    bullet_char: str = "◦"
    bullet_indent: float = 11.65       # 40.0 pt bullet position relative to margin
    bullet_text_indent: float = 12.1   # 52.1 pt text position relative to bullet

    # ── Contact Layout ──
    contact_separator: str = " | "
    contact_alignment: int = 2         # 2=right alignment for contact box

    # ── Section Order ──
    section_order: List[str] = Field(
        default_factory=lambda: [
            "contact_info",
            "summary",
            "education",
            "skills",
            "projects",
            "work_experience",
            "extra_curricular",
        ]
    )

    # ── Adaptive Fitting Limits ──
    min_body_font_size: float = 9.5    # minimum body size before emergency strategy
    min_heading_font_size: float = 11.0
    min_line_spacing: float = 1.0
    min_section_space: float = 4.0
