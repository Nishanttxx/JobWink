import logging
import httpx
from typing import List, Dict, Any, Optional
from config import Config
from collectors.base_collector import BaseJobCollector
from database.supabase_client import SupabaseJobDatabase

logger = logging.getLogger(__name__)

class JSearchCollector(BaseJobCollector):
    """
    Collector for JSearch / OpenWebNinja API.
    Endpoints:
      - Direct OpenWebNinja: https://api.openwebninja.com/jsearch/search-v2
      - RapidAPI: https://jsearch.p.rapidapi.com/search
    Documentation: https://www.openwebninja.com/api/jsearch
    """
    def __init__(self, db: SupabaseJobDatabase):
        super().__init__("JSearch", db)
        self.api_key = Config.JSEARCH_API_KEY or Config.RAPIDAPI_KEY
        self.is_rapidapi = bool(not Config.JSEARCH_API_KEY and Config.RAPIDAPI_KEY)

    def _build_location_string(self, item: Dict[str, Any]) -> str:
        city = item.get("job_city") or ""
        state = item.get("job_state") or ""
        country = item.get("job_country") or ""
        parts = [p.strip() for p in [city, state, country] if p and str(p).strip()]
        if parts:
            return ", ".join(parts)
        if item.get("job_is_remote"):
            return "Remote"
        return "United States"

    def _extract_apply_url(self, item: Dict[str, Any]) -> Optional[str]:
        """
        Extracts the job application URL directly from the API response.
        Prioritizes direct job_apply_link, then job_google_link or apply_options.
        Never fabricates URLs.
        """
        apply_link = item.get("job_apply_link")
        if apply_link and str(apply_link).strip().startswith("http"):
            return str(apply_link).strip()

        # Check apply_options if returned
        apply_options = item.get("apply_options") or []
        if isinstance(apply_options, list):
            for opt in apply_options:
                if isinstance(opt, dict):
                    link = opt.get("apply_link") or opt.get("link")
                    if link and str(link).strip().startswith("http"):
                        return str(link).strip()

        google_link = item.get("job_google_link")
        if google_link and str(google_link).strip().startswith("http"):
            return str(google_link).strip()

        return None

    def fetch_jobs(self, page: int = 1) -> List[Dict[str, Any]]:
        if not self.api_key:
            logger.warning("JSEARCH_API_KEY / RAPIDAPI_KEY not configured. Skipping JSearch collection.")
            return []

        # Determine endpoint and headers
        if self.is_rapidapi:
            url = "https://jsearch.p.rapidapi.com/search"
            headers = {
                "X-RapidAPI-Key": self.api_key,
                "X-RapidAPI-Host": "jsearch.p.rapidapi.com"
            }
        else:
            url = "https://api.openwebninja.com/jsearch/search-v2"
            headers = {
                "x-api-key": self.api_key
            }

        params = {
            "query": "software engineer developer tech",
            "date_posted": "today",
            "page": str(page),
            "num_pages": "1"
        }

        try:
            with httpx.Client(timeout=20.0) as client:
                response = client.get(url, params=params, headers=headers)
                if response.status_code == 200:
                    data = response.json()
                    results = data.get("data", [])
                    formatted = []

                    for item in results:
                        if not isinstance(item, dict):
                            continue

                        job_id = str(item.get("job_id") or "")
                        title = item.get("job_title") or "Software Engineer"
                        company = item.get("employer_name") or "Unknown Company"
                        logo = item.get("employer_logo")
                        location = self._build_location_string(item)
                        description = item.get("job_description") or title
                        is_remote = bool(item.get("job_is_remote", False))
                        emp_type = item.get("job_employment_type") or "FULLTIME"
                        apply_url = self._extract_apply_url(item)

                        # Parse timestamp (datetime string or epoch timestamp)
                        posted_at = (
                            item.get("job_posted_at_datetime_utc") or
                            item.get("job_posted_at_timestamp") or
                            item.get("job_posted_at")
                        )

                        # Salary handling
                        sal_min = item.get("job_min_salary")
                        sal_max = item.get("job_max_salary")
                        sal_currency = item.get("job_salary_currency") or "USD"
                        sal_period = item.get("job_salary_period") or ""

                        salary_range = None
                        if sal_min is not None and sal_max is not None:
                            salary_range = f"${int(sal_min):,} - ${int(sal_max):,} {sal_currency} {sal_period}".strip()
                        elif sal_min is not None:
                            salary_range = f"From ${int(sal_min):,} {sal_currency} {sal_period}".strip()

                        # Skills / Highlights
                        highlights = item.get("job_highlights") or {}
                        qualifications = highlights.get("Qualifications") or []
                        skills = item.get("job_required_skills") or []
                        if isinstance(qualifications, list) and not skills:
                            skills = [str(q) for q in qualifications[:5]]

                        formatted.append({
                            "source_job_id": job_id,
                            "title": title,
                            "company": company,
                            "company_logo": logo,
                            "location": location,
                            "city": item.get("job_city"),
                            "state": item.get("job_state"),
                            "country": item.get("job_country"),
                            "remote": is_remote,
                            "workplace_type": "Remote" if is_remote else "On-site",
                            "employment_type": emp_type,
                            "description": description,
                            "salary_min": sal_min,
                            "salary_max": sal_max,
                            "salary_currency": sal_currency,
                            "salary_range": salary_range,
                            "apply_url": apply_url,
                            "job_url": apply_url,
                            "posted_at": posted_at,
                            "publisher": item.get("job_publisher"),
                            "skills": skills
                        })

                    return formatted
                else:
                    logger.error(f"JSearch API returned status {response.status_code}: {response.text}")
                    return []
        except Exception as e:
            logger.error(f"Exception during JSearch API fetch: {e}")
            return []
