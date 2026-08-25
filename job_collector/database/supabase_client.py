import os
import json
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime, timezone
from supabase import create_client, Client
from config import Config
from normalizer.job_normalizer import NormalizedJob

logger = logging.getLogger(__name__)

CACHE_FILE = os.path.join(os.path.dirname(__file__), "..", "collected_jobs_cache.json")

class SupabaseJobDatabase:
    def __init__(self):
        if not Config.SUPABASE_URL or not Config.SUPABASE_KEY:
            raise ValueError("SUPABASE_URL and SUPABASE_KEY must be configured.")
        self.client: Client = create_client(Config.SUPABASE_URL, Config.SUPABASE_KEY)
        self._schema_has_extended_columns: Optional[bool] = None
        self._local_cache: List[Dict[str, Any]] = self._load_local_cache()

    def _load_local_cache(self) -> List[Dict[str, Any]]:
        if os.path.exists(CACHE_FILE):
            try:
                with open(CACHE_FILE, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                return []
        return []

    def _save_local_cache(self):
        try:
            with open(CACHE_FILE, "w", encoding="utf-8") as f:
                json.dump(self._local_cache, f, indent=2)
        except Exception as e:
            logger.error(f"Failed to write local cache: {e}")

    def start_ingestion_log(self, source: str) -> str:
        try:
            res = self.client.table("job_ingestion_logs").insert({
                "source": source,
                "started_at": datetime.now(timezone.utc).isoformat(),
                "status": "RUNNING"
            }).execute()
            if res.data and len(res.data) > 0:
                return res.data[0]["id"]
        except Exception:
            pass
        return ""

    def update_ingestion_log(self, log_id: str, data: Dict[str, Any]):
        if not log_id:
            return
        try:
            data["completed_at"] = datetime.now(timezone.utc).isoformat()
            self.client.table("job_ingestion_logs").update(data).eq("id", log_id).execute()
        except Exception:
            pass

    def is_job_existing(self, external_job_id: str, normalized_hash: str, clean_url: Optional[str] = None) -> bool:
        # Check local cache first
        for item in self._local_cache:
            if item.get("external_job_id") == external_job_id or item.get("normalized_hash") == normalized_hash:
                return True
            if clean_url:
                cached_url = item.get("apply_url") or item.get("job_url") or ""
                if cached_url and clean_url in cached_url.lower():
                    return True

        # Check cloud DB
        try:
            res1 = self.client.table("jobs").select("id").eq("external_job_id", external_job_id).execute()
            if res1.data and len(res1.data) > 0:
                return True
        except Exception:
            pass

        return False

    def upsert_job(self, job: NormalizedJob) -> str:
        job_dict = job.to_dict()
        
        # Always store in local cache to guarantee data availability
        existing_index = next((i for i, item in enumerate(self._local_cache) if item.get("external_job_id") == job.external_job_id), None)
        if existing_index is not None:
            self._local_cache[existing_index] = job_dict
            action = "upserted"
        else:
            self._local_cache.append(job_dict)
            action = "inserted"
        self._save_local_cache()

        # Attempt cloud DB write
        core_payload = {
            "external_job_id": job.external_job_id,
            "job_title": job.job_title,
            "company_name": job.company_name,
            "company_logo_url": job.company_logo_url,
            "location": job.location,
            "salary_range": job.salary_range,
            "platform_source": job.source,
            "job_url": job.job_url or job.apply_url,
            "description": job.description,
            "required_skills": job.required_skills,
            "is_active": job.is_active,
            "posted_at": job.source_posted_at
        }

        try:
            self.client.table("jobs").upsert(core_payload, on_conflict="external_job_id").execute()
        except Exception as e:
            logger.debug(f"Cloud DB write skipped (pending SQL migration execution): {e}")

        return action
