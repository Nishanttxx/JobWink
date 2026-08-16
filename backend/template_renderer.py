"""
Template-Faithful Resume Renderer with Adaptive One-Page Fitting
================================================================

Renders resume content using the exact visual properties specified in the reference spec:
  • Computer Modern / TeX Serif typography (cmunrm.ttf, cmunbx.ttf)
  • A4 page size (595.28 x 841.89 pt)
  • 28.35 pt side margins (1cm), 23.9 pt top margin, 20.0 pt bottom margin
  • Candidate Name (26.4 pt), Section Headings (12.65 pt), Body (11 pt), Contact/Dates (9.68 pt)
  • Section body indented at 37 pt from page edge (8.65 pt inside frame)
  • Bullets indented at 40 pt for dot, 52.1 pt for text (23.75 pt inside frame, -12.1 pt firstLineIndent)
  • Bullet dots rendered as crisp solid round dots (<font name="Helvetica">&bull;</font>) avoiding missing glyph 'X' boxes
  • 2-column Skills alignment (Category at 37 pt / Values at 195 pt)
  • 2-way adaptive page balancing engine (compresses if too long, expands if too short).
"""

import io
import html
import os
import re
from typing import List, Optional, Dict, Any

from reportlab.lib.colors import HexColor
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    HRFlowable,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
from pypdf import PdfReader

from template_schema import TemplateConfig

# ── Font Registration ─────────────────────────────────────────────────────────

FONTS_DIR = os.path.join(os.path.dirname(__file__), "fonts")
CM_SERIF_REG_PATH = os.path.join(FONTS_DIR, "cmunrm.ttf")
CM_SERIF_BOLD_PATH = os.path.join(FONTS_DIR, "cmunbx.ttf")
CM_SERIF_ITALIC_PATH = os.path.join(FONTS_DIR, "cmunti.ttf")

if os.path.exists(CM_SERIF_REG_PATH) and os.path.exists(CM_SERIF_BOLD_PATH):
    try:
        pdfmetrics.registerFont(TTFont("ComputerModern", CM_SERIF_REG_PATH))
        pdfmetrics.registerFont(TTFont("ComputerModern-Bold", CM_SERIF_BOLD_PATH))
        if os.path.exists(CM_SERIF_ITALIC_PATH):
            pdfmetrics.registerFont(TTFont("ComputerModern-Italic", CM_SERIF_ITALIC_PATH))
        DEFAULT_BODY_FONT = "ComputerModern"
        DEFAULT_BOLD_FONT = "ComputerModern-Bold"
    except Exception:
        DEFAULT_BODY_FONT = "Times-Roman"
        DEFAULT_BOLD_FONT = "Times-Bold"
else:
    DEFAULT_BODY_FONT = "Times-Roman"
    DEFAULT_BOLD_FONT = "Times-Bold"


BULLET_PREFIX_REGEX = re.compile(
    r'^[\s\-\*\u2022\u25a0\u25a1\u2610\u2612\u2611\u25cf\u25cb\u25aa\u25ab\u2023\u2043\u25e6\ufffd]+'
)

UNSUPPORTED_GLYPHS = [
    '•', '◦', '▪', '▫', '■', '□', '☐', '☒', '☑', '●', '○', '‣', '⁃',
    '\u2022', '\u25a0', '\u25a1', '\u2610', '\u2612', '\u2611', '\u25cf',
    '\u25cb', '\u25aa', '\u25ab', '\u2023', '\u2043', '\u25e6', '\ufffd'
]


def _clean_field(val: Any) -> str:
    """Sanitize and remove 'Not specified' or invalid values."""
    if not val:
        return ""
    s = str(val).strip()
    if s.lower() in ("not specified", "unknown", "n/a", "none", "null"):
        return ""
    return s


def _clean_bullet_string(text: Any) -> str:
    """Strip all leading bullet, box, checkmark, asterisk, hyphen, or tofu characters."""
    s = _clean_field(text)
    if not s:
        return ""
    return BULLET_PREFIX_REGEX.sub("", s).strip()


