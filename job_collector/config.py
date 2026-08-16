import os
from dotenv import load_dotenv

# Load .env file from current directory
dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(dotenv_path=dotenv_path)

class Config:
    SUPABASE_URL = os.getenv("SUPABASE_URL", "https://YOUR_SUPABASE_REF.supabase.co")
    SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_ANON_KEY")
    
    # API Credentials & Endpoints
    JOOBLE_API_KEY = os.getenv("JOOBLE_API_KEY", "REDACTED_JOOBLE_KEY")
    ADZUNA_APP_ID = os.getenv("ADZUNA_APP_ID", "REDACTED_ADZUNA_APP_ID")
    ADZUNA_APP_KEY = os.getenv("ADZUNA_APP_KEY", "REDACTED_ADZUNA_APP_KEY")
    AIDEVBOARD_API_URL = os.getenv("AIDEVBOARD_API_URL", "https://aidevboard.com/api/v1/catalog")
    AGENTIC_ENGINEERING_API_URL = os.getenv("AGENTIC_ENGINEERING_API_URL", "https://agentic-engineering-jobs.com/api/v1/jobs")
    HIMALAYAS_API_URL = os.getenv("HIMALAYAS_API_URL", "https://himalayas.app/jobs/api")
    
    # System settings
    MAX_JOB_AGE_HOURS = 48

