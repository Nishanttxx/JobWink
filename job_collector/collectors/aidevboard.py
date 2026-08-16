import logging
import httpx
from typing import List, Dict, Any
from config import Config
from collectors.base_collector import BaseJobCollector
from database.supabase_client import SupabaseJobDatabase

logger = logging.getLogger(__name__)

class AidevboardCollector(BaseJobCollector):
    def __init__(self, db: SupabaseJobDatabase):
        super().__init__("Aidevboard", db)
        self.url = Config.AIDEVBOARD_API_URL

    def fetch_jobs(self, page: int = 1) -> List[Dict[str, Any]]:
        # Aidevboard catalog endpoint returns the primary open catalog
        if page > 1:
            return []

        try:
            headers = {"User-Agent": "JobWinkCollector/1.0", "Accept": "application/json"}
            with httpx.Client(timeout=15.0) as client:
                response = client.get(self.url, headers=headers)
                if response.status_code == 200:
                    data = response.json()
                    jobs_raw = data.get("jobs", [])
                    return jobs_raw
                else:
                    logger.error(f"Aidevboard API status {response.status_code}: {response.text}")
                    return []
        except Exception as e:
            logger.error(f"Exception during Aidevboard fetch: {e}")
            return []
