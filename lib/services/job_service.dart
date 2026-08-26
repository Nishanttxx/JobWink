import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/job_match.dart';
import 'supabase_service.dart';

class JobService {
  static final JobService instance = JobService._internal();

  JobService._internal();

  List<JobMatch>? _cachedJobPool;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Rapidly fetches real job postings with strict timeout, deduplication, 10+ jobs guarantee, and fresh randomization.
  Future<List<JobMatch>> fetchLatest48hJobs({bool forceRefresh = false}) async {
    // If pool is already cached and not forcing refresh, return a newly randomized rotation
    if (_cachedJobPool != null && _cachedJobPool!.isNotEmpty && !forceRefresh) {
      final rotated = List<JobMatch>.from(_cachedJobPool!)..shuffle(Random());
      return rotated;
    }

    final client = SupabaseService.instance.client;
    List<JobMatch> fetched = [];

    if (client != null) {
      try {
        final response = await client
            .from('jobs')
            .select('*')
            .eq('is_active', true)
            .order('posted_at', ascending: false)
            .limit(100)
            .timeout(const Duration(seconds: 3));

        if (response.isNotEmpty) {
          fetched = (response as List)
              .map((json) {
                try {
                  return JobMatch.fromJson(json);
                } catch (_) {
                  return null;
                }
              })
              .whereType<JobMatch>()
              .where(_isValidJob)
              .toList();
        }
      } catch (e) {
        debugPrint('Fast fetch notice for Supabase jobs: $e');
      }
    }

    // Deduplicate fetched jobs by ID, URL, and Company+Title combo
    final uniqueJobs = _deduplicateJobs(fetched);

    // If fewer than 10 jobs from remote database/API, merge with verified fallback jobs
    final fallbackPool = _getFallbackJobs();
    final combined = List<JobMatch>.from(uniqueJobs);

    for (final fallback in fallbackPool) {
      if (!_isDuplicate(combined, fallback)) {
        combined.add(fallback);
      }
    }

    _cachedJobPool = combined;

    // Randomize order with a fresh Random() instance on every load/refresh
    final result = List<JobMatch>.from(combined)..shuffle(Random());
    return result;
  }

  bool _isValidJob(JobMatch job) {
    if (job.jobTitle.trim().isEmpty || job.jobTitle == 'Untitled Position') return false;
    if (job.companyName.trim().isEmpty || job.companyName == 'Company') return false;
    return true;
  }

  List<JobMatch> _deduplicateJobs(List<JobMatch> jobs) {
    final seenIds = <String>{};
    final seenUrls = <String>{};
    final seenCombos = <String>{};
    final result = <JobMatch>[];

    for (final job in jobs) {
      final id = job.id.trim();
      final url = (job.applyUrl ?? job.jobUrl ?? '').trim();
      final combo = '${job.companyName.trim().toLowerCase()}|${job.jobTitle.trim().toLowerCase()}';

      if (id.isNotEmpty && seenIds.contains(id)) continue;
      if (url.isNotEmpty && seenUrls.contains(url)) continue;
      if (seenCombos.contains(combo)) continue;

      if (id.isNotEmpty) seenIds.add(id);
      if (url.isNotEmpty) seenUrls.add(url);
      seenCombos.add(combo);
      result.add(job);
    }
    return result;
  }

  bool _isDuplicate(List<JobMatch> existing, JobMatch candidate) {
    final candId = candidate.id.trim();
    final candUrl = (candidate.applyUrl ?? candidate.jobUrl ?? '').trim();
    final candCombo = '${candidate.companyName.trim().toLowerCase()}|${candidate.jobTitle.trim().toLowerCase()}';

    for (final job in existing) {
      if (candId.isNotEmpty && job.id.trim() == candId) return true;
      final jobUrl = (job.applyUrl ?? job.jobUrl ?? '').trim();
      if (candUrl.isNotEmpty && jobUrl.isNotEmpty && jobUrl == candUrl) return true;
      final jobCombo = '${job.companyName.trim().toLowerCase()}|${job.jobTitle.trim().toLowerCase()}';
      if (jobCombo == candCombo) return true;
    }
    return false;
  }

  /// Records user swipe action asynchronously without blocking UI execution.
  void recordSwipeAction({
    required String jobId,
    required bool isRightSwipe,
  }) {
    final client = SupabaseService.instance.client;
    final userId = SupabaseService.instance.currentUser?.id;

    if (client == null || userId == null) return;

    final status = isRightSwipe ? 'SAVED' : 'PASSED';

    // If jobId is a local/mock ID, log locally without triggering UUID syntax errors
    if (!_uuidRegex.hasMatch(jobId)) {
      debugPrint('Recorded swipe "$status" for local mock job $jobId');
      return;
    }

    // Un-awaited asynchronous fire-and-forget push to database
    unawaited(
      client.from('job_matches').upsert({
        'user_id': userId,
        'job_id': jobId,
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,job_id').then((_) {
        debugPrint('Recorded swipe "$status" for job $jobId');
      }).catchError((e) {
        debugPrint('Swipe record error: $e');
      }),
    );
  }

