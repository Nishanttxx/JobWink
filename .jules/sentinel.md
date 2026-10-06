## 2026-09-01 - Prevent path traversal when accessing local file snapshots
**Vulnerability:** `save_resume_persist` and `load_resume_persist` used string formatting to construct file paths for resumes: `DATA_STORE_DIR / f"{resume_id}.json"`. This allowed attackers to use paths like `../../../../etc/passwd` to read or write files outside the local `data_store` directory.
**Learning:** Python's `pathlib` operator `/` does not protect against `..` components. Since the backend allows users to provide an arbitrary string as `resume_id` in API requests, validating paths is strictly required when reading/writing state to the disk.
**Prevention:** Ensure that all dynamically constructed paths from user inputs are resolved and explicitly checked using `file_path.is_relative_to(DATA_STORE_DIR.resolve())` before executing any file operations.
## 2026-09-07 - [Secure CORS Configuration]
**Vulnerability:** The FastAPI backend used a dangerously permissive CORS configuration (`allow_origins=["*"]`), which allowed any origin to make cross-origin requests to the API.
**Learning:** In production environments, allowing all origins can expose sensitive endpoints to CSRF-like attacks or data theft from malicious domains. APIs must explicitly define allowed origins.
**Prevention:** Ensure `CORSMiddleware` reads allowed origins from environment variables and provides a strict default for local development, rather than using wildcards.
## 2026-09-08 - [Secure CORS Configuration in Node.js Proxy]
**Vulnerability:** The Express.js Node proxy server (`server.js`) was using a dangerously permissive CORS configuration (`app.use(cors())`), allowing any origin to make cross-origin requests to its parsing API. This mirrored a previous vulnerability found in the FastAPI backend.
**Learning:** In production environments, allowing all origins exposes sensitive endpoints to unauthorized access, CSRF-like attacks, or data theft from malicious domains. Security practices must be uniform across all services (backend and proxy).
**Prevention:** Ensure `cors()` middleware is configured to read allowed origins from an environment variable (`ALLOWED_ORIGINS`), and fallback to a strict default like `http://localhost` for development. Avoid using wildcard defaults across all server setups.
