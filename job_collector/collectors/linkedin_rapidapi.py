import logging
import httpx
from typing import List, Dict, Any, Optional
from config import Config
from collectors.base_collector import BaseJobCollector
from database.supabase_client import SupabaseJobDatabase

logger = logging.getLogger(__name__)

class LinkedInRapidApiCollector(BaseJobCollector):
    """
    Collector for LinkedIn Job Search API via RapidAPI.
    Endpoint: https://linkedin-job-search-api.p.rapidapi.com/active-jb
    Example: https://linkedin-job-search-api.p.rapidapi.com/active-jb?time_frame=24h&limit=20&offset=0
    """
    def __init__(self, db: SupabaseJobDatabase):
        super().__init__("LinkedIn", db)
        self.api_key = Config.RAPIDAPI_KEY
        self.host = Config.RAPIDAPI_HOST or "linkedin-job-search-api.p.rapidapi.com"
        self.base_url = "https://linkedin-job-search-api.p.rapidapi.com/active-jb"

    def _extract_apply_url(self, item: Dict[str, Any]) -> Optional[str]:
        """
        Extracts the job URL or direct application URL from the LinkedIn API response.
        Prioritizes direct application URL, cleaned LinkedIn URL, or job URL.
        Never fabricates URLs.
        """
        urls_to_check = [
            item.get("apply_url"),
            item.get("application_url"),
            item.get("direct_apply_url"),
            item.get("linkedin_job_url_cleaned"),
            item.get("linkedin_job_url"),
            item.get("url"),
            item.get("job_url"),
            item.get("link")
        ]

        for u in urls_to_check:
            if u and isinstance(u, str) and u.strip().startswith("http"):
                return u.strip()

        return None

    def fetch_jobs(self, page: int = 1) -> List[Dict[str, Any]]:
        if not self.api_key:
            logger.warning("RAPIDAPI_KEY is not configured. Skipping LinkedIn RapidAPI collection.")
            return []

        limit = 20
        offset = (page - 1) * limit
        params = {
            "time_frame": "24h",
            "limit": str(limit),
            "offset": str(offset)
        }
        headers = {
            "x-rapidapi-key": self.api_key,
            "x-rapidapi-host": self.host
        }

        try:
            with httpx.Client(timeout=20.0) as client:
                response = client.get(self.base_url, params=params, headers=headers)
                if response.status_code == 200:
                    data = response.json()
                    
                    # Handle both list responses and dictionary responses {"data": [...]}
                    raw_items = []
                    if isinstance(data, list):
                        raw_items = data
                    elif isinstance(data, dict):
                        raw_items = data.get("data") or data.get("jobs") or data.get("results") or []

                    formatted = []
                    for item in raw_items:
                        if not isinstance(item, dict):
                            continue

                        job_id = str(
                            item.get("id") or 
                            item.get("job_id") or 
                            item.get("linkedin_job_id") or 
                            item.get("urn") or 
                            ""
                        )
                        title = item.get("title") or item.get("job_title") or "Software Engineer"
                        company = (
                            item.get("company_name") or 
                            item.get("company") or 
                            item.get("employer") or 
                            "Company"
                        )
                        logo = (
                            item.get("company_logo_url") or 
                            item.get("company_logo") or 
                            item.get("logo")
                        )
                        location = item.get("location") or item.get("place") or "Remote"
                        description = item.get("description") or item.get("job_description") or title
                        posted_at = (
                            item.get("posted_at") or 
                            item.get("post_date") or 
                            item.get("date_posted") or 
                            item.get("listed_at") or 
                            item.get("created_at")
                        )
                        apply_url = self._extract_apply_url(item)

                        is_remote = (
                            bool(item.get("is_remote", False)) or 
                            "remote" in str(location).lower() or 
                            str(item.get("workplace_type", "")).lower() == "remote"
                        )

                        formatted.append({
                            "source_job_id": job_id,
                            "title": title,
                            "company": company,
                            "company_logo": logo,
                            "location": location,
                            "remote": is_remote,
                            "workplace_type": "Remote" if is_remote else (item.get("workplace_type") or "On-site"),
                            "employment_type": item.get("employment_type") or item.get("job_type") or "Full-time",
                            "description": description,
                            "salary": item.get("salary") or item.get("salary_range") or item.get("compensation"),
                            "apply_url": apply_url,
                            "job_url": apply_url,
                            "posted_at": posted_at,
                            "publisher": "LinkedIn",
                            "skills": item.get("skills") or item.get("required_skills") or []
                        })

                    return formatted
                else:
                    logger.error(f"LinkedIn RapidAPI returned status {response.status_code}: {response.text}")
                    return []
        except Exception as e:
            logger.error(f"Exception during LinkedIn RapidAPI fetch: {e}")
            return []
