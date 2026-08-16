import logging
import abc
from typing import List, Dict, Any
from normalizer.job_normalizer import JobNormalizer, NormalizedJob
from deduplication.deduplicator import Deduplicator
from database.supabase_client import SupabaseJobDatabase

logger = logging.getLogger(__name__)

class BaseJobCollector(abc.ABC):
    def __init__(self, source_name: str, db: SupabaseJobDatabase):
        self.source_name = source_name
        self.db = db
        self.deduplicator = Deduplicator(db)

    @abc.abstractmethod
    def fetch_jobs(self, page: int = 1) -> List[Dict[str, Any]]:
        """Fetch raw jobs for a given page from the source API or scraper."""
        pass

    def run(self, max_pages: int = 5) -> Dict[str, Any]:
        log_id = self.db.start_ingestion_log(self.source_name)
        stats = {
            "jobs_found": 0,
            "jobs_added": 0,
            "jobs_updated": 0,
            "jobs_skipped": 0,
            "duplicates_found": 0,
            "jobs_outside_48_hours": 0,
            "status": "COMPLETED",
            "errors": None
        }

        try:
            logger.info(f"Starting job collection for {self.source_name}...")
            stop_collection = False

            for page in range(1, max_pages + 1):
                if stop_collection:
                    break

                logger.info(f"[{self.source_name}] Fetching page {page}...")
                raw_jobs = self.fetch_jobs(page=page)
                if not raw_jobs:
                    break

                stats["jobs_found"] += len(raw_jobs)

                for raw_job in raw_jobs:
                    try:
                        normalized = JobNormalizer.normalize(raw_job, self.source_name)

                        # Check 48-hour window
                        if not normalized.is_within_48_hours:
                            stats["jobs_outside_48_hours"] += 1
                            # If results are strictly chronological, we can stop
                            continue

                        # Check deduplication
                        if self.deduplicator.is_duplicate(normalized):
                            stats["duplicates_found"] += 1
                            stats["jobs_skipped"] += 1
                            continue

                        # Save to Supabase
                        action = self.db.upsert_job(normalized)
                        if action == "inserted":
                            stats["jobs_added"] += 1
                        else:
                            stats["jobs_updated"] += 1

                    except Exception as e:
                        logger.error(f"Error processing job in {self.source_name}: {e}")
                        stats["jobs_skipped"] += 1

            logger.info(f"Completed collection for {self.source_name}. Added: {stats['jobs_added']}, Duplicates: {stats['duplicates_found']}")

        except Exception as e:
            logger.error(f"Collector {self.source_name} failed: {e}")
            stats["status"] = "FAILED"
            stats["errors"] = str(e)

        finally:
            self.db.update_ingestion_log(log_id, stats)

        return stats
