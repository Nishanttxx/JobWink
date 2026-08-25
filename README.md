# 🚀 JobWink — AI Resume Tailoring & Job Matcher

![Gemini](https://img.shields.io/badge/Gemini-%F0%9F%8C%9F-blue) ![OpenAI](https://img.shields.io/badge/OpenAI-%F0%9F%92%BB-lightgrey) ![Supabase](https://img.shields.io/badge/Supabase-%F0%9F%92%BB-green) ![Flutter](https://img.shields.io/badge/Flutter-%F0%9F%93%B0-blue)

JobWink is an elegant, AI-powered resume builder, ATS analyzer, and job-matching assistant built with Flutter, Supabase, Google Gemini, and OpenAI. Tailor resumes to job descriptions, extract structured profiles from uploads, and get actionable ATS feedback — all with a smooth fallback across AI providers so users never see quota errors.

---

## ✨ Highlights

- Clean, Flutter-based UI for building and tailoring resumes.
- Multimodal resume parsing (PDF / JPG / PNG / DOCX) into a structured JSON profile.
- Intelligent resume tailoring that matches experience bullets and skills to target job postings without inventing facts.
- Realistic ATS scoring and clear, actionable recommendations.
- Resilient AI orchestration with an automatic fallback from Gemini to OpenAI on quota errors.


## 📸 Demo



## 📚 Table of Contents

- [Architecture & AI Fallback System](#-architecture--ai-fallback-system)
- [Key Capabilities](#-key-capabilities)
- [Dependencies](#-dependencies--packages)
- [Configuration](#-configuration--environment-variables)
- [Testing Providers](#-testing-providers)
- [Quick Start](#-quick-start)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🏗️ Architecture & AI Fallback System

JobWink uses a central AI orchestration service (AIService) that routes requests to providers and transparently falls back when needed.

```
Frontend (Flutter UI)
       │
       ▼
AIService (Provider Manager)
       │
       ├──► Primary Provider: GeminiService (gemini-flash-latest)
       │         │
       │         ├── Success ──► Return Parsed / Tailored Resume JSON
       │         │
       │         └── Quota Exceeded / 429 Rate Limit
       │                  │
       │                  ▼
       └──► Fallback Provider: OpenAIService (gpt-4o-mini / REST)
                 │
                 └──► Return Same Structured JSON Schema
```

Automation ensures the UI receives a single, consistent response whether Gemini or OpenAI handles the request.


## 🔑 Key Capabilities

- Resume parsing into structured profile fields: `fullName`, `summary`, `skills`, `experience`, `projects`, `education`.
- Resume tailoring that maps bullets and skills to job descriptions while avoiding hallucinations.
- ATS analysis with scores like `overallScore`, `keywordScore`, `formatScore`, and `contentScore` plus clear remediation tips.
- Provider orchestration with automatic fallback on `RESOURCE_EXHAUSTED` / HTTP 429 so the end-user never sees quota errors.


## 📦 Dependencies & Packages

- google_generative_ai: ^0.4.6 (Gemini SDK)
- dart_openai: ^6.1.1 (Official OpenAI SDK)
- http: ^1.6.0 (HTTP REST fallback)
- supabase_flutter: ^2.17.1 (Authentication & Persistence)


## ⚙️ Configuration & Environment Variables

Copy `.env.example` to `.env` or configure `AIConfig` directly in code.

```env
# AI Provider API Keys
GEMINI_API_KEY=your_gemini_api_key_here
OPENAI_API_KEY=your_openai_api_key_here

# Provider Routing Options
PRIMARY_AI_PROVIDER=gemini
FALLBACK_AI_PROVIDER=openai

# Provider Force Override ('none', 'gemini', 'openai')
FORCE_AI_PROVIDER=none

# OpenAI Model Selection
OPENAI_MODEL=gpt-4o-mini

# Server / API Settings
PORT=5000
FRONTEND_URL=http://localhost:3000
```

> Security: Keep API keys on the server/service layer. Never commit `.env` to the repo.


## 🧪 Testing Providers

1. Test Gemini (Normal Mode)
- Set `FORCE_AI_PROVIDER=none` or `FORCE_AI_PROVIDER=gemini`.
- Upload a resume or click "Tailor Resume".
- Look for logs:
  - `[AIService] Primary provider: Gemini`
  - `[AIService] Gemini request successful`

2. Test OpenAI (Forced Mode)
- Set `FORCE_AI_PROVIDER=openai` in `AIConfig`:
```dart
AIConfig.forceProvider = 'openai';
```
- Expected logs:
  - `[AIService] Forced provider: OpenAI`
  - `[OpenAIService] Processing resume...`
  - `[OpenAIService] Resume tailoring successful`

3. Test Automatic Quota Fallback
- Simulate or trigger a Gemini quota error (HTTP 429 / `RESOURCE_EXHAUSTED`).
- Expected logs:
  - `[AIService] Gemini quota exceeded`
  - `[AIService] Switching to OpenAI fallback`
  - `[OpenAIService] Processing resume...`
- The UI should receive a seamless tailored output without user interruption.


## ⚡ Quick Start

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

Server or service (if applicable):
```bash
# From the server directory
dart run bin/server.dart
```


## 🛠️ Contributing

Contributions are welcome! Open an issue for feature requests or bug reports, and send a PR for fixes.

- Follow the repo's code style.
- Write tests for new features where possible.
- Keep secrets out of commits.


## 📄 License

This project is open source — add your preferred license or keep it as-is.


---


