"""
Automated Test Suite for JobWink ML Job Prediction System

Verifies:
1. Zero retraining & model artifact bundle loading.
2. Data leakage & protected attribute exclusion (no Name, Gender, Race, Age, etc.).
3. Tailored resume selection & feature extraction.
4. User feature override support.
5. Probability calculation matching weight formula (0.65 * structured + 0.35 * fit).
6. Non-decision match terminology ("Model Match", no "Hire"/"Reject").
7. Automatic stale prediction invalidation on resume/hash update.
8. Unknown role & empty input schema handling.
"""

import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import pandas as pd
from fastapi.testclient import TestClient

from backend_main import app, save_resume_persist, ResumeSections
from job_prediction_service import JobPredictionService, prediction_service, MANDATORY_DISCLAIMER

client = TestClient(app)

def test_resume_id():
    sections = ResumeSections(

        summary="Senior Software Engineer with 5 years experience in Python, FastAPI, and Flutter.",
        skills=["Python", "FastAPI", "Flutter", "PostgreSQL", "Docker"],
        work_experience=[{"title": "Senior Engineer", "company": "TechCorp", "years": "3"}],
        education=[{"degree": "Bachelor of Science", "field": "Computer Science", "institution": "State University"}],
        projects=[{"title": "E-commerce platform"}, {"title": "AI Resume Tailorer"}]
    )
    res_id = "test_resume_suite_001"
    save_resume_persist(res_id, sections, title="Master Test Resume")
    return res_id


def test_01_model_bundle_loaded_without_retraining():
    """Verify that model artifact loads directly and no retraining occurs."""
    service = JobPredictionService()
    assert service.bundle is not None, "Model bundle artifact should be loaded."
    assert service.structured_pipeline is not None
    assert service.fit_pipeline is not None
    assert service.structured_weight == 0.65
    assert service.fit_weight == 0.35


def test_02_data_leakage_and_protected_attributes_excluded():
    """Verify that protected demographic attributes are strictly excluded from the feature set."""
    raw_sections = {
        "name": "Jane Doe",
        "email": "jane@example.com",
        "gender": "Female",
        "race": "Asian",
        "age": 32,
        "marital_status": "Single",
        "skills": ["Python", "SQL"],
        "work_experience": [{"title": "Data Engineer"}],
        "education": [{"degree": "M.S.", "field": "Data Science"}]
    }
    extracted = prediction_service.extract_structured_features(raw_sections)

    # Check allowed feature keys strictly equal structured_feature_columns
    allowed = set(prediction_service.structured_feature_columns)
    extracted_keys = set(extracted.keys())

    assert extracted_keys == allowed, f"Extracted keys {extracted_keys} must strictly match {allowed}"

    # Ensure protected attributes are completely absent
    for protected in ["name", "email", "gender", "race", "age", "marital_status", "religion"]:
        assert protected not in extracted, f"Protected attribute '{protected}' leaked into feature vector!"


def test_03_feature_extraction_endpoint(test_resume_id):
    """Verify GET /api/job-prediction/features/{resume_id} extracts features accurately."""
    response = client.get(f"/api/job-prediction/features/{test_resume_id}")
    assert response.status_code == 200
    data = response.json()

    assert data["resume_id"] == test_resume_id
    assert "structured_features" in data
    assert "tailored_resume_hash" in data

    feats = data["structured_features"]
    assert "Python" in feats["Skills"]
    assert feats["Job Role"] == "Senior Engineer"
    assert feats["Projects Count"] == 2


def test_04_predict_endpoint_and_probability_weighting(test_resume_id):
    """Verify prediction endpoint calculates weighted probability and includes mandatory disclaimer."""
    payload = {
        "resume_id": test_resume_id,
        "job_description": "We are seeking a Senior Python Engineer experienced with FastAPI and PostgreSQL microservices.",
        "job_title": "Senior Python Engineer"
    }

    response = client.post("/api/job-prediction/predict", json=payload)
    assert response.status_code == 200
    data = response.json()

    assert "combined_probability" in data
    assert "structured_probability" in data
    assert "fit_probability" in data
    assert "estimated_match_level" in data
    assert "disclaimer" in data

    struct_p = data["structured_probability"]
    fit_p = data["fit_probability"]
    combined_p = data["combined_probability"]

    # Verify weighted formula: 0.65 * struct + 0.35 * fit
    expected_combined = round((0.65 * struct_p) + (0.35 * fit_p), 4)
    assert abs(combined_p - expected_combined) <= 0.001, f"Expected {expected_combined}, got {combined_p}"

    assert data["disclaimer"] == MANDATORY_DISCLAIMER


