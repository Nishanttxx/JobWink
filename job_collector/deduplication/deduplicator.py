import logging
from typing import Set, Tuple
from normalizer.job_normalizer import NormalizedJob
from database.supabase_client import SupabaseJobDatabase

logger = logging.getLogger(__name__)

class Deduplicator:
    def __init__(self, db: SupabaseJobDatabase):
        self.db = db
        self.seen_in_batch: Set[str] = set()

    def is_duplicate(self, job: NormalizedJob) -> bool:
        # Check in-memory batch deduplication first
        batch_key = f"{job.source}_{job.source_job_id}"
        hash_key = job.normalized_hash

        if batch_key in self.seen_in_batch or hash_key in self.seen_in_batch:
            return True

        # Check database
        if self.db.is_job_existing(job.external_job_id, job.normalized_hash):
            return True

        # Mark seen
        self.seen_in_batch.add(batch_key)
        self.seen_in_batch.add(hash_key)
        return False
