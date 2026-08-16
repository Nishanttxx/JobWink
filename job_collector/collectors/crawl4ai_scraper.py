import logging
import asyncio
import re
from typing import List, Dict, Any
try:
    from crawl4ai import AsyncWebCrawler
    CRAWL4AI_AVAILABLE = True
except ImportError:
    AsyncWebCrawler = None
    CRAWL4AI_AVAILABLE = False

from collectors.base_collector import BaseJobCollector
from database.supabase_client import SupabaseJobDatabase


logger = logging.getLogger(__name__)

# Permitted sources for Crawl4AI web scraping
PERMITTED_SCRAPE_TARGETS = [
    {
        "name": "Stripe Careers",
        "company": "Stripe",
        "url": "https://stripe.com/jobs/search",
    },
    {
        "name": "Vercel Careers",
        "company": "Vercel",
        "url": "https://vercel.com/careers",
    },
    {
        "name": "Supabase Careers",
        "company": "Supabase",
        "url": "https://supabase.com/careers",
    }
]

class Crawl4AIScraper(BaseJobCollector):
    def __init__(self, db: SupabaseJobDatabase):
        super().__init__("Crawl4AI_Scraper", db)

    def fetch_jobs(self, page: int = 1) -> List[Dict[str, Any]]:
        if page > 1:
            return []

        if not CRAWL4AI_AVAILABLE:
            logger.warning("crawl4ai package is not installed. Skipping Crawl4AI scraper.")
            return []

        try:
            return asyncio.run(self._scrape_all())
        except Exception as e:
            logger.error(f"Error running Crawl4AI scraper: {e}")
            return []


    async def _scrape_all(self) -> List[Dict[str, Any]]:
        extracted_jobs = []

        async with AsyncWebCrawler(verbose=False) as crawler:
            for target in PERMITTED_SCRAPE_TARGETS:
                url = target["url"]
                company = target["company"]
                try:
                    logger.info(f"Crawl4AI scraping: {url}...")
                    result = await crawler.arun(url=url)
                    if result.success and result.markdown:
                        content = result.markdown
                        # Parse job listings from markdown content
                        lines = content.split("\n")
                        current_title = None

                        for line in lines:
                            line_clean = line.strip()
                            if not line_clean:
                                continue
                            
                            # Match role title headings or bullet points
                            if re.search(r'(engineer|developer|architect|designer|manager|lead|frontend|backend|fullstack|data)', line_clean, re.I):
                                title = re.sub(r'^[#*\-\s]+', '', line_clean)
                                if len(title) < 100:
                                    extracted_jobs.append({
                                        "source_job_id": f"{company.lower()}_{hash(title) & 0xffffffff}",
                                        "title": title,
                                        "company": company,
                                        "location": "Remote / On-site",
                                        "description": f"Role at {company}: {title}. Scraped via Crawl4AI.",
                                        "job_url": url,
                                        "posted_at": None  # Inferred as recent
                                    })
                except Exception as e:
                    logger.error(f"Failed to scrape {url} with Crawl4AI: {e}")

        return extracted_jobs
