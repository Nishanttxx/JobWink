import logging
import httpx
from typing import List, Dict, Any
from config import Config
from collectors.base_collector import BaseJobCollector
from database.supabase_client import SupabaseJobDatabase

logger = logging.getLogger(__name__)

class AdzunaCollector(BaseJobCollector):
    def __init__(self, db: SupabaseJobDatabase):
        super().__init__("Adzuna", db)
        self.app_id = Config.ADZUNA_APP_ID
        self.app_key = Config.ADZUNA_APP_KEY

    def fetch_jobs(self, page: int = 1) -> List[Dict[str, Any]]:
        if not self.app_id or not self.app_key:
            logger.warning("Adzuna credentials not configured. Skipping.")
            return []

        url = f"https://api.adzuna.com/v1/api/jobs/us/search/{page}"
        params = {
            "app_id": self.app_id,
            "app_key": self.app_key,
            "results_per_page": 20,
            "what": "developer engineer tech",
            "sort_by": "date"
        }

        try:
            with httpx.Client(timeout=15.0) as client:
                response = client.get(url, params=params)
                if response.status_code == 200:
                    data = response.json()
                    results = data.get("results", [])
                    formatted = []
                    for item in results:
                        formatted.append({
                            "source_job_id": str(item.get("id", "")),
                            "title": item.get("title"),
                            "company": item.get("company", {}).get("display_name"),
                            "location": item.get("location", {}).get("display_name"),
                            "description": item.get("description"),
                            "salary_min": item.get("salary_min"),
                            "salary_max": item.get("salary_max"),
                            "job_url": item.get("redirect_url"),
                            "posted_at": item.get("created")
                        })
                    return formatted
                else:
                    logger.error(f"Adzuna API status {response.status_code}: {response.text}")
                    return []
        except Exception as e:
            logger.error(f"Exception during Adzuna fetch: {e}")
            return []