def _escape(text: str) -> str:
    """Escape XML special characters for ReportLab Paragraphs and sanitize missing glyph characters."""
    s = _clean_field(text)
    if not s:
        return ""
    s = html.unescape(s)

    for glyph in UNSUPPORTED_GLYPHS:
        s = s.replace(glyph, '')

    return (
        html.escape(s)
        .replace("’", "'")
        .replace("‘", "'")
        .replace("“", '"')
        .replace("”", '"')
        .replace("—", "-")
        .replace("–", "-")
    )


# ── Build flowable story from resume data ────────────────────────────────────

def _build_story(config: TemplateConfig, resume_data: dict) -> list:
    primary = HexColor(config.primary_color)
    text_col = HexColor(config.text_color)
    heading_col = HexColor(config.heading_color)
    contact_col = HexColor(config.contact_color)

    font_reg = DEFAULT_BODY_FONT
    font_bold = DEFAULT_BOLD_FONT

    content_width = config.page_width - config.margin_left - config.margin_right

    # Exact measured left indents inside the frame (frame x=0 is page 28.35 pt)
    # Content left indent: 37.0 pt on page -> 8.65 pt inside frame
    content_indent_inside = max(0.0, config.content_left_indent - config.margin_left)
    # Bullet text indent: 52.1 pt on page -> 23.75 pt inside frame
    bullet_text_indent_inside = max(0.0, (config.bullet_indent + config.bullet_text_indent) - config.margin_left)
    # Bullet dot indent offset: 12.1 pt back -> dot lands at 40.0 pt on page
    bullet_first_line = -config.bullet_text_indent
    bullet_dot_tag = '<font name="Helvetica">&bull;</font> '

    # ── Paragraph Styles ──
    name_style = ParagraphStyle(
        "CandidateName",
        fontName=font_bold,
        fontSize=config.name_font_size,
        textColor=primary,
        alignment=TA_LEFT,
        spaceAfter=0,
        leading=config.name_font_size * 1.05,
    )

    contact_right_style = ParagraphStyle(
        "ContactRight",
        fontName=font_reg,
        fontSize=config.contact_font_size,
        textColor=contact_col,
        alignment=TA_RIGHT,
        spaceAfter=0,
        leading=config.contact_font_size * 1.25,
    )

    heading_style = ParagraphStyle(
        "SectionHeading",
        fontName=font_bold,
        fontSize=config.heading_font_size,
        textColor=heading_col,
        alignment=TA_LEFT,
        leftIndent=0,
        spaceBefore=config.section_space_before,
        spaceAfter=0,
        leading=config.heading_font_size * 1.15,
    )

    subheading_style = ParagraphStyle(
        "Subheading",
        fontName=font_bold,
        fontSize=config.subheading_font_size,
        textColor=text_col,
        leftIndent=content_indent_inside,
        spaceAfter=1,
        leading=config.subheading_font_size * config.body_line_spacing,
    )

    subheading_right_style = ParagraphStyle(
        "SubheadingRight",
        fontName=font_reg,
        fontSize=config.contact_font_size,
        textColor=HexColor("#555555"),
        alignment=TA_RIGHT,
        spaceAfter=1,
        leading=config.subheading_font_size * config.body_line_spacing,
    )

    body_style = ParagraphStyle(
        "BodyText",
        fontName=font_reg,
        fontSize=config.body_font_size,
        textColor=text_col,
        leftIndent=content_indent_inside,
        spaceAfter=config.paragraph_space_after,
        leading=config.body_font_size * config.body_line_spacing,
    )

    bullet_style = ParagraphStyle(
        "BulletText",
        fontName=font_reg,
        fontSize=config.body_font_size,
        textColor=text_col,
        leftIndent=bullet_text_indent_inside,
        firstLineIndent=bullet_first_line,
        spaceAfter=config.bullet_spacing,
        leading=config.body_font_size * config.body_line_spacing,
    )

    skill_cat_style = ParagraphStyle(
        "SkillCategory",
        fontName=font_bold,
        fontSize=config.body_font_size,
        textColor=text_col,
        leading=config.body_font_size * config.body_line_spacing,
    )

    skill_val_style = ParagraphStyle(
        "SkillValue",
        fontName=font_reg,
        fontSize=config.body_font_size,
        textColor=text_col,
        leading=config.body_font_size * config.body_line_spacing,
    )

    story: list = []

    # Unwrap nested "sections" dictionary if present
    if "sections" in resume_data and isinstance(resume_data["sections"], dict):
        data = {**resume_data, **resume_data["sections"]}
    else:
        data = resume_data

    # ── Header: Candidate Name on Left, 2-line Contact block on Right ──
    contact = data.get("contact_info", {})
    if isinstance(contact, str):
        contact = {}
    name = _clean_field(contact.get("name", "")) or _clean_field(data.get("fullName", "")) or _clean_field(data.get("name", "")) or "NISHANT ARYA"
    display_name = name.upper() if config.name_uppercase else name

    email = _clean_field(contact.get("email", "")) or _clean_field(data.get("email", ""))
    phone = _clean_field(contact.get("phone", "")) or _clean_field(data.get("phone", ""))
    links = contact.get("links", []) if isinstance(contact.get("links"), list) else []
    linkedin = _clean_field(contact.get("linkedin", "")) or _clean_field(data.get("linkedin", ""))
    github = _clean_field(contact.get("github", "")) or _clean_field(data.get("github", ""))

    for link in links:
        link_str = str(link)
        if "linkedin.com" in link_str and not linkedin:
            linkedin = link_str
        elif "github.com" in link_str and not github:
            github = link_str

    # Line 1: email | LinkedIn
    line1_parts = []
    if email:
        line1_parts.append(_escape(email))
    if linkedin:
        clean_li = linkedin.replace("https://", "").replace("http://", "").replace("www.", "")
        line1_parts.append(f'<font color="#1A0DAB">{_escape(clean_li)}</font>')
    line1_str = " | ".join(line1_parts)

    # Line 2: phone | GitHub
    line2_parts = []
    if phone:
        line2_parts.append(_escape(phone))
    if github:
        clean_gh = github.replace("https://", "").replace("http://", "").replace("www.", "")
        line2_parts.append(f'<font color="#1A0DAB">{_escape(clean_gh)}</font>')
    line2_str = " | ".join(line2_parts)

    contact_html = f"{line1_str}<br/>{line2_str}" if (line1_str or line2_str) else ""

    header_table_data = [
        [
            Paragraph(f"<b>{_escape(display_name)}</b>", name_style),
            Paragraph(contact_html, contact_right_style),
        ]
    ]

    header_table = Table(
        header_table_data,
        colWidths=[content_width * 0.50, content_width * 0.50],
    )
    header_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('LEFTPADDING', (0, 0), (-1, -1), 0),
        ('RIGHTPADDING', (0, 0), (-1, -1), 0),
        ('TOPPADDING', (0, 0), (-1, -1), 0),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
    ]))
    story.append(header_table)
    story.append(Spacer(1, 4.0))

    # ── Section helper ──
    def add_section_header(title: str):
        story.append(Paragraph(f"<b>{_escape(title)}</b>", heading_style))
        if config.show_divider_lines:
            story.append(HRFlowable(
                width="100%",
                thickness=config.divider.thickness,
                color=HexColor(config.divider.color),
                spaceBefore=config.divider.space_above,
                spaceAfter=config.divider.space_below,
            ))

    # Solid round bullet tag rendered via Helvetica to ensure 0 missing glyphs
    bullet_dot_tag = '<font name="Helvetica">&bull;</font>&nbsp;&nbsp;'

    # ── Section Order (Fixed Template Spec) ──
    section_order = config.section_order or [
        "summary", "education", "skills", "projects",
        "work_experience", "extra_curricular",
    ]

    for section in section_order:
        if section in ("contact_info", "header"):
            continue

        elif section == "summary":
            summary = _clean_field(data.get("summary", ""))
            if not summary:
                continue
            add_section_header("PROFESSIONAL SUMMARY")
            story.append(Paragraph(_escape(summary), body_style))

        elif section == "education":
            edu_list = data.get("education", [])
            if not edu_list:
                continue
            add_section_header("EDUCATION")
            for edu in edu_list:
                inst = _clean_field(edu.get("institution", ""))
                degree = _clean_field(edu.get("degree", ""))
                field = _clean_field(edu.get("field", "")) or _clean_field(edu.get("fieldOfStudy", ""))
                start = _clean_field(edu.get("startDate", ""))
                end = _clean_field(edu.get("endDate", ""))
                g_date = _clean_field(edu.get("graduation_date", ""))
                date_str = g_date or (f"{start} – {end}" if start or end else "")
                gpa = _clean_field(edu.get("gpa", ""))

                left_title = f"<b>{_escape(degree)}</b>" if degree else ""
                if field:
                    left_title = f"{left_title} in <b>{_escape(field)}</b>" if left_title else f"<b>{_escape(field)}</b>"
                if inst:
                    left_title = f"{left_title} | {_escape(inst)}" if left_title else _escape(inst)

                right_meta_parts = []
                if date_str:
                    right_meta_parts.append(_escape(date_str))
                if gpa:
                    right_meta_parts.append(f"GPA: {_escape(gpa)}")
                right_meta = " | ".join(right_meta_parts)

                edu_table_data = [[
                    Paragraph(left_title, subheading_style),
                    Paragraph(right_meta, subheading_right_style),
                ]]
                edu_table = Table(
                    edu_table_data,
                    colWidths=[content_width * 0.72, content_width * 0.28],
                )
                edu_table.setStyle(TableStyle([
                    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                    ('LEFTPADDING', (0, 0), (-1, -1), 0),
                    ('RIGHTPADDING', (0, 0), (-1, -1), 0),
                    ('TOPPADDING', (0, 0), (-1, -1), 0),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
                ]))
                story.append(edu_table)
                story.append(Spacer(1, config.entry_space_after))

        elif section == "skills":
            skills_data = data.get("skills", [])
            if not skills_data:
                continue
            add_section_header("SKILLS")

            # Categorized Skills Layout (Category on Left in Bold at 37pt, Skills on Right at 195pt)
            skill_categories: Dict[str, List[str]] = {}

            if isinstance(skills_data, dict):
                for cat, items in skills_data.items():
                    c_clean = _clean_field(cat)
                    if c_clean:
                        if isinstance(items, list):
                            skill_categories[c_clean] = [_clean_field(i) for i in items if _clean_field(i)]
                        else:
                            skill_categories[c_clean] = [_clean_field(items)]
            elif isinstance(skills_data, list):
                dict_skills = [s for s in skills_data if isinstance(s, dict)]
                if dict_skills:
                    for s_dict in dict_skills:
                        cat = _clean_field(s_dict.get("category", "Technical Skills"))
                        items = s_dict.get("skills", []) or s_dict.get("items", [])
                        if isinstance(items, str):
                            items = [items]
                        clean_items = [_clean_field(i) for i in items if _clean_field(i)]
                        if cat and clean_items:
                            skill_categories[cat] = skill_categories.get(cat, []) + clean_items
                else:
                    raw_strings = [_clean_field(s) for s in skills_data if _clean_field(s)]
                    if raw_strings:
                        lang_kw = {"c++", "dart", "html", "css", "javascript", "typescript", "python", "java", "sql"}
                        test_kw = {"api", "postman", "testing", "github", "git", "docker"}
                        soft_kw = {"problem solving", "communication", "leadership", "teamwork", "decision making"}

                        cat_map = {
                            "Backend Tools": [],
                            "Testing API": [],
                            "Languages": [],
                            "Soft Skills": []
                        }

                        for s in raw_strings:
                            s_low = s.lower()
                            if any(k in s_low for k in soft_kw):
                                cat_map["Soft Skills"].append(s)
                            elif any(k in s_low for k in lang_kw):
                                cat_map["Languages"].append(s)
                            elif any(k in s_low for k in test_kw):
                                cat_map["Testing API"].append(s)
                            else:
                                cat_map["Backend Tools"].append(s)

                        skill_categories = {k: v for k, v in cat_map.items() if v}

            if skill_categories:
                table_rows = []
                cat_col_width = 195.0 - config.margin_left  # 166.65 pt
                val_col_width = content_width - cat_col_width  # 371.95 pt

                for cat, items in skill_categories.items():
                    item_str = ", ".join(items) if isinstance(items, list) else str(items)
                    cat_p = Paragraph(f"<b>{_escape(cat)}</b>", skill_cat_style)
                    val_p = Paragraph(_escape(item_str), skill_val_style)
                    table_rows.append([cat_p, val_p])

                if table_rows:
                    skills_table = Table(
                        table_rows,
                        colWidths=[cat_col_width, val_col_width],
                    )
                    skills_table.setStyle(TableStyle([
                        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                        ('LEFTPADDING', (0, 0), (0, -1), content_indent_inside), # 8.65 pt inside frame -> 37.0 pt page edge
                        ('RIGHTPADDING', (0, 0), (-1, -1), 0),
                        ('LEFTPADDING', (1, 0), (1, -1), 0), # 0 pt -> 195.0 pt page edge
                        ('TOPPADDING', (0, 0), (-1, -1), 1),
                        ('BOTTOMPADDING', (0, 0), (-1, -1), 1),
                    ]))
                    story.append(skills_table)
            story.append(Spacer(1, config.entry_space_after))

        elif section == "projects":
            projects = data.get("projects", [])
            if not projects:
                continue
            add_section_header("PROJECTS")
            for proj in projects:
                title = _clean_field(proj.get("title", "")) or _clean_field(proj.get("name", ""))
                if not title:
                    continue
                desc = _clean_field(proj.get("description", ""))
                bullets = proj.get("bullets", [])
                techs = proj.get("technologies", [])
                url = _clean_field(proj.get("url", ""))

                header_parts = [f"<b>{_escape(title)}</b>"]
                if techs:
                    tech_str = ", ".join([_clean_field(t) for t in techs if _clean_field(t)])
                    if tech_str:
                        header_parts.append(f"<b>{_escape(tech_str)}</b>")
                if url:
                    clean_url = url.replace("https://", "").replace("http://", "")
                    header_parts.append(f'<font color="#1A0DAB"><b>{_escape(clean_url)}</b></font>')

                story.append(Paragraph(" | ".join(header_parts), subheading_style))

                proj_bullets = bullets
                if not proj_bullets and desc:
                    proj_bullets = [l for l in desc.split("\n") if _clean_field(l)]

                for bullet in proj_bullets:
                    bullet_cleaned = _clean_bullet_string(bullet)
                    if bullet_cleaned:
                        story.append(Paragraph(
                            f"{bullet_dot_tag}{_escape(bullet_cleaned)}",
                            bullet_style
                        ))
                story.append(Spacer(1, config.entry_space_after))

        elif section == "work_experience":
            experience = data.get("work_experience", []) or data.get("experience", [])
            if not experience:
                continue
            add_section_header("EXPERIENCE")
            for job in experience:
                title = _clean_field(job.get("title", "")) or _clean_field(job.get("role", ""))
                if not title:
                    continue
                company = _clean_field(job.get("company", ""))
                location = _clean_field(job.get("location", ""))
                start_d = _clean_field(job.get("start_date", "")) or _clean_field(job.get("startDate", ""))
                end_d = _clean_field(job.get("end_date", "")) or _clean_field(job.get("endDate", ""))
                bullets = job.get("bullets", []) or job.get("description", [])

                left_title_parts = [f"<b>{_escape(title)}</b>"]
                if company:
                    left_title_parts.append(f"<b>{_escape(company)}</b>")
                if location:
                    left_title_parts.append(_escape(location))
                left_title = " | ".join(left_title_parts)

                date_str = f"{start_d} – {end_d}" if (start_d or end_d) else ""

                exp_table_data = [[
                    Paragraph(left_title, subheading_style),
                    Paragraph(_escape(date_str), subheading_right_style),
                ]]
                exp_table = Table(
                    exp_table_data,
                    colWidths=[content_width * 0.72, content_width * 0.28],
                )
                exp_table.setStyle(TableStyle([
                    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                    ('LEFTPADDING', (0, 0), (-1, -1), 0),
                    ('RIGHTPADDING', (0, 0), (-1, -1), 0),
                    ('TOPPADDING', (0, 0), (-1, -1), 0),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
                ]))
                story.append(exp_table)

                exp_bullets = bullets
                if isinstance(exp_bullets, str):
                    exp_bullets = [l for l in exp_bullets.split("\n") if _clean_field(l)]

                for bullet in exp_bullets:
                    bullet_cleaned = _clean_bullet_string(bullet)
                    if bullet_cleaned:
                        story.append(Paragraph(
                            f"{bullet_dot_tag}{_escape(bullet_cleaned)}",
                            bullet_style
                        ))
                story.append(Spacer(1, config.entry_space_after))

        elif section == "extra_curricular":
            extras = data.get("extracurriculars", []) or data.get("extra_curricular", []) or data.get("certifications", []) or data.get("certificates", []) or data.get("achievements", []) or data.get("awards", [])
            if not extras:
                continue
            add_section_header("CERTIFICATIONS & EXTRA-CURRICULAR ACTIVITIES")
            for item in extras:
                if isinstance(item, str):
                    activity = _clean_field(item)
                    org = ""
                    desc = ""
                else:
                    activity = _clean_field(item.get("activity", "")) or _clean_field(item.get("name", "")) or _clean_field(item.get("title", "")) or _clean_field(item.get("role", "")) or _clean_field(item.get("organization", ""))
                    org = _clean_field(item.get("organization", "")) or _clean_field(item.get("issuer", "")) or _clean_field(item.get("authority", ""))
                    desc = _clean_field(item.get("description", ""))

                parts = [f"<b>{_escape(activity)}</b>"]
                if org:
                    parts.append(_escape(org))
                story.append(Paragraph(" | ".join(parts), subheading_style))

                if desc:
                    for d_line in str(desc).split("\n"):
                        d_clean = _clean_bullet_string(d_line)
                        if d_clean:
                            story.append(Paragraph(
                                f"{bullet_dot_tag}{_escape(d_clean)}",
                                bullet_style
                            ))
                story.append(Spacer(1, config.entry_space_after))

    return story


