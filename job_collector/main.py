import sys
import argparse
import logging
import uvicorn
from fastapi import FastAPI, BackgroundTasks, HTTPException
from database.supabase_client import SupabaseJobDatabase
from collectors.jooble import JoobleCollector
from collectors.adzuna import AdzunaCollector
from collectors.ashby import AshbyCollector
from collectors.crawl4ai_scraper import Crawl4AIScraper
from collectors.aidevboard import AidevboardCollector
from collectors.agentic_engineering import AgenticEngineeringCollector
from collectors.himalayas import HimalayasCollector

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("JobCollectorService")

app = FastAPI(
    title="JobWink Ingestion & Crawl4AI Service",
    description="Collects, normalizes, 48-hour filters, deduplicates, and ingests job postings into Supabase."
)

def run_collectors(sources=None):
    db = SupabaseJobDatabase()
    collectors = {
        "jooble": JoobleCollector(db),
        "adzuna": AdzunaCollector(db),
        "ashby": AshbyCollector(db),
        "crawl4ai": Crawl4AIScraper(db),
        "aidevboard": AidevboardCollector(db),
        "agentic_engineering": AgenticEngineeringCollector(db),
        "himalayas": HimalayasCollector(db)
    }

    targets = sources if sources else list(collectors.keys())
    results = {}

    for src in targets:
        if src in collectors:
            logger.info(f"--- Running collector: {src} ---")
            stats = collectors[src].run()
            results[src] = stats
        else:
            logger.warning(f"Unknown collector source: {src}")

    return results

@app.get("/api/health")
def health_check():
    return {"status": "ok", "service": "JobWink Collector & Crawl4AI Pipeline"}

@app.post("/api/collect/all")
def collect_all_jobs(background_tasks: BackgroundTasks):
    background_tasks.add_task(run_collectors)
    return {"message": "Job collection across all sources started in background."}

@app.post("/api/collect/{source}")
def collect_source_jobs(source: str, background_tasks: BackgroundTasks):
    valid_sources = ["jooble", "adzuna", "ashby", "crawl4ai", "aidevboard", "agentic_engineering", "himalayas"]
    if source.lower() not in valid_sources:
        raise HTTPException(status_code=400, detail=f"Invalid source. Choose from {valid_sources}")
    background_tasks.add_task(run_collectors, [source.lower()])
    return {"message": f"Job collection for source '{source}' started in background."}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="JobWink Collection Pipeline Runner")
    parser.add_argument("--run-all", action="store_true", help="Run all collectors synchronously")
    parser.add_argument("--source", type=str, help="Run a specific collector (jooble, adzuna, ashby, crawl4ai, aidevboard, agentic_engineering, himalayas)")

    parser.add_argument("--port", type=int, default=8000, help="Port to run FastAPI server on")

    args = parser.parse_args()

    if args.run_all:
        logger.info("Executing synchronous CLI job collection for all sources...")
        res = run_collectors()
        print("\n=== Collection Results Summary ===")
        for k, v in res.items():
            print(f"[{k.upper()}] Added: {v.get('jobs_added')}, Skipped/Duplicates: {v.get('jobs_skipped')}, Outside 48h: {v.get('jobs_outside_48_hours')}, Status: {v.get('status')}")
        sys.exit(0)
    elif args.source:
        logger.info(f"Executing CLI job collection for source: {args.source}...")
        res = run_collectors([args.source])
        print("\n=== Collection Results Summary ===")
        for k, v in res.items():
            print(f"[{k.upper()}] Added: {v.get('jobs_added')}, Skipped/Duplicates: {v.get('jobs_skipped')}, Outside 48h: {v.get('jobs_outside_48_hours')}, Status: {v.get('status')}")
        sys.exit(0)
    else:
        logger.info("Starting FastAPI server on port %d...", args.port)
        uvicorn.run(app, host="0.0.0.0", port=args.port)
