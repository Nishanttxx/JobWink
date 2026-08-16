import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from fastapi.testclient import TestClient
from backend_main import app, RESUMES

client = TestClient(app)

def run_tests():
    print("--- 1. Testing POST /resume/new ---")
    res_new = client.post("/resume/new")
    assert res_new.status_code == 200, f"Expected 200, got {res_new.status_code}: {res_new.text}"
    new_data = res_new.json()
    new_id = new_data["resume_id"]
    print(f"Created new resume ID: {new_id}")

    pdf_path = r"c:\Users\na623\Downloads\files\Nishant Arya.pdf"
    pdf_bytes = None
    if os.path.exists(pdf_path):
        with open(pdf_path, "rb") as f:
            pdf_bytes = f.read()
    pdf_bytes = (
        b"%PDF-1.4\n"
        b"1 0 obj <</Type /Catalog /Pages 2 0 R>> endobj\n"
        b"2 0 obj <</Type /Pages /Kids [3 0 R] /Count 1>> endobj\n"
        b"3 0 obj <</Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources <</Font <</F1 4 0 R>>>> /Contents 5 0 R>> endobj\n"
        b"4 0 obj <</Type /Font /Subtype /Type1 /BaseFont /Helvetica>> endobj\n"
        b"5 0 obj <</Length 73>> stream\n"
        b"BT\n/F1 12 Tf\n100 700 Td\n(John Doe Resume - Senior Software Engineer Python FastAPI Flutter) Tj\nET\n"
        b"endstream\nendobj\n"
        b"xref\n0 6\n0000000000 65535 f \n0000000009 00000 n \n0000000056 00000 n \n0000000111 00000 n \n0000000225 00000 n \n0000000294 00000 n \n"
        b"trailer <</Size 6 /Root 1 0 R>>\nstartxref\n418\n%%EOF"
    )

    print(f"\n--- 1b. Testing POST /extract-pdf ---")
    res_ext = client.post(
        "/extract-pdf",
        files={"file": ("test_resume.pdf", pdf_bytes, "application/pdf")}
    )
    assert res_ext.status_code in (200, 422), f"Extract PDF unexpected status: {res_ext.status_code}: {res_ext.text}"
    print(f"Extract PDF endpoint responded as expected (status: {res_ext.status_code}).")

    print(f"\n--- 2. Testing POST /resume/upload ---")
    res_upload = client.post(
        "/resume/upload",
        files={"file": ("test_resume.pdf", pdf_bytes, "application/pdf")}
    )
    assert res_upload.status_code in (200, 422), f"Upload response: {res_upload.text}"
    assert res_upload.status_code == 200, f"Upload failed: {res_upload.text}"
    upload_data = res_upload.json()
    uploaded_id = upload_data["resume_id"]
    sections = upload_data["sections"]
    print(f"Uploaded resume ID: {uploaded_id}")

    print(f"\n--- 3. Testing GET /resume/{uploaded_id} ---")
    res_get = client.get(f"/resume/{uploaded_id}")
    assert res_get.status_code == 200
    print("Successfully fetched stored resume.")

    print(f"\n--- 4. Testing PATCH /resume/{uploaded_id}/section/skills ---")
    patch_payload = {"content": ["Python", "FastAPI", "Docker", "Flutter", "AI Agents"]}
    res_patch = client.patch(f"/resume/{uploaded_id}/section/skills", json=patch_payload)
    assert res_patch.status_code == 200
    print(f"Updated skills: {res_patch.json()['sections']['skills']}")

    print(f"\n--- 5. Testing POST /resume/{uploaded_id}/tailor ---")
    job_desc = (
        "Seeking a Senior Backend & AI Automation Engineer proficient in Python, FastAPI, Docker, "
        "and LLM orchestration to build scalable microservices and data pipelines."
    )
    res_tailor = client.post(f"/resume/{uploaded_id}/tailor", json={"job_description": job_desc})
    assert res_tailor.status_code == 200
    tailored_data = res_tailor.json()
    tailored_id = tailored_data["resume_id"]
    print(f"Tailored resume saved under new ID: {tailored_id}")

    print(f"\n--- 6. Testing Memory Cache Eviction & Database Persistence Fetch ---")
    RESUMES.clear() # Evict in-memory cache to simulate server restart / fresh worker process
    res_db_fetch = client.get(f"/resume/{uploaded_id}")
    assert res_db_fetch.status_code == 200
    print(f"Successfully re-loaded resume {uploaded_id} from persistence after clearing memory cache!")

    print(f"\n--- 7. Testing GET /resume/{tailored_id}/export (PDF & DOCX) ---")
    res_pdf = client.get(f"/resume/{tailored_id}/export?format=pdf")
    assert res_pdf.status_code == 200
    assert len(res_pdf.content) > 0
    print(f"Exported PDF size: {len(res_pdf.content)} bytes")

    res_docx = client.get(f"/resume/{tailored_id}/export?format=docx")
    assert res_docx.status_code == 200
    assert len(res_docx.content) > 0
    print(f"Exported DOCX size: {len(res_docx.content)} bytes")

    print(f"\n--- 8. Testing POST /template/analyze & GET /resume/{tailored_id}/render ---")
    res_tmpl = client.post("/template/analyze", files={"file": ("test_resume.pdf", pdf_bytes, "application/pdf")})
    assert res_tmpl.status_code == 200
    tmpl_id = res_tmpl.json()["template_id"]
    print(f"Analyzed template ID: {tmpl_id}")

    res_render = client.get(f"/resume/{tailored_id}/render?template_id={tmpl_id}")
    assert res_render.status_code == 200
    assert len(res_render.content) > 0
    print(f"Rendered templated PDF size: {len(res_render.content)} bytes")

    print("\nALL PERSISTENT BACKEND ENDPOINT TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    run_tests()
