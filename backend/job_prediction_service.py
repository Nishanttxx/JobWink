"""
JobWink ML Job Prediction Service

Loads trained model bundle ('D:\\job_prediction_model_v1_bundle.joblib' or configured path) at startup.
Performs model inference without retraining.
Excludes protected demographic attributes.
Manages hash verification and staleness invalidation.
"""

import os
import hashlib
import json
import uuid
from typing import Dict, Any, Optional, Tuple
from pathlib import Path
import pandas as pd
import numpy as np
import joblib

# Default model path
DEFAULT_MODEL_PATH = r"D:\job_prediction_model_v1_bundle.joblib"

# Mandatory legal disclaimer text
MANDATORY_DISCLAIMER = (
    "Model-estimated probability based on statistical feature match. "
    "This score does not guarantee interview shortlisting or employment outcomes, "
    "nor is it an automated hiring decision."
)

class JobPredictionService:
    def __init__(self, model_path: Optional[str] = None):
        self.model_path = model_path or os.environ.get("JOB_PREDICTION_MODEL_PATH", DEFAULT_MODEL_PATH)
        self.bundle: Optional[Dict[str, Any]] = None
        self.structured_pipeline = None
        self.fit_pipeline = None
        self.structured_feature_columns = [
            'Skills', 'Certifications', 'Education', 'Job Role',
            'Experience (Years)', 'Salary Expectation ($)', 'Projects Count'
        ]
        self.structured_weight = 0.65
        self.fit_weight = 0.35
        self.positive_threshold = 0.5
        self.model_version = "v1.0.0"

        # In-memory prediction store & staleness map
        # prediction_id -> prediction_dict
        self.predictions: Dict[str, Dict[str, Any]] = {}
        self.load_model()

    def load_model(self) -> bool:
        """Loads model bundle artifact into memory at startup. Never retrains."""
        path_to_load = Path(self.model_path)
        if not path_to_load.exists():
            print(f"JobPredictionService Note: Model bundle not found at {path_to_load}. Using fallback inference mode.")
            return False

        try:
            self.bundle = joblib.load(str(path_to_load))
            self.structured_pipeline = self.bundle.get("structured_hiring_pipeline")
            self.fit_pipeline = self.bundle.get("resume_job_fit_pipeline")
            self.structured_feature_columns = self.bundle.get("structured_feature_columns", self.structured_feature_columns)
            self.structured_weight = float(self.bundle.get("structured_model_weight", 0.65))
            self.fit_weight = float(self.bundle.get("fit_model_weight", 0.35))
            self.positive_threshold = float(self.bundle.get("job_fit_positive_threshold", 0.5))
            self.model_version = self.bundle.get("model_version", "v1.0.0")
            print(f"Successfully loaded Job Prediction ML Model bundle (Version: {self.model_version}) from {path_to_load}")
            return True
        except Exception as e:
            print(f"Error loading model bundle: {e}")
            return False

    def compute_resume_hash(self, sections_dict: Dict[str, Any]) -> str:
        """Computes SHA-256 hash of tailored resume sections to detect state changes."""
        serialized = json.dumps(sections_dict, sort_keys=True)
        return hashlib.sha256(serialized.encode("utf-8")).hexdigest()

    def extract_structured_features(self, sections_dict: Dict[str, Any]) -> Dict[str, Any]:
        """
        Extracts structured feature fields from a ResumeSections dict.
        Guarantees strict exclusion of protected attributes (Name, Email, Age, Gender, Race, etc.).
        """
        skills_list = sections_dict.get("skills", [])
        skills_str = ", ".join(skills_list) if isinstance(skills_list, list) else str(skills_list)
        if not skills_str.strip():
            skills_str = "General Technical Skills"

        # Certifications from keywords or summary
        keywords = sections_dict.get("keywords", [])
        cert_candidates = [k for k in keywords if "cert" in k.lower() or "aws" in k.lower() or "scrum" in k.lower() or "cpa" in k.lower() or "pmp" in k.lower()]
        cert_str = ", ".join(cert_candidates) if cert_candidates else "Professional Certificate"

        # Education
        edu_list = sections_dict.get("education", [])
        edu_str = "Bachelor of Science"
        if edu_list and isinstance(edu_list, list) and len(edu_list) > 0:
            top_edu = edu_list[0]
            if isinstance(top_edu, dict):
                degree = top_edu.get("degree", "")
                field = top_edu.get("field", "")
                institution = top_edu.get("institution", "")
                edu_str = f"{degree} {field}".strip() or institution or "Higher Education"

        # Job Role
        work_list = sections_dict.get("work_experience", [])
        job_role = "Software Engineer"
        if work_list and isinstance(work_list, list) and len(work_list) > 0:
            top_job = work_list[0]
            if isinstance(top_job, dict) and top_job.get("title"):
                job_role = top_job.get("title")

        # Experience (Years)
        exp_years = float(max(len(work_list) * 1.5, 1.0))
        # Look for explicit years in summary
        summary = sections_dict.get("summary", "")
        import re
        match = re.search(r"(\d+)\+?\s*years", summary, re.IGNORECASE)
        if match:
            try:
                exp_years = float(match.group(1))
            except ValueError:
                pass

        # Salary Expectation
        salary_exp = 100000.0

        # Projects Count
        projects_list = sections_dict.get("projects", [])
        proj_count = len(projects_list) if isinstance(projects_list, list) else 0

        # Return ONLY the exact 7 non-protected structured feature columns
        return {
            "Skills": skills_str,
            "Certifications": cert_str,
            "Education": edu_str,
            "Job Role": job_role,
            "Experience (Years)": float(exp_years),
            "Salary Expectation ($)": float(salary_exp),
            "Projects Count": int(proj_count),
        }

    def predict(
        self,
        resume_id: str,
        sections_dict: Dict[str, Any],
        job_description: str,
        user_features_override: Optional[Dict[str, Any]] = None,
        job_title: Optional[str] = None,
        user_id: Optional[str] = None,
        resume_version_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Executes prediction pipeline given resume sections, target job description, and optional user overrides.
        Guarantees no retraining occurs.
        """
        if not job_description.strip():
            job_description = "General Engineering & Technical Position"

        # 1. Extract or apply overridden features
        base_features = self.extract_structured_features(sections_dict)
        if user_features_override:
            for col in self.structured_feature_columns:
                if col in user_features_override:
                    val = user_features_override[col]
                    if col in ["Experience (Years)", "Salary Expectation ($)"]:
                        try:
                            val = float(val)
                        except (ValueError, TypeError):
                            val = base_features[col]
                    elif col == "Projects Count":
                        try:
                            val = int(val)
                        except (ValueError, TypeError):
                            val = base_features[col]
                    else:
                        val = str(val)
                    base_features[col] = val

        # 2. Compute probabilities
        structured_prob = 0.65
        fit_prob = 0.55

        if self.structured_pipeline and self.fit_pipeline:
            try:
                # Structured model inference
                df_structured = pd.DataFrame([base_features])
                # Reorder columns explicitly to match pipeline requirements
                df_structured = df_structured[self.structured_feature_columns]
                structured_prob = float(self.structured_pipeline.predict_proba(df_structured)[0, 1])

                # Text fit model inference
                # Construct combined fit string format
                summary_text = sections_dict.get("summary", "")
                skills_text = ", ".join(sections_dict.get("skills", []))
                resume_text_representation = f"{base_features['Job Role']} {summary_text} {skills_text}".strip()
                fit_input = f"{resume_text_representation} [SEP] {job_description}"

                fit_prob = float(self.fit_pipeline.predict_proba([fit_input])[0, 1])
            except Exception as e:
                print(f"Model prediction execution note: {e}. Fallback to rule calculation.")
                structured_prob = self._heuristic_structured_score(base_features)
                fit_prob = self._heuristic_fit_score(sections_dict, job_description)
        else:
            structured_prob = self._heuristic_structured_score(base_features)
            fit_prob = self._heuristic_fit_score(sections_dict, job_description)

        # 3. Calculate weighted combined probability
        combined_prob = (self.structured_weight * structured_prob) + (self.fit_weight * fit_prob)
        combined_prob = max(0.0, min(1.0, combined_prob))

        # 4. Determine Match Level (NEVER use Hired / Rejected)
        is_match = combined_prob >= self.positive_threshold
        if combined_prob >= 0.75:
            estimated_match_level = "High Model Match"
        elif combined_prob >= 0.50:
            estimated_match_level = "Moderate Model Match"
        else:
            estimated_match_level = "Low Model Match"

        # 5. Compute hash & store prediction record
        tailored_hash = self.compute_resume_hash(sections_dict)
        prediction_id = str(uuid.uuid4())

        record = {
            "id": prediction_id,
            "user_id": user_id,
            "resume_id": resume_id,
            "resume_version_id": resume_version_id,
            "tailored_resume_hash": tailored_hash,
            "job_title": job_title or base_features["Job Role"],
            "job_description": job_description,
            "extracted_features": base_features,
            "structured_probability": round(structured_prob, 4),
            "fit_probability": round(fit_prob, 4),
            "combined_probability": round(combined_prob, 4),
            "is_match": is_match,
            "estimated_match_level": estimated_match_level,
            "is_stale": False,
            "disclaimer": MANDATORY_DISCLAIMER,
            "created_at": pd.Timestamp.now().isoformat(),
        }

        # Clear existing non-stale predictions for this resume_id and mark stale if hash changes
        for pid, existing in self.predictions.items():
            if existing.get("resume_id") == resume_id:
                if existing.get("tailored_resume_hash") != tailored_hash or existing.get("resume_version_id") != resume_version_id:
                    existing["is_stale"] = True

        self.predictions[prediction_id] = record
        return record

    def invalidate_stale_predictions(self, resume_id: str, new_hash: Optional[str] = None):
        """Marks any prediction associated with resume_id as stale when resume content changes."""
        for pid, record in self.predictions.items():
            if record.get("resume_id") == resume_id:
                if new_hash is None or record.get("tailored_resume_hash") != new_hash:
                    record["is_stale"] = True

    def get_latest_prediction(self, resume_id: str) -> Optional[Dict[str, Any]]:
        """Retrieves the latest prediction record for a resume."""
        matching = [p for p in self.predictions.values() if p.get("resume_id") == resume_id]
        if not matching:
            return None
        matching.sort(key=lambda x: x.get("created_at", ""), reverse=True)
        return matching[0]

    def _heuristic_structured_score(self, features: Dict[str, Any]) -> float:
        score = 0.5
        if features.get("Experience (Years)", 0) >= 3:
            score += 0.15
        if len(str(features.get("Skills", "")).split(",")) >= 4:
            score += 0.15
        if features.get("Projects Count", 0) >= 2:
            score += 0.10
        return min(0.95, score)

    def _heuristic_fit_score(self, sections: Dict[str, Any], job_desc: str) -> float:
        skills = sections.get("skills", [])
        if not skills or not job_desc:
            return 0.5
        matches = sum(1 for s in skills if s.lower() in job_desc.lower())
        ratio = matches / max(len(skills), 1)
        return min(0.95, max(0.2, 0.4 + (ratio * 0.5)))


# Singleton instance
prediction_service = JobPredictionService()
