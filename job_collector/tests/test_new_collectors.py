import os
import sys
import unittest
from datetime import datetime, timezone, timedelta
from unittest.mock import MagicMock, patch

# Add parent directory to python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from config import Config
from normalizer.job_normalizer import JobNormalizer, NormalizedJob
from deduplication.deduplicator import Deduplicator
from collectors.serpapi_google_jobs import SerpApiGoogleJobsCollector
from collectors.jsearch import JSearchCollector
from collectors.linkedin_rapidapi import LinkedInRapidApiCollector

class TestNewJobSourcesIntegration(unittest.TestCase):
    def setUp(self):
        self.mock_db = MagicMock()
        self.mock_db.is_job_existing.return_value = False
        self.mock_db.upsert_job.return_value = "inserted"
        self.mock_db.start_ingestion_log.return_value = "log-123"
        self.mock_db._local_cache = []

    def test_serpapi_parsing_and_apply_url_extraction(self):
        collector = SerpApiGoogleJobsCollector(self.mock_db)
        
        sample_serpapi_item = {
            "title": "Senior Flutter Developer",
            "company_name": "Google",
            "location": "Bangalore, Karnataka, India",
            "description": "Building cross-platform mobile apps using Flutter and Dart.",
            "job_id": "google_job_abc_123",
            "detected_extensions": {
                "posted_at": "5 hours ago",
                "schedule_type": "Full-time",
                "salary": "$120K–$150K a year",
                "work_from_home": False
            },
            "apply_options": [
                {"title": "Apply on LinkedIn", "link": "https://in.linkedin.com/jobs/view/123456789?utm_source=serpapi"},
                {"title": "Apply on Company Site", "link": "https://careers.google.com/jobs/results/987654"}
            ],
            "via": "via Google Careers",
            "thumbnail": "https://logo.clearbit.com/google.com"
        }

        # 1. Test apply URL extraction prioritizes company site
        best_url = collector._extract_best_apply_url(sample_serpapi_item)
        self.assertEqual(best_url, "https://careers.google.com/jobs/results/987654")

        # 2. Test normalization into NormalizedJob
        normalized = JobNormalizer.normalize(
            {
                "source_job_id": sample_serpapi_item["job_id"],
                "title": sample_serpapi_item["title"],
                "company": sample_serpapi_item["company_name"],
                "company_logo": sample_serpapi_item["thumbnail"],
                "location": sample_serpapi_item["location"],
                "description": sample_serpapi_item["description"],
                "salary": sample_serpapi_item["detected_extensions"]["salary"],
                "employment_type": sample_serpapi_item["detected_extensions"]["schedule_type"],
                "apply_url": best_url,
                "job_url": best_url,
                "posted_at": sample_serpapi_item["detected_extensions"]["posted_at"],
            },
            source_name="SerpApi"
        )

        self.assertEqual(normalized.source, "SerpApi")
        self.assertEqual(normalized.job_title, "Senior Flutter Developer")
        self.assertEqual(normalized.company_name, "Google")
        self.assertEqual(normalized.apply_url, "https://careers.google.com/jobs/results/987654")
        self.assertTrue(normalized.is_within_48_hours)
        self.assertEqual(normalized.salary_range, "$120K–$150K a year")

    def test_jsearch_parsing_and_normalization(self):
        collector = JSearchCollector(self.mock_db)

        now_utc = datetime.now(timezone.utc)
        iso_posted_at = (now_utc - timedelta(hours=3)).isoformat()

        sample_jsearch_item = {
            "job_id": "jsearch_job_9988",
            "job_title": "AI Backend Engineer",
            "employer_name": "OpenAI",
            "employer_logo": "https://logo.clearbit.com/openai.com",
            "job_city": "San Francisco",
            "job_state": "CA",
            "job_country": "US",
            "job_is_remote": True,
            "job_employment_type": "FULLTIME",
            "job_description": "Architect high-throughput AI services with Python and FastAPI.",
            "job_posted_at_datetime_utc": iso_posted_at,
            "job_apply_link": "https://openai.com/careers/ai-backend-engineer",
            "job_google_link": "https://www.google.com/search?q=openai+jobs",
            "job_publisher": "Direct",
            "job_min_salary": 180000,
            "job_max_salary": 240000,
            "job_salary_currency": "USD",
            "job_salary_period": "YEAR"
        }

        apply_url = collector._extract_apply_url(sample_jsearch_item)
        self.assertEqual(apply_url, "https://openai.com/careers/ai-backend-engineer")

        loc_str = collector._build_location_string(sample_jsearch_item)
        self.assertEqual(loc_str, "San Francisco, CA, US")

        normalized = JobNormalizer.normalize(
            {
                "source_job_id": sample_jsearch_item["job_id"],
                "title": sample_jsearch_item["job_title"],
                "company": sample_jsearch_item["employer_name"],
                "company_logo": sample_jsearch_item["employer_logo"],
                "location": loc_str,
                "remote": sample_jsearch_item["job_is_remote"],
                "description": sample_jsearch_item["job_description"],
                "salary_min": sample_jsearch_item["job_min_salary"],
                "salary_max": sample_jsearch_item["job_max_salary"],
                "salary_currency": sample_jsearch_item["job_salary_currency"],
                "apply_url": apply_url,
                "job_url": apply_url,
                "posted_at": sample_jsearch_item["job_posted_at_datetime_utc"],
            },
            source_name="JSearch"
        )

        self.assertEqual(normalized.source, "JSearch")
        self.assertEqual(normalized.job_title, "AI Backend Engineer")
        self.assertEqual(normalized.company_name, "OpenAI")
        self.assertTrue(normalized.remote)
        self.assertEqual(normalized.workplace_type, "Remote")
        self.assertEqual(normalized.salary_range, "$180,000 - $240,000")
        self.assertTrue(normalized.is_within_48_hours)

    def test_linkedin_rapidapi_parsing_and_normalization(self):
        collector = LinkedInRapidApiCollector(self.mock_db)

        now_utc = datetime.now(timezone.utc)
        sample_linkedin_item = {
            "id": "li_job_776655",
            "title": "Staff Mobile Engineer",
            "company_name": "Stripe",
            "company_logo_url": "https://logo.clearbit.com/stripe.com",
            "location": "Remote",
            "description": "Design financial mobile experiences.",
            "posted_at": (now_utc - timedelta(hours=8)).isoformat(),
            "direct_apply_url": "https://stripe.com/jobs/staff-mobile",
            "linkedin_job_url_cleaned": "https://www.linkedin.com/jobs/view/776655",
            "salary": "$200,000 - $250,000 / year",
            "employment_type": "Full-time",
            "is_remote": True
        }

        apply_url = collector._extract_apply_url(sample_linkedin_item)
        self.assertEqual(apply_url, "https://stripe.com/jobs/staff-mobile")

        normalized = JobNormalizer.normalize(
            {
                "source_job_id": sample_linkedin_item["id"],
                "title": sample_linkedin_item["title"],
                "company": sample_linkedin_item["company_name"],
                "company_logo": sample_linkedin_item["company_logo_url"],
                "location": sample_linkedin_item["location"],
                "remote": sample_linkedin_item["is_remote"],
                "description": sample_linkedin_item["description"],
                "salary": sample_linkedin_item["salary"],
                "employment_type": sample_linkedin_item["employment_type"],
                "apply_url": apply_url,
                "job_url": apply_url,
                "posted_at": sample_linkedin_item["posted_at"]
            },
            source_name="LinkedIn"
        )

        self.assertEqual(normalized.source, "LinkedIn")
        self.assertEqual(normalized.job_title, "Staff Mobile Engineer")
        self.assertEqual(normalized.company_name, "Stripe")
        self.assertTrue(normalized.remote)
        self.assertEqual(normalized.apply_url, "https://stripe.com/jobs/staff-mobile")
        self.assertTrue(normalized.is_within_48_hours)

    def test_cross_provider_deduplication_priority(self):
        deduplicator = Deduplicator(self.mock_db)

        # Job 1: From SerpApi
        job_serpapi = JobNormalizer.normalize({
            "source_job_id": "serp_101",
            "title": "Software Engineer",
            "company": "Google",
            "location": "Bangalore",
            "apply_url": "https://careers.google.com/jobs/101?utm_source=serpapi",
            "posted_at": "3 hours ago"
        }, source_name="SerpApi")

        # Job 2: From JSearch for the SAME role and company
        job_jsearch = JobNormalizer.normalize({
            "source_job_id": "jsearch_202",
            "title": "Software Engineer",
            "company": "Google",
            "location": "Bangalore",
            "apply_url": "https://careers.google.com/jobs/101?utm_source=jsearch&ref=tracker",
            "posted_at": "4 hours ago"
        }, source_name="JSearch")

        # Job 3: From LinkedIn for the SAME role and company
        job_linkedin = JobNormalizer.normalize({
            "source_job_id": "li_303",
            "title": "Software Engineer",
            "company": "Google",
            "location": "Bangalore",
            "apply_url": "https://careers.google.com/jobs/101",
            "posted_at": "2 hours ago"
        }, source_name="LinkedIn")

        # First job must be accepted
        self.assertFalse(deduplicator.is_duplicate(job_serpapi))

        # Second job must be detected as a duplicate (via normalized clean URL & content hash)
        self.assertTrue(deduplicator.is_duplicate(job_jsearch))

        # Third job must also be detected as a duplicate
        self.assertTrue(deduplicator.is_duplicate(job_linkedin))

    def test_48_hour_filtering(self):
        now = datetime.now(timezone.utc)

        # Job from 6 hours ago
        recent_job = JobNormalizer.normalize({
            "title": "DevOps Engineer",
            "company": "TechCorp",
            "posted_at": (now - timedelta(hours=6)).isoformat()
        }, "Test")
        self.assertTrue(recent_job.is_within_48_hours)

        # Job from 5 days ago
        old_job = JobNormalizer.normalize({
            "title": "Legacy C++ Developer",
            "company": "OldCorp",
            "posted_at": (now - timedelta(days=5)).isoformat()
        }, "Test")
        self.assertFalse(old_job.is_within_48_hours)

    def test_relative_date_parsing_variations(self):
        # Test various relative strings
        dt_5h = JobNormalizer.parse_datetime("5 hours ago")
        self.assertIsNotNone(dt_5h)
        self.assertTrue(JobNormalizer.is_within_48_hours(dt_5h))

        dt_1d = JobNormalizer.parse_datetime("1 day ago")
        self.assertIsNotNone(dt_1d)
        self.assertTrue(JobNormalizer.is_within_48_hours(dt_1d))

        dt_today = JobNormalizer.parse_datetime("today")
        self.assertIsNotNone(dt_today)
        self.assertTrue(JobNormalizer.is_within_48_hours(dt_today))

        dt_old = JobNormalizer.parse_datetime("7 days ago")
        self.assertIsNotNone(dt_old)
        self.assertFalse(JobNormalizer.is_within_48_hours(dt_old))

    def test_main_run_collectors_registration(self):
        from main import ALL_COLLECTOR_SOURCES, run_collectors

        self.assertIn("serpapi", ALL_COLLECTOR_SOURCES)
        self.assertIn("jsearch", ALL_COLLECTOR_SOURCES)
        self.assertIn("linkedin", ALL_COLLECTOR_SOURCES)

        # Test running specifically the 3 new collectors with mock DB
        with patch('main.SupabaseJobDatabase', return_value=self.mock_db):
            results = run_collectors(sources=["serpapi", "jsearch", "linkedin"])
            self.assertIn("serpapi", results)
            self.assertIn("jsearch", results)
            self.assertIn("linkedin", results)

if __name__ == "__main__":
    unittest.main()

