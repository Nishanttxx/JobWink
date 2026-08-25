import logging
import re
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse
from typing import Set, Optional
from normalizer.job_normalizer import NormalizedJob
from database.supabase_client import SupabaseJobDatabase

logger = logging.getLogger(__name__)

class Deduplicator:
    """
    Deduplication engine enforcing 3-tier priority:
    1. Provider Job ID (source + source_job_id / external_job_id)
    2. Normalized Application URL (stripped of UTM and tracking parameters)
    3. Normalized Company + Title + Location Hash
    """
    def __init__(self, db: SupabaseJobDatabase):
        self.db = db
        self.seen_ids: Set[str] = set()
        self.seen_urls: Set[str] = set()
        self.seen_hashes: Set[str] = set()

    @staticmethod
    def clean_url(url: Optional[str]) -> str:
        if not url or not isinstance(url, str):
            return ""
        try:
            parsed = urlparse(url.strip())
            if not parsed.scheme or not parsed.netloc:
                return url.strip().lower()

            # Filter tracking query parameters
            tracking_keys = {
                'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content',
                'ref', 'source', 'gh_src', 'fbclid', 'gclid', 'msclkid', 'trk', 'trackingId'
            }
            query_dict = parse_qs(parsed.query)
            filtered_query = {k: v for k, v in query_dict.items() if k.lower() not in tracking_keys}
            clean_query = urlencode(filtered_query, doseq=True)

            clean_path = parsed.path.rstrip('/')
            clean_netloc = parsed.netloc.lower()
            if clean_netloc.startswith("www."):
                clean_netloc = clean_netloc[4:]

            cleaned = urlunparse((parsed.scheme.lower(), clean_netloc, clean_path, '', clean_query, ''))
            return cleaned.rstrip('/')
        except Exception:
            return url.strip().lower()

    def is_duplicate(self, job: NormalizedJob) -> bool:
        # Tier 1: Provider Job ID
        batch_id_key = f"{job.source}_{job.source_job_id}" if job.source_job_id else job.external_job_id
        if batch_id_key in self.seen_ids:
            logger.debug(f"[Deduplication Tier 1] Duplicate ID in batch: {batch_id_key}")
            return True

        # Tier 2: Normalized Application URL
        clean_apply_url = self.clean_url(job.apply_url or job.job_url)
        if clean_apply_url and clean_apply_url in self.seen_urls:
            logger.debug(f"[Deduplication Tier 2] Duplicate URL in batch: {clean_apply_url}")
            return True

        # Tier 3: Normalized Company + Title + Location Hash
        hash_key = job.normalized_hash
        if hash_key in self.seen_hashes:
            logger.debug(f"[Deduplication Tier 3] Duplicate Company/Title/Location hash in batch: {hash_key}")
            return True

        # Check Database (local cache + cloud)
        if self.db.is_job_existing(
            external_job_id=job.external_job_id,
            normalized_hash=job.normalized_hash,
            clean_url=clean_apply_url
        ):
            return True

        # Mark seen
        self.seen_ids.add(batch_id_key)
        if clean_apply_url:
            self.seen_urls.add(clean_apply_url)
        self.seen_hashes.add(hash_key)
        return False
