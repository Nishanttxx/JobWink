## 2026-09-01 - Prevent path traversal when accessing local file snapshots
**Vulnerability:** `save_resume_persist` and `load_resume_persist` used string formatting to construct file paths for resumes: `DATA_STORE_DIR / f"{resume_id}.json"`. This allowed attackers to use paths like `../../../../etc/passwd` to read or write files outside the local `data_store` directory.
**Learning:** Python's `pathlib` operator `/` does not protect against `..` components. Since the backend allows users to provide an arbitrary string as `resume_id` in API requests, validating paths is strictly required when reading/writing state to the disk.
**Prevention:** Ensure that all dynamically constructed paths from user inputs are resolved and explicitly checked using `file_path.is_relative_to(DATA_STORE_DIR.resolve())` before executing any file operations.
## 2024-09-16 - Overly Permissive CORS Configuration
**Vulnerability:** The application was using `allow_origins=["*"]` and `allow_methods=["*"]` for CORS in FastAPI.
**Learning:** This is an overly permissive configuration that allows any origin to make requests to the backend APIs, which can lead to data exposure and Cross-Site Request Forgery (CSRF)-like attacks. It's crucial to always scope down CORS strictly to the allowed origins.
**Prevention:** Use an environment variable like `ALLOWED_ORIGINS` to configure allowed origins dynamically, with a fallback only to safe development origins. Restrict HTTP methods to only what is needed.