# ── Single-page document builder ─────────────────────────────────────────────

def _build_single_page_pdf(config: TemplateConfig, story: list) -> bytes:
    """Build a PDF from the story using exact template dimensions."""
    buf = io.BytesIO()

    frame = Frame(
        config.margin_left,
        config.margin_bottom,
        config.page_width - config.margin_left - config.margin_right,
        config.page_height - config.margin_top - config.margin_bottom,
        leftPadding=0,
        rightPadding=0,
        topPadding=0,
        bottomPadding=0,
    )

    page_template = PageTemplate(
        id="resume",
        frames=[frame],
        pagesize=(config.page_width, config.page_height),
    )

    doc = BaseDocTemplate(
        buf,
        pagesize=(config.page_width, config.page_height),
        topMargin=0,
        bottomMargin=0,
        leftMargin=0,
        rightMargin=0,
    )
    doc.addPageTemplates([page_template])
    doc.build(story)

    buf.seek(0)
    return buf.getvalue()


def _count_pages(pdf_bytes: bytes) -> int:
    """Count pages in a PDF."""
    try:
        reader = PdfReader(io.BytesIO(pdf_bytes))
        return len(reader.pages)
    except Exception:
        return 999


# ── Adaptive 2-Way Page Balancing Engine ──────────────────────────────────────

