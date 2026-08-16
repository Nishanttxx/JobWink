import logging
import httpx
from typing import List, Dict, Any
from config import Config
from collectors.base_collector import BaseJobCollector
from database.supabase_client import SupabaseJobDatabase

logger = logging.getLogger(__name__)

class HimalayasCollector(BaseJobCollector):
    def __init__(self, db: SupabaseJobDatabase):
        super().__init__("Himalayas", db)
        self.url = Config.HIMALAYAS_API_URL

    def fetch_jobs(self, page: int = 1) -> List[Dict[str, Any]]:
        limit = 20
        offset = (page - 1) * limit

        try:
            params = {"limit": limit, "offset": offset}
            headers = {"User-Agent": "JobWinkCollector/1.0", "Accept": "application/json"}
            with httpx.Client(timeout=15.0) as client:
                response = client.get(self.url, params=params, headers=headers)
                if response.status_code == 200:
                    data = response.json()
                    return data.get("jobs", [])
                else:
                    logger.error(f"Himalayas API status {response.status_code}: {response.text}")
                    return []
        except Exception as e:
            logger.error(f"Exception during Himalayas fetch: {e}")
            return []
