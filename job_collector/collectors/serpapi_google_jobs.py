import logging
import httpx
from typing import List, Dict, Any, Optional
from config import Config
from collectors.base_collector import BaseJobCollector
from database.supabase_client import SupabaseJobDatabase

logger = logging.getLogger(__name__)

class SerpApiGoogleJobsCollector(BaseJobCollector):
    """
    Collector for Google Jobs via SerpApi.
    Endpoint: https://serpapi.com/search?engine=google_jobs
    Doc: https://serpapi.com/google-jobs-api
    """
    def __init__(self, db: SupabaseJobDatabase):
        super().__init__("SerpApi", db)
        self.api_key = Config.SERPAPI_API_KEY
        self.base_url = "https://serpapi.com/search"

    def _extract_best_apply_url(self, item: Dict[str, Any]) -> Optional[str]:
        """
        Extracts the best available application URL from apply_options or share_link.
        Prioritizes direct employer application links over third-party aggregators.
        Never fabricates or guesses URLs.
        """
        apply_options = item.get("apply_options") or []
        if isinstance(apply_options, list) and len(apply_options) > 0:
            # 1. Look for direct company / employer application options
            for opt in apply_options:
                if isinstance(opt, dict):
                    title = str(opt.get("title", "")).lower()
                    link = opt.get("link")
                    if link and ("apply on company" in title or "employer" in title or "direct" in title):
                        return str(link).strip()

            # 2. Use the first valid apply option link provided by API
            for opt in apply_options:
                if isinstance(opt, dict):
                    link = opt.get("link")
                    if link and str(link).strip().startswith("http"):
                        return str(link).strip()

        # 3. Fallback to share_link or link returned in root response
        share_link = item.get("share_link") or item.get("link")
        if share_link and str(share_link).strip().startswith("http"):
            return str(share_link).strip()

        return None

    def fetch_jobs(self, page: int = 1) -> List[Dict[str, Any]]:
        if not self.api_key:
            logger.warning("SERPAPI_API_KEY is not configured. Skipping SerpApi collection.")
            return []

        start_offset = (page - 1) * 10
        params = {
            "engine": "google_jobs",
            "q": "software engineer developer tech remote",
            "api_key": self.api_key,
            "hl": "en",
            "start": start_offset,
        }

        try:
            with httpx.Client(timeout=20.0) as client:
                response = client.get(self.base_url, params=params)
                if response.status_code == 200:
                    data = response.json()
                    jobs_results = data.get("jobs_results", [])
                    formatted = []

                    for item in jobs_results:
                        if not isinstance(item, dict):
                            continue

                        detected = item.get("detected_extensions") or {}
                        posted_at_raw = detected.get("posted_at") or item.get("posted_at")
                        salary_raw = detected.get("salary") or item.get("salary")
                        schedule_type = detected.get("schedule_type") or item.get("employment_type")
                        apply_url = self._extract_best_apply_url(item)

                        # Extract extensions list (e.g. ['5 hours ago', 'Full-time', 'Work from home'])
                        extensions = item.get("extensions") or []
                        is_remote = detected.get("work_from_home", False)
                        if not is_remote and any("work from home" in str(e).lower() or "remote" in str(e).lower() for e in extensions):
                            is_remote = True

                        job_id = item.get("job_id") or ""

                        formatted.append({
                            "source_job_id": str(job_id),
                            "title": item.get("title") or "Software Engineer",
                            "company": item.get("company_name") or "Unknown Company",
                            "company_logo": item.get("thumbnail"),
                            "location": item.get("location") or ("Remote" if is_remote else "United States"),
                            "description": item.get("description") or item.get("title", ""),
                            "salary": salary_raw,
                            "employment_type": schedule_type,
                            "remote": is_remote,
                            "apply_url": apply_url,
                            "job_url": apply_url,
                            "posted_at": posted_at_raw,
                            "publisher": item.get("via"),
                        })

                    return formatted
                else:
                    logger.error(f"SerpApi returned status {response.status_code}: {response.text}")
                    return []
        except Exception as e:
            logger.error(f"Exception during SerpApi Google Jobs fetch: {e}")
            return []