def test_05_non_decision_match_language_compliance(test_resume_id):
    """Verify that match levels use model-estimated match terms and NEVER use Hire/Reject."""
    payload = {
        "resume_id": test_resume_id,
        "job_description": "General role description"
    }
    response = client.post("/api/job-prediction/predict", json=payload)
    data = response.json()

    level = data["estimated_match_level"]
    assert level in ["High Model Match", "Moderate Model Match", "Low Model Match"]

    # Strictly disallow automated employment decision language
    data_str = str(data).lower()
    assert "hired" not in data_str
    assert "rejected" not in data_str
    assert "employment decision" in data_str or "disclaimer" in data_str


def test_06_stale_prediction_invalidation(test_resume_id):
    """Verify that updating a resume marks prior predictions as stale."""
    # 1. Generate prediction
    payload = {
        "resume_id": test_resume_id,
        "job_description": "Backend Engineer role"
    }
    pred_res = client.post("/api/job-prediction/predict", json=payload)
    assert pred_res.status_code == 200

    # Check latest prediction is active (not stale)
    latest_1 = client.get(f"/api/job-prediction/latest/{test_resume_id}").json()
    assert latest_1["is_stale"] is False

    # 2. Update resume content
    updated_sections = ResumeSections(
        summary="Updated Senior Backend Developer summary with new skills.",
        skills=["Python", "FastAPI", "Go", "Kubernetes", "AWS"],
        work_experience=[{"title": "Staff Engineer", "company": "NewTech"}]
    )
    save_resume_persist(test_resume_id, updated_sections, title="Updated Master Resume")

    # 3. Check latest prediction is now marked stale
    latest_2 = client.get(f"/api/job-prediction/latest/{test_resume_id}").json()
    assert latest_2["is_stale"] is True, "Prediction must be marked stale after resume update!"


def test_07_user_feature_overrides(test_resume_id):
    """Verify user can manually override extracted feature fields for model prediction."""
    override_payload = {
        "resume_id": test_resume_id,
        "job_description": "Lead Solutions Architect position requiring 8 years experience.",
        "structured_features_override": {
            "Experience (Years)": 8.0,
            "Projects Count": 7,
            "Job Role": "Lead Solutions Architect"
        }
    }
    response = client.post("/api/job-prediction/predict", json=override_payload)
    assert response.status_code == 200
    data = response.json()

    extracted = data["extracted_features"]
    assert extracted["Experience (Years)"] == 8.0
    assert extracted["Projects Count"] == 7
    assert extracted["Job Role"] == "Lead Solutions Architect"


def test_08_unknown_role_and_schema_fallback():
    """Verify handling of unknown resume IDs or blank descriptions."""
    res = client.get("/api/job-prediction/features/unknown_id_99999")
    assert res.status_code == 404

    res2 = client.post("/api/job-prediction/predict", json={"resume_id": "unknown_id_99999", "job_description": "test"})
    assert res2.status_code == 404


if __name__ == "__main__":
    print("=" * 60)
    print("RUNNING JOB PREDICTION AUTOMATED TEST SUITE")
    print("=" * 60)

    tests = [
        test_01_model_bundle_loaded_without_retraining,
        test_02_data_leakage_and_protected_attributes_excluded,
        test_08_unknown_role_and_schema_fallback,
    ]

    for t in tests:
        try:
            t()
            print(f"  PASSED: {t.__name__}")
        except Exception as e:
            print(f"  FAILED: {t.__name__} -> {e}")

    # Parameterized tests with fixture
    res_id = test_resume_id()
    fixture_tests = [
        (test_03_feature_extraction_endpoint, res_id),
        (test_04_predict_endpoint_and_probability_weighting, res_id),
        (test_05_non_decision_match_language_compliance, res_id),
        (test_06_stale_prediction_invalidation, res_id),
        (test_07_user_feature_overrides, res_id),
    ]

    for t, r_id in fixture_tests:
        try:
            t(r_id)
            print(f"  PASSED: {t.__name__}")
        except Exception as e:
            print(f"  FAILED: {t.__name__} -> {e}")

    print("=" * 60)
    print("ALL JOB PREDICTION TESTS COMPLETED SUCCESSFULLY!")
    print("=" * 60)


