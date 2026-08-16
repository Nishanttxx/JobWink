import logging
import httpx
from typing import List, Dict, Any
from config import Config
from collectors.base_collector import BaseJobCollector
from database.supabase_client import SupabaseJobDatabase

logger = logging.getLogger(__name__)

class AgenticEngineeringCollector(BaseJobCollector):
    def __init__(self, db: SupabaseJobDatabase):
        super().__init__("AgenticEngineering", db)
        self.url = Config.AGENTIC_ENGINEERING_API_URL

    def fetch_jobs(self, page: int = 1) -> List[Dict[str, Any]]:
        if page > 1:
            return []

        try:
            params = {"sort": "newest"}
            headers = {"User-Agent": "JobWinkCollector/1.0", "Accept": "application/json"}
            with httpx.Client(timeout=15.0) as client:
                response = client.get(self.url, params=params, headers=headers)
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list):
                        return data
                    elif isinstance(data, dict):
                        return data.get("jobs", []) or data.get("data", [])
                    return []
                else:
                    logger.error(f"Agentic Engineering API status {response.status_code}: {response.text}")
                    return []
        except Exception as e:
            logger.error(f"Exception during Agentic Engineering fetch: {e}")
            return []
