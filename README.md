<div align="center">

<img src="assets/images/jobwink_logo.png" width="96" alt="JobWink" />

# JobWink

### The job hunt, automated end to end.

**Resume → ATS score → Swipe-to-apply → Salary prediction → Pipeline tracking.**
One Flutter app. One AI brain. Zero spreadsheets.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-Python-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Supabase](https://img.shields.io/badge/Supabase-Postgres-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)

[**Live App**](https://jobwink.pages.dev) · [Features](#-what-it-does) · [Architecture](#-how-it-fits-together) · [Setup](#-run-it-locally) · [AI Stack](#-the-ai-stack)

</div>

<br>

> Most job-search tools do **one** thing — a resume builder, or a tracker, or a swipe deck.
> JobWink does the whole loop: it writes your resume, scores it against the job, finds you the job, predicts what it pays, and remembers where you left off.

<br>

## ⚡ What it does

<table>
<tr>
<td width="50%" valign="top">

### 📝 Resume Editor
Upload a PDF/DOCX or start blank — AI parses and populates every section. Pull project descriptions straight from GitHub. Live PDF preview as you type. Full version history in Supabase.

### 🎯 ATS Score Engine
Paste a JD, watch an animated gauge score your match in real time. Keywords are ranked High/Medium/Low priority and highlighted directly in your resume — gaps get called out with suggestions.

</td>
<td width="50%" valign="top">

### 💼 Swipe Job Matcher
Tinder for your career. Spring-physics swipe cards, jobs ranked by AI match %, saved/passed stacks, one-tap apply straight to the source listing.

### 🔮 Salary Predictor
An ML model reads your resume + a JD and returns a predicted salary range with a confidence interval — plus a feature-by-feature breakdown of what drove the number.

</td>
</tr>
</table>

Also included: a **Kanban application tracker** (Saved → Applied → Interviewing → Offer), an **admin dashboard** for quota and user management, and a full **marketing landing page** with dark/light theming baked in.

<br>

## 🧠 The AI stack

JobWink doesn't bet on one model — it cascades through a provider chain so a rate limit never becomes downtime.

```
  Gemini 2.5 Flash/Pro  →  Groq (Llama 3.3 70B)  →  OpenAI GPT-4o  →  xAI Grok-3  →  NVIDIA Nemotron
        primary               fallback #1            fallback #2      fallback #3      fallback #4

              plus specialists on standby: Cerebras · Mistral · HuggingFace
```

If the primary provider errors or hits quota, the orchestrator silently retries down the chain — the user never sees it.

<br>

## 🏗️ How it fits together

```
Flutter Web App  ──▶  AI Service (multi-provider orchestrator)
      │                        │
      │                        ▼
      │              Provider cascade (Gemini → Groq → OpenAI → ...)
      │
      ▼
Python FastAPI Backend  ──▶  Template Analyzer · Renderer · Salary Predictor
      │
      ▼
Supabase (Postgres)  ──  users · resumes · history · usage logs · quotas
      ▲
      │
Job Collector (Python)  ──  multi-source scrapers → dedupe → normalize → sync
```

<br>

## 🚀 Run it locally

```bash
git clone https://github.com/Nishanttxx/JobWink.git
cd JobWink

# 1. Environment
cp .env.example .env        # add your Supabase + AI provider keys

# 2. Flutter frontend
flutter pub get
flutter run -d chrome       # or: -d web-server --web-port 8080

# 3. Python backend (separate terminal)
cd backend
pip install -r requirements.txt
python backend_main.py      # → http://127.0.0.1:8000
```

<details>
<summary><strong>Windows: auto-start the backend on boot</strong></summary>

<br>

```powershell
.\install_background_service.ps1
```

Registers `start_backend_silent.vbs` as a Startup entry, so the FastAPI server is always running in the background.

</details>

<br>

## 📡 Backend API

| Method | Endpoint | What it does |
|---|---|---|
| `POST` | `/resume/new` | Create a blank resume |
| `POST` | `/resume/upload` | Upload PDF/DOCX → AI-parsed sections |
| `PATCH` | `/resume/{id}/section/{name}` | Update one section |
| `POST` | `/resume/{id}/tailor` | AI-tailor resume to a JD |
| `GET` | `/resume/{id}/export` | Download as PDF or DOCX |
| `POST` | `/template/analyze` | Extract design tokens from a PDF template |
| `POST` | `/job/predict` | ML salary + fit prediction |

<br>

## 🗂️ Project structure

```
lib/
├── screens/            resume_editor (5,700+ lines), swipe_matcher, job_prediction,
│                       dashboard, application_tracker, admin, profile
├── services/           ai_service (orchestrator), jd_keyword_engine, resume_export,
│                       one client per AI provider, github_service, job_service
├── widgets/            30+ reusable components — ats_score_gauge, hero_section, ...
└── theme/              typography, colors, dark/light tokens

backend/                FastAPI server, template analyzer/renderer, salary model
job_collector/          scraper orchestrator, dedup + normalization, Supabase sync
supabase/               migrations + full schema documentation
```

<br>

## 🧪 Testing

43 unit & widget tests covering quota logic, AI resume parsing, PDF layout overflow, ATS keyword matching, and cloud round-trips.

```bash
flutter test
```

<br>

## 🔐 Auth & data

Supabase Auth (email/password, email verification, password reset) with Row Level Security on every table, and admin roles gated by an email allowlist + `is_admin` flag.

<br>

## 🤝 Contributing

```bash
git checkout -b feature/amazing-feature
git commit -m "feat: add amazing feature"
git push origin feature/amazing-feature
```

Then open a PR.

<br>

<div align="center">

**JobWink** — *wink at your dream job.*

Built with Flutter, Dart, Python, and a stubborn refusal to let one AI provider be a single point of failure.

</div>
