import hashlib
import re
from datetime import datetime, timezone, timedelta
from typing import Optional, List, Dict, Any
from dataclasses import dataclass, field, asdict
from dateutil import parser as date_parser

@dataclass
class NormalizedJob:
    source: str
    source_job_id: str
    external_job_id: str
    job_title: str
    company_name: str
    company_logo_url: Optional[str] = None
    location: Optional[str] = "Remote"
    country: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    remote: bool = False
    workplace_type: str = "On-site"
    employment_type: str = "Full-time"
    experience_level: Optional[str] = None
    salary_range: Optional[str] = None
    salary_min: Optional[float] = None
    salary_max: Optional[float] = None
    salary_currency: str = "USD"
    description: str = ""
    required_skills: List[str] = field(default_factory=list)
    responsibilities: Optional[str] = None
    requirements: Optional[str] = None
    source_posted_at: Optional[str] = None
    source_updated_at: Optional[str] = None
    first_seen_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    last_seen_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    apply_url: Optional[str] = None
    job_url: Optional[str] = None
    company_url: Optional[str] = None
    is_active: bool = True
    is_within_48_hours: bool = True
    normalized_hash: str = ""

    def to_dict(self) -> Dict[str, Any]:
        d = asdict(self)
        # Rename job_title -> job_title, platform_source -> source
        d["platform_source"] = self.source
        return d