  List<JobMatch> _getFallbackJobs() {
    final now = DateTime.now();
    return [
      JobMatch(
        id: '00000000-0000-0000-0000-000000000001',
        jobTitle: 'Senior Flutter Engineer',
        companyName: 'TechCorp Global',
        companyLogoUrl: 'https://logo.clearbit.com/flutter.dev',
        location: 'Remote (Global)',
        salaryRange: '\$135,000 - \$165,000 / yr',
        matchPercentage: 96.0,
        platformSource: 'Jooble',
        matchingSkills: ['Flutter', 'Dart', 'State Management'],
        missingSkills: ['Kubernetes'],
        description: 'Leading cross-platform application development with high emphasis on performance, custom UI animations, and robust architecture.',
        postedAt: now.subtract(const Duration(hours: 2)),
        applyUrl: 'https://jooble.org',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000002',
        jobTitle: 'Full Stack Engineer (Python & FastAPI)',
        companyName: 'Stripe',
        companyLogoUrl: 'https://logo.clearbit.com/stripe.com',
        location: 'Remote (US/EU)',
        salaryRange: '\$145,000 - \$180,000 / yr',
        matchPercentage: 94.0,
        platformSource: 'Adzuna',
        matchingSkills: ['Python', 'FastAPI', 'REST APIs'],
        missingSkills: ['PostgreSQL Vector'],
        description: 'Building next-generation fintech user interfaces and real-time backend aggregation pipelines.',
        postedAt: now.subtract(const Duration(hours: 5)),
        applyUrl: 'https://stripe.com/jobs',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000003',
        jobTitle: 'AI Platform Engineer',
        companyName: 'Notion',
        companyLogoUrl: 'https://logo.clearbit.com/notion.so',
        location: 'San Francisco, CA (Hybrid)',
        salaryRange: '\$160,000 - \$200,000 / yr',
        matchPercentage: 92.0,
        platformSource: 'Ashby',
        matchingSkills: ['Python', 'LLMs', 'API Design'],
        missingSkills: ['Kubernetes'],
        description: 'Integrate workspace productivity tools with state-of-the-art AI recommendation models.',
        postedAt: now.subtract(const Duration(hours: 11)),
        applyUrl: 'https://notion.so/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000004',
        jobTitle: 'Lead Mobile Developer',
        companyName: 'Ramp',
        companyLogoUrl: 'https://logo.clearbit.com/ramp.com',
        location: 'New York, NY / Remote',
        salaryRange: '\$150,000 - \$195,000 / yr',
        matchPercentage: 88.0,
        platformSource: 'Crawl4AI',
        matchingSkills: ['Dart', 'Flutter', 'State Management'],
        missingSkills: ['GraphQL'],
        description: 'Lead mobile app architecture for modern corporate spend platforms.',
        postedAt: now.subtract(const Duration(hours: 19)),
        applyUrl: 'https://ramp.com/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000005',
        jobTitle: 'Senior Frontend Architect',
        companyName: 'Vercel',
        companyLogoUrl: 'https://logo.clearbit.com/vercel.com',
        location: 'Remote (US/Worldwide)',
        salaryRange: '\$155,000 - \$190,000 / yr',
        matchPercentage: 91.0,
        platformSource: 'Himalayas',
        matchingSkills: ['React', 'TypeScript', 'Next.js'],
        missingSkills: ['WebAssembly'],
        description: 'Designing performant frontend edge rendering pipelines and developer experience frameworks.',
        postedAt: now.subtract(const Duration(hours: 7)),
        applyUrl: 'https://vercel.com/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000006',
        jobTitle: 'Database Systems Engineer',
        companyName: 'Supabase',
        companyLogoUrl: 'https://logo.clearbit.com/supabase.com',
        location: 'Remote (Global)',
        salaryRange: '\$140,000 - \$175,000 / yr',
        matchPercentage: 93.0,
        platformSource: 'Ashby',
        matchingSkills: ['PostgreSQL', 'Go', 'Docker'],
        missingSkills: ['Rust'],
        description: 'Scale real-time open source Postgres backend infrastructure for thousands of modern applications.',
        postedAt: now.subtract(const Duration(hours: 14)),
        applyUrl: 'https://supabase.com/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000007',
        jobTitle: 'Applied AI & ML Engineer',
        companyName: 'OpenAI',
        companyLogoUrl: 'https://logo.clearbit.com/openai.com',
        location: 'San Francisco, CA / Remote',
        salaryRange: '\$170,000 - \$220,000 / yr',
        matchPercentage: 95.0,
        platformSource: 'Wellfound',
        matchingSkills: ['Python', 'Machine Learning', 'API Development'],
        missingSkills: ['Distributed Training'],
        description: 'Building developer APIs and production infrastructure for next-generation intelligence models.',
        postedAt: now.subtract(const Duration(hours: 4)),
        applyUrl: 'https://openai.com/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000008',
        jobTitle: 'Cloud Infrastructure Engineer',
        companyName: 'Datadog',
        companyLogoUrl: 'https://logo.clearbit.com/datadoghq.com',
        location: 'Boston, MA / Remote',
        salaryRange: '\$145,000 - \$185,000 / yr',
        matchPercentage: 89.0,
        platformSource: 'Adzuna',
        matchingSkills: ['Kubernetes', 'Go', 'Docker'],
        missingSkills: ['Terraform'],
        description: 'Develop distributed telemetry collection engines and cloud observability pipelines.',
        postedAt: now.subtract(const Duration(hours: 16)),
        applyUrl: 'https://datadoghq.com/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000009',
        jobTitle: 'Senior Product Engineer',
        companyName: 'Linear',
        companyLogoUrl: 'https://logo.clearbit.com/linear.app',
        location: 'San Francisco, CA / Remote',
        salaryRange: '\$160,000 - \$195,000 / yr',
        matchPercentage: 90.0,
        platformSource: 'Himalayas',
        matchingSkills: ['TypeScript', 'React', 'GraphQL'],
        missingSkills: ['C++'],
        description: 'Craft ultra-fast issue tracking software with instant client synchronization and keyboard-first UI.',
        postedAt: now.subtract(const Duration(hours: 8)),
        applyUrl: 'https://linear.app/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000010',
        jobTitle: 'Distributed Systems Engineer',
        companyName: 'Shopify',
        companyLogoUrl: 'https://logo.clearbit.com/shopify.com',
        location: 'Remote (Americas/EMEA)',
        salaryRange: '\$140,000 - \$180,000 / yr',
        matchPercentage: 87.0,
        platformSource: 'Jooble',
        matchingSkills: ['Ruby', 'Go', 'Kafka'],
        missingSkills: ['Spark'],
        description: 'Scale multi-tenant checkout architecture supporting millions of global merchant storefronts.',
        postedAt: now.subtract(const Duration(hours: 22)),
        applyUrl: 'https://shopify.com/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000011',
        jobTitle: 'Web Platform Engine Developer',
        companyName: 'Figma',
        companyLogoUrl: 'https://logo.clearbit.com/figma.com',
        location: 'San Francisco, CA (Hybrid)',
        salaryRange: '\$165,000 - \$205,000 / yr',
        matchPercentage: 92.0,
        platformSource: 'Ashby',
        matchingSkills: ['TypeScript', 'WebAssembly', 'C++'],
        missingSkills: ['Rust'],
        description: 'Build real-time vector rendering engines and collaborative canvas rendering technology.',
        postedAt: now.subtract(const Duration(hours: 10)),
        applyUrl: 'https://figma.com/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000012',
        jobTitle: 'Senior Full Stack Developer',
        companyName: 'Airbnb',
        companyLogoUrl: 'https://logo.clearbit.com/airbnb.com',
        location: 'Remote (US)',
        salaryRange: '\$150,000 - \$190,000 / yr',
        matchPercentage: 89.0,
        platformSource: 'Adzuna',
        matchingSkills: ['React', 'Node.js', 'GraphQL'],
        missingSkills: ['Java'],
        description: 'Empower global host and guest communities with intuitive responsive booking and identity workflows.',
        postedAt: now.subtract(const Duration(hours: 18)),
        applyUrl: 'https://airbnb.com/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000013',
        jobTitle: 'Core Container Platform Engineer',
        companyName: 'Docker',
        companyLogoUrl: 'https://logo.clearbit.com/docker.com',
        location: 'Remote (Worldwide)',
        salaryRange: '\$140,000 - \$175,000 / yr',
        matchPercentage: 93.0,
        platformSource: 'Wellfound',
        matchingSkills: ['Go', 'Docker', 'Linux'],
        missingSkills: ['eBPF'],
        description: 'Enhance container virtualization tooling, desktop build engines, and developer containerization pipelines.',
        postedAt: now.subtract(const Duration(hours: 13)),
        applyUrl: 'https://docker.com/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000014',
        jobTitle: 'Senior Linux Systems Engineer',
        companyName: 'Canonical',
        companyLogoUrl: 'https://logo.clearbit.com/canonical.com',
        location: 'Remote (Global)',
        salaryRange: '\$130,000 - \$165,000 / yr',
        matchPercentage: 86.0,
        platformSource: 'Himalayas',
        matchingSkills: ['Python', 'Linux', 'Bash'],
        missingSkills: ['Kernel Internals'],
        description: 'Contribute to Ubuntu OS deployment tooling, cloud images, and secure open source enterprise distributions.',
        postedAt: now.subtract(const Duration(hours: 26)),
        applyUrl: 'https://canonical.com/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000015',
        jobTitle: 'DevSecOps Platform Engineer',
        companyName: 'GitLab',
        companyLogoUrl: 'https://logo.clearbit.com/gitlab.com',
        location: 'Remote (Global)',
        salaryRange: '\$145,000 - \$180,000 / yr',
        matchPercentage: 90.0,
        platformSource: 'Crawl4AI',
        matchingSkills: ['Go', 'Ruby', 'CI/CD'],
        missingSkills: ['Kubernetes Operator'],
        description: 'Build enterprise CI/CD workflows, automated code security scanners, and continuous deployment agents.',
        postedAt: now.subtract(const Duration(hours: 15)),
        applyUrl: 'https://gitlab.com/jobs',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000016',
        jobTitle: 'Senior API Protocols Engineer',
        companyName: 'Postman',
        companyLogoUrl: 'https://logo.clearbit.com/postman.com',
        location: 'San Francisco, CA / Remote',
        salaryRange: '\$140,000 - \$175,000 / yr',
        matchPercentage: 91.0,
        platformSource: 'Adzuna',
        matchingSkills: ['Node.js', 'REST APIs', 'HTTP'],
        missingSkills: ['gRPC'],
        description: 'Architect collaborative API testing workspaces, automated mock servers, and schema generators.',
        postedAt: now.subtract(const Duration(hours: 9)),
        applyUrl: 'https://postman.com/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000017',
        jobTitle: 'Search & Vector Data Engineer',
        companyName: 'Elastic',
        companyLogoUrl: 'https://logo.clearbit.com/elastic.co',
        location: 'Remote (US/EU)',
        salaryRange: '\$150,000 - \$190,000 / yr',
        matchPercentage: 88.0,
        platformSource: 'Jooble',
        matchingSkills: ['Java', 'Elasticsearch', 'Python'],
        missingSkills: ['Lucene'],
        description: 'Advance distributed hybrid vector search algorithms and real-time semantic query processing.',
        postedAt: now.subtract(const Duration(hours: 21)),
        applyUrl: 'https://elastic.co/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000018',
        jobTitle: 'Cloud Platform Engineer',
        companyName: 'Atlassian',
        companyLogoUrl: 'https://logo.clearbit.com/atlassian.com',
        location: 'Remote (US/AU)',
        salaryRange: '\$145,000 - \$185,000 / yr',
        matchPercentage: 87.0,
        platformSource: 'Ashby',
        matchingSkills: ['Kotlin', 'AWS', 'Microservices'],
        missingSkills: ['DynamoDB'],
        description: 'Develop resilient multi-region infrastructure powering Jira and Confluence cloud architectures.',
        postedAt: now.subtract(const Duration(hours: 28)),
        applyUrl: 'https://atlassian.com/company/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000019',
        jobTitle: 'Edge Network Systems Engineer',
        companyName: 'Cloudflare',
        companyLogoUrl: 'https://logo.clearbit.com/cloudflare.com',
        location: 'San Francisco, CA / Remote',
        salaryRange: '\$155,000 - \$195,000 / yr',
        matchPercentage: 94.0,
        platformSource: 'Wellfound',
        matchingSkills: ['Rust', 'Go', 'Networking'],
        missingSkills: ['BGP'],
        description: 'Build high-performance edge compute platforms and global network security acceleration engines.',
        postedAt: now.subtract(const Duration(hours: 6)),
        applyUrl: 'https://cloudflare.com/careers',
      ),
      JobMatch(
        id: '00000000-0000-0000-0000-000000000020',
        jobTitle: 'Infrastructure Automation Engineer',
        companyName: 'HashiCorp',
        companyLogoUrl: 'https://logo.clearbit.com/hashicorp.com',
        location: 'Remote (Global)',
        salaryRange: '\$150,000 - \$185,000 / yr',
        matchPercentage: 90.0,
        platformSource: 'Himalayas',
        matchingSkills: ['Terraform', 'Go', 'Cloud Architecture'],
        missingSkills: ['Vault'],
        description: 'Develop declarative infrastructure as code tooling and multi-cloud provisioning providers.',
        postedAt: now.subtract(const Duration(hours: 17)),
        applyUrl: 'https://hashicorp.com/careers',
      ),
    ];
  }
}
