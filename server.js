import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import multer from 'multer';
import pdfParse from 'pdf-parse';
import Anthropic from '@anthropic-ai/sdk';
import { GoogleGenAI } from '@google/genai';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '25mb' }));

// File upload configuration in memory
const upload = multer({ storage: multer.memoryStorage() });

// 1. Primary Claude Client (Local Antigravity Proxy)
const primaryClaude = new Anthropic({
  baseURL: 'http://127.0.0.1:8080',
  apiKey: 'test',
});

// 2. Fallback Gemini Client
const geminiClient = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

const SYSTEM_PROMPT = `You are an expert ATS parser and resume analytics engine.
Extract all details from the resume into structured sections, and analyze keyword alignment against the provided Job Description.

STRICT REQUIREMENT: You MUST output ONLY valid raw JSON matching this schema:
{
  "parsedSections": {
    "personalInfo": { "fullName": "", "email": "", "phone": "", "location": "", "linkedin": "", "portfolio": "" },
    "summary": "",
    "skills": { "technical": [], "soft": [], "toolsAndFrameworks": [] },
    "workExperience": [
      { "role": "", "company": "", "duration": "", "location": "", "bulletPoints": [] }
    ],
    "education": [
      { "degree": "", "institution": "", "year": "", "gpa": "" }
    ],
    "projects": [
      { "name": "", "description": "", "techStack": [], "link": "" }
    ],
    "certifications": []
  },
  "jobDescriptionAnalysis": {
    "matchedKeywords": [],
    "missingKeywords": [],
    "keywordHighlightMap": [
      { "keyword": "", "category": "technical | tool | soft", "foundInResume": true }
    ],
    "matchScorePercentage": 0,
    "suggestions": []
  }
}`;

// --- Primary: Claude Opus via Antigravity ---
async function parseWithClaudeOpus(prompt) {
  console.log('[Primary] Parsing via Claude Opus (Antigravity quota)...');
  const response = await primaryClaude.messages.create({
    model: 'claude-opus-4-6-thinking',
    max_tokens: 4096,
    system: SYSTEM_PROMPT,
    messages: [{ role: 'user', content: prompt }],
  });

  const contentBlocks = response.content || [];
  const textBlock = contentBlocks.find((b) => b.type === 'text');
  return textBlock ? textBlock.text : '';
}

// --- Fallback: Google Gemini API ---
async function parseWithGemini(prompt) {
  console.warn('[Fallback] Antigravity exhausted or failed. Routing to Gemini API...');
  const fullPrompt = `${SYSTEM_PROMPT}\n\n${prompt}`;
  
  const response = await geminiClient.models.generateContent({
    model: 'gemini-2.5-flash',
    contents: fullPrompt,
    config: {
      responseMimeType: 'application/json',
    },
  });

  return response.text;
}

// --- Controller Function with Failover ---
async function dispatchExtraction(resumeText, jobDescription) {
  const userPrompt = `
RESUME CONTENT:
"""
${resumeText}
"""

JOB DESCRIPTION:
"""
${jobDescription || 'No job description provided. Skip keyword matching analysis.'}
"""
`;

  try {
    const rawText = await parseWithClaudeOpus(userPrompt);
    return {
      source: 'claude-opus-antigravity',
      data: cleanAndParseJSON(rawText),
    };
  } catch (error) {
    console.error(`[Claude Failed]: ${error.message}`);
    const fallbackText = await parseWithGemini(userPrompt);
    return {
      source: 'gemini-fallback',
      data: cleanAndParseJSON(fallbackText),
    };
  }
}

function cleanAndParseJSON(rawText) {
  const cleaned = rawText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
  return JSON.parse(cleaned);
}

// ================= API ENDPOINTS =================

// Endpoint 1: Direct File Upload (PDF or TXT) + Job Description
app.post('/api/upload-and-analyze', upload.single('resumeFile'), async (req, res) => {
  try {
    let extractedText = '';

    if (req.file) {
      if (req.file.mimetype === 'application/pdf') {
        const parsedPdf = await pdfParse(req.file.buffer);
        extractedText = parsedPdf.text;
      } else {
        extractedText = req.file.buffer.toString('utf-8');
      }
    } else if (req.body.resumeText) {
      extractedText = req.body.resumeText;
    } else {
      return res.status(400).json({ error: 'Please upload a resume file or provide resumeText.' });
    }

    const jobDescription = req.body.jobDescription || '';
    const result = await dispatchExtraction(extractedText, jobDescription);

    return res.json({
      success: true,
      source: result.source,
      data: result.data,
    });
  } catch (err) {
    console.error('[Fatal Process Error]:', err);
    return res.status(500).json({ error: 'Failed to extract resume data.', details: err.message });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`ATS Parser Server running on http://127.0.0.1:${PORT}`));