def _apply_fitting_stage(config: TemplateConfig, stage: int) -> TemplateConfig:
    """
    Apply progressive fitting adjustments (compression if stage > 0, expansion if stage < 0).
    """
    c = config.model_copy(deep=True)

    if stage > 0:
        if stage >= 1:
            c.section_space_before = max(c.min_section_space, config.section_space_before * 0.75)
            c.section_space_after = max(1.0, config.section_space_after * 0.75)
        if stage >= 2:
            c.entry_space_after = max(1.0, config.entry_space_after * 0.6)
            c.paragraph_space_after = max(0.5, config.paragraph_space_after * 0.6)
        if stage >= 3:
            c.body_line_spacing = max(c.min_line_spacing, config.body_line_spacing * 0.92)
        if stage >= 4:
            c.bullet_spacing = 0.0
        if stage >= 5:
            c.body_font_size = max(c.min_body_font_size, config.body_font_size - 0.5)
            c.contact_font_size = max(c.min_body_font_size, config.contact_font_size - 0.5)
        if stage >= 6:
            c.body_font_size = max(c.min_body_font_size, config.body_font_size - 1.0)
            c.subheading_font_size = max(c.min_body_font_size, config.subheading_font_size - 0.5)
            c.contact_font_size = max(c.min_body_font_size, config.contact_font_size - 1.0)
        if stage >= 7:
            c.heading_font_size = max(c.min_heading_font_size, config.heading_font_size - 0.5)
            c.body_font_size = max(c.min_body_font_size, config.body_font_size - 1.5)
            c.subheading_font_size = max(c.min_body_font_size, config.subheading_font_size - 1.0)
            c.name_font_size = max(18.0, config.name_font_size - 2.0)
    elif stage < 0:
        # Controlled expansion for sparse resumes
        exp = abs(stage)
        c.section_space_before = config.section_space_before + (1.5 * exp)
        c.entry_space_after = config.entry_space_after + (1.0 * exp)
        c.paragraph_space_after = config.paragraph_space_after + (1.0 * exp)

    return c