class JobNormalizer:
    @staticmethod
    def parse_datetime(val: Any) -> Optional[datetime]:
        """Parses various date formats into UTC datetime object."""
        if not val:
            return None
        if isinstance(val, datetime):
            if val.tzinfo is None:
                return val.replace(tzinfo=timezone.utc)
            return val.astimezone(timezone.utc)
        if isinstance(val, (int, float)):
            # Timestamp (seconds or millis)
            if val > 1e11:
                val = val / 1000.0
            return datetime.fromtimestamp(val, tz=timezone.utc)
        if isinstance(val, str):
            val = val.strip()
            # Relative dates like "3 hours ago", "yesterday"
            now = datetime.now(timezone.utc)
            lower_val = val.lower()
            if "hour" in lower_val:
                match = re.search(r'(\d+)', val)
                hours = int(match.group(1)) if match else 1
                return now - timedelta(hours=hours)
            if "day" in lower_val:
                match = re.search(r'(\d+)', val)
                days = int(match.group(1)) if match else 1
                return now - timedelta(days=days)
            if "minute" in lower_val:
                match = re.search(r'(\d+)', val)
                mins = int(match.group(1)) if match else 10
                return now - timedelta(minutes=mins)
            if lower_val in ["today", "just now"]:
                return now

            try:
                dt = date_parser.parse(val)
                if dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
                return dt.astimezone(timezone.utc)
            except Exception:
                return None
        return None

    @staticmethod
    def calculate_normalized_hash(company: str, title: str, location: str) -> str:
        clean_company = re.sub(r'[^a-z0-9]', '', (company or "").lower())
        clean_title = re.sub(r'[^a-z0-9]', '', (title or "").lower())
        clean_loc = re.sub(r'[^a-z0-9]', '', (location or "").lower())
        raw_str = f"{clean_company}|{clean_title}|{clean_loc}"
        return hashlib.sha256(raw_str.encode('utf-8')).hexdigest()

    @classmethod
    def is_within_48_hours(cls, dt: Optional[datetime]) -> bool:
        if not dt:
            # If no timestamp available, treat as within 48h to avoid false rejections
            return True
        cutoff = datetime.now(timezone.utc) - timedelta(hours=48)
        return dt >= cutoff

    @classmethod
    def normalize(cls, raw_data: Dict[str, Any], source_name: str) -> NormalizedJob:
        source_job_id = str(raw_data.get("source_job_id") or raw_data.get("id") or raw_data.get("guid") or "")
        external_id = f"{source_name}_{source_job_id}" if source_job_id else f"{source_name}_{hashlib.md5(str(raw_data).encode()).hexdigest()[:10]}"
        
        title = raw_data.get("title") or raw_data.get("job_title") or "Untitled Position"
        company = raw_data.get("company") or raw_data.get("company_name") or raw_data.get("companyName") or "Unknown Company"
        
        # Location handling
        raw_loc = raw_data.get("location")
        if not raw_loc and raw_data.get("locationRestrictions"):
            loc_restrictions = raw_data.get("locationRestrictions")
            if isinstance(loc_restrictions, list):
                raw_loc = ", ".join([str(loc) for loc in loc_restrictions if loc])
            else:
                raw_loc = str(loc_restrictions)
        location = raw_loc or "Remote"

        posted_dt = cls.parse_datetime(
            raw_data.get("posted_at") or 
            raw_data.get("source_posted_at") or 
            raw_data.get("published_at") or 
            raw_data.get("pubDate") or 
            raw_data.get("created") or 
            raw_data.get("created_at")
        )
        updated_dt = cls.parse_datetime(
            raw_data.get("updated_at") or 
            raw_data.get("source_updated_at")
        ) or posted_dt

        effective_dt = updated_dt or posted_dt or datetime.now(timezone.utc)
        within_48h = cls.is_within_48_hours(effective_dt)

        hash_val = cls.calculate_normalized_hash(company, title, location)

        # Skills extraction
        raw_skills = raw_data.get("skills") or raw_data.get("required_skills") or raw_data.get("tags") or raw_data.get("categories") or []
        if isinstance(raw_skills, str):
            skills = [s.strip() for s in raw_skills.split(",") if s.strip()]
        elif isinstance(raw_skills, list):
            skills = [str(s).strip() for s in raw_skills if s]
        else:
            skills = []

        # Workplace type & remote detection
        loc_lower = str(location).lower()
        workplace_raw = str(raw_data.get("workplace") or raw_data.get("workplace_type") or "").lower()
        remote_scope_raw = str(raw_data.get("remote_scope") or "").lower()
        
        if "remote" in loc_lower or raw_data.get("remote") is True or workplace_raw == "remote" or "remote" in remote_scope_raw:
            workplace_type = "Remote"
            remote_flag = True
        elif "hybrid" in loc_lower or workplace_raw == "hybrid":
            workplace_type = "Hybrid"
            remote_flag = False
        else:
            workplace_type = "On-site"
            remote_flag = False

        # Salary parsing
        sal_min = raw_data.get("salary_min") if raw_data.get("salary_min") is not None else raw_data.get("minSalary")
        sal_max = raw_data.get("salary_max") if raw_data.get("salary_max") is not None else raw_data.get("maxSalary")
        
        try:
            salary_min = float(sal_min) if sal_min is not None else None
        except (ValueError, TypeError):
            salary_min = None

        try:
            salary_max = float(sal_max) if sal_max is not None else None
        except (ValueError, TypeError):
            salary_max = None

        salary_range = raw_data.get("salary_range") or raw_data.get("salary")
        if not salary_range and (salary_min or salary_max):
            if salary_min and salary_max:
                salary_range = f"${int(salary_min):,} - ${int(salary_max):,}"
            elif salary_min:
                salary_range = f"From ${int(salary_min):,}"
            elif salary_max:
                salary_range = f"Up to ${int(salary_max):,}"

        apply_link = raw_data.get("apply_url") or raw_data.get("applicationLink") or raw_data.get("job_url") or raw_data.get("url") or raw_data.get("link")
        job_link = raw_data.get("job_url") or raw_data.get("url") or apply_link

        return NormalizedJob(
            source=source_name,
            source_job_id=source_job_id,
            external_job_id=external_id,
            job_title=title,
            company_name=company,
            company_logo_url=raw_data.get("company_logo") or raw_data.get("company_logo_url") or raw_data.get("companyLogo"),
            location=location,
            country=raw_data.get("country"),
            city=raw_data.get("city"),
            state=raw_data.get("state"),
            remote=remote_flag,
            workplace_type=workplace_type,
            employment_type=raw_data.get("employment_type") or raw_data.get("job_type") or raw_data.get("employmentType") or "Full-time",
            experience_level=raw_data.get("experience_level") or raw_data.get("seniority"),
            salary_range=salary_range,
            salary_min=salary_min,
            salary_max=salary_max,
            salary_currency=raw_data.get("salary_currency") or raw_data.get("currency") or "USD",
            description=raw_data.get("description") or raw_data.get("excerpt") or title,
            required_skills=skills,
            responsibilities=raw_data.get("responsibilities"),
            requirements=raw_data.get("requirements"),
            source_posted_at=posted_dt.isoformat() if posted_dt else datetime.now(timezone.utc).isoformat(),
            source_updated_at=effective_dt.isoformat() if effective_dt else datetime.now(timezone.utc).isoformat(),
            apply_url=apply_link,
            job_url=job_link,
            company_url=raw_data.get("company_url"),
            is_active=True,
            is_within_48_hours=within_48h,
            normalized_hash=hash_val
        )

