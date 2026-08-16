import logging
import httpx
from typing import List, Dict, Any
from config import Config
from collectors.base_collector import BaseJobCollector
from database.supabase_client import SupabaseJobDatabase

logger = logging.getLogger(__name__)

class JoobleCollector(BaseJobCollector):
    def __init__(self, db: SupabaseJobDatabase):
        super().__init__("Jooble", db)
        self.api_key = Config.JOOBLE_API_KEY
        self.url = f"https://jooble.org/api/{self.api_key}"

    def fetch_jobs(self, page: int = 1) -> List[Dict[str, Any]]:
        if not self.api_key:
            logger.warning("Jooble API Key not provided. Skipping.")
            return []

        payload = {
            "keywords": "developer engineer software",
            "page": page,
            "resultonpage": 20
        }
        headers = {"Content-Type": "application/json"}

        try:
            with httpx.Client(timeout=15.0) as client:
                response = client.post(self.url, json=payload, headers=headers)
                if response.status_code == 200:
                    data = response.json()
                    jobs_raw = data.get("jobs", [])
                    formatted = []
                    for item in jobs_raw:
                        formatted.append({
                            "source_job_id": str(item.get("id", "")),
                            "title": item.get("title"),
                            "company": item.get("company"),
                            "location": item.get("location"),
                            "description": item.get("snippet"),
                            "salary": item.get("salary"),
                            "job_url": item.get("link"),
                            "posted_at": item.get("updated")
                        })
                    return formatted
                else:
                    logger.error(f"Jooble API returned status {response.status_code}: {response.text}")
                    return []
        except Exception as e:
            logger.error(f"Exception during Jooble API fetch: {e}")
            return []