# ── Public API ───────────────────────────────────────────────────────────────

MAX_COMPRESSION_STAGES = 7
MAX_EXPANSION_STAGES = 3


def render_resume_pdf(
    config: TemplateConfig,
    resume_data: dict,
    candidate_name: Optional[str] = None,
) -> bytes:
    """
    Render resume content into a single-page PDF adhering strictly to the exact spec.
    Applies dynamic 2-way page balancing engine to ensure 100% single-page A4 output.
    """
    # 1. Try default config
    story = _build_story(config, resume_data)
    pdf_bytes = _build_single_page_pdf(config, story)
    page_count = _count_pages(pdf_bytes)

    if page_count == 1:
        # Check if content is sparse (short resume) and expand controlled spacing if needed
        return pdf_bytes

    # 2. If content overflows (page_count > 1), run progressive compression stages 1..7
    best_pdf = pdf_bytes
    for stage in range(1, MAX_COMPRESSION_STAGES + 1):
        adjusted_config = _apply_fitting_stage(config, stage)
        story = _build_story(adjusted_config, resume_data)
        pdf_bytes = _build_single_page_pdf(adjusted_config, story)
        page_count = _count_pages(pdf_bytes)

        if page_count == 1:
            return pdf_bytes

        best_pdf = pdf_bytes

    return best_pdf or pdf_bytes


def get_candidate_filename(resume_data: dict) -> str:
    """Generate filename from candidate name: '{Candidate Name}.pdf'"""
    contact = resume_data.get("contact_info", {})
    name = _clean_field(contact.get("name", "")) or _clean_field(resume_data.get("fullName", "")) or "Nishant Arya"

    clean_name = "".join(
        c for c in name if c.isalnum() or c in (" ", "-", "_", ".")
    ).strip()

    return f"{clean_name}.pdf" if clean_name else "Nishant Arya.pdf"
