import logging
import httpx
from typing import List, Dict, Any
from collectors.base_collector import BaseJobCollector
from database.supabase_client import SupabaseJobDatabase

logger = logging.getLogger(__name__)

# Sample public Ashby job boards for tech companies
ASHBY_TARGET_BOARDS = [
    "notion",
    "ramp",
    "linear",
    "openai",
    "figma",
    "replit"
]

class AshbyCollector(BaseJobCollector):
    def __init__(self, db: SupabaseJobDatabase):
        super().__init__("Ashby", db)

    def fetch_jobs(self, page: int = 1) -> List[Dict[str, Any]]:
        # Page 1 loops over target boards
        if page > 1:
            return []

        all_jobs = []

        for board in ASHBY_TARGET_BOARDS:
            url = f"https://api.ashbyhq.com/posting-api/job-board/{board}?includeCompensation=true"
            try:
                with httpx.Client(timeout=15.0) as client:
                    response = client.get(url)
                    if response.status_code == 200:
                        data = response.json()
                        postings = data.get("jobs", [])
                        for item in postings:
                            all_jobs.append({
                                "source_job_id": str(item.get("id", "")),
                                "title": item.get("title"),
                                "company": board.capitalize(),
                                "location": item.get("location"),
                                "employment_type": item.get("employmentType"),
                                "job_url": item.get("jobUrl"),
                                "posted_at": item.get("publishedAt"),
                                "updated_at": item.get("updatedAt"),
                                "description": item.get("descriptionHtml") or item.get("title")
                            })
                    else:
                        logger.debug(f"Ashby board {board} status {response.status_code}")
            except Exception as e:
                logger.error(f"Error fetching Ashby board {board}: {e}")

        return all_jobs
