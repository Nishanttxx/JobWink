import http.client

host = 'jooble.org'
key = 'REDACTED_JOOBLE_KEY'

connection = http.client.HTTPConnection(host)
#request headers
headers = {"Content-type": "application/json"}
#json query
body = '{ "keywords": "it", "location": "Bern"}'
connection.request('POST','/api/' + key, body, headers)
response = connection.getresponse()
print(response.status, response.reason)
print(response.read())

adzuna api key:
REDACTED_ADZUNA_APP_KEY
application id:REDACTED_ADZUNA_APP_ID

ashby : https://api.ashbyhq.com/jobBoard.list

agentic engineering jobs:
curl "https://agentic-engineering-jobs.com/api/v1/jobs?sort=newest"
curl "https://agentic-engineering-jobs.com/api/v1/jobs/acme-senior-ai-engineer-abc123"
curl "https://agentic-engineering-jobs.com/api/v1/salaries?dimension=overview"


ai dev jobs:
{
"access": {
"catalog_url": "https://aidevboard.com/api/v1/catalog",
"description": "Public read endpoints are open and free. API keys are optional for stable agent identity and keyed hourly throttling.",
"docs_url": "https://aidevboard.com/docs",
"employer_pilot_url": "https://aidevboard.com/verified-interview-pilot",
"mode": "open",
"register_url": "https://aidevboard.com/api/v1/register"
},
"candidate_resume_action": {
"application_authorized": false,
"candidate_charge": 0,
"endpoint": "https://aidevboard.com/api/v1/candidate/resume-preview",
"job_id_json_path": "jobs[].id",
"method": "POST",
"preview_requires_identity": false,
"required_body_fields": [
"job_id",
"evidence_bullets"
],
"requires_explicit_human_review": true,
"saved_artifact_protocol": "mcp",
"saved_artifact_requires_verified_human": true,
"saved_artifact_tool": "compile_job_specific_resume",
"search_requires_identity": false,
"status": "available_after_candidate_selects_job",
"submission_performed": false,
"uses_candidate_verified_evidence": true
},
"degraded": false,
"estimated": false,
"has_next": true,
"jobs": [
{
"id": "de2fe643-57d2-481c-ae63-e9cde0fbbe4f",
"company_id": "d3f1a010-47af-48d2-8b4e-a5953078daac",
"title": "Senior Software Engineer, Production Engineering",
"slug": "senior-software-engineer-production-engineering-571d6200",
"description": "WHY HARVEY\n\nAt Harvey, we’re transforming how legal and professional services operate. By combining frontier agentic AI, an enterprise-grade platform, and deep domain expertise, we’re reshaping how critical knowledge work gets done for decades to come.\n\nThis is a rare chance to help build a generational company at a true inflection point. We have strong product-market fit and world-class investor support. We’re scaling fast and defining a new category in real time. The work is ambitious, the bar is high, and the opportunity for growth — personal, professional, and financial — is unmatched.\n\nOur team moves fast, takes ownership, and is deeply committed to the mission — operating with intensity, staying close to our customers, and pushing each other for excellence. We live by three values: Decisiveness, Simplicity, and Job's Not Finished. We act quickly on clear judgment over perfect information, we believe simplicity is what scales, and we're never satisfied with where we are. If you want to do the best work of your career alongside people who share that drive, we'd love to build with you.\n\nAt Harvey, the future of professional services is being written today — and we’re just getting started.\n\n\n\n\nROLE OVERVIEW\n\nHarvey is building the AI platform trusted by the world’s leading law firms and enterprises. Our infrastructure is the foundation that powers every customer interaction, every model inference, and every production workload.\n\nWe’re looking for a Production Engineer to help build and operate Harvey’s core compute and networking infrastructure, Kubernetes platform, workflow orchestration platform, and production infrastructure foundations. You’ll work on the systems that enable engineering teams to move quickly and operate reliable services at scale.\n\nIn this role, you’ll improve the reliability, scalability, security, and efficiency of Harvey’s infrastructure platform. You’ll solve complex production challenges across compute fleet management, capacity planning, infrastructure automation, and production operations. You’ll partner closely with Product Engineering, Security, AI Infrastructure, and Platform teams to ensure our infrastructure scales with Harvey’s rapid growth.\n\nAt Harvey, we value Decisiveness, Simplicity, and the belief that Job’s Not Finished. We move quickly, prioritize clarity, and continuously raise the bar for engineering excellence.\n\n\n\n\nWHAT YOU'LL DO\n\n\nINFRASTRUCTURE ENGINEERING & TECHNICAL LEADERSHIP\n\n - Design, build, and operate the production infrastructure that powers Harvey’s products and AI workloads.\n\n - Drive technical direction across compute infrastructure, networking, Kubernetes, workflow orchestration, and production operations.\n\n - Lead complex, cross-functional technical initiatives that improve reliability, scalability, security, operational efficiency, and infrastructure cost.\n\n - Partner with Product Engineering, Security, AI Infrastructure, and Platform teams to translate product and business requirements into resilient infrastructure solutions.\n\n - Establish reusable patterns, tooling, and paved paths that help engineering teams ship and operate production services safely.\n\n - Raise the engineering bar through thoughtful design reviews, clear technical documentation, operational rigor, and mentorship.\n\n\nINFRASTRUCTURE FOUNDATION & PRODUCTION OPERATIONS\n\n - Build and operate Harvey’s global compute and network infrastructure, ensuring high availability, scalability, reliability, and performance.\n\n - Improve compute utilization, performance, and service availability while supporting rapidly growing AI workloads.\n\n - Develop capacity models, demand forecasts, and fleet lifecycle automation to help infrastructure scale efficiently with business growth.\n\n - Operate and continuously improve Harvey’s Kubernetes platform, including cluster provisioning, upgrades, networking, monitoring, reliability, performance, and operational automation.\n\n - Drive infrastructure cost efficiency through capacity management, resource rightsizing, workload optimization, and utilization monitoring.\n\n - Build secure infrastructure foundations, including identity and access management, network isolation, secrets management, auditing, and compliance controls.\n\n - Develop scalable Infrastructure-as-Code and automation frameworks using technologies such as Terraform and Pulumi.\n\n - Improve observability, monitoring, alerting, incident response, and operational readiness across the infrastructure platform.\n\n - Participate in the on-call rotation, lead incident response when needed, and turn production learnings into durable engineering improvements.\n\n\n\n\nWHAT YOU HAVE\n\n - 5+ years of software, infrastructure, site reliability, or production engineering experience.\n\n - Deep experience building and operating large-scale cloud infrastructure on AWS, Azure, or Google Cloud Platform.\n\n - Strong hands-on experience operating Kubernetes in production, including ",
"salary_min": 161300,
"salary_max": 241900,
"location": "New York, NY",
"workplace": "onsite",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "senior",
"tags": [
"cloud",
"llm",
"distributed-systems",
"agents"
],
"apply_url": "https://jobs.ashbyhq.com/harvey/dbd9a156-a841-42a0-a3e5-beed8de60a7c/application",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-30T23:37:30.751Z",
"expires_at": "2026-08-30T14:02:51.494115Z",
"created_at": "2026-07-31T14:02:51.633596Z",
"updated_at": "2026-07-31T14:02:51.633596Z",
"company_name": "Harvey AI",
"company_slug": "harvey-ai",
"company_logo_url": "https://www.google.com/s2/favicons?domain=harvey.ai&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/de2fe643-57d2-481c-ae63-e9cde0fbbe4f"
},
{
"id": "7cdce99e-031e-43cb-9967-7cec462f2c5b",
"company_id": "d3f1a010-47af-48d2-8b4e-a5953078daac",
"title": "Staff Software Engineer, Production Engineering",
"slug": "staff-software-engineer-production-engineering-491a96a6",
"description": "WHY HARVEY\n\nAt Harvey, we’re transforming how legal and professional services operate. By combining frontier agentic AI, an enterprise-grade platform, and deep domain expertise, we’re reshaping how critical knowledge work gets done for decades to come.\n\nThis is a rare chance to help build a generational company at a true inflection point. We have strong product-market fit and world-class investor support. We’re scaling fast and defining a new category in real time. The work is ambitious, the bar is high, and the opportunity for growth — personal, professional, and financial — is unmatched.\n\nOur team moves fast, takes ownership, and is deeply committed to the mission — operating with intensity, staying close to our customers, and pushing each other for excellence. We live by three values: Decisiveness, Simplicity, and Job's Not Finished. We act quickly on clear judgment over perfect information, we believe simplicity is what scales, and we're never satisfied with where we are. If you want to do the best work of your career alongside people who share that drive, we'd love to build with you.\n\nAt Harvey, the future of professional services is being written today — and we’re just getting started.\n\n\n\n\nROLE OVERVIEW\n\nHarvey is building the AI platform trusted by the world’s leading law firms and enterprises. Our infrastructure is the foundation that powers every customer interaction, every model inference, and every production workload.\n\nWe’re looking for a Production Engineer to help build and operate Harvey’s core compute and networking infrastructure, Kubernetes platform, workflow orchestration platform, and production infrastructure foundations. You’ll work on the systems that enable engineering teams to move quickly and operate reliable services at scale.\n\nIn this role, you’ll improve the reliability, scalability, security, and efficiency of Harvey’s infrastructure platform. You’ll solve complex production challenges across compute fleet management, capacity planning, infrastructure automation, and production operations. You’ll partner closely with Product Engineering, Security, AI Infrastructure, and Platform teams to ensure our infrastructure scales with Harvey’s rapid growth.\n\nAt Harvey, we value Decisiveness, Simplicity, and the belief that Job’s Not Finished. We move quickly, prioritize clarity, and continuously raise the bar for engineering excellence.\n\n\n\n\nWHAT YOU'LL DO\n\n\nINFRASTRUCTURE ENGINEERING & TECHNICAL LEADERSHIP\n\n - Design, build, and operate the production infrastructure that powers Harvey’s products and AI workloads.\n\n - Drive technical direction across compute infrastructure, networking, Kubernetes, workflow orchestration, and production operations.\n\n - Lead complex, cross-functional technical initiatives that improve reliability, scalability, security, operational efficiency, and infrastructure cost.\n\n - Partner with Product Engineering, Security, AI Infrastructure, and Platform teams to translate product and business requirements into resilient infrastructure solutions.\n\n - Establish reusable patterns, tooling, and paved paths that help engineering teams ship and operate production services safely.\n\n - Raise the engineering bar through thoughtful design reviews, clear technical documentation, operational rigor, and mentorship.\n\n\nINFRASTRUCTURE FOUNDATION & PRODUCTION OPERATIONS\n\n - Build and operate Harvey’s global compute and network infrastructure, ensuring high availability, scalability, reliability, and performance.\n\n - Improve compute utilization, performance, and service availability while supporting rapidly growing AI workloads.\n\n - Develop capacity models, demand forecasts, and fleet lifecycle automation to help infrastructure scale efficiently with business growth.\n\n - Operate and continuously improve Harvey’s Kubernetes platform, including cluster provisioning, upgrades, networking, monitoring, reliability, performance, and operational automation.\n\n - Drive infrastructure cost efficiency through capacity management, resource rightsizing, workload optimization, and utilization monitoring.\n\n - Build secure infrastructure foundations, including identity and access management, network isolation, secrets management, auditing, and compliance controls.\n\n - Develop scalable Infrastructure-as-Code and automation frameworks using technologies such as Terraform and Pulumi.\n\n - Improve observability, monitoring, alerting, incident response, and operational readiness across the infrastructure platform.\n\n - Participate in the on-call rotation, lead incident response when needed, and turn production learnings into durable engineering improvements.\n\n\n\n\nWHAT YOU HAVE\n\n - 10+ years of software, infrastructure, site reliability, or production engineering experience.\n\n - Deep experience building and operating large-scale cloud infrastructure on AWS, Azure, or Google Cloud Platform.\n\n - Strong hands-on experience operating Kubernetes in production, including",
"salary_min": 231000,
"salary_max": 340000,
"location": "New York, NY",
"workplace": "hybrid",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "lead",
"tags": [
"agents",
"cloud",
"llm",
"distributed-systems"
],
"apply_url": "https://jobs.ashbyhq.com/harvey/11571c63-2fc5-41ce-b855-c949ead5efca/application",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-30T23:37:06.693Z",
"expires_at": "2026-08-30T14:02:51.578555Z",
"created_at": "2026-07-31T14:02:51.787171Z",
"updated_at": "2026-07-31T14:02:51.787171Z",
"company_name": "Harvey AI",
"company_slug": "harvey-ai",
"company_logo_url": "https://www.google.com/s2/favicons?domain=harvey.ai&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/7cdce99e-031e-43cb-9967-7cec462f2c5b"
},
{
"id": "c34cb4dc-e213-4e56-8a8c-21698bf37856",
"company_id": "d3f1a010-47af-48d2-8b4e-a5953078daac",
"title": "Staff Software Engineer, Production Engineering",
"slug": "staff-software-engineer-production-engineering-3d8da43c",
"description": "WHY HARVEY\n\nAt Harvey, we’re transforming how legal and professional services operate. By combining frontier agentic AI, an enterprise-grade platform, and deep domain expertise, we’re reshaping how critical knowledge work gets done for decades to come.\n\nThis is a rare chance to help build a generational company at a true inflection point. We have strong product-market fit and world-class investor support. We’re scaling fast and defining a new category in real time. The work is ambitious, the bar is high, and the opportunity for growth — personal, professional, and financial — is unmatched.\n\nOur team moves fast, takes ownership, and is deeply committed to the mission — operating with intensity, staying close to our customers, and pushing each other for excellence. We live by three values: Decisiveness, Simplicity, and Job's Not Finished. We act quickly on clear judgment over perfect information, we believe simplicity is what scales, and we're never satisfied with where we are. If you want to do the best work of your career alongside people who share that drive, we'd love to build with you.\n\nAt Harvey, the future of professional services is being written today — and we’re just getting started.\n\n\n\n\nROLE OVERVIEW\n\nHarvey is building the AI platform trusted by the world’s leading law firms and enterprises. Our infrastructure is the foundation that powers every customer interaction, every model inference, and every production workload.\n\nWe’re looking for a Production Engineer to help build and operate Harvey’s core compute and networking infrastructure, Kubernetes platform, workflow orchestration platform, and production infrastructure foundations. You’ll work on the systems that enable engineering teams to move quickly and operate reliable services at scale.\n\nIn this role, you’ll improve the reliability, scalability, security, and efficiency of Harvey’s infrastructure platform. You’ll solve complex production challenges across compute fleet management, capacity planning, infrastructure automation, and production operations. You’ll partner closely with Product Engineering, Security, AI Infrastructure, and Platform teams to ensure our infrastructure scales with Harvey’s rapid growth.\n\nAt Harvey, we value Decisiveness, Simplicity, and the belief that Job’s Not Finished. We move quickly, prioritize clarity, and continuously raise the bar for engineering excellence.\n\n\n\n\nWHAT YOU'LL DO\n\n\nINFRASTRUCTURE ENGINEERING & TECHNICAL LEADERSHIP\n\n - Design, build, and operate the production infrastructure that powers Harvey’s products and AI workloads.\n\n - Drive technical direction across compute infrastructure, networking, Kubernetes, workflow orchestration, and production operations.\n\n - Lead complex, cross-functional technical initiatives that improve reliability, scalability, security, operational efficiency, and infrastructure cost.\n\n - Partner with Product Engineering, Security, AI Infrastructure, and Platform teams to translate product and business requirements into resilient infrastructure solutions.\n\n - Establish reusable patterns, tooling, and paved paths that help engineering teams ship and operate production services safely.\n\n - Raise the engineering bar through thoughtful design reviews, clear technical documentation, operational rigor, and mentorship.\n\n\nINFRASTRUCTURE FOUNDATION & PRODUCTION OPERATIONS\n\n - Build and operate Harvey’s global compute and network infrastructure, ensuring high availability, scalability, reliability, and performance.\n\n - Improve compute utilization, performance, and service availability while supporting rapidly growing AI workloads.\n\n - Develop capacity models, demand forecasts, and fleet lifecycle automation to help infrastructure scale efficiently with business growth.\n\n - Operate and continuously improve Harvey’s Kubernetes platform, including cluster provisioning, upgrades, networking, monitoring, reliability, performance, and operational automation.\n\n - Drive infrastructure cost efficiency through capacity management, resource rightsizing, workload optimization, and utilization monitoring.\n\n - Build secure infrastructure foundations, including identity and access management, network isolation, secrets management, auditing, and compliance controls.\n\n - Develop scalable Infrastructure-as-Code and automation frameworks using technologies such as Terraform and Pulumi.\n\n - Improve observability, monitoring, alerting, incident response, and operational readiness across the infrastructure platform.\n\n - Participate in the on-call rotation, lead incident response when needed, and turn production learnings into durable engineering improvements.\n\n\n\n\nWHAT YOU HAVE\n\n - 10+ years of software, infrastructure, site reliability, or production engineering experience.\n\n - Deep experience building and operating large-scale cloud infrastructure on AWS, Azure, or Google Cloud Platform.\n\n - Strong hands-on experience operating Kubernetes in production, including",
"salary_min": 231000,
"salary_max": 340000,
"location": "San Francisco, CA",
"workplace": "hybrid",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "lead",
"tags": [
"agents",
"distributed-systems",
"llm",
"cloud"
],
"apply_url": "https://jobs.ashbyhq.com/harvey/dad3437f-9f4c-444a-bf4a-ae2a9a1047c2/application",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-30T23:36:49.147Z",
"expires_at": "2026-08-30T14:02:51.732912Z",
"created_at": "2026-07-31T14:02:51.873377Z",
"updated_at": "2026-07-31T14:02:51.873377Z",
"company_name": "Harvey AI",
"company_slug": "harvey-ai",
"company_logo_url": "https://www.google.com/s2/favicons?domain=harvey.ai&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/c34cb4dc-e213-4e56-8a8c-21698bf37856"
},
{
"id": "f6b450cf-09f3-4a6a-8009-3581532effd1",
"company_id": "d3f1a010-47af-48d2-8b4e-a5953078daac",
"title": "Senior Software Engineer, Production Engineering",
"slug": "senior-software-engineer-production-engineering-c605fa70",
"description": "WHY HARVEY\n\nAt Harvey, we’re transforming how legal and professional services operate. By combining frontier agentic AI, an enterprise-grade platform, and deep domain expertise, we’re reshaping how critical knowledge work gets done for decades to come.\n\nThis is a rare chance to help build a generational company at a true inflection point. We have strong product-market fit and world-class investor support. We’re scaling fast and defining a new category in real time. The work is ambitious, the bar is high, and the opportunity for growth — personal, professional, and financial — is unmatched.\n\nOur team moves fast, takes ownership, and is deeply committed to the mission — operating with intensity, staying close to our customers, and pushing each other for excellence. We live by three values: Decisiveness, Simplicity, and Job's Not Finished. We act quickly on clear judgment over perfect information, we believe simplicity is what scales, and we're never satisfied with where we are. If you want to do the best work of your career alongside people who share that drive, we'd love to build with you.\n\nAt Harvey, the future of professional services is being written today — and we’re just getting started.\n\n\n\n\nROLE OVERVIEW\n\nHarvey is building the AI platform trusted by the world’s leading law firms and enterprises. Our infrastructure is the foundation that powers every customer interaction, every model inference, and every production workload.\n\nWe’re looking for a Production Engineer to help build and operate Harvey’s core compute and networking infrastructure, Kubernetes platform, workflow orchestration platform, and production infrastructure foundations. You’ll work on the systems that enable engineering teams to move quickly and operate reliable services at scale.\n\nIn this role, you’ll improve the reliability, scalability, security, and efficiency of Harvey’s infrastructure platform. You’ll solve complex production challenges across compute fleet management, capacity planning, infrastructure automation, and production operations. You’ll partner closely with Product Engineering, Security, AI Infrastructure, and Platform teams to ensure our infrastructure scales with Harvey’s rapid growth.\n\nAt Harvey, we value Decisiveness, Simplicity, and the belief that Job’s Not Finished. We move quickly, prioritize clarity, and continuously raise the bar for engineering excellence.\n\n\n\n\nWHAT YOU'LL DO\n\n\nINFRASTRUCTURE ENGINEERING & TECHNICAL LEADERSHIP\n\n - Design, build, and operate the production infrastructure that powers Harvey’s products and AI workloads.\n\n - Drive technical direction across compute infrastructure, networking, Kubernetes, workflow orchestration, and production operations.\n\n - Lead complex, cross-functional technical initiatives that improve reliability, scalability, security, operational efficiency, and infrastructure cost.\n\n - Partner with Product Engineering, Security, AI Infrastructure, and Platform teams to translate product and business requirements into resilient infrastructure solutions.\n\n - Establish reusable patterns, tooling, and paved paths that help engineering teams ship and operate production services safely.\n\n - Raise the engineering bar through thoughtful design reviews, clear technical documentation, operational rigor, and mentorship.\n\n\nINFRASTRUCTURE FOUNDATION & PRODUCTION OPERATIONS\n\n - Build and operate Harvey’s global compute and network infrastructure, ensuring high availability, scalability, reliability, and performance.\n\n - Improve compute utilization, performance, and service availability while supporting rapidly growing AI workloads.\n\n - Develop capacity models, demand forecasts, and fleet lifecycle automation to help infrastructure scale efficiently with business growth.\n\n - Operate and continuously improve Harvey’s Kubernetes platform, including cluster provisioning, upgrades, networking, monitoring, reliability, performance, and operational automation.\n\n - Drive infrastructure cost efficiency through capacity management, resource rightsizing, workload optimization, and utilization monitoring.\n\n - Build secure infrastructure foundations, including identity and access management, network isolation, secrets management, auditing, and compliance controls.\n\n - Develop scalable Infrastructure-as-Code and automation frameworks using technologies such as Terraform and Pulumi.\n\n - Improve observability, monitoring, alerting, incident response, and operational readiness across the infrastructure platform.\n\n - Participate in the on-call rotation, lead incident response when needed, and turn production learnings into durable engineering improvements.\n\n\n\n\nWHAT YOU HAVE\n\n - 5+ years of software, infrastructure, site reliability, or production engineering experience.\n\n - Deep experience building and operating large-scale cloud infrastructure on AWS, Azure, or Google Cloud Platform.\n\n - Strong hands-on experience operating Kubernetes in production, including ",
"salary_min": 161300,
"salary_max": 241900,
"location": "San Francisco, CA",
"workplace": "hybrid",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "senior",
"tags": [
"llm",
"distributed-systems",
"agents",
"cloud"
],
"apply_url": "https://jobs.ashbyhq.com/harvey/6a840e0d-6af8-4ad6-a182-7534ce64e7e2/application",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-30T23:36:32.93Z",
"expires_at": "2026-08-30T14:02:51.372468Z",
"created_at": "2026-07-31T14:02:51.549594Z",
"updated_at": "2026-07-31T14:02:51.549594Z",
"company_name": "Harvey AI",
"company_slug": "harvey-ai",
"company_logo_url": "https://www.google.com/s2/favicons?domain=harvey.ai&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/f6b450cf-09f3-4a6a-8009-3581532effd1"
},
{
"id": "779deee1-0368-49f3-ac2e-15d6f3fab503",
"company_id": "1f4520df-9fc1-4ace-a80b-6c3266f03e8a",
"title": "Governance, Risk and Compliance Lead",
"slug": "governance-risk-and-compliance-lead-c6e10c7d",
"description": "Thinking Machines Lab's mission is to empower humanity through advancing collaborative general intelligence. We're building a future where everyone has access to the knowledge and tools to make AI work for their unique needs and goals. \n We are scientists, engineers, and builders who’ve created some of the most widely used AI products, including ChatGPT and Character.ai, open-weights models like Mistral, as well as popular open source projects like PyTorch, OpenAI Gym, Fairseq, and Segment Anything.\n About the Role \n We're looking for a GRC Lead who personally drives our certifications (SOC 2, ISO 27001, FedRAMP and others as we grow) from scoping through audit close, and runs our compliance processes day to day. You'll collect the evidence, write the control documentation, and sit across from the auditor yourself.\n You'll work closely with security, legal, safety, and engineering to answer compliance and risk questions directly, using your own technical understanding of how our systems work. Day to day, you'll be managing audits, controls, and risk assessments. Alongside that, you'll be building the roadmap for what this function needs to look like in a year.\n What You'll Do \n \n Own our certification roadmap end to end: scope each certification, build the control set, collect and organize evidence, and represent TML directly to auditors through to close.\n Manage recurring compliance processes on a set cadence: control testing, audit prep and response, risk register maintenance, and policy attestations.\n Answer compliance and risk questions from engineering, security, and product teams directly, by building enough technical fluency across our infrastructure, model deployment, and data handling to do so without escalating every question.\n Track regulatory and framework requirements relevant to an AI company (GDPR, EU AI Act, and similar) and translate them into specific, actionable controls.\n Identify gaps in current compliance coverage as the company adds new products, infrastructure, or jurisdictions, and propose what needs to change before it becomes a blocker.\n Build and maintain the tooling and documentation that make the next audit cycle faster than the last one.\n Plan a multi-quarter roadmap for the GRC function itself, while continuing to personally run the certifications and audits already on the books.\n \n Skills and Qualifications \n Minimum qualifications: \n \n 7+ years related experience across technology and cybersecurity Governance, Risk, and Compliance (GRC), with demonstrated breadth across all three disciplines.\n Experience leading a SOC 2, ISO 27001, FedRAMP or comparable certification from scoping through audit close.\n Hands-on experience collecting audit evidence and writing control documentation.\n Experience managing a recurring compliance process, such as control testing, risk register maintenance, or policy attestations.\n Experience learning new technical domains quickly and translating them for non-technical stakeholders.\n \n Preferred qualifications: \n We encourage you to apply even if you don't meet all preferred qualifications. \n \n Background as a software engineer or in a technical engineering role, now applied to GRC, evidenced by scripts, tools, or automations you've personally built for evidence collection, control testing, or audit workflows.\n Experience translating complex compliance requirements into scalable automation using AI agents and custom built tooling.\n Experience growing a GRC function's capability (new certifications, tooling, or processes) as a company scaled.\n \n You'll Thrive in This Role if \n \n You want to run the certification yourself, end to end.\n You're the one in the room with the auditor, walking through evidence.\n You can hold this week's deadlines and next year's roadmap at the same time.\n \n Logistics \n \n Location: This role is based in San Francisco, California.\n Compensation: Depending on background, skills and experience, the expected annual salary range for this position is $225,000 - $350,000.\n Visa sponsorship: We sponsor visas. While we can't guarantee success for every candidate or role, if you're the right fit, we're committed to working through the visa process together.\n Benefits: Thinking Machines offers generous health, dental, and vision benefits, unlimited PTO, paid parental leave, and relocation support as needed.\n As set forth in Thinking Machines' Equal Employment Opportunity policy, we do not discriminate on the basis of any protected group status under any applicable law.\n As set forth in Thinking Machines' Equal Employment Opportunity policy, we do not discriminate on the basis of any protected group status under any applicable law. \n Thinking Machines Lab will consider for employment qualified applicants with criminal histories in a manner consistent with the requirements of the California Fair Chance Act, the San Francisco Fair Chance Ordinance, and any other applicable state or local fair chance ordinance or law.",
"salary_min": 225000,
"salary_max": 350000,
"location": "San Francisco, CA",
"workplace": "onsite",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "lead",
"tags": [
"agents",
"pytorch",
"mlops",
"security"
],
"apply_url": "https://job-boards.greenhouse.io/thinkingmachines/jobs/5375726008",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-30T19:58:17Z",
"expires_at": "2026-08-30T14:18:47.01745Z",
"created_at": "2026-07-31T14:18:47.119503Z",
"updated_at": "2026-07-31T14:18:47.119503Z",
"company_name": "Thinking Machines",
"company_slug": "thinking-machines",
"company_logo_url": "https://www.google.com/s2/favicons?domain=thinkingmachin.es&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/779deee1-0368-49f3-ac2e-15d6f3fab503"
},
{
"id": "7e2ff3bd-ddcd-46de-9de6-f861ceb0ca00",
"company_id": "fa25a1f6-acd0-42b6-a229-f4d258ed5c3d",
"title": "Senior Data Scientist",
"slug": "senior-data-scientist-e96948ff",
"description": "Employee Applicant Privacy Notice \n Who we are: \n \n Shape a brighter financial future with us.\n Together with our members, we’re changing the way people think about and interact with personal finance.\n We’re a next-generation financial services company and national bank using innovative, mobile-first technology to help our millions of members reach their goals. The industry is going through an unprecedented transformation, and we’re at the forefront. We’re proud to come to work every day knowing that what we do has a direct impact on people’s lives, with our core values guiding us every step of the way. Join us to invest in yourself, your career, and the financial world. \n The Role: \n The Risk Data Science team is looking for a Senior Data Scientist to develop advanced machine learning and statistical models, guide measurement, strategy, and data-driven decision making to support various credit risk and operational areas at SoFi. The Data Scientist will work closely with Credit, Risk, Product, Engineering, and Operations teams to design solutions for underwriting, portfolio management, loss mitigation, and loss forecasting etc. These tasks involve researching and applying state of the art modeling methodologies to solve complex business problems. This role is very rewarding as your work will have a direct and immediate impact on the business’ profitability.\n What You’ll Do: \n \n Develop, implement, and continuously improve machine learning and statistical models that support various credit, risk, and operational procedures including but not limited to underwriting, portfolio management, loss mitigation, and loss forecasting, etc.\n Present model performance and insights to Credit, Risk, and Business Unit leaders.\n Proactively identify opportunities to apply advanced modeling approaches to solve complex business problems.\n Explore and leverage in-house and external data sources to enhance model predictive power.\n Collaborate with the Model Risk Management team to demonstrate models are developed with high level rigor that satisfy Model Risk Management and Governance requirements. \n Perform ongoing monitoring of the models through the construction of dashboards and KPI tracking\n Collaborate with the Product and Engineering teams to improve the model development, deployment, monitoring, and model re-calibration/re-build process..\n Explore and apply in-house and open-source machine learning and statistical tools and algorithms to develop and improve models.\n \n What You’ll Need: \n \n Master’s degree in Statistics, Econometrics, Mathematics, Operations Research, Physics, Computer Science, Engineering, or quantitative field required. PhD degree preferred.\n 3+ years of relevant work experience in building and implementing machine learning and statistical models.\n Excellent logic reasoning and communication abilities when interpreting business requirements and translating them into effective data solutions.\n Strong skills in writing efficient SQL queries and Python code to create complex attributes, especially with large datasets.\n Strong sensitivity to details in data and proactively investigate them to uncover unknown patterns.\n Strong knowledge of databases and related languages/tools such as SQL, NoSQL, Hive, etc. \n Demonstrated sophisticated experience in building efficient and reliable pipelines that interact with large datasets stored in SageMaker and Snowflake, automating recurring processes such as data extraction and processing, feature selection, model training, model monitoring, and generating documentation templates to support reproducibility and cross-functional collaboration.\n Excellent knowledge of machine learning and statistical modeling methods for supervised and unsupervised learning. These methods include (but are not limited to) regression, classification, clustering, outlier detection, novelty detection, decision trees, nearest neighbors, support vector machines, ensemble methods and boosting, neural networks, deep learning and its various applications. Continuously following the advancement of machine learning and artificial intelligence to update your knowledge and skills in order to solve business problems with the most efficient methodologies\n Strong programming skills in Python and machine learning libraries (e.g., sklearn, lightgbm, xgboost, pytorch, tensorflow, keras, etc.)\n \n Nice To Have: \n \n Experience in a lending organization.\n Experience with model documentation and delivering effective verbal and written communication.\n Experience in working closely with Product, Engineering, and Model Risk Management teams.\n Experience with AWS or GCP.\n \n Compensation and Benefits \n The base pay range for this role is listed below. Final base pay offer will be determined based on individual factors such as the candidate’s experience, skills, and location. \n  \n This role may also be eligible for a bonus and/or long term incentives. Your recruiter will provide more information",
"salary_min": 128000,
"salary_max": 180000,
"location": "Frisco, TX",
"workplace": "onsite",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "senior",
"tags": [
"cloud",
"deep-learning",
"pytorch",
"tensorflow",
"mlops",
"data-science"
],
"apply_url": "https://sofi.com/careers/job/7819499003?gh_jid=7819499003",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-30T19:28:51Z",
"expires_at": "2026-08-30T14:19:37.336478Z",
"created_at": "2026-07-31T14:19:37.432523Z",
"updated_at": "2026-07-31T14:19:37.432523Z",
"company_name": "SoFi",
"company_slug": "sofi",
"company_logo_url": "https://www.google.com/s2/favicons?domain=sofi.com&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/7e2ff3bd-ddcd-46de-9de6-f861ceb0ca00"
},
{
"id": "729bdc61-a693-49f1-bc55-87988031946c",
"company_id": "3029e985-56bf-4ac2-9ae1-df4cdd53b12f",
"title": "Principal, AI Research Engineering",
"slug": "principal-ai-research-engineering-e33034b4",
"description": "About Zscaler \n Zscaler accelerates digital transformation to ensure our customers can be more agile, efficient, resilient, and secure. As an AI-forward enterprise , we are constantly pushing the envelope, leveraging the world’s largest security data lake to power our cloud-native Zero Trust Exchange platform. This innovation protects our customers from cyberattacks and data loss by securely connecting users, devices, and applications in any location.\n Here, impact in your role matters more than title and trust is built on results. We say, impact over activity. We seek innovators who actively use AI to amplify their impact and who thrive in an environment where we leverage intelligent systems to stay ahead of evolving threats. We believe in transparency and value constructive, honest debate —we’re focused on getting to the best ideas, faster. We build high-performing teams that can make an impact quickly and with high quality. To do this, we are building a culture of execution centered on customer obsession , collaboration, ownership, and accountability.\n We value high-impact, high-accountability with a sense of urgency where you’re enabled to do your best work and embrace your potential. If you’re driven by purpose, thrive on solving complex challenges, and want to be part of the team that’s helping to secure the AI age, we invite you to bring your talents to Zscaler and help shape the future of cybersecurity.\n Role \n We are looking for a Principal, AI Research Engineer to join our AI & Data Protection team. This role is hybrid based in San Jose, CA, and reports to the EVP, AI Security and Strategic Initiatives.\n Zscaler’s mission is to secure the world’s data in the age of AI. As the leader of the world’s largest security cloud, the Zero Trust Exchange, we are uniquely positioned to define how the global enterprise safely adopts, scales, and secures Artificial Intelligence. You will be the primary architect of Zscaler’s AI ecosystem, bridging the gap between our core Zero Trust platform and the rapidly evolving world of LLMs, GPU infrastructure, and AI application frameworks. This role is ideal for a technical leader who deeply understands the \"AI Stack\" and has a proven track record of building thriving developer and partner ecosystems at scale.\n What you’ll do (Role Expectations) \n \n Define the AI Ecosystem Strategy by leading the vision for integrations with frontier model providers, vector database companies, and AI infrastructure leaders\n Lead the \"Secure AI\" roadmap by owning the lifecycle for features that enable safe use of 3rd-party LLMs and prevent data leakage\n Build a developer ecosystem by defining and launching APIs, SDKs, and integration patterns for \"Zero Trust-native\" applications\n Drive market leadership and cross-functional partnerships to turn complex technical integrations into high-growth go-to-market motions\n \n Who You Are (Success Profile) \n \n You thrive in ambiguity. You're comfortable building the path as you walk it. You thrive in a dynamic environment, seeing ambiguity not as a hindrance, but as the raw material to build something meaningful.\n You act like an owner. Your passion for the mission fuels your bias for action. You operate with integrity because you genuinely care about the outcome. True ownership involves leveraging dynamic range: the ability to navigate seamlessly between high-level strategy and hands-on execution.\n You are a problem-solver. You love running towards the challenges because you are laser-focused on finding the solution, knowing that solving the hard problems delivers the biggest impact.\n You are a high-trust collaborator. You are ambitious for the team, not just yourself. You embrace our challenge culture by giving and receiving ongoing feedback—knowing that candor delivered with clarity and respect is the truest form of teamwork and the fastest way to earn trust.\n You are a learner. You have a true growth mindset and are obsessed with your own development, actively seeking feedback to become a better partner and a stronger teammate. You love what you do and you do it with purpose.\n \n What We’re Looking for (Minimum Qualifications) \n \n 8+ years of experience in technical leadership or engineering partnerships with a history of building impactful industry relationships\n Deep technical fluency in the AI lifecycle including training vs. inference, GPU roles, context windows, and RAG architectures\n Ability to apply first-principles thinking to fundamental security and networking challenges in enterprise LLM deployment\n Strong bias for action with a \"Ship Early, Iterate Fast\" mentality and focus on delivering high-value MVPs\n Foundational understanding of AI/ML technologies and experience leveraging, securing, or positioning AI-driven solutions to optimize outcomes within your functional domain   \n \n What Will Make You Stand Out (Preferred Qualifications) \n \n Proven track record of building thriving developer and partner ecosyst",
"salary_min": 171500,
"salary_max": 245000,
"location": "Remote (US)",
"workplace": "hybrid",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "principal",
"tags": [
"data-pipeline",
"gpu",
"llm",
"rag",
"embeddings",
"security",
"search",
"research"
],
"apply_url": "https://job-boards.greenhouse.io/zscaler/jobs/5058767007",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-30T18:11:08Z",
"expires_at": "2026-08-30T14:10:21.783546Z",
"created_at": "2026-07-31T14:10:21.914294Z",
"updated_at": "2026-07-31T14:10:21.914294Z",
"company_name": "Zscaler",
"company_slug": "zscaler",
"company_logo_url": "https://www.google.com/s2/favicons?domain=zscaler.com&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/729bdc61-a693-49f1-bc55-87988031946c"
},
{
"id": "f58aea8d-a306-4d60-bd12-166357332a58",
"company_id": "b459414f-fd43-42c4-a6e1-f07225286a75",
"title": "Infrastructure Engineer - Member of Technical Staff",
"slug": "infrastructure-engineer-member-of-technical-staff-4ef83d2d",
"description": "ABOUT THE COMPANY\n\nSimile is The Simulation Company. We simulate human behavior to keep people at the center of the decisions that shape the world. With AI, anyone can create a product, a campaign, a policy, or a script — the bottleneck has moved upstream. The hard question is no longer whether you can create something, but what to create, for whom, and how to bring it to life. Those are fundamentally human decisions, and they shouldn't be left to chance or handed off to an algorithm. We're building the infrastructure to understand human behavior at scale and to represent humans in an increasingly agentic world. Our mission is to simulate all eight billion people on earth.\n\n\n\nWe launched five months ago. Since then we've grown revenue 5x, built a new foundation model for human behavior that has run tens of millions of simulations for F100 enterprises, trained a first-of-its-kind confidence model that predicts the accuracy of every simulation, and released the first product that lets organizations verifiably predict the future. The world's leading companies use Simile to make business-critical decisions — from consumer leaders like CVS Health and Wealthfront to professional services organizations like Deloitte and Gallup — strategizing product launches, entering new markets, and forecasting earnings calls.\n\n\n\nWe've raised over $200M at a $2B post-money valuation led by Greenoaks, with Index Ventures, Hanabi, A*, Bain Capital Ventures, and CVS Health Ventures. We've grown from a small home in Palo Alto to a global team of 50+, and we're building a team of the best researchers, engineers, designers, and operators in the world. The future is too important to be left to chance.\n\n\n\n\n\nABOUT THE TEAM\n\nThe Infrastructure team is the backbone of our platform. We build the foundational systems that allow our AI agents to operate at scale with uncompromising security. We operate at the intersection of high-scale cloud networking, distributed systems, and enterprise-grade privacy.\n\n\n\n\nWE ORGANIZE OUR WORK INTO THREE CORE PILLARS:\n\n - Cloud Foundation: Managing our multi-cloud footprint (AWS/GCP) with a focus on high availability, cost-efficiency, and Infrastructure-as-Code.\n\n - Enterprise Deployments: Building the \"paved paths\" for VPC peering, PrivateLink, and BYOC (Bring Your Own Cloud) architectures for our largest customers.\n\n - Platform & Reliability: Developing the CI/CD pipelines and observability stacks (p99 latency tracking, SLOs) that empower our entire engineering org to ship safely.\n\n\n\n\nABOUT THE ROLE\n\nWe are looking for an Infrastructure Engineer who thrives on the complexity of modern deployment patterns. You will own the infrastructure roadmap from design to operation, ensuring our platform is resilient, compliant, and ready for global scale.\n\n\n\n\nRESPONSIBILITIES\n\n - Architect Multi-Cloud Environments: Design and scale multi-region architectures across AWS and GCP to support global data residency and failover requirements.\n\n - Enable Engineering Velocity: Partner cross-functionally with Product Engineering, Research, and Security teams to build internal tooling and \"paved paths\" that accelerate development velocity and empower every engineer to ship with confidence.\n\n - Own Enterprise Connectivity: Build and automate secure networking solutions, including VPC peering, PrivateLink, and dedicated interconnects for customer-managed environments.\n\n - Drive Reliability: Set and maintain strict SLOs. You’ll optimize networking paths and resource allocation to ensure our real-time AI features hit their latency targets.\n\n - Champion GitOps: Manage our entire stack via Terraform/Pulumi; ensuring that \"the code is the truth\" across all environments.\n\n - Security & Compliance: Implement \"security-by-design,\" focusing on encryption at rest/transit and identity management (SAML/SCIM) to meet SOC2 and HIPAA standards.\n\n\n\n\nREQUIREMENTS\n\n\nMUST HAVES\n\n - 5+ years of experience building production-grade infrastructure in a high-growth environment.\n\n - Cloud Polyglot: Deep expertise in AWS is required; experience with GCP or Azure is a major plus.\n\n - Networking Guru: Deep understanding of DNS, Load Balancing, Service Meshes, and complex VPC routing.\n\n - IaC Architect: Proven track record managing large-scale environments using Terraform, Pulumi, or other production-ready, battle-tested IaC tools with a focus on reusable, modular infrastructure.\n\n - Operational Mindset: Experience with modern observability (Datadog, OpenTelemetry) and a \"you build it, you run it\" mentality.\n\n - Communication: Ability to write clear technical specs for both internal teams and external customers.\n\n\nNICE TO HAVES\n\n - AI/ML Infrastructure: Experience building or scaling infrastructure for AI/ML workloads, specifically high-throughput inference systems or GPU-accelerated computing.\n\n - Kubernetes Mastery: Strong K8s (EKS/GKE) experience, specifically around multi-tenant security and resource isolation.\n   \n\n\n\n\nCOMPENSATION & BENEFITS\n\nAt",
"salary_min": 200000,
"salary_max": 400000,
"location": "San Francisco, CA",
"workplace": "onsite",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "lead",
"tags": [
"generative-ai",
"distributed-systems",
"agents",
"cloud",
"infrastructure"
],
"apply_url": "https://jobs.ashbyhq.com/simile/ed518612-bd1e-416b-9e53-77f363eae525/application",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-30T17:16:03.287Z",
"expires_at": "2026-08-30T14:11:51.540988Z",
"created_at": "2026-04-14T03:21:23.993958Z",
"updated_at": "2026-07-31T14:11:51.666253Z",
"company_name": "Simile",
"company_slug": "simile",
"company_logo_url": "https://www.google.com/s2/favicons?domain=simile.ai&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/f58aea8d-a306-4d60-bd12-166357332a58"
},
{
"id": "426da38a-255b-4b18-aa49-edd706e59a31",
"company_id": "6ea0f41a-b13e-481a-b410-5195f391f939",
"title": "Research Engineer, Large-Scale Training",
"slug": "research-engineer-large-scale-training-19a25c49",
"description": "About the Role \n The Model Shaping team at Together AI works on products and research for tailoring open foundation models to downstream applications. We build services that allow machine learning developers to choose the best models for their tasks and further improve these models using domain-specific data. In addition, we develop new methods for more efficient model training and evaluation, drawing inspiration from a broad spectrum of ideas across machine learning, natural language processing, and ML systems. \n As a Research Engineer on the Scaling Team within Model Shaping, you will turn cutting-edge research on efficient foundation model training into robust, high-performance systems. You will profile and optimize Together's training infrastructure, identify performance bottlenecks across the stack, and implement state-of-the-art techniques from both the research literature and our own scientists in production environments. \n Your work will directly shape the fine-tuning experience of Together's customers. You will rapidly bring newly released open-source models onto the Model Shaping platform, ensuring they train efficiently and reliably across diverse customer workloads. Working closely with Research Scientists, you will also build the experimental infrastructure that accelerates research and enables validated ideas to be deployed reliably at scale. \n Responsibilities \n \n Design, implement, and optimize core components of Together's large-scale training infrastructure. \n Integrate new model architectures, validate training correctness and convergence, and optimize performance for production fine-tuning workloads. \n Profile distributed training workloads to identify and eliminate bottlenecks across compute, memory, and communication. \n Design and execute experiments to validate performance hypotheses and benchmark new approaches against state-of-the-art methods. \n Partner closely with Research Scientists to productionize novel training methods and contribute to publications and open-source releases. \n Rapidly enable support for newly released open-source foundation models on the Together platform. \n Build and maintain experimental infrastructure that accelerates research while ensuring production-quality reliability and scalability. \n \n Requirements \n \n Demonstrated ability to independently take ambiguous performance or infrastructure problems from investigation through deployment. \n Strong programming skills in Python and PyTorch, with an emphasis on writing efficient, maintainable code. \n Hands-on experience training or fine-tuning large neural networks in multi-GPU or multi-node environments. \n Solid understanding of ML systems fundamentals, including GPU architecture, mixed-precision training, and distributed training paradigms such as data, tensor, pipeline, or expert parallelism. \n Strong communication skills and the ability to collaborate effectively with both researchers and engineers. \n Passion for staying current with advances in AI research and applying them to real-world systems. \n Excitement about translating cutting-edge research into production systems that deliver customer impact. \n \n Nice to Have \n \n Experience writing optimized NVIDIA GPU kernels using CUDA or Triton, or implementing communication collectives with technologies such as NCCL or NVSHMEM. \n Experience with large-scale training frameworks such as FSDP, DeepSpeed, Megatron-LM, or custom distributed training systems. \n Experience optimizing distributed training for compute efficiency, memory efficiency, or scalability. \n Experience running and managing large-scale GPU experiments, including scheduling, monitoring, and fault tolerance. \n Contributions to widely used open-source ML or ML systems projects. \n Experience building or operating ML products or managed services used by external customers. \n \n About Together AI \n Together AI is a research-driven artificial intelligence company. We believe open and transparent AI systems will drive innovation and create the best outcomes for society, and together we are on a mission to significantly lower the cost of modern AI systems by co-designing software, hardware, algorithms, and models. We have contributed to leading open-source research, models, and datasets to advance the frontier of AI, and our team has been behind technological advancement such as FlashAttention, ATLAS, RedPajama, and Mamba. We invite you to join a passionate group of researchers in our journey in building the next generation AI infrastructure. \n Compensation \n We offer competitive compensation, startup equity, health insurance, and other benefits. The US base salary range for this full-time position is $200,000 - $290,000. Our salary ranges are determined by location, level and role. Individual compensation will be determined by experience, skills, and job-related knowledge. \n Equal Opportunity \n Together AI is an Equal Opportunity Employer and is proud to offer equal employment opportunity to everyone reg",
"salary_min": 200000,
"salary_max": 290000,
"location": "San Francisco, CA",
"workplace": "onsite",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "senior",
"tags": [
"nlp",
"gpu",
"generative-ai",
"pytorch",
"deep-learning",
"fine-tuning",
"distributed-systems",
"search"
],
"apply_url": "https://job-boards.greenhouse.io/togetherai/jobs/5199554007",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-30T16:52:05Z",
"expires_at": "2026-08-30T14:02:19.764671Z",
"created_at": "2026-07-31T14:02:19.892066Z",
"updated_at": "2026-07-31T14:02:19.892066Z",
"company_name": "Together AI",
"company_slug": "together-ai",
"company_logo_url": "https://www.google.com/s2/favicons?domain=together.ai&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/426da38a-255b-4b18-aa49-edd706e59a31"
},
{
"id": "fd3eb5ae-4e46-413b-8f93-f36fa985d12b",
"company_id": "5d6de1f6-4d6c-463b-8a2b-a5caeadb97b4",
"title": "Senior Software Engineer, Airflow Infrastructure - NYC",
"slug": "senior-software-engineer-airflow-infrastructure-nyc-56b64bea",
"description": "Astronomer empowers data teams to bring mission-critical software, analytics, and AI to life and is the company behind Astro, the industry-leading unified DataOps platform powered by Apache Airflow®. Astro accelerates building reliable data products that unlock insights, unleash AI value, and powers data-driven applications. Trusted by more than 800 of the world's leading enterprises, Astronomer lets businesses do more with their data. To learn more, visit www.astronomer.io http://www.astronomer.io.\n\n\n\n\nABOUT THIS ROLE:\n\nAt Astronomer, we’re redefining how companies run Apache Airflow at scale. Our R&D organization is home to some of the most innovative minds in cloud infrastructure and open-source software.\n\nWe’re looking for a Senior Software Engineer to join our Airflow Infra team, part of Astro, our flagship cloud platform. You’ll be building the critical layer that connects the open-source Airflow ecosystem to enterprise-grade, massively scalable cloud infrastructure. Your work will directly influence how global organizations orchestrate data pipelines at scale—making them faster, more reliable, and easier to manage.\n\nIf you’re driven by impact, excited by scale, and ready to work on the kind of infrastructure challenges that push the boundaries of what’s possible in cloud-native systems, this is the opportunity you’ve been waiting for.\n\n\n\nHybrid Work Model: For this role, you will embrace a flexible hybrid work model with at least 3 days per week in our New York City office.\n\n\n\n\n\n\nWHAT YOU GET TO DO:\n\n - Engineer backend services with high quality, maintainable and well tested code.\n\n - Partner with other engineers, product, customer reliability support, and leadership to achieve business goals and define how our systems should evolve.\n\n - Regularly engage in code reviews and provide constructive feedback.\n\n - Optimize the performance, reliability and scalability of existing backend services.\n\n - Investigate, prototype and propose ideas to improve user experience.\n\n - Create and maintain technical documentation for systems and processes, ensuring clarity and accessibility.\n\n - Participate in on-call rotation, troubleshoot and debug to solve incidents.\n\n\n\n\nWHAT YOU BRING TO THE ROLE:\n\n - 5+ years of experience building and delivering SaaS products.\n\n - Strong proficiency in Python or Golang.\n\n - Hands-on experience with Kubernetes.\n\n - Solid understanding of and experience with integrating with RESTful APIs and distributed systems.\n\n - Comfortable with testing frameworks, such as pytest.\n\n - Strong communication skills, both written and verbal, with experience in creating technical specifications.\n\n - A passion for reliability and operational excellence.\n\n - Ability to scope work and coordinate cross-functionally to address risks and ensure successful delivery.\n\n - Experience with software development best practices, such as code reviews, testing, CI/CD, version control, automation and debugging.\n\n - Ability to adjust to change and rapid pace of development.\n\n - Proactive approach to identifying and addressing issues, with a focus on ownership and accountability.\n\n\n\n\nBONUS POINTS IF YOU HAVE:\n\n - Experience with Apache Airflow\n\n\n\nThe estimated salary for this role ranges from $200,000 - $230,000 based on leveling and geography, along with an equity component and a comprehensive benefits package. This range is merely an estimate; actual compensation may deviate from this range based on skills, experience, and qualifications.\n\n\n\n#LI-Fulltime\n\n#LI-Hybrid\n\n\n\nAt Astronomer, we value diversity. We are an equal opportunity employer: we do not discriminate on the basis of race, religion, color, national origin, gender, sexual orientation, age, marital status, veteran status, or disability status.",
"salary_min": 200000,
"salary_max": 230000,
"location": "New York, NY",
"workplace": "hybrid",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "senior",
"tags": [
"distributed-systems",
"data-pipeline",
"cloud",
"infrastructure"
],
"apply_url": "https://jobs.ashbyhq.com/astronomer/0166149d-ce80-4a1b-8371-5c989b28c1e7/application",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-30T12:55:18.027Z",
"expires_at": "2026-08-30T14:18:05.658808Z",
"created_at": "2026-07-30T14:18:05.190927Z",
"updated_at": "2026-07-31T14:18:05.764215Z",
"company_name": "Astronomer",
"company_slug": "astronomer",
"company_logo_url": "https://www.google.com/s2/favicons?domain=astronomer.io&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/fd3eb5ae-4e46-413b-8f93-f36fa985d12b"
},
{
"id": "c2f24669-9a25-4737-a0de-fe1453d33f0d",
"company_id": "c587b06c-b6f0-4d1d-b694-6fb6abc2a6bb",
"title": "Director of Customer Experience",
"slug": "director-of-customer-experience-82241238",
"description": "Who We Are \n Lightning AI is the company behind PyTorch Lightning. Founded in 2019, we build an end-to-end platform for developing, training, and deploying AI systems—designed to take ideas from research to production with less friction.\n Through our merger with Voltage Park, a neocloud and AI Factory, Lightning AI combines developer-first software with cost-efficient, large-scale compute. Teams get the tools they need for experimentation, training, and production inference, with security, observability, and control built in.\n We serve solo researchers, startups, and large enterprises. Lightning AI operates globally with offices in New York City, San Francisco, Seattle, and London, and is backed by Coatue, Index Ventures, Bain Capital Ventures, and Firstminute.\n The Way We Work\n The people who thrive here are builders who move fast, communicate openly, take ownership, and continuously improve themselves, their teams, and our company. Here's what that looks like in practice:\n \n Move with Urgency: We move quickly, make thoughtful decisions, and keep momentum. We value action over perfection and learn by shipping.\n Take Ownership: We own outcomes, not just our individual work. We make decisions that move the company forward and follow through.\n Communicate Openly: We communicate directly, seek to understand, and create clarity for others. Honest conversations help us move faster together.\n Build Great Teams: We lead by example, empower others, and create healthy teams where people can do their best work.\n Raise the Bar: We're always improving ourselves. We learn from feedback, consistently challenge ourselves to grow, and focus on the work that matters most.\n Think Long-Term: We design for what's next. We create scalable systems, simplify complexity, and use AI and automation to amplify our impact.\n \n  \n Who We Look For \n The people who thrive at Lightning AI are builders who move with urgency, communicate openly, take ownership, and continuously raise the bar for themselves and their teams.\n We value leaders who create clarity in complex environments, stay close to customers and the work, and build systems that scale without introducing unnecessary processes.\n About the Role \n We are looking for a Director of Customer Experience to build and lead the organization responsible for helping Lightning AI customers realize meaningful value from our platform.\n You will own the strategy, operating model, and execution of our customer experience function, leading a team of Technical Account Managers and Customer Experience Managers supporting customers across the AI lifecycle—from initial onboarding and workload migration through production adoption, optimization, and expansion.\n This role sits at the intersection of customers, engineering, product, sales, and infrastructure. You will be accountable for ensuring customers can successfully build and operate AI workloads on Lightning AI while receiving clear, proactive, and technically credible guidance throughout the relationship.\n The right leader will combine strong customer judgment with technical depth and operational rigor. You should be comfortable getting into the technical details enough so that you understand where customers are blocked, influencing product priorities, and advising executives on retention, risk, adoption, and account health.\n This is a highly visible leadership role with the opportunity to define what world-class customer experience looks like for a developer-first AI platform and infrastructure company.\n What You’ll Do \n \n Define and own Lightning AI’s customer experience strategy across onboarding, implementation, adoption, technical success, support coordination, retention, and expansion.\n Build, lead, and develop a high-performing global team of Technical Account Managers and Support Engineers.\n Establish account-health frameworks that combine product usage, platform reliability, workload performance, customer sentiment, support activity, and commercial risk.\n Create clear escalation and incident-management processes that provide customers with fast response times, strong ownership, seamless internal coordination, and proactive communication.\n Define and track the metrics that matter, including time to value, activation, platform adoption, workload growth, retention, expansion, customer health, resolution time, and customer satisfaction.\n Turn customer conversations and usage patterns into actionable insights for product and engineering.\n Scale the function thoughtfully, balancing high-touch customer engagement with automation, self-service resources, and repeatable programs.\n \n What You’ll Need \n \n 10+ years of experience across customer experience, customer success, technical account management, solutions architecture, professional services, or a related customer-facing function.\n Growth-stage, enterprise SaaS, developer platform, cloud infrastructure, or AI infrastructure environment preferred, but not required\n A proven trac",
"salary_min": 155000,
"salary_max": 220000,
"location": "New York, NY",
"workplace": "hybrid",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "lead",
"tags": [
"gpu",
"mlops",
"distributed-systems",
"cloud",
"pytorch"
],
"apply_url": "https://job-boards.greenhouse.io/lightningai/jobs/7821031003",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-30T03:29:03Z",
"expires_at": "2026-08-30T14:03:51.452084Z",
"created_at": "2026-07-30T14:03:45.87698Z",
"updated_at": "2026-07-31T14:03:51.583879Z",
"company_name": "Lightning AI",
"company_slug": "lightning-ai",
"company_logo_url": "https://www.google.com/s2/favicons?domain=lightning.ai&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/c2f24669-9a25-4737-a0de-fe1453d33f0d"
},
{
"id": "695debc1-7b4a-40f3-8ba9-0d3393471571",
"company_id": "b459414f-fd43-42c4-a6e1-f07225286a75",
"title": "Research Infrastructure - Member of Technical Staff",
"slug": "member-of-technical-staff-2cec38c1",
"description": "ABOUT THE COMPANY\n\nSimile is The Simulation Company. We simulate human behavior to keep people at the center of the decisions that shape the world. With AI, anyone can create a product, a campaign, a policy, or a script — the bottleneck has moved upstream. The hard question is no longer whether you can create something, but what to create, for whom, and how to bring it to life. Those are fundamentally human decisions, and they shouldn't be left to chance or handed off to an algorithm. We're building the infrastructure to understand human behavior at scale and to represent humans in an increasingly agentic world. Our mission is to simulate all eight billion people on earth.\n\n\n\nWe launched five months ago. Since then we've grown revenue 5x, built a new foundation model for human behavior that has run tens of millions of simulations for F100 enterprises, trained a first-of-its-kind confidence model that predicts the accuracy of every simulation, and released the first product that lets organizations verifiably predict the future. The world's leading companies use Simile to make business-critical decisions — from consumer leaders like CVS Health and Wealthfront to professional services organizations like Deloitte and Gallup — strategizing product launches, entering new markets, and forecasting earnings calls.\n\n\n\nWe've raised over $200M at a $2B post-money valuation led by Greenoaks, with Index Ventures, Hanabi, A*, Bain Capital Ventures, and CVS Health Ventures. We've grown from a small home in Palo Alto to a global team of 50+, and we're building a team of the best researchers, engineers, designers, and operators in the world. The future is too important to be left to chance.\n\n\n\n\n\nABOUT THE TEAM\n\nResearch Infrastructure builds the systems that every step of the model lifecycle runs on: data ingestion and schema design, distributed training, evaluation, serving, and monitoring. We are the reason a researcher's hypothesis can become a production simulation in days rather than quarters.\n\n\n\nTwo things make this problem unusual. First, our research-to-product pipeline is unusually tight - the experimental methods we validate on Monday are integrated into systems customers use to make high-stakes decisions. Second, simulating a society means running inference over populations of agents, not single requests. A single customer study can mean millions of model calls with interdependent state. Cost per simulation and latency per agent are not back-office metrics for us; they determine what research is even possible to run.\n\n\n\n\nABOUT THE ROLE\n\nAs a Member of Technical Staff in Research Infrastructure, you will build the platform our researchers train, evaluate, and deploy on - and own it through the last mile, where a trained checkpoint becomes a production service serving millions of interdependent agent calls at a cost per simulation we can afford.\n\n\n\nThis is a role for someone who is energized by both halves of that. You will spend some weeks designing the data schemas and training pipelines a research team depends on, others profiling a serving path to find where the FLOPs and GPU memory are going, and others still bringing up cluster nodes or deleting the third redundant copy of a code path. The common thread is leverage: every improvement you make compounds across every researcher and every simulation we run.\n\n\n\nWe are looking for engineers who find it gratifying to see their work pushed to its absolute limits, and who own problems end-to-end - including the last mile of deployment that most people would rather hand off.\n\n\n\n\nIN THIS ROLE, YOU WILL\n\n - Build the ML platform our researchers live in. Design and operate the services, libraries, and tooling that cover the full lifecycle - data exploration, feature generation, experiment tracking, training orchestration, evaluation, and deployment. Success is defined by your ability to increase experiment velocity, streamlining the researcher’s path from ideation to a fully validated, production-ready model.\n\n - Make training and data pipelines fast. Own throughput end to end: model FLOPs utilization across our training configs, tokenization cost when the data mix changes, and ingestion paths that take hours today where they should take minutes. Profile where the time and GPU memory actually go, then fix it, including the observability that makes the next bottleneck obvious before it bites.\n\n - Make serving fast and cheap enough to run a society. Own the inference path our simulations run on: batching and scheduling, KV cache reuse across agents sharing context, quantization, and the request patterns unique to population-scale runs where one study is millions of interdependent calls. Cost per simulation and latency per agent decide what research we can afford to run at all, so treat them as research constraints, not ops metrics.\n\n - Scaling simulation Data. Lead the redesign of our data architecture to handle the complexity and sheer volume of our simulation mode",
"salary_min": 200000,
"salary_max": 400000,
"location": "San Francisco, CA",
"workplace": "onsite",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "lead",
"tags": [
"mlops",
"pytorch",
"gpu",
"generative-ai",
"distributed-systems",
"agents",
"search",
"data-pipeline"
],
"apply_url": "https://jobs.ashbyhq.com/simile/9acc73e4-7f77-49dc-b0f6-1a9d26b33b04/application",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-30T01:26:30.32Z",
"expires_at": "2026-08-30T14:11:51.806559Z",
"created_at": "2026-04-22T15:46:51.33414Z",
"updated_at": "2026-07-31T14:11:51.928823Z",
"company_name": "Simile",
"company_slug": "simile",
"company_logo_url": "https://www.google.com/s2/favicons?domain=simile.ai&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/695debc1-7b4a-40f3-8ba9-0d3393471571"
},
{
"id": "cc0d7d3c-5d48-448b-a332-3a75998f31e6",
"company_id": "9bd78d17-fe7f-46b8-82c9-7c3499c319cd",
"title": "Open Source AI Engineer (Typescript)",
"slug": "open-source-ai-engineer-typescript-db5c66c2",
"description": "About Arize\n AI is rapidly transforming the world. As generative AI reshapes industries, teams need powerful ways to monitor, troubleshoot, and optimize their AI systems. That’s where we come in. Arize AI is the leading AI & Agent Engineering observability and evaluation platform , empowering AI engineers to ship high-performing, reliable agents and applications. From first prototype to production scale, Arize AX unifies build, test, and run in a single workspace—so teams can ship faster with confidence.\n We’re a Series C  company backed by top-tier investors,   with  over $135M in funding  and a rapidly growing customer base of  150+ leading enterprises and Fortune 500 companies.  Customers like  Booking.com , Uber, Siemens, and PepsiCo leverage Arize to deliver AI that works.\n The Opportunity \n AI is rapidly transforming the world. Whether it’s developing the next generation of human-level intelligence, enhancing voice assistants, or enabling researchers to analyze genetic markers at scale, AI is increasingly integrated into various aspects of our daily lives.\n Arize AI is the leading AI observability and evaluation platform, empowering AI engineers to build and deploy high-performing, reliable models. As the AI landscape shifts from traditional ML to generative AI and agentic systems, Arize ensures teams have the tools to monitor, troubleshoot, and improve AI in production.\n We’re looking for an Open Source AI Engineer to join our growing OSS team to drive the development of new frameworks, metrics, and tooling that help people build, test, and improve LLM tasks. You’ll play a lead role in shaping how developers measure and understand performance in advanced AI systems, all in the open.\n What You’ll Work On \n \n Build LLM Observability Frameworks: Design, architect, and open-source new libraries, pipelines, and APIs that make it simpler to monitor, evaluate, and improve LLM output.\n Collaborate with the Community: Partner closely with the broader AI open source ecosystem, gather feedback, review pull requests, and steer the direction of the project to address real developer needs.\n Prototype and Iterate Rapidly: Experiment with state-of-the-art LLM techniques, turning research into practical developer tooling.\n Improve Observability and Debugging: Integrate with our existing platform to surface deeper insights on LLM behavior—help teams quickly diagnose and fix issues such as hallucinations or bias.\n Educate and Evangelize: Write blog posts, white papers, tutorials, and documentation to help developers succeed with our open source tools and grow the LLM eval community.\n \n What We’re Looking For \n We’re looking for an engineer who’s deeply passionate about AI, loves working in the open, and thrives in a fast-paced environment where “everyone wears multiple hats”. You likely share our core values:\n \n Open Source Champion: You believe collaboration and community-driven development unlocks the best innovations.\n Creative Problem Solver: You enjoy tackling ambiguous challenges and finding elegant technical solutions.\n Data & Metrics Driven: You value empirical results, enjoy creating or refining evaluation metrics, and iterate based on real-world feedback.\n Technically Curious: You’re always learning—exploring new LLM architectures, prompt engineering strategies, or emerging library standards.\n Builder Mindset: You relish the process of taking ideas from initial prototypes to production-ready solutions that delight users.\n \n Desired Skills & Experience \n \n Hands-on LLM Experience: Familiarity with popular LLM frameworks, prompt engineering techniques, and agent harnesses.\n Strong TypeScript Proficiency: You understand TypeScript and can write isomorphic code that executes seamlessly across clients, servers, and diverse edge runtimes.\n Open Source Track Record: Contributions to open source projects, personal GitHub repos with interesting AI demos, or a history of active engagement in developer communities.\n ML Observability & Tools: Familiarity with debugging AI applications, exploring embeddings, or building data-heavy dashboards is a plus.\n \n Why Work With Us \n \n Shape the Future of AI Evaluation: Be at the forefront of designing new ways to measure and improve next-generation LLMs.\n High Impact, Real Ownership: Join a team that values autonomy and speed. You’ll drive major initiatives from day one and see your work used by developers worldwide.\n Fully Remote, Flexible Environment: We are a fully remote company with offices in the Bay Area and NYC for those who prefer in-person collaboration.\n Cutting-Edge Challenges: Our platform already helps analyze millions of AI predictions daily, giving you the chance to refine your evaluation tooling on real, large-scale production workloads.\n Work With a Talented, Passionate Team: Collaborate closely with top engineers who are dedicated to making AI more transparent, reliable, and impactful.\n \n The estimated annual salary and var",
"salary_min": 185000,
"salary_max": 200000,
"location": "Remote (US)",
"workplace": "remote",
"remote_scope": "restricted",
"job_type": "full-time",
"experience_level": "mid",
"tags": [
"agents",
"llm",
"generative-ai",
"typescript"
],
"apply_url": "https://job-boards.greenhouse.io/arizeai/jobs/6119757004",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-29T22:10:40Z",
"expires_at": "2026-08-30T14:03:58.968363Z",
"created_at": "2026-07-30T14:03:53.474251Z",
"updated_at": "2026-07-31T14:03:59.108226Z",
"company_name": "Arize AI",
"company_slug": "arize-ai",
"company_logo_url": "https://www.google.com/s2/favicons?domain=arize.com&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/cc0d7d3c-5d48-448b-a332-3a75998f31e6"
},
{
"id": "d4ea1ff8-70df-49cc-9765-24075e42ced0",
"company_id": "e5e49ca2-fa01-4747-a951-326be14de524",
"title": "Staff ML Engineer, Agent Training & Environments",
"slug": "staff-ml-engineer-agent-training-environments-c9d2eab1",
"description": "Shape the Future of AI \n At Labelbox, we're building the critical infrastructure that powers breakthrough AI models at leading research labs and enterprises. Since 2018, we've been pioneering data-centric approaches that are fundamental to AI development, and our work becomes even more essential as AI capabilities expand exponentially.\n About Labelbox \n We're the only company offering three integrated solutions for frontier AI development:\n \n Enterprise Platform & Tools : Advanced annotation tools, workflow automation, and quality control systems that enable teams to produce high-quality training data at scale\n Frontier Data Labeling Service : Specialized data labeling through Alignerr, leveraging subject matter experts for next-generation AI models\n Expert Marketplace : Connecting AI teams with highly skilled annotators and domain experts for flexible scaling\n \n Why Join Us \n \n High-Impact Environment : We operate like an early-stage startup, focusing on impact over process. You'll take on expanded responsibilities quickly, with career growth directly tied to your contributions.\n Technical Excellence : Work at the cutting edge of AI development, collaborating with industry leaders and shaping the future of artificial intelligence.\n Innovation at Speed : We celebrate those who take ownership, move fast, and deliver impact. Our environment rewards high agency and rapid execution.\n Continuous Growth : Every role requires continuous learning and evolution. You'll be surrounded by curious minds solving complex problems at the frontier of AI.\n Clear Ownership : You'll know exactly what you're responsible for and have the autonomy to execute. We empower people to drive results through clear ownership and metrics.\n \n Role Overview\n Labelbox is the RL data factory for advancing frontier agent capabilities. We build the data, environments, and evaluations that frontier labs use to train and judge their agents.\n This role sits where training meets infrastructure. You will run the experiments and build the systems that run them: environments agents act in, verifiers that decide whether they succeeded, and the fine-tuning pipelines that turn that signal into a better model. We're looking for someone who does both halves — the engineering throughput of a strong platform engineer, and real depth in post-training agents.\n The bar is high: engineers with strong judgment who set technical direction, turn prototypes into reliable systems fast, and are at the frontier of agent-first engineering practice.\n  \n What you'll work on\n \n RL environments for agentic tasks: task definitions, tool surfaces, state and reset semantics, reward design — and the harness that runs thousands of them in parallel.\n Verifiers and graders: programmatic checks, LLM judges, rubric pipelines, pass@k scoring. Deciding what \"the agent succeeded\" means, and making that judgment trustworthy at scale.\n Fine-tuning pipelines that turn evaluation signals into measurable agent improvements — SFT and RL, from data collection through training to checkpoint evaluation.\n Eval systems that run millions of agent trajectories to measure model and product quality.\n Training and serving infrastructure that scales to the throughput frontier labs need: multi-launcher orchestration, long-running job fault tolerance, cost accounting.\n \n What we're looking for\n As an engineer \n \n A 3+ year track record of shipping systems that customers and other engineers still rely on.\n Exceptional throughput, without the quality tax. You ship a lot, you review a lot, and the v1 you ship becomes the foundation the rest of the team builds on.\n Strong system and API design judgment. Hard architecture calls land with you: you make them, defend them under pressure, and update fast when someone else is right.\n You ship production code with coding agents daily. You know where they break and what it takes to make them reliable, and you use that to move the whole team faster.\n You build the substrate other people's work runs on — tooling, CI, harnesses, libraries — and you treat that as the job, not a distraction from it.\n You move fast in ambiguous, startup-pace environments, with influence over authority.\n Deep proficiency in Python, and comfort across the rest of the stack.\n \n As an RL post-training practitioner \n \n You have fine-tuned models for agentic tasks and made them measurably better. SFT plus at least one RL method (GRPO, PPO, DPO, or similar) in production.\n You have built environments agents operate in, and you know why reward and task design is where most of the difficulty actually lives.\n You have designed verifiers or graders for open-ended work, and you know how they get gamed.\n You debug training runs forensically and methodically.\n You reason about compute-economics. You know what an experiment costs, when a run is not worth finishing, and how to get the same signal for a tenth of the spend.\n You write up what you learned so it changes what the team does next.\n \n",
"salary_min": 250000,
"salary_max": 280000,
"location": "San Francisco, CA",
"workplace": "hybrid",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "lead",
"tags": [
"fine-tuning",
"agents",
"api-design",
"llm",
"distributed-systems",
"machine-learning"
],
"apply_url": "https://job-boards.greenhouse.io/labelbox/jobs/5199053007",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-29T21:20:44Z",
"expires_at": "2026-08-30T14:05:20.057069Z",
"created_at": "2026-07-30T14:05:19.341348Z",
"updated_at": "2026-07-31T14:05:20.191336Z",
"company_name": "Labelbox",
"company_slug": "labelbox",
"company_logo_url": "https://www.google.com/s2/favicons?domain=labelbox.com&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/d4ea1ff8-70df-49cc-9765-24075e42ced0"
},
{
"id": "52277b68-b383-40c7-8131-7a3ae5014e26",
"company_id": "f0134765-5cdf-4b32-b956-b7a147d9d415",
"title": "Senior Manager, Data Engineering",
"slug": "senior-manager-data-engineering-c76ddd18",
"description": "Role Description\n \n We are seeking a Senior Manager, Data Engineering to lead the team responsible for the reliability, quality, cost, and velocity of Dropbox's core data platform. This is a hands-on engineering leader who owns the pipelines and data products that Product, GTM, Finance, and the CTO organization depend on to make decisions. \n  \n In this role, you will lead and grow a team of data engineers building and operating our ingestion, transformation, orchestration, and serving layers, as well as the self-serve analytics substrate that lets partner teams answer their own questions without bespoke engineering work. \n  \n The ideal candidate is a deeply technical, product-minded engineering leader who can hold a high bar on system reliability and data quality while partnering closely with Data Science, Business Intelligence Engineering, Analytics, and Product to turn fragmented, ticket-driven data work into durable, reusable data products. \n Responsibilities\n \n \n Data Quality & Observability: Establish and enforce a rigorous data quality culture: lineage, freshness monitoring, anomaly detection, and outcome-oriented, gaming-resistant quality metrics. \n \n Self-Serve Platform: Lead the engineering of the self-serve analytics substrate, reducing bespoke request volume and increasing partner-team autonomy. \n \n Cost & Efficiency: Own the unit economics of the data platform — compute and storage efficiency — and drive measurable improvements without sacrificing reliability. \n \n Cross-Functional Partnership: Partner deeply with Data Science, BIE, Analytics, Product, Data Platform, and the CTO org to define the semantic layer, modeling standards, and data contracts that make downstream work trustworthy and fast. \n \n Engineering Culture: Establish rigorous engineering practices — code review, testing, CI/CD for data, incident response, and postmortems — and champion the effective, measured use of AI coding tools to improve engineering productivity. \n \n Team Leadership: Lead, mentor, and grow a high-talent-density team of data engineers, fostering a culture of ownership, technical excellence, psychological safety, and continuous learning. \n \n Requirements\n \n \n 8+ years of data engineering or backend/data infrastructure experience with increasing scope, ideally in high-scale environments. \n \n 3+ years of experience directly managing and growing engineering teams, including hiring, coaching, performance management, and team design. \n \n Deep Technical Expertise: Proven track record building and operating large-scale batch and streaming pipelines (e.g., Spark, dbt, Airflow/orchestration) on a modern lakehouse or warehouse stack (e.g., Databricks, Snowflake, BigQuery). \n \n Reliability & Quality: Demonstrated ownership of data SLAs, observability, lineage, and incident response for business-critical pipelines. \n \n Systems & Modeling: Strong data modeling fundamentals and the ability to design a semantic layer and data contracts that serve many downstream consumers. \n \n Stakeholder Management: Excellent communication and the ability to align engineering, data science, analytics, and business partners around shared reliability and quality goals. \n \n Preferred Qualifications\n \n \n Platform / Self-Serve Experience: Track record building self-serve data or analytics platforms that reduced bespoke request volume and increased partner autonomy. \n \n AI-Forward Engineering: Experience integrating AI coding tools and LLM-based tooling into the engineering workflow, with a measured approach to impact and guardrails. \n \n Cost Discipline: Demonstrated success improving compute/storage unit economics without regressing reliability. \n \n Familiarity with modern data governance, privacy, and access-control practices. \n \n Experience operating in a pod or embedded model serving multiple business partners. \n \n \n Durable Skills \n AI fluency means using these tools to amplify human judgment, not replace it. We believe people with these skills will thrive as work and technology continue to evolve: \n \n Awareness: U nderstand yourself and others . \n Judgment: E valuat e information and mak e decisions in complex situations . \n Adaptability: L earn, adjust, and stay effective through change . \n Connection: C ommunicat e , collaborat e , and build trust . \n \n To learn more about why these skills matter and what the data shows about thriving through change, read this blog post from our Chief People Officer, Melanie Rosenwasser. \n Compensation \n US Zone 1 \n This role is not available in Zone 1 \n US Zone 2\n $202,700 — $274,300 USD \n US Zone 3\n $180,200 — $243,800 USD",
"salary_min": 180200,
"salary_max": 243800,
"location": "Remote (US)",
"workplace": "remote",
"remote_scope": "restricted",
"job_type": "full-time",
"experience_level": "senior",
"tags": [
"llm",
"mlops",
"data-engineering",
"data-science"
],
"apply_url": "https://jobs.dropbox.com/listing/8090062?gh_jid=8090062",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-29T21:04:04Z",
"expires_at": "2026-08-30T14:09:49.140781Z",
"created_at": "2026-07-30T14:09:22.265716Z",
"updated_at": "2026-07-31T14:09:49.270687Z",
"company_name": "Dropbox",
"company_slug": "dropbox",
"company_logo_url": "https://www.google.com/s2/favicons?domain=www.dropbox.com&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/52277b68-b383-40c7-8131-7a3ae5014e26"
},
{
"id": "26c78124-fdbf-475f-8684-21a68bdecb67",
"company_id": "e3915539-5a8f-4461-9f26-06366a918674",
"title": "Chief Engineer, Autonomous Flight",
"slug": "chief-engineer-autonomous-flight-0bcdc454",
"description": "Anduril Industries is a defense technology company with a mission to transform U.S. and allied military capabilities with advanced technology. By bringing the expertise, technology, and business model of the 21st century’s most innovative companies to the defense industry, Anduril is changing how military systems are designed, built and sold. Anduril’s family of systems is powered by Lattice OS, an AI-powered operating system that turns thousands of data streams into a realtime, 3D command and control center. As the world enters an era of strategic competition, Anduril is committed to bringing cutting-edge autonomy, AI, computer vision, sensor fusion, and networking technology to the military in months, not years.\n About the Job   \n The Air Dominance & Strike team at Anduril develops aerial and multi-domain robotic systems. The team is responsible for taking products like Fury (unmanned fighter jet) and Barracuda (air-breathing cruise missile) from concept to product. The team also develops Lattice for Mission Autonomy, Anduril’s premier software platform that enables masses of Fury, Barracuda, and other first and third-party robots to collaborate across various missions. We work in close coordination with specialist teams like Perception, Motion Planning, Hardware, and Test Engineering to solve some of the hardest problems facing our customers.   \n As a Chief Engineer, you will own the technical architecture and system-level design of the onboard autonomy stack, command and control systems, and modular payloads for our next-generation autonomous platforms. With a software heavy focus, you will guide lean, multi-disciplinary engineering teams from \"0-to-1\" design through deployment, bridging the gap between high-level business strategy and rigorous engineering execution.   \n What You'll Do:   \n \n Lead systems engineering, requirements decomposition, and technical architecture for software-heavy robotics systems.   \n \n \n Guide small, fast-moving groups of individual contributors through the design, implementation, and deployment phases of emerging programs.    \n \n \n Oversee hardware/software integration and testing (simulation, hardware-in-the-loop, and field testing) to ensure perception, motion planning, and task allocation algorithms run seamlessly on physical platforms.    \n \n \n Partner with Product Managers and Business Development to convert customer mission needs and operational concepts into concrete technical milestones.    \n \n \n Decide technical trade-offs across concurrent programs, helping teams prioritize engineering efforts.   \n \n Required Qualifications:   \n \n Proven track record directing technical architecture and guiding individual contributors as a lead engineer   \n \n \n Background in developing and fielding software-heavy robotics, autonomous systems, or aerospace products.   \n \n \n Strong hardware/software integration skills, including robotics software architectures and tactical mission systems.   \n \n \n Experience with autonomous systems, mission-critical Department of Defense systems, or tactical edge technologies.   \n \n \n Travel:  Ability to travel up to 25% to customer sites and field testing locations.   \n \n \n Education:  BS, MS, or PhD in Robotics, Aerospace, ME, EE, CS, or equivalent.   \n \n \n Security Clearance:  Eligible to obtain and maintain an active U.S. Secret clearan   \n \n Preferred Qualifications:   \n \n Advanced knowledge in Motion Planning, Perception, Command & Control, SLAM, task allocation, or tactical networking.   \n \n \n Work history involving multi-domain unmanned systems (air, ground, or maritime).   \n \n \n Understanding of edge-AI/ML deployment on autonomous physical systems.   \n \n   \n US Salary Range\n $220,000 — $330,000 USD \n The salary range for this role is an estimate based on a wide range of compensation factors, inclusive of base salary only. Actual salary offer may vary based on (but not limited to) work experience, education and/or training, critical skills, and/or business considerations. Highly competitive equity grants are included in the majority of full time offers; and are considered part of Anduril's total compensation package. Additionally, Anduril offers top-tier benefits for full-time employees, including:   \n  \n Benefits \n At Anduril, we invest in our people. Our comprehensive, competitive benefits package (available at little to no cost to employees) ensures you’re supported in health, recovery, and whatever comes next.  For more information, Explore Our Benefits . \n  \n \n Protecting Yourself from Recruitment Scams \n Anduril is committed to maintaining the integrity of our Talent acquisition process and the security of our candidates. We've observed a rise in sophisticated phishing and fraudulent schemes where individuals impersonate Anduril representatives, luring job seekers with false interviews or job offers. These scammers often attempt to extract payment or sensitive personal informa",
"salary_min": 220000,
"salary_max": 330000,
"location": "Costa Mesa, CA",
"workplace": "onsite",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "senior",
"tags": [
"payments",
"cloud",
"robotics",
"computer-vision",
"gpu"
],
"apply_url": "https://boards.greenhouse.io/andurilindustries/jobs/5158222007?gh_jid=5158222007",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-29T19:46:59Z",
"expires_at": "2026-08-30T14:07:46.508717Z",
"created_at": "2026-07-30T14:07:20.585832Z",
"updated_at": "2026-07-31T14:07:46.679205Z",
"company_name": "Anduril",
"company_slug": "anduril",
"company_logo_url": "https://www.google.com/s2/favicons?domain=anduril.com&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/26c78124-fdbf-475f-8684-21a68bdecb67"
},
{
"id": "53b083b9-1530-4dcb-b335-4fb71a87a4ec",
"company_id": "af3a34e9-b9f3-4d69-bcf2-f13327711b7d",
"title": "Staff Product Manager, Applied AI",
"slug": "staff-product-manager-applied-ai-174941ef",
"description": "Apptronik is a human-centered robotics company developing AI-powered robots to support humanity in every facet of life. Our flagship humanoid robot, Apollo, is built to collaborate thoughtfully with people, starting with critical industries such as manufacturing and logistics, with future applications in healthcare, the home, and beyond. We operate at the cutting edge of Applied AI, applying our expertise across the full robotics stack to solve some of society's most important problems. You will join a team dedicated to bringing Apollo to market at scale, tackling the complex challenges like safety, commercialization, and mass production to change the world for the better.\n JOB SUMMARY\n You will focus on driving the product vision, ensuring seamless execution across the complex hardware/software divide, and translating market demands into user oriented, executable product roadmaps.\n ESSENTIAL DUTIES AND RESPONSIBILITIES / KEY ACCOUNTABILITIES\n \n Own and maintain the physical AI model roadmap: product vision, milestones, and release cycles for the core model stack\n Drive the integration, adaptation, and fine-tuning of foundation models into Apollo's autonomy stack. Sequence which capabilities graduate into the shipping model, balancing capability velocity against reliability and safety.\n Translate customer use cases into model capability requirements and acceptance criteria\n Partner with our data collection and evaluation team on benchmarks, real-world evaluation, and the success criteria that gate real-world deployment.\n Own the data strategy that feeds model development: define what to collect and why, the target tasks and behaviors, and the quality bar.\n Align data technology and operations teams on collection techniques, tooling, and quality expectations.\n Define and prioritize use cases based on business impact, feasibility, and customer needs.\n Ensure that product development efforts align with real-world economic value for customers.\n Synthesize insights from user research, customer meetings, usage data, and sales feedback into a strategy that delivers business objectives and customer benefits.\n Work with industrial design, user experience, and engineering teams to conceptualize and implement interactive features.\n Define product features/enhancements and communicate requirements to engineering teams via clearly written requirements documents, diagrams, and concise verbal communication.\n Support product marketing initiatives, partner relationships, and other opportunities to accelerate the adoption of our products.\n \n SKILLS AND REQUIREMENTS\n \n 7+ years of experience in product management\n Strong understanding of modern robot learning techniques including imitation learning, reinforcement learning\n Demonstrated experience integrating, adapting, or fine-tuning models\n Strong familiarity with the constraints of running large neural networks on physical edge devices\n Strong analytical skills with experience in performance tracking and data-driven decision-making.\n Excellent communication skills, both verbal and written, enabling translation of technical insights into business impact.\n You make decisions in uncertainty, prioritizing velocity over perfection\n You prioritize user feedback, promoting and advocating for that voice to internal teams.\n \n NICE TO HAVE\n \n Experience with autonomous robots or autonomous vehicles.\n Experience using simulation tools to improve user experience.\n Hands-on experience training or fine-tuning foundation\n Experience with data collection operation (teleoperation fleets, annotation and curation pipelines).\n Experience working with customers in light and heavy duty industrial environments\n Experience with robotics and functional safety standards (ISO 10218, ISO/TS 15066, ISO 13482, RIA 15.08).\n \n EDUCATION and/or EXPERIENCE\n \n Bachelor's degree (or equivalent) in mechanical, electrical, systems, or robotics engineering, or a related field; advanced degree or MBA helpful.\n At least 10 years of experience in product management or engineering, including 5+ years leading product managers, with a track record of shipping complex hardware products.\n \n PHYSICAL REQUIREMENTS\n \n Prolonged periods of sitting at a desk and working on a computer.\n Ability to spend time on lab and manufacturing floors, and to travel to supplier and manufacturing sites as needed.\n Must be able to lift 15 pounds at times.\n Vision to read printed materials and a computer screen; hearing and speech to communicate. The annual salary range is $215,000 - $245,000\n  \n  \n *This is a direct hire.  Please, no outside Agency solicitations. \n Apptronik provides equal employment opportunities to all employees and applicants for employment and prohibits discrimination and harassment of any type without regard to race, color, religion, age, sex, national origin, disability status, genetics, protected veteran status, sexual orientation, gender identity or expression, or any other characteristic protected by federal, ",
"salary_min": 215000,
"salary_max": 245000,
"location": "Mountain View, CA",
"workplace": "onsite",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "lead",
"tags": [
"deep-learning",
"autonomous-vehicles",
"reinforcement-learning",
"fine-tuning",
"generative-ai",
"healthcare",
"robotics"
],
"apply_url": "https://boards.greenhouse.io/apptronik/jobs/6120107004?gh_jid=6120107004",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-29T19:41:00Z",
"expires_at": "2026-08-30T14:13:38.325787Z",
"created_at": "2026-07-30T14:13:24.845031Z",
"updated_at": "2026-07-31T14:13:38.459052Z",
"company_name": "Apptronik",
"company_slug": "apptronik",
"company_logo_url": "https://www.google.com/s2/favicons?domain=apptronik.com&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/53b083b9-1530-4dcb-b335-4fb71a87a4ec"
},
{
"id": "26ff78f6-343e-4984-9a0b-7cc44695d2ad",
"company_id": "19955a21-2cd6-41fd-a4a8-19b7a942ac16",
"title": "Senior Value Engineer - Public Sector",
"slug": "senior-value-engineer-public-sector-03f25565",
"description": "Celonis is the global leader in Process Intelligence and the pioneer of Process Mining technology. As one of the world’s fastest-growing enterprise SaaS companies, we are changemakers pushing the boundaries of what’s possible. We invest heavily in advanced AI capabilities—specifically our Process Intelligence Graph—to turn data insights into immediate business action. We believe there is a massive opportunity to unlock global productivity and sustainability by placing intelligence at the core of every business process. Join our mission to make processes work for people, companies, and the planet.\n Role Description \n As a Senior Value Engineer specializing in the Public Sector, you are pushing the envelope in solving critical operational challenges for State and Local Government agencies. You will be working with our most strategic public sector clients, understanding their unique objectives—from enhancing citizen services and modernizing legacy systems to optimizing grant management and regulatory compliance—and building Celonis solutions using the world’s leading Process Intelligence (PI) platform in combination with top AI and ML technology partners, such as Microsoft, OpenAI, and Databricks. With Celonis’ Process Intelligence (PI) platform, we feed operational context to AI so it understands the complex realities of government operations (breaking down agency silos) and enables agencies to industrialize AI. This unlocks real ROI on AI deployments, maximizing taxpayer value at scale. There is no AI without PI. You will prototype these solutions, demonstrate their value to government CIOs and Agency Directors, and ensure successful implementation, adoption, and value realization to increase the footprint of Celonis across state and local governments.\n Key Responsibilities: \n \n \n AI Discovery & Solutioning: Understand public sector AI strategies and specific agency challenges (e.g., benefits administration backlogs, procurement bottlenecks, public safety resource allocation, or permitting delays). As a Celonis product and government domain expert, find the best problem-solution fit and translate agency requirements into innovative solutions that deliver measurable public impact.\n \n Pre- and Post-Sales Execution: Actively drive the full customer lifecycle within the public sector. Lead technical discovery and capability demonstrations during the complex government pre-sales and procurement (RFP) cycles, and remain deeply involved post-sale to guide implementation, ensuring agreed value and adoption thresholds are successfully met.\n \n Hackathons & Prototyping: Think out of the box, have a „can-do“ attitude, and don’t shy away from complex legacy processes. Leverage cutting-edge AI technologies to rapidly build creative prototypes in agency hackathons, solving critical pain points to improve constituent experiences.\n \n Agentic Process Transformation: Support our government customers in achieving real value out of AI deployments at scale, enabling a fundamental shift from traditional, rigid, paper-heavy workflows to the use of autonomous AI agents empowered by our Celonis Process Intelligence Platform (e.g., intelligent case triaging or automated compliance checks).\n \n Proof Projects: End-to-end execution of critical Proof-of-Value projects. This includes architecting and delivering secure, scalable LLM/agent systems with RAG, tools, and guardrails, while seamlessly integrating with government enterprise data, identity protocols, and stringent compliance/security frameworks (e.g., StateRAMP, HIPAA, CJIS).\n \n Domain & Industry Leadership: Serve as the internal and external technical subject matter expert for the State & Local Government vertical, scaling knowledge across the organization regarding agency processes and public sector nuances.\n \n Requirements: \n \n \n 5+ years of experience leading technical pre-sales and post-sales engagements specifically within the Public Sector (State & Local Government). This includes navigating government procurement cycles, building compelling ROI business cases for public funds, and guiding technical implementations through to constituent value realization.\n \n Deep understanding of business processes native to state and local governments (such as Health & Human Services, Procurement, Finance, DMV operations, or Public Safety) with the ability to translate high-level policy or agency needs into specific, impactful AI use cases.\n \n Expertise in generative AI techniques like RAG, few-shot learning, prompt engineering, multi-agent orchestration, multimodal understanding, or fine-tuning used to build high-impact use cases (e.g., intelligent constituent-facing chatbots, automated processing of policy documents, or grant application analysis).\n \n Solid knowledge of Python and common ML libraries (such as LangChain, pandas, pydantic, sklearn, PyTorch) as well as data engineering tools and technologies.\n \n Strong presentation skills to both internal and external ",
"salary_min": 156000,
"salary_max": 183000,
"location": "Redwood City, CA",
"workplace": "hybrid",
"remote_scope": "not_remote",
"job_type": "full-time",
"experience_level": "senior",
"tags": [
"fine-tuning",
"agents",
"pytorch",
"generative-ai",
"cloud",
"llm"
],
"apply_url": "https://job-boards.greenhouse.io/celonis/jobs/7817311003?gh_jid=7817311003",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-29T19:37:33Z",
"expires_at": "2026-08-30T14:09:25.09002Z",
"created_at": "2026-07-30T14:08:58.534188Z",
"updated_at": "2026-07-31T14:09:25.214287Z",
"company_name": "Celonis",
"company_slug": "celonis",
"company_logo_url": "https://www.google.com/s2/favicons?domain=www.celonis.com&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/26ff78f6-343e-4984-9a0b-7cc44695d2ad"
},
{
"id": "862e6737-af2a-43b2-8d28-3f1aca3b1716",
"company_id": "72014eb6-e84d-48c2-af5c-5424ebec0b3c",
"title": "Machine Learning Manager, Feed Relevance (Retrieval)",
"slug": "machine-learning-manager-feed-relevance-retrieval-a91727ea",
"description": "Reddit is a community of communities. It’s built on shared interests, passion, and trust, and is home to the most open and authentic conversations on the internet. Every day, Reddit users submit, vote, and comment on the topics they care most about. With 100,000+ active communities and approximately 130 million daily active unique visitors, Reddit is one of the internet’s largest sources of information. For more information, visit www.redditinc.com .\n Reddit is looking for an experienced Engineering Manager to lead our Feed Retrieval team. In this role, you’ll lead a high-impact team of Machine Learning Engineers building the systems that identify, retrieve, and shape the candidate inventory powering Reddit’s personalized feeds. Your team will work at the foundation of Feed Relevance: expanding the set of high-quality content Reddit can recommend, improving personalization and discovery for users across different levels of signal, and building scalable ML systems that directly shape the experiences of over 120M+ daily users. If applying ML / AI in production to improve Reddit Relevance excites you, then you’ve found the right place.\n Responsibilities: \n \n Define Technical Vision & Strategy: Define the technical vision and long-term roadmap for Feed Retrieval, aligning large-scale recommender-system investments with Reddit’s product, ecosystem, and business objectives.\n Roadmap & Prioritization: Translate broad Feed Relevance goals into a focused team roadmap, making clear prioritization tradeoffs across model quality, inventory expansion, experimentation velocity, infrastructure cost, and operational reliability.\n Team Leadership & Development: Coach and support the development of your team, constantly seeking opportunities to grow their skills and impact. \n Technical Execution & Delivery: Oversee the design, development, and optimization of retrieval systems that source relevant, diverse, fresh, and high-quality candidates for personalized feed experiences.\n Measurement & Learning: Establish strong measurement, experimentation, and debugging practices so the team can understand retrieval quality, candidate coverage, source incrementality, and downstream impact.\n Platform & Infrastructure Collaboration: Collaborate with ML platform, infrastructure, ranking, safety, and product teams to build scalable, low-latency retrieval systems that can support the next generation of AI-powered recommendations.\n Operational Excellence: Maintain high standards for system performance, reliability, latency, cost efficiency, and responsible recommendation practices.\n Cross-Functional Partnership: Work with cross-functional partners from across the company to identify key areas of opportunity, set expectations, and communicate your team’s work.\n Recruiting & Growth: Partner with our incredible recruiting team to attract, interview, and hire diverse and talented machine learning engineers, growing a world-class team.\n \n Qualifications: \n \n Experience Leading ML Teams: 2+ years of experience building and managing high-performing ML or recommender-systems teams.\n Deep ML Expertise: Hands-on experience with large-scale production ML systems, ideally including recommender systems, retrieval models, embedding-based systems, sequence models, transformer-based architectures, or LLM-powered recommendation applications.\n Technical Domain Knowledge: Strong understanding of recommender systems, especially candidate retrieval, embedding/indexing systems, ranking handoffs, feed personalization, exploration, content quality, and measurement strategies. \n Strategic Thinking: Ability to develop and communicate a clear technical strategy across ambiguous problem spaces, balancing user relevance, ecosystem health, system scalability, and business impact.\n Impact-Driven Mindset: Passion for developing scalable, well-designed, and responsible AI solutions that drive business value.\n Exceptional Communication & Collaboration: Strong interpersonal skills and a collaborative mindset, with the ability to effectively communicate complex technical topics to diverse audiences and build strong relationships with cross-functional partners.\n \n Benefits: \n \n Comprehensive Healthcare Benefits and Income Replacement Programs\n 401k with Employer Match\n Global Benefit programs that fit your lifestyle, from workspace to professional development to caregiving support\n Family Planning Support\n Gender-Affirming Care\n Mental Health & Coaching Benefits\n Flexible Vacation & Paid Volunteer Time Off\n Generous Paid Parental Leave \n \n #LI-remote, #LI-JS5\n Pay Transparency: \n This job posting may span more than one career level.\n In addition to base salary, this job is eligible to receive equity in the form of restricted stock units, and depending on the position offered, it may also be eligible to receive a commission. Additionally, Reddit offers a wide range of benefits to U.S.-based employees, including medical, dental, and vision insurance, 401(k) prog",
"salary_min": 253300,
"salary_max": 354600,
"location": "Remote (US)",
"workplace": "remote",
"remote_scope": "restricted",
"job_type": "full-time",
"experience_level": "junior",
"tags": [
"healthcare",
"llm",
"fine-tuning",
"evaluation",
"machine-learning"
],
"apply_url": "https://job-boards.greenhouse.io/reddit/jobs/8094985",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-29T19:24:35Z",
"expires_at": "2026-08-30T14:09:31.295056Z",
"created_at": "2026-07-30T14:09:04.880987Z",
"updated_at": "2026-07-31T14:09:31.418717Z",
"company_name": "Reddit",
"company_slug": "reddit",
"company_logo_url": "https://www.google.com/s2/favicons?domain=www.reddit.com&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/862e6737-af2a-43b2-8d28-3f1aca3b1716"
},
{
"id": "62bc42b9-5266-4541-8c1e-b4a390d629a1",
"company_id": "47c8818e-9a45-4180-8d96-931d2774d36b",
"title": "Senior Applied ML Engineer",
"slug": "senior-applied-ml-engineer-39a82ca2",
"description": "About Upstart \n At Upstart, we’re united by a mission that matters: to radically reduce the cost and complexity of borrowing for all Americans. Every day, we bring creativity, experimentation, and advanced AI to reshape access to credit, helping millions move forward financially with clarity and confidence.\n As the leading AI lending marketplace, we partner with banks and credit unions to expand access to affordable credit through technology that’s both radically intelligent and deeply human. Our platform runs over one million predictions per borrower using more than 1,800 signals, powering smarter, fairer decisions for millions of customers. But the numbers only hint at the impact. Every idea, every voice, and every contribution moves us closer to a world where credit never stands between people and their financial progress.\n We’re proudly digital-first, giving most Upstarters the flexibility to do their best work from wherever they thrive, alongside teammates across 80+ cities in the US and Canada. Digital-first doesn’t mean distant. We’re intentional about in-person connection through team onsites, planning sessions, and moments that spark creativity and trust. And whether you choose to work primarily from home or collaborate in-person from one of our offices in Columbus, Austin, the Bay Area, or New York City (opening Summer 2026), you’ll have the support to work in the way that works best for you.\n If you’re energized by tackling meaningful problems, excited to innovate with purpose, and motivated by work that truly matters, we’d love to hear from you.\n The Team \n Upstart’s Applied LLM team is building foundational infrastructure that democratizes access to generative AI for every product and engineering team across the company.  This is a cross-functional team at the intersection of machine learning, product, and engineering. Our mission is to bring the power of ML, particularly large language models (LLMs) and generative AI, to life in Upstart’s core products.\n As a Senior Applied Machine Learning Engineer focused on building Upstart's LLM applications, you'll work closely with researchers, product managers, platform engineers, and designers to ship intelligent features that elevate the user experience and expand the capabilities of our systems.\n How you’ll make an impact: \n \n Design and build user-facing ML features that harness LLMs and generative AI to unlock new product capabilities\n Partner with product, design, and ML research to prototype and deliver high-impact, ML-powered experiences\n Own the technical architecture and implementation strategy for applied ML systems - balancing latency, observability, and iteration speed\n Build scalable services and APIs that bring model outputs to users in trustworthy and intuitive ways\n Collaborate across platform, infra, and legal/compliance teams to ensure ML deployments meet standards for safety, fairness, and performance\n Establish and evangelize best practices for prompt design, model evaluation, and experimentation across the org\n \n What we’re looking for:  \n \n Minimum qualifications: \n \n 4+ years of software engineering experience, with 2+ years working directly on ML-driven products or intelligent systems\n Proven ability to lead complex initiatives across engineering, product, and research stakeholders\n Strong backend development skills (e.g., Python with FastAPI or Flask), plus experience with cloud-native tooling (e.g., Kubernetes, Docker, Terraform)\n Experience integrating LLMs or ML models into production systems, including APIs and user-facing applications\n Excellent communication skills and a collaborative, product-minded approach\n Ability to think rigorously about system design, latency tradeoffs, and user impact when working with ML features \n \n Preferred qualifications: \n \n Experience shipping GenAI or LLM-powered features using frameworks like LangChain, LlamaIndex, or OpenAI APIs\n Familiarity with retrieval-augmented generation (RAG), vector search (e.g., FAISS, Pinecone), and real-time inference patterns\n Proficiency in full-stack development, including front-end work with React or similar frameworks\n Strong intuition for prompt engineering, model testing, and evaluation methodologies\n Experience navigating complex requirements around explainability, user trust, or compliance in ML applications\n Track record of influencing architecture or product direction at a team or org level\n \n \n Position location This role is available in the following locations: Remote\n Travel requirements As a digital first company, the majority of your work can be accomplished remotely. The majority of our employees can live and work anywhere in the U.S but are encouraged to to still spend high quality time in-person collaborating via regular onsites. The in-person sessions’ cadence varies depending on the team and role; most teams meet once or twice per quarter for 2-4 consecutive days at a time.\n  \n #LI-REMOTE \n #LI-Associate \n #LI-",
"salary_min": 177700,
"salary_max": 220000,
"location": "United States",
"workplace": "remote",
"remote_scope": "restricted",
"job_type": "full-time",
"experience_level": "senior",
"tags": [
"embeddings",
"generative-ai",
"rag",
"llm",
"agents",
"machine-learning"
],
"apply_url": "https://careers.upstart.com/jobs?gh_jid=8094141",
"is_featured": false,
"is_sticky": false,
"status": "active",
"published_at": "2026-07-29T19:08:51Z",
"expires_at": "2026-08-30T14:16:14.165909Z",
"created_at": "2026-07-30T14:16:08.133536Z",
"updated_at": "2026-07-31T14:16:14.264711Z",
"company_name": "Upstart",
"company_slug": "upstart",
"company_logo_url": "https://www.google.com/s2/favicons?domain=upstart.com&sz=128",
"quality_score": 90,
"url": "https://aidevboard.com/job/62bc42b9-5266-4541-8c1e-b4a390d629a1"
}
],
"page": 1,
"per_page": 20,
"total": 8997,
"total_is_exact": true,
"total_pages": 450
}

himalayas:
{
"comments": "13/03/2026: The API has been updated to include the companySlug field in the response.",
"updatedAt": 1786243351,
"offset": 0,
"limit": 20,
"totalCount": 100327,
"jobs": [
{
"title": "Scientifique principal des données en IA",
"excerpt": "Why Valtech?  We’retheexperience innovation company - a trusted partner to the world’s most recognized brands.",
"companyName": "name",
"companySlug": "valtech",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Senior"
],
"currency": null,
"locationRestrictions": [
"Canada"
],
"timezoneRestrictions": [
-8,
-7,
-6,
-5,
-4,
-3.5
],
"categories": [
"Data-Science",
"AI-Data-Science",
"Data-Scientist",
"Machine-Learning",
"Data",
"Responsable-Des-Données-Et-IA",
"Pesquisa-De-IA"
],
"parentCategories": [
"Data Science"
],
"description": "<p>Why <a href=\"https://himalayas.app/companies/valtech\">Valtech</a>? We’retheexperience innovation company - a trusted partner to the world’s most recognized brands. To our people we offer growth opportunities, a values-driven culture, international careers and the chance to shape the future of experience.</p><h3><strong>The opportunity</strong></h3><p>At <a href=\"https://himalayas.app/companies/valtech\">Valtech</a>, you’ll find an environment designed for continuous learning, meaningful impact, and professional growth. Whether you're pioneering new digital solutions, challenging conventional thinking or building the next generation of customer experiences, your work will help transform industries.</p><h3>We are proud of:</h3><ul>\n<li>The work we do and the innovation we drive</li>\n<li>Our values of share, care and dare</li>\n<li>A workplace culture that fosters creativity, diversity and autonomy</li>\n<li>Our borderless, global framework, which enables seamless collaboration</li>\n</ul><h3><strong>The role </strong></h3><p><strong>Please note, we are only accepting applicants from the provinces of Ontario and Québec for this role. </strong>For Québec-based candidates, fluency in English is necessary because the position entails collaboration with teams based in the rest of Americas and occasionally in Europe.</p><p>As a <strong>[JOB TITLE]</strong>, you are passionate about experience innovation and eager to push the boundaries of what’s possible. You bring<strong> [X YEARS]</strong> of experience, a growth mindset and a drive to make a lasting impact.</p><h3>You will thrive in this role if you are:</h3><ul>\n<li>A curious problem solver who challenges the status quo</li>\n<li>A collaborator who values teamwork and knowledge-sharing</li>\n<li>Excited by the intersection of technology, creativity and data</li>\n<li>Experienced in Agile methodologies and consulting (a plus)</li>\n</ul><h3>Role responsibilities</h3><ul>\n<li><strong>LIST KEY RESPONSIBILITIES SPECIFIC TO THE ROLE</strong></li>\n<li>Avoid terms such as “rockstar”, “superstar” or anything which may deter people who do not resonate with this type of language.</li>\n<li>Be mindful of descriptive words. According to research, the following words import ‘masculine’ characteristics, and are likely to deter female applicants: independent, lead, competitive, assertive, determined, analytical. Those words generally increasing the female response rate: responsible, connect, dedicated, support, sociable, conscientious</li>\n</ul><h3><strong>Must have qualifications</strong></h3><p>To be considered for this role, you must meet the following essential qualifications:</p><ul>\n<li>Must-have skills or experience to do the responsibilities that are objective </li>\n<li>The candidate should be able to answer YES or NO to each of these qualifications easily </li>\n<li>This should just be what’s absolutely necessary to perform the role responsibilities </li>\n<li>Example includes: Upper-intermediate English level</li>\n</ul><h3><strong>Nice to have qualifications </strong></h3><ul>\n<li>Nice-to-haves but not disqualifiers </li>\n<li>This can be the “dream list” of qualifications </li>\n<li>Can be more subjective than the minimum qualifications </li>\n<li>Example includes: Strong communication and presentation skills</li>\n<li>Example includes: Accountability, collaboration, and time-management skills</li>\n<li>Example includes: Strong desire to learn more about business every day</li>\n</ul><p><strong>If you do not meet all the listed qualifications or have gaps in your experience, we still encourage you to apply. At <a href=\"https://himalayas.app/companies/valtech\">Valtech</a>, we recognize that talent comes in many forms, and we value diverse perspectives and a willingness to learn.</strong></p><h3><strong>Commitment to reaching all kinds of people</strong></h3><p>We design experiences that work for all kinds of people - and that starts with our own teams. At <a href=\"https://himalayas.app/companies/valtech\">Valtech</a>, we’re intentional about building an inclusive culture where everyone feels supported to grow, thrive and achieve their goals. No matter your background, you belong here. Explore our Diversity &amp; Inclusion site to see how we’re creating a more equitable <a href=\"https://himalayas.app/companies/valtech\">Valtech</a> for all.</p><h3><strong>The benefits </strong></h3><p>This is a <strong>[EMPLOYMENT TYPE]</strong> position based in <strong>[COUNTRY / Location]</strong>. <strong>[IF SALARY RANGE IS REQUIRED</strong>] The offered salary range is <strong>[RANGE]</strong> annually, depending on experience and location.</p><p><a href=\"https://himalayas.app/companies/valtech\">Valtech</a> offers a comprehensive benefits package effective after three months of continuous service:</p><ul>\n<li>A <strong>comprehensive insurance plan</strong>, where you can choose the module that best suits your needs—Gold, Silver, or Bronze. The employer may contribute up to 80% of your coverage depending on the selected module. This plan includes <strong>short- and long-term disability coverage</strong>.</li>\n<li>\n<strong>Dialogue via Sun Life</strong> provides virtual healthcare services, allowing you to consult with a healthcare professional for emergencies, prescription renewals, and more. You also have access to the <strong>Employee and Family Assistance Program</strong>, as well as a <strong>complete mental health support program</strong>.</li>\n<li>A <strong>$500 Personal Spending Account</strong>, which can be used for healthcare reimbursements, gym memberships, public transit passes, office supplies, or contributions to your RRSP through <a href=\"https://himalayas.app/companies/valtech\">Valtech</a>.</li>\n<li>A <strong>retirement plan</strong> where <a href=\"https://himalayas.app/companies/valtech\">Valtech</a> will match 100% of your RRSP contributions through a Deferred Profit Sharing Plan (DPSP), up to a maximum of 4%. You can start contributing to your RRSP immediately, and to the DPSP after 3 months. The vesting of the DPSP will be after a 24 months of service. </li>\n<li>Access to a <strong>flexible vacation under <a href=\"https://himalayas.app/companies/valtech\">Valtech</a>'s policy</strong> to support your work-life balance, with 5 days available during your probation period and a prorated amount calculated for the remainder of the year.</li>\n<li>\n<strong>Personal Technology Reimbursement</strong> – $30/month for every employee-offered on day 1. </li>\n<li>We close during the <strong>winter holidays</strong> and <strong>offer flexible scheduling</strong> throughout the year, so you can enjoy those sunny Friday afternoons—provided your weekly hours are completed.</li>\n</ul><h3><strong>Your application process</strong></h3><p>Once you apply, our Talent Acquisition team will review your application. If your skills and experience align with the role, we’ll reach out for next steps.Your CV should cover key information on relevant experiences and expertise. We do not require information such as age, gender, marital status, or a headshot in your application. We review all candidates based on skills, experience, and potential.</p><p>⚠️ Beware of recruitment fraud: Only engage with official <a href=\"https://himalayas.app/companies/valtech\">Valtech</a> email addresses.</p><p>We are committed to inclusion and accessibility. If you need reasonable accommodations during the interview process, please either indicate it in your application or let your Talent Partner know.</p><h3><strong>About <a href=\"https://himalayas.app/companies/valtech\">Valtech</a></strong></h3><p><a href=\"https://himalayas.app/companies/valtech\">Valtech</a> is the experience innovation company that exists to unlock a better way to experience the world. By blending crafts, categories, and cultures, we help brands unlock new value in an increasingly digital world.</p><p>At the intersection of data, AI, creativity, and technology, we drive transformation for leading organizations, including L’Oréal, Mars, Audi, P&amp;G, Volkswagen Dolby, and more.</p><p>At <a href=\"https://himalayas.app/companies/valtech\">Valtech</a>, we don’t just talk about transformation. We make it happen. Our people are the heart of our success, and we foster a workplace where everyone has the support to thrive, grow and innovate.</p><p>Are you ready to create what’s next? Join us.</p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786243351,
"expiryDate": 1791427350,
"applicationLink": "https://himalayas.app/companies/valtech/jobs/scientifique-principal-des-donnees-en-ia",
"guid": "https://himalayas.app/companies/valtech/jobs/scientifique-principal-des-donnees-en-ia"
},
{
"title": "Cost Controller",
"excerpt": "Mission - Why we exist, what we do, and why we need you SpotMe is a leading B2B event platform that helps enterprises increase the impact of their events by delivering CRM-connected, high-quality experiences across in-person, virtual, hybrid events, and webinars.",
"companyName": "name",
"companySlug": "spotme",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Mid-level"
],
"currency": null,
"locationRestrictions": [
"Bulgaria"
],
"timezoneRestrictions": [
2
],
"categories": [
"Cost-Controller",
"Finance-Controller",
"Accounts-Payable-Specialist",
"Expense-Management",
"Finance-Operations",
"Cost-Control-Specialist",
"Cost-Control-Analyst",
"Senior-Cost-Controller",
"Cost-Controls-Analyst"
],
"parentCategories": [],
"description": "<p><strong>Mission - Why we exist, what we do, and why we need you</strong></p><p><a href=\"https://himalayas.app/companies/spotme\">SpotMe</a> is a leading B2B event platform that helps enterprises increase the impact of their events by delivering CRM-connected, high-quality experiences across in-person, virtual, hybrid events, and webinars. With a strong focus on life sciences, <a href=\"https://himalayas.app/companies/spotme\">SpotMe</a> powers Onomi: an HCP engagement product that enables medical and commercial teams to run impactful congresses, symposia, advisory boards, and webinars. Together, <a href=\"https://himalayas.app/companies/spotme\">SpotMe</a> and Onomi turn events into a company’s most effective engagement channel. </p><p>This position is the ideal role for aspiring finance talents, including AP Analysts/Specialists, Junior Accountants, Billing Analysts, but not limited to, who want to build a strong foundation in cost control and business partnership within a SaaS environment. Detail-oriented and proactive, you will thrive in a fast-moving, service-driven organization where rigor and accountability matter. You will develop hands-on expertise in Event Services cost validation, invoice and expense control, and cross-functional collaboration, while learning how to challenge assumptions and ask the right questions with confidence and professionalism. </p><p>As a Cost Controller, you will be responsible for controlling, validating, and booking all finance-related activities linked to the Event Services team, ensuring that: </p><ul>\n<li>Event Services costs are accurate, justified, and compliant</li>\n<li>Logged hours, invoices, and expenses are validated against supporting evidence</li>\n<li>Finance acts as a strong, credible business partner, able to challenge the Event Services team and external suppliers when needed</li>\n</ul><p>You will report to the Accounting Manager, and will : </p><ul>\n<li>Audit and validate Event Services hours (35%)</li>\n<li>Review and challenge logged hours from employees and associates by cross-checking against delivery evidence.</li>\n<li>Review, book, and validate Event Services-related invoices (20%)</li>\n<li>Ensure invoices match approved hours, contracts, and internal approvals before booking and payment.</li>\n<li>Manage Event Services travel and expense operations (20%)</li>\n<li>Organize travel for the Event Services teams and review related expenses to ensure policy compliance and cost efficiency.</li>\n<li>Act as the first line of Finance control for Event Services costs (15%)</li>\n<li>Identify discrepancies, ask the right questions, and follow up with internal teams and external suppliers to resolve issues.</li>\n<li>Support operational improvements and documentation (10%)</li>\n<li>Help strengthen processes, controls, and documentation to improve accuracy, consistency, and efficiency over time.</li>\n</ul><h3>Objectives - The problems you will solve</h3><p>First 30 Days - Understand &amp; Get Oriented</p><p>Build a <strong>deep understanding of Event Services operations and finance controls</strong>, while establishing credibility through rigor, curiosity, and professionalism.</p><h3>You will:</h3><ul>\n<li>Get familiar with our SaaS services model and delivery processes</li>\n<li>Learn how hours are logged by employees and associates and gain proficiency in key tools such as Xero, ApprovalMax, Salesforce, Mavenlink and Expensify</li>\n<li>Understand how Event Services-related hours, invoices, expenses and travel are processed</li>\n<li>Work closely with Finance and Event Services stakeholders to understand expectations and workflows</li>\n<li>Identify  <strong>at least 3 control or process improvement opportunities</strong>\n</li>\n</ul><p>By the end of 30 days, you’re comfortable navigating our systems and can explain how Event Services costs flow from delivery to payment.</p><p>Days 31-60 - Take Ownership, Start Challenging</p><p>Take <strong>operational ownership</strong> of Event Services finance processes and begin <strong>actively validating and challenging</strong> data.</p><h3>You will:</h3><ul>\n<li>Independently review and validate logged hours for employees and associates</li>\n<li>Review and book Event Services-related hours, invoices, and payments</li>\n<li>Support travel bookings and review related expenses</li>\n<li>Start asking questions and flagging inconsistencies when data doesn’t add up</li>\n</ul><p>By the end of 60 days, you’re managing Event Services finance operations with confidence and are seen as a reliable point of contact. You begin to act as the <strong>first line of control</strong> for Event Services costs.</p><p>Days 61-90 - Strengthen Controls &amp; Be a Finance Partner</p><p>Move from execution to <strong>operational excellence and continuous improvement</strong>, while being recognized as a <strong>trusted finance partner</strong>.</p><h3>You will:</h3><ul>\n<li>Confidently challenge discrepancies with internal teams and external suppliers</li>\n<li>Help improve validation rules, documentation, and operational processes</li>\n<li>Support month-end activities related to Event Services costs</li>\n<li>Build strong working relationships across Finance and Event Services</li>\n</ul><p>By the end of 90 days, you’re operating independently, adding structure and rigor to Event Services finance operations, and acting as a trusted partner to the business.</p><p>End of 90 Days - Fully Successful in Role</p><h3>After the 90th day, the Cost Controller:</h3><ul>\n<li>Operates <strong>independently</strong>\n</li>\n<li>Challenges confidently and professionally</li>\n<li>Maintains clean, compliant Event Services cost records</li>\n<li>Is viewed as <strong>firm but fair</strong> by the Event Services team and the suppliers</li>\n<li>Contributes actively to improving finance operations</li>\n</ul><h3>What you need to be great at:</h3><ul>\n<li>Maturity and confidence, even at a junior level.</li>\n<li>Ability to challenge constructively: you are comfortable asking difficult questions and pushing back when something doesn’t add up, while remaining calm, factual, and respectful with all stakeholders.</li>\n<li>High attention to detail: you are highly skilled in thoroughly and consistently reviewing data, spot inconsistencies, and follow through until issues are fully resolved. </li>\n<li>Strong sense of ethics and fairness: You are able to make sound judgment when balancing control, pragmatism, and business needs - especially in ambiguous situations.</li>\n<li>Organized, reliable, and consistent: You are able to manage recurring operational tasks reliably, maintain clear documentation, and work within established controls while helping improve them over time.</li>\n<li>Ownership and Accountability: You take responsibility for outcomes, not just tasks. You follow issues through to resolution and ensure commitments are met without needing constant follow-up.</li>\n<li>Comfortable working cross-functionally: you are a strong collaborator across departments, able to partner and communicate with both finance and non-finance stakeholders.</li>\n</ul><p><strong>What we want to hear about/What we are most curious about:</strong></p><ul>\n<li>A situation where you had to challenge numbers or data that didn’t add up, even if it was uncomfortable - and how you handled the discussion.</li>\n<li>How you stay rigorous and organized when dealing with operational, detail-heavy work.</li>\n<li>Your experience working with time tracking, invoices, expenses, or operational finance processes, even in an internship, junior role, or non-traditional setting.</li>\n<li>How you communicate with non-finance stakeholders and keep discussions factual, calm, and constructive.</li>\n</ul><p><a href=\"https://himalayas.app/companies/spotme\">SpotMe</a> recruits, compensates, and promotes regardless of race, color, religion, gender, gender identity or expression, sexual orientation, national origin, genetics, disability, age, parental status, or veteran status.</p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786243161,
"expiryDate": 1791427160,
"applicationLink": "https://himalayas.app/companies/spotme/jobs/cost-controller",
"guid": "https://himalayas.app/companies/spotme/jobs/cost-controller"
},
{
"title": "EverHealth - Revenue Cycle Management (RCM) Manager ( Remote, US)",
"excerpt": "AtEverCommerce[Nasdaq: EVCM], we are on a mission to digitally transform the service economy with tailored, end-to-end SaaS solutions that simplify and empower the lives of our 725,000+ customers.",
"companyName": "name",
"companySlug": "evercommerce",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": 60000,
"maxSalary": 70000,
"salaryPeriod": "annual",
"seniority": [
"Manager"
],
"currency": "USD",
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"Revenue-Cycle-Management",
"Healthcare-Administration",
"Claims-Management",
"Denial-Management",
"Healthcare-Operations",
"Revenue-Cycle-Management-Manager",
"Revenue-Cycle-Manager",
"Revenue-Cycle-Operations-Manager"
],
"parentCategories": [],
"description": "<div><p>At<a href=\"https://himalayas.app/companies/evercommerce\">EverCommerce</a>[Nasdaq: EVCM], we are on a mission to digitally transform the service economy with tailored, end-to-end SaaS solutions that simplify and empower the lives of our 725,000+ customers. As a leading service commerce platform, our modern digital and mobile applications create predictable, informed, and convenient experiences between customers and their service professionals in the areas of Home &amp; Field Services, Health Services, and Wellness industries.</p></div><div>\n<p>We are building an extraordinary company and looking for talented, energetic, and motivated people to join our team. You can learn more about our Company, Culture and Values here:</p>\n<p>We are looking for a<b>Revenue Cycle Management (RCM) Manage</b>r is responsible for leading the organization’s revenue cycle operations with a focus on accounts receivable optimization, denial management, claims resolution, and overall client financial performance. This role provides leadership to the Claims Management Specialist team and partners with Service Managers, BPO partners, and Operations to improve client health, maximize reimbursement, and drive operational excellence.</p>\n</div><p>The RCM Manager provides strategic leadership for the Claims Management Specialist team by establishing priorities, driving performance, and ensuring the team delivers actionable insights that improve client financial outcomes. While Claims Management Specialists are responsible for investigating claims, identifying root causes, and recommending solutions, the RCM Manager is accountable for working with leadership on the strategic direction, removing operational barriers, aligning resources, and ensuring recommendations are executed to achieve measurable improvements in revenue cycle performance.</p><h3>Key Responsibilities</h3><h3>Leadership &amp; Team Management</h3><ul>\n<li>Lead, mentor, and develop the Claims Management Specialist team.</li>\n<li>Establish team goals, performance expectations, and professional development plans.</li>\n<li>Monitor productivity, quality, and service levels to ensure operational excellence.</li>\n<li>Foster a culture of accountability, collaboration, continuous learning, and data-driven decision making.</li>\n<li>Conduct performance reviews, coaching sessions, and career development planning.</li>\n</ul><h3>Strategic Leadership &amp; Accountability</h3><ul>\n<li>Establish the strategic vision and priorities for the Claims Management Specialist team in alignment with organizational and client objectives.</li>\n<li>Own revenue cycle performance by ensuring the team focuses on the highest-impact opportunities for revenue recovery and operational improvement.</li>\n<li>Translate analytical findings into actionable business strategies and operational initiatives.</li>\n<li>Prioritize work based on client health, financial impact, payer trends, and organizational goals.</li>\n<li>Remove barriers that prevent successful execution of team recommendations.</li>\n<li>Hold the team accountable for delivering measurable improvements in key revenue cycle metrics while empowering specialists to determine the most effective analytical approach and claim resolution strategies.</li>\n<li>Serve as the primary escalation point for complex reimbursement issues, systemic payer challenges, and cross-functional operational concerns.</li>\n<li>Balance day-to-day operational priorities with long-term strategic initiatives to improve scalability, efficiency, and client outcomes.</li>\n</ul><h3>Revenue Cycle Strategy &amp; Performance</h3><ul>\n<li>Develop and execute strategies to improve revenue cycle performance across assigned client portfolios.</li>\n<li>Monitor organizational and client-level performance against established KPIs.</li>\n<li>Identify trends impacting reimbursement and implement corrective action plans.</li>\n<li>Provide strategic recommendations to senior leadership regarding revenue cycle optimization.</li>\n<li>Drive initiatives that improve cash flow, reduce aging accounts receivable, and increase reimbursement.</li>\n</ul><h3>Claims Management Oversight</h3><p>Provide oversight and direction for the Claims Management Specialist team responsible for:</p><ul>\n<li>Complex claims resolution</li>\n<li>Root cause analysis of denied and unpaid claims</li>\n<li>Payer trend analysis</li>\n<li>Practice workflow analysis</li>\n<li>Revenue recovery opportunities</li>\n<li>Escalation of systemic reimbursement issues</li>\n</ul><p>Ensure recommendations developed by the team result in measurable operational improvements.</p><h3>Denial Management &amp; Revenue Integrity</h3><ul>\n<li>Oversee organizational denial management strategy.</li>\n<li>Review denial trends and identify systemic opportunities for improvement.</li>\n<li>Partner with operational leaders to implement denial prevention initiatives.</li>\n<li>Ensure timely escalation of payer issues and reimbursement challenges.</li>\n<li>Monitor effectiveness of corrective action plans.</li>\n</ul><h3>Client Health &amp; Operational Partnership</h3><ul>\n<li>Partner with Service Managers to improve client financial performance and overall client health.</li>\n<li>Participate in client business reviews and operational performance meetings.</li>\n<li>Support initiatives that improve client retention and revenue optimization.</li>\n<li>Provide executive-level reporting and recommendations on revenue cycle performance.</li>\n</ul><h3>BPO Oversight &amp; Operational Excellence</h3><ul>\n<li>Provide leadership for BPO performance related to revenue cycle functions.</li>\n<li>Ensure consistent claim resolution practices across internal and outsourced teams.</li>\n</ul><h3>Analytics &amp; Reporting</h3><p>Develop and monitor dashboards and performance reporting for key revenue cycle metrics, including:</p><ul>\n<li>Accounts Receivable &gt;90 Days</li>\n<li>Days Revenue Outstanding (DRO)</li>\n<li>Denial Rate</li>\n<li>Clean Claim Rate</li>\n<li>Net Collection Rate</li>\n<li>Cash Collections</li>\n<li>Aging A/R</li>\n<li>Appeal Success Rate</li>\n<li>Payer Performance Trends</li>\n<li>Client Health (RAG Status)</li>\n</ul><p>Use analytics to prioritize improvement initiatives and communicate performance to leadership.</p><h3>Process Improvement &amp; Innovation</h3><ul>\n<li>Lead continuous improvement initiatives across revenue cycle operations.</li>\n<li>Identify workflow inefficiencies and implement scalable solutions.</li>\n<li>Collaborate with Technology and Product teams to enhance reporting and automation.</li>\n<li>Standardize best practices across clients and operational teams.</li>\n<li>Support implementation of new revenue cycle technologies and process enhancements.</li>\n</ul><h3>Compliance &amp; Industry Knowledge</h3><ul>\n<li>Ensure compliance with payer guidelines, HIPAA, CMS regulations, and organizational policies.</li>\n<li>Maintain current knowledge of reimbursement methodologies and industry trends.</li>\n<li>Support audit readiness and quality assurance initiatives.</li>\n</ul><h3><b>Skills and Experienceneeded for success in this role:</b></h3><ul>\n<li>Bachelor’s degree in Healthcare Administration, Business, Finance, or related field (or equivalent experience).</li>\n<li>7+ years of Revenue Cycle Management experience.</li>\n<li>3+ years of leadership experience managing revenue cycle or accounts receivable teams.</li>\n<li>Deep expertise in:<ul>\n<li>Claims management</li>\n<li>Denial management</li>\n<li>Accounts receivable</li>\n<li>Revenue cycle analytics</li>\n<li>Payer reimbursement methodologies</li>\n<li>Healthcare operations</li>\n</ul>\n</li>\n<li>Strong analytical, reporting, and problem-solving skills.</li>\n<li>Experience leading cross-functional initiatives and influencing stakeholders.</li>\n</ul><h3>Preferred</h3><ul>\n<li>Experience working with outsourced (BPO) revenue cycle operations.</li>\n<li>Experience supporting multi-client healthcare organizations.</li>\n<li>Experience with healthcare analytics platforms, BI reporting, and revenue cycle dashboards.</li>\n</ul><p><b>Where:</b><br>The<a href=\"https://himalayas.app/companies/evercommerce\">EverCommerce</a>team is distributed globally, with teams inthe U.S., Canada, the U.K., Jordan, New Zealand, and Australia. With a widely distributed team, we are used to working remotely across different time zones. This role can be based anywhere in theUnited States– ifyou’reclose to one of our offices, we can set you up in-office or you can work 100% remotely. Please note that you must be eligible to work without sponsorship to qualify for this position, and this role may require travel to our Corporate Headquarters in Denver, Colorado, or toother office locations around North America.</p><div>\n<div><p><b>Benefits and Perks</b>(JUST U.S.):</p></div>\n<div><ul><li><p>Flexibility to work where/how you want within your country of employment – in-office, remote, or hybrid</p></li></ul></div>\n<div><ul><li><p>Continued investment in your professional development</p></li></ul></div>\n<div><ul><li><p>Day 1 access to a robust health and wellness benefits package, including an annual wellness stipend.</p></li></ul></div>\n<div><ul><li><p>401k with up to a 4% match and immediate vesting</p></li></ul></div>\n<div><ul><li><h3>Flexible and generous (FTO) time-off</h3></li></ul></div>\n<div><ul><li><h3>Employee Stock Purchase Program</h3></li></ul></div>\n</div><div><p><b>Compensation:</b>The target base compensation for this positionis $60,000 to $70,000 USD ayear in mostUSlocations. Final offer amounts aredeterminedby multiple factors including location,local market variances, andcandidate experience andexpertise,and may vary from the amounts listed above.</p></div><div><div><div><div><div><div><div><p><a href=\"https://himalayas.app/companies/evercommerce\">EverCommerce</a> is an equal opportunity employer and we value diversity at our company. We do not discriminate on the basis of race, religion, color, national origin, gender identity, sexual orientation, age, marital status, veteran status, or disability status. We look forward to reviewing your credentials and getting to know more about your experience!</p></div></div></div></div></div></div></div><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242829,
"expiryDate": 1791426829,
"applicationLink": "https://himalayas.app/companies/evercommerce/jobs/everhealth-revenue-cycle-management-rcm-manager-remote-us",
"guid": "https://himalayas.app/companies/evercommerce/jobs/everhealth-revenue-cycle-management-rcm-manager-remote-us"
},
{
"title": "Product Designer (Figma)",
"excerpt": "Product Designer (Figma)Are you a talented designer with a passion for product management?",
"companyName": "name",
"companySlug": "codekeeper",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": 10000,
"maxSalary": 100000,
"salaryPeriod": "annual",
"seniority": [
"Mid-level"
],
"currency": "USD",
"locationRestrictions": [
"Indonesia"
],
"timezoneRestrictions": [
7,
8,
9
],
"categories": [
"Product-Designer",
"UI-Designer",
"UX-Designer",
"Visual-Designer",
"Product-Design",
"Product-Designer-(UI-UX)",
"Product-UX-Designer",
"UX-Product-Designer",
"Digital-Product-Designer"
],
"parentCategories": [
"Design"
],
"description": "<h3>Product Designer (Figma)</h3><p>Are you a talented designer with a passion for product management? Do you enjoy working in fast-paced, evolving environments where your ideas and decisions directly influence outcomes? If you’re motivated by ownership and the opportunity to make a real impact, this could be the perfect role for you.</p><p><a href=\"https://himalayas.app/companies/codekeeper\">Codekeeper</a> is accepting applications over the next two months and will appoint the successful candidate as soon as we find the right fit.</p><h3>About the Role</h3><p>As a designer, your main focus will be transforming customer needs into user journeys and creating visually appealing and intuitive interfaces. Your design skills will play a vital role in turning ideas into tangible products that our development team will bring to life.</p><h3>What You’ll Be Doing</h3><ul>\n<li><p>Translate customer needs into user journeys and design beautiful and intuitive interfaces.</p></li>\n<li><p>Collaborate with the Product Manager and/or Creative Director to conduct research, design, and prototype new user experiences.</p></li>\n<li><p>Develop user cases, scenarios, wireframes, prototypes, and mockups for screens and flows.</p></li>\n<li><p>Create visual assets and document design guidelines for implementation.</p></li>\n<li><p>Present and effectively communicate designs and deliverables to peers and executives.</p></li>\n</ul><h3>Why <a href=\"https://himalayas.app/companies/codekeeper\">Codekeeper</a>?</h3><p><a href=\"https://himalayas.app/companies/codekeeper\">Codekeeper</a> was founded by tech industry professionals to revolutionize software escrow for the cloud era. We offer state-of-the-art software escrow solutions that mitigate third-party risks in business operations. As a remote-first company with a central office in The Hague, we prioritize a healthy, resilient organization to support the development of our robust app.</p><p>🌐 </p><h3>What You Can Expect</h3><ul>\n<li><h3>Passionate and fun-loving colleagues</h3></li>\n<li><p>Startup mindset with ample opportunities for growth</p></li>\n<li><h3>Regular team activities and gatherings</h3></li>\n<li><p>Comprehensive onboarding process with a dedicated ramp-up period</p></li>\n<li><p>A supportive team that values open communication and direct feedback</p></li>\n<li><p>A chance to excel in your career and make a difference</p></li>\n</ul><h3>About You</h3><ul>\n<li><p>Proficient copywriting skills in English.</p></li>\n<li><p>Strong understanding of color theory and typography.</p></li>\n<li><p>Ability to thrive in a fast-paced, deadline-driven environment.</p></li>\n<li><p>Dedication, enthusiasm, and a sense of humor.</p></li>\n<li><p>Access to a Mac with Figma (or preference for this design tool).</p></li>\n</ul><h3>Additional Requirements</h3><ul>\n<li><h3>Analysis of user journeys.</h3></li>\n<li><p>Working with design systems and symbol libraries.</p></li>\n</ul><h3>Additional Info</h3><ul>\n<li>Remote</li>\n<li>Join us to shape the future of software escrow!</li>\n</ul><h3>How to Apply</h3><p>Please send an application that speaks directly to how you would like to fill this position. There are no right answers or expectations. Show us your role in our company’s future and our role in yours. Address some of the work we do. Introduce yourself as a colleague. Feel free to respond in either Dutch or English.</p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242826,
"expiryDate": 1791426825,
"applicationLink": "https://himalayas.app/companies/codekeeper/jobs/product-designer-figma-8862593472",
"guid": "https://himalayas.app/companies/codekeeper/jobs/product-designer-figma-8862593472"
},
{
"title": "1225 - 398PTN | Azure Migration Engineer",
"excerpt": "Azure Migration Engineer - Portugal (Remote)Our ClientOur client is a technology consulting company with strong expertise in digital transformation, covering areas such as software development, infrastructure, data, QA, and low-code solutions.",
"companyName": "name",
"companySlug": "talentcross",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Mid-level"
],
"currency": null,
"locationRestrictions": [
"Portugal"
],
"timezoneRestrictions": [
-1,
0
],
"categories": [
"Azure-Migration-Engineer",
"Cloud-Migration",
"Infrastructure-Engineering",
"Cloud-Architecture",
"Azure-Engineering",
"Azure-Network-Engineer",
"Microsoft-Azure-Engineer",
"Azure-Cloud-Engineer",
"Cloud-Migration-Engineer",
"Azure-Engineer"
],
"parentCategories": [],
"description": "<h3><strong>Azure Migration Engineer - Portugal (Remote)</strong></h3><h3><strong>Our Client</strong></h3>Our client is a <strong>technology consulting company</strong> with strong expertise in <strong>digital transformation</strong>, covering areas such as software development, infrastructure, data, QA, and low-code solutions. <strong>They support clients across multiple industries</strong> by delivering scalable, high-quality tech solutions. The company has a solid presence in Portugal and operates internationally.<br><br><h3><strong>Responsibilities:</strong></h3><ul>\n<li><p><strong>Assess existing environments</strong>, including on-prem infrastructure, servers, applications, dependencies, networking, storage, and databases, to define a robust migration approach.</p></li>\n<li><p>Conduct <strong>discovery and dependency analysis</strong> across applications, services, and data assets.</p></li>\n<li><p><strong>Define and apply the most suitable migration strategy</strong>, such as <strong>lift &amp; shift, refactoring, re-architecting, or rebuilding</strong>.</p></li>\n<li><p><strong>Design the target Azure architecture</strong>, covering networking, identity, security, compute, storage, high availability, and <strong>disaster recovery (DR)</strong>.</p></li>\n<li><p>Leverage <strong>Microsoft migration tools</strong> (e.g., <strong>Azure Migrate, Azure Site Recovery, Database Migration Service</strong>) as well as third-party solutions when required.</p></li>\n<li><p>Develop and maintain <strong>automation and Infrastructure as Code (IaC)</strong> for provisioning using <strong>Terraform, ARM, Bicep, PowerShell, or Azure CLI</strong>.</p></li>\n<li><p><strong>Plan and execute migration pilots and tests</strong> to validate functionality before full cutover.</p></li>\n<li><p><strong>Manage cutover activities</strong>, data migration, synchronization, and downtime minimization.</p></li>\n<li><p>After migration, <strong>monitor performance</strong>, optimize costs, and ensure <strong>security, compliance, and stability</strong>.</p></li>\n<li><p><strong>Document all project phases</strong>, including runbooks, playbooks, and rollback strategies.</p></li>\n<li><p><strong>Coordinate with cross-functional teams</strong> (infrastructure, networking, security, applications, and business stakeholders) and support overall project governance.</p></li>\n</ul><h3><strong>Technical Requirements:</strong></h3><ul>\n<li><p><strong>Proven hands-on experience with Azure</strong>, including <strong>Virtual Machines, Azure SQL / Managed Instances, Azure Storage, VNets, NSGs, ExpressRoute / VPN, and Azure AD / identity services</strong>.</p></li>\n<li><p>Experience with <strong>Azure migration tools</strong>, such as <strong>Azure Migrate, Azure Site Recovery, and Database Migration Service</strong>.</p></li>\n<li><p>Strong knowledge of <strong>cloud networking, security, governance, and compliance</strong>.</p></li>\n<li><p>Proficiency in <strong>automation and IaC</strong>, using <strong>Terraform, ARM, Bicep, PowerShell, and Azure CLI</strong>.</p></li>\n<li><p>Ability to <strong>analyze infrastructure, performance bottlenecks, dependencies, and migration-related issues</strong>.</p></li>\n<li><p>Solid understanding of <strong>backup, disaster recovery, and high availability (HA)</strong> solutions.</p></li>\n<li><p>Development experience using at least one framework, preferably <strong>.NET</strong>.</p></li>\n<li><p><strong>Languages (spoken and written): Portuguese and English (mandatory)</strong>.</p></li>\n</ul><h3><strong>Preferred Qualifications:</strong></h3><ul>\n<li><p><strong>Azure certifications</strong> such as <strong>AZ-104 (Administrator), AZ-305 (Solutions Architect)</strong>, or equivalent.</p></li>\n<li><p>Previous experience migrating <strong>physical servers, virtual machines, or containers</strong> to Azure.</p></li>\n<li><p>Background working in <strong>hybrid environments</strong> (on-prem + cloud).</p></li>\n<li><p>Familiarity with <strong>agile methodologies or project management frameworks</strong> (e.g., Scrum, Kanban).</p></li>\n<li><p>Strong communication skills to <strong>present risks, plans, results, and technical decisions</strong> to non-technical stakeholders.</p></li>\n<li><p>Experience with <strong>post-migration monitoring tools</strong>, such as <strong>Azure Monitor, Log Analytics, and Application Insights</strong>.</p></li>\n</ul><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242819,
"expiryDate": 1791426818,
"applicationLink": "https://himalayas.app/companies/talentcross/jobs/1225-398ptn-azure-migration-engineer",
"guid": "https://himalayas.app/companies/talentcross/jobs/1225-398ptn-azure-migration-engineer"
},
{
"title": "AI Product Manager",
"excerpt": "AI Product Manager – Conversational AI (Voice & NLU)Our client, a pioneer in innovative financial solutions, is seeking an AI Product Manager – Conversational AI to lead the strategic development and deployment of voice-based AI solutions.",
"companyName": "name",
"companySlug": "pm-consulting",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Senior"
],
"currency": null,
"locationRestrictions": [
"Philippines"
],
"timezoneRestrictions": [
8
],
"categories": [
"AI-Product-Management",
"Conversational-AI",
"Voice-AI",
"Product-Management",
"NLP-Product-Management",
"AI-Product-Manager",
"AI-Product-Manager-Lead",
"AI-ML-Product-Manager",
"AI-Product-Management-Jobs",
"Artificial-Intelligence-Product-Management",
"Senior-AI-Product-Manager",
"AI-Product-Lead"
],
"parentCategories": [
"Product"
],
"description": "<h3>AI Product Manager – Conversational AI (Voice &amp; NLU)</h3><p>Our client, a pioneer in innovative financial solutions, is seeking an <strong>AI Product Manager – Conversational AI</strong> to lead the strategic development and deployment of voice-based AI solutions. This role serves as an organization-wide leader, owning the vision for automated customer interactions and driving the adoption of sophisticated voice bot technology. The ideal candidate blends technical NLP expertise with product leadership to transform customer experience through automation.</p><h3>Key Responsibilities</h3><h4><strong>Product Strategy &amp; Roadmap Ownership</strong></h4><ul>\n<li>\n<strong>Strategic Vision</strong>: Define and own the long-term product vision and roadmap for voice-based conversational AI solutions, specifically leveraging <strong>Google Dialogflow</strong>.</li>\n<li>\n<strong>End-to-End Delivery</strong>: Lead the full product lifecycle from initial ideation and requirements gathering to deployment, scaling, and continuous optimization.</li>\n<li>\n<strong>Success Metrics</strong>: Define project scope and success metrics (e.g., containment rates, sentiment accuracy) to track the business impact of AI deployments.</li>\n</ul><h4><strong>Technical Oversight &amp; Innovation</strong></h4><ul>\n<li>\n<strong>NLU Configuration</strong>: Provide hands-on guidance on <strong>Dialogflow CX/NLU</strong> configurations, including the design of intents, entities, and complex fulfillment logic.</li>\n<li>\n<strong>Technical Guidance</strong>: Oversee data processing, model development, and deployment (MLOps) to ensure robust and scalable AI performance.</li>\n<li>\n<strong>Cloud Architecture</strong>: Navigate cloud-based data architectures to ensure seamless integration of VoiceBOTs into existing ecosystem infrastructures.</li>\n</ul><h4><strong>Stakeholder &amp; Team Leadership</strong></h4><ul>\n<li>\n<strong>Cross-Functional Management</strong>: Lead a specialized team of AI specialists, data scientists, and QA engineers to deliver high-quality conversational experiences.</li>\n<li>\n<strong>Business Alignment</strong>: Work closely with Operations, Collections, CRM, and CX teams to translate operational pain points into automated AI workflows.</li>\n<li>\n<strong>Advocacy</strong>: Act as the internal champion for AI, educating stakeholders on the capabilities and limitations of conversational technologies.</li>\n</ul><h3>Requirements</h3><h4><strong>Experience &amp; Education</strong></h4><ul>\n<li>\n<strong>Professional Tenure</strong>: Minimum of 3<strong>+ years of work experience</strong> specifically within the AI field.</li>\n<li>\n<strong>AI/ML Foundatons</strong>: Solid understanding of Machine Learning, Deep Learning, and Natural Language Processing (NLP) methodologies.</li>\n<li>\n<strong>Lifecycle Knowledge</strong>: Demonstrated experience in defining project scope, objectives, and technical deployment (MLOps).</li>\n</ul><h4><strong>Technical Skills &amp; Certifications</strong></h4><ul>\n<li>\n<strong>Cloud Platforms</strong>: Familiarity with major cloud providers (<strong>GCP, Azure, or AWS</strong>).</li>\n<li>\n<strong>Preferred Credentials</strong>: Fundamental-level certifications such as <strong>Azure AI Fundamentals (AI-900)</strong> or GCP equivalents are highly considered.</li>\n<li>\n<strong>Tooling</strong>: Expertise in <strong>Dialogflow CX</strong> or similar Conversational AI platforms.</li>\n</ul><h4><strong>Core Competencies</strong></h4><ul>\n<li>\n<strong>Leadership</strong>: Proven ability to manage cross-functional technical teams in a fast-paced environment.</li>\n<li>\n<strong>Communication</strong>: Ability to bridge the gap between complex AI technicalities and business-centric outcomes.</li>\n<li>\n<strong>Agility</strong>: A proactive mindset capable of navigating the rapidly evolving landscape of Generative and Conversational AI.</li>\n</ul><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242813,
"expiryDate": 1791426813,
"applicationLink": "https://himalayas.app/companies/pm-consulting/jobs/ai-product-manager",
"guid": "https://himalayas.app/companies/pm-consulting/jobs/ai-product-manager"
},
{
"title": "Senior Software Engineer (Flask/React) - Remote, Latin America",
"excerpt": "Bluelight is a leading software consultancy dedicated to designing and developing innovative technology that enhances users' lives.",
"companyName": "name",
"companySlug": "bluelight-consulting",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Senior"
],
"currency": null,
"locationRestrictions": [
"Panama"
],
"timezoneRestrictions": [
-5
],
"categories": [
"Software-Engineer",
"Fullstack-Development",
"Python-Development",
"React",
"Software-Engineering",
"Remote-Senior-Backend-Engineer",
"Remote-Senior-Full-Stack-Developer",
"Senior-Full-Stack-Engineer-(JavaScript-Python)",
"Senior-Full-Stack-Engineer-(React-Node.Js)",
"Senior-Python-Software-Engineer"
],
"parentCategories": [
"Developer"
],
"description": "<div>Bluelight is a leading software consultancy dedicated to designing and developing innovative technology that enhances users' lives. With a steadfast commitment to delivering exceptional service to our clients, Bluelight excels in its focus on quality and customer satisfaction. Our mission is not only to create cutting-edge applications but also to foster a collaborative and enriching work environment where each team member can grow and thrive. With a presence across the United States and Central/South America, Bluelight is in an exciting phase of expansion, continually seeking exceptional talent to join its dynamic and diverse community.</div><div>We are looking for a skilled individual to join our rapidly growing team at Bluelight. This position is ideal for someone who thrives in a fast-paced, dynamic environment where everyone's opinions and efforts are valued and appreciated. You will have the opportunity to contribute to challenging and meaningful projects, developing high-quality applications that stand out in the market. We value continuous learning, personal growth, and hard work, offering a collaborative environment that promotes professional development. If you are passionate about software development and eager to be part of a growing software consultancy, we invite you to apply and join us on this exciting journey.</div><h3>Technical Qualifications</h3><ul>\n<li>Backend: 5+ years of experience with Python (Flask, SQLAlchemy, Celery) and building complex, service-oriented server logic.</li>\n<li>Frontend: Modern JavaScript/TypeScript development utilizing React for scalable single-page application (SPA) architectures.</li>\n<li>Data Access: Heavy experience with relational databases (PostgreSQL), data storage systems, and advanced data-access models.</li>\n</ul><h3>Core Responsibilities:</h3><ul>\n<li>Full-Stack Ownership: Architect, test, and ship end-to-end full-stack software solutions to fulfill complex financial reporting and data visualization needs.</li>\n<li>Optimization: Refactor existing software continuously using Agile methodologies to improve overall maintainability and speed.</li>\n<li>Collaboration: Partner with product managers and data engineering teams to safely extract, parse, and serve multi-billion-dollar private asset analytics.</li>\n</ul><div>Being a consultant in our team is a fun, challenging, and rewarding career choice. Your contributions are highly valued by clients, and the work you do often has a direct and significant impact on their business.</div><div>You will have the opportunity to work on a variety of projects for our incredible clients, which will accelerate your career growth. You’ll collaborate with modern technologies and work alongside some of the best professionals in the industry!</div><div>If you’re eager to be part of an exciting, challenging, and rapidly growing consultancy, we encourage you to apply. </div><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242813,
"expiryDate": 1791426812,
"applicationLink": "https://himalayas.app/companies/bluelight-consulting/jobs/senior-software-engineer-flask-react-remote-latin-america",
"guid": "https://himalayas.app/companies/bluelight-consulting/jobs/senior-software-engineer-flask-react-remote-latin-america"
},
{
"title": "TikTok Shop Growth Manager",
"excerpt": "Fabula is a fast-growing D2C coffee brand in the United States.",
"companyName": "name",
"companySlug": "scalejet",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Manager"
],
"currency": null,
"locationRestrictions": [
"Ukraine"
],
"timezoneRestrictions": [
2,
3
],
"categories": [
"TikTok-Shop-Growth-Manager",
"Affiliate-Marketing-Manager",
"Creator-Economy-Partnerships",
"D2C-ECommerce-Growth",
"Performance-Marketing-Manager",
"TikTok-Shop-Manager",
"TikTok-E-Commerce-Manager",
"TikTok-Shop-Director",
"TikTok-Shop-Specialist",
"TikTok-Shop-Marketing",
"Growth-Manager"
],
"parentCategories": [
"Growth"
],
"description": "<p>Fabula is a fast-growing D2C coffee brand in the United States. TikTok is our next major growth channel, and we're looking for someone to build and own it.</p><p>This role is responsible for our entire TikTok Shop growth engine - from affiliate recruitment and creator partnerships to content sourcing, campaign execution, and performance optimization.</p><p>You'll work directly with the founders to build a scalable creator ecosystem that drives measurable revenue, not just engagement.</p><p><strong>This is not a traditional influencer marketing or social media management role.</strong> We're looking for someone who understands TikTok Shop as a performance channel and knows how to scale affiliate and creator programs that generate GMV.</p><h3>What you'll own</h3><ul>\n<li>Build, manage, and scale our TikTok Shop Affiliate Program, including creator sourcing, vetting, onboarding, briefing, commission structures (Open Collaboration, Targeted, VIP), and ongoing relationship management</li>\n<li>High-volume creator and influencer outreach, gifting campaigns, negotiations, and partnership management</li>\n<li>Build and maintain a high-quality UGC pipeline, ensuring creators consistently produce content that can be repurposed for paid advertising (including Spark Ads and whitelisted content)</li>\n<li>Develop and execute our organic TikTok content strategy, including trends, posting cadence, creator collaborations, and community engagement</li>\n<li>Create FDA-compliant creator briefs and ensure all content aligns with platform and regulatory requirements</li>\n<li>Manage affiliate platform operations (Social Snowball, GRIN, Aspire, Modash, Insense, or similar)</li>\n<li>Analyze creator and affiliate performance using GMV, attributed orders, CAC, creator ROI, conversion rates, and other performance metrics</li>\n<li>Continuously test new outreach strategies, creator types, incentives, and partnership models to improve program performance</li>\n</ul><p><strong>Success in this role is measured by GMV growth, creator activation rates, attributed revenue, creator ROI, CAC, affiliate retention, and the ability to build a predictable pipeline of high-performing creators.</strong></p><h3>You are</h3><ul>\n<li>3–5+ years of experience managing TikTok creators, affiliates, or influencer programs for D2C/eCommerce brands or agencies</li>\n<li>You've personally built or managed a TikTok Shop affiliate program with measurable business results</li>\n<li>Experienced with TikTok Creator Marketplace and at least one affiliate platform such as Social Snowball, GRIN, Aspire, Modash, or Insense</li>\n<li>Comfortable managing high-volume outreach (50+ creator conversations per month) while tracking response rates and conversion through the funnel</li>\n<li>Strong written English - you write outreach messages, creator briefs, and partnership communications</li>\n<li>Performance-minded - you measure success in GMV, conversions, CAC, and creator ROI, not vanity metrics</li>\n<li>You use AI daily to improve outreach, creator research, briefing, content ideation, and operational efficiency. AI fluency is non-negotiable.</li>\n<li>Comfortable working closely with founders in a fast-paced environment and incorporating feedback quickly</li>\n<li>Highly organized and capable of managing multiple creator relationships simultaneously</li>\n</ul><h3>Bonus:</h3><ul>\n<li>Experience with Spark Ads and whitelisted content workflows</li>\n<li>Existing creator network within supplements, wellness, health, beauty, or lifestyle niches</li>\n<li>Understanding of FTC and FDA compliance requirements for influencer marketing</li>\n</ul><h3>Schedule</h3><ul>\n<li>Fully remote</li>\n<li>Minimum 6-hour overlap with US Eastern Time (10:00 AM–4:00 PM ET)</li>\n</ul><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242798,
"expiryDate": 1791426797,
"applicationLink": "https://himalayas.app/companies/scalejet/jobs/tiktok-shop-growth-manager",
"guid": "https://himalayas.app/companies/scalejet/jobs/tiktok-shop-growth-manager"
},
{
"title": "Nurse RA ESP-5",
"excerpt": "Eres enfermero/a?  ¿Te sientes motivado por la calidad y la seguridad del paciente?",
"companyName": "name",
"companySlug": "teladoc-health",
"companyLogo": "thumbnail_url",
"employmentType": "Part Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Mid-level"
],
"currency": null,
"locationRestrictions": [
"Spain"
],
"timezoneRestrictions": [
0,
1
],
"categories": [
"Nursing",
"Healthcare",
"Telehealth-Nursing",
"Remote-Healthcare",
"Health-Education",
"Clinical-Research"
],
"parentCategories": [],
"description": "<p>Eres enfermero/a? ¿Te sientes motivado por la calidad y la seguridad del paciente? ¿Te interesa una jornada que facilite la conciliación entre la vida laboral y familiar?</p><p><a href=\"https://himalayas.app/companies/teladoc-health\">Teladoc Health</a> International somos la marca líder en el mundo en asistencia sanitaria virtual. Nuestros servicios abarcan todo el espectro de necesidades de atención médica, desde simples hasta complejas. Conectamos a nuestros usuarios con la atención primaria, salud mental y experta.</p><p>Estamos ampliando nuestro equipo de enfermería. Tu misión será ayudar a los pacientes con diferentes patologías, realizando educación sanitaria para el manejo de su día a día, promoviendo la motivación al cambio de hábitos de vida saludables.</p><h3>Qué harás en tu día a día:</h3><ul>\n<li>Realizar encuestas sobre salud para recopilar datos útiles acerca del estado de salud y bienestar de los encuestados con el objetivo de comprender la salud en general, los factores que repercuten en cierta enfermedad, la opinión sobre los servicios médicos proporcionados y los factores de riesgo asociados con la salud del individuo, entre otros.</li>\n<li>Se trata de obtener una evaluación general acerca de la salud del cliente, teniendo en cuanta su historial médico pero completa.</li>\n<li>Recopilar los datos de salud de acuerdo con los estándares de calidad establecidos a nivel interno.</li>\n<li>Transcripción de información clara y ordenada, completa y comprensible.</li>\n<li>Ayudar a paciente con desconocimiento sobre sus antecedentes médicos.</li>\n</ul><h3>Qué ofrecemos:</h3><ul>\n<li>Contrato fijo discontinuo directamente por empresa.</li>\n<li><b>Incorporación en 07/09</b></li>\n<li>Jornada laboral <b>FLEXIBLE</b> de lunes a viernes de turno de mañana (9-15) o de tarde 15-21h (min 20 h/semana). <b>Nos adaptamos a tu disponibilidad.</b>\n</li>\n<li>Formación inicial y continuada.</li>\n<li>Posibilidad de desarrollarte en la empresa referente a nivel mundial en servicios.</li>\n<li><b>TELETRABAJO 100%</b></li>\n</ul><h3>Requisitos:</h3><ul>\n<li>Licenciatura/Grado en Enfermería.(Colegiatura en España)</li>\n<li>Experiencia de min. 6 meses en el ámbito sanitario.</li>\n<li>Habilidades informáticas nivel usuario.</li>\n</ul><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242782,
"expiryDate": 1791426781,
"applicationLink": "https://himalayas.app/companies/teladoc-health/jobs/nurse-ra-esp-5",
"guid": "https://himalayas.app/companies/teladoc-health/jobs/nurse-ra-esp-5"
},
{
"title": "Hubspot Commerce Specialist",
"excerpt": "Hubspot Commerce SpecialistPosition OverviewMarket My Market is a fast-growing marketing agency onboarding roughly 20 new clients per month and billing over $1M in recurring revenue monthly.",
"companyName": "name",
"companySlug": "market-my-market",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": 60000,
"maxSalary": 70000,
"salaryPeriod": "annual",
"seniority": [
"Mid-level"
],
"currency": "USD",
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"HubSpot-Commerce-Specialist",
"Accounts-Receivable-Specialist",
"Billing-Specialist",
"Finance-Operations",
"AR-Collections",
"Hubspot-Specialist",
"HubSpot-CRM-Specialist",
"Digital-Commerce-Specialist",
"HubSpot-Integration-Specialist",
"HubSpot-Consultant"
],
"parentCategories": [],
"description": "<h3>Hubspot Commerce Specialist</h3><h3>Position Overview</h3><p><a href=\"https://himalayas.app/companies/market-my-market\">Market My Market</a> is a fast-growing marketing agency onboarding roughly 20 new clients per month and billing over $1M in recurring revenue monthly. As we scale, we are hiring a full-time Hubspot Commerce Specialist to own the full billing and collections lifecycle. This role is responsible for processing subscriptions, payment links, and invoices in HubSpot Commerce, reconciling HubSpot against QuickBooks, communicating with clients on billing concerns and adjustments, and supporting forecasting, reporting, and process efficiency. This is a remote position, and the Specialist must be available to work Eastern Time Zone business hours.</p><h3>Key Responsibilities</h3><h3>Billing &amp; Payments</h3><ul>\n<li>Set up and manage recurring subscriptions in HubSpot Commerce</li>\n<li>Create and send payment links and generate invoices at scale</li>\n<li>Apply incoming payments and resolve failed or declined transactions</li>\n<li>Follow up on past-due balances and manage collections</li>\n<li>Process prorations, credits, refunds, upgrades, downgrades, and one-off charges accurately and on time</li>\n</ul><h3>Reconciliation &amp; Accuracy</h3><ul>\n<li>Reconcile HubSpot Commerce activity against QuickBooks to ensure transactions, payouts, and balances match</li>\n<li>Investigate and resolve discrepancies between platforms</li>\n<li>Maintain clean, accurate, audit-ready financial records</li>\n<li>Keep the receivables ledger current and reflective of real-time client activity</li>\n</ul><h3>Client Communication</h3><ul>\n<li>Serve as the point of contact for client billing questions, concerns, and disputes</li>\n<li>Communicate professionally and promptly to resolve billing issues</li>\n<li>Coordinate adjustments and payment arrangements while protecting the client relationship</li>\n<li>Partner with Client Experience Managers and leadership to resolve escalations</li>\n</ul><h3>Forecasting, Reporting &amp; Efficiency</h3><ul>\n<li>Support revenue forecasting and cash-flow projections</li>\n<li>Build and maintain AR reporting, including aging, and collections</li>\n<li>Deliver clear, accurate reports to leadership on a regular cadence</li>\n<li>Identify and implement efficiencies and automation to keep billing and reconciliation processes scalable as volume grows</li>\n</ul><h3>Qualifications</h3><ul>\n<li>Hands-on experience with the HubSpot Commerce platform, including processing subscriptions, payment links, and invoices (required)</li>\n<li>Proven experience reconciling billing platforms against QuickBooks</li>\n<li>4+ years in accounts receivable, billing, or a similar finance operations role</li>\n<li>Comfortable managing high transaction volume in a fast-paced, high-growth environment</li>\n<li>Strong written and verbal communication skills for client-facing interactions</li>\n<li>Meticulous attention to detail and strong organizational habits</li>\n<li>A process-improvement mindset with the ability to spot and fix inefficiencies</li>\n<li>Available to work full-time on Eastern Time Zone business hours</li>\n</ul><h3>Preferred Qualifications</h3><ul>\n<li>Experience in an agency or subscription/SaaS billing environment</li>\n<li>Familiarity with reporting or automation tools (e.g., advanced Excel/Sheets, BI dashboards)</li>\n<li>Exposure to month-end close and collaboration with an accounting team</li>\n</ul><h3>Location</h3><h3>This position is fully remote and we are only hiring candidates located in the following states: </h3><ul>\n<li>Alabama</li>\n<li>California</li>\n<li>Colorado</li>\n<li>Florida</li>\n<li>Georgia</li>\n<li>Illinois</li>\n<li>Indiana</li>\n<li>Iowa</li>\n<li>North Carolina</li>\n<li>New Jersey</li>\n<li>Nevada</li>\n<li>New York</li>\n<li>Maryland</li>\n<li>South Carolina</li>\n<li>Texas</li>\n<li>Washington</li>\n<li>Virginia</li>\n</ul><h3>Compensation &amp; Benefits</h3><ul>\n<li>$60,000 - $70,000 per year, salary based on experience</li>\n<li>PTO: 2 weeks per year</li>\n<li>Health insurance benefits</li>\n<li>401(k) plan (after 1 year of employment)</li>\n<li>Remote work opportunity</li>\n</ul><p>All emails will come from a @marketmymarket.com or @applytojob.com domain only. All other emails are fraudulent. We will never interview candidates via Microsoft Teams.</p><h3>Our Core Values</h3><ul>\n<li>Do What You Say</li>\n<li>Be Honest and Transparent</li>\n<li>Proactive, Not Reactive</li>\n<li>Be Thought-Leading</li>\n<li>Instill Trust Through Consistent Accountability</li>\n<li>Always Do Better, Always Be Better</li>\n<li>Do the Right Thing for Clients and MMM</li>\n</ul><p><a href=\"https://himalayas.app/companies/market-my-market\">Market My Market</a> is an equal opportunity employer and does not tolerate discrimination in employment on the basis of race, color, age, sex, sexual orientation, gender identity or expression, religion, disability, ethnicity, national origin, marital status, protected veteran status, genetic information, or any other legally protected classification or status.</p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242720,
"expiryDate": 1791426719,
"applicationLink": "https://himalayas.app/companies/market-my-market/jobs/hubspot-commerce-specialist-5700716476",
"guid": "https://himalayas.app/companies/market-my-market/jobs/hubspot-commerce-specialist-5700716476"
},
{
"title": "Researcher, Neurotechnology",
"excerpt": "About the RoleThis is a rare opportunity to join a small, fast-moving neurotechnology startup at the ground floor.",
"companyName": "name",
"companySlug": "clera",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": 80000,
"maxSalary": 120000,
"salaryPeriod": "annual",
"seniority": [
"Mid-level"
],
"currency": "USD",
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"Neuroscience-Research-Scientist",
"Neurorobotics-Specialist",
"PhD-Researcher-In-Neurobiology",
"Neuroscience-Research"
],
"parentCategories": [],
"description": "<h3>About the Role</h3><p>This is a rare opportunity to join a small, fast-moving neurotechnology startup at the ground floor. We're conducting groundbreaking research into brain health, human performance, and the nervous system — and we're looking for a hands-on Researcher to work directly at the intersection of neuroscience, technology, and medicine.</p><p>You'll operate cutting-edge non-invasive neurotechnology devices, work face-to-face with research participants, and help shape the studies that could redefine how we understand and support human health. Your work will have direct, visible impact on both the science and the company's direction.</p><p>This is a fully on-site role in Boston, MA. You should be comfortable being present and engaged in person, 6 days per week, 9am–6pm.</p><h3>What You'll Do</h3><ul>\n<li><p>Work directly with research participants during study sessions, prioritizing their safety and comfort while collecting high-quality data</p></li>\n<li><p>Operate, test, and maintain cutting-edge neurotechnology devices with precision and care</p></li>\n<li><p>Collect, organize, and analyze experimental data to support ongoing research initiatives</p></li>\n<li><p>Identify patterns in observations and translate findings into actionable insights</p></li>\n<li><p>Help improve research protocols, standard operating procedures, and tooling based on real-world experience in the lab</p></li>\n<li><p>Collaborate across neuroscience, engineering, medicine, and operations teams to solve complex, interdisciplinary problems</p></li>\n<li><p>Take ownership of foundational projects that shape the trajectory of the company</p></li>\n</ul><h3>What We're Looking For</h3><h3>Must-haves (dealbreakers):</h3><ul>\n<li><p>2+ years of experience in research, clinical, or laboratory environments — conducting studies, collecting data, or operating specialized equipment</p></li>\n<li><p>Demonstrated ability to work directly with human research participants or patients in clinical or medical settings</p></li>\n<li><p>Experience operating, troubleshooting, and maintaining specialized medical or scientific instruments</p></li>\n</ul><h3>Required skills &amp; background:</h3><ul>\n<li><p>Proficiency in experimental data collection, organization, and analysis using spreadsheets, databases, or statistical software</p></li>\n<li><p>Experience designing, documenting, or improving research protocols and SOPs</p></li>\n<li><p>Background in neuroscience, biology, psychology, engineering, medicine, or a related life sciences discipline</p></li>\n<li><p>Ability to identify patterns in experimental observations and communicate findings clearly</p></li>\n<li><p>Comfortable working in fast-paced, high-urgency environments with multiple concurrent priorities</p></li>\n</ul><h3>Nice to have:</h3><ul>\n<li><p>Experience with clinical trial design, regulatory compliance, or IRB processes</p></li>\n<li><p>Background in neurotechnology, brain-computer interfaces, or non-invasive neuromodulation</p></li>\n<li><p>Experience in sleep science, sleep disorders, or sleep medicine research</p></li>\n<li><p>Proficiency with data visualization or statistical software such as R, Python, or MATLAB</p></li>\n<li><p>Familiarity with laboratory information management systems (LIMS)</p></li>\n</ul><p>We care far more about demonstrated capability and genuine curiosity than specific credentials. Strong candidates may include recent graduates with hands-on research experience, clinical trial coordinators, neuroscience researchers, or data-driven problem solvers passionate about human health.</p><h3>Compensation &amp; Benefits</h3><ul>\n<li><p><strong>Salary:</strong> $80,000 – $120,000 USD annually, depending on experience</p></li>\n<li><p>Opportunity for significant early-stage ownership and career growth in a rapidly evolving field</p></li>\n<li><p><strong>Visa sponsorship:</strong> Not available — candidates must be authorized to work in the United States</p></li>\n</ul><h3>Location</h3><ul>\n<li><p><strong>On-site only</strong> — Boston, MA</p></li>\n<li><p>6 days per week, 9am–6pm in-person availability required</p></li>\n<li><p>Remote and hybrid arrangements are not available for this role</p></li>\n</ul><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242708,
"expiryDate": 1791426707,
"applicationLink": "https://himalayas.app/companies/clera/jobs/researcher-neurotechnology",
"guid": "https://himalayas.app/companies/clera/jobs/researcher-neurotechnology"
},
{
"title": "GDPR Compliance Consultant",
"excerpt": "Job Description Role Title: GDPR Compliance Consultant Department / Seat Name: TAC Reports To (LMA): TBDType: Contractor/1099/Project Based Pay Range: $100-$125/hr— About RSI Security RSI Security is a leading cybersecurity and compliance consulting firm helping organizations navigate complex regulatory and security requirements.",
"companyName": "name",
"companySlug": "rsi-security",
"companyLogo": "thumbnail_url",
"employmentType": "Contractor",
"minSalary": 100,
"maxSalary": 125,
"salaryPeriod": "hourly",
"seniority": [
"Senior"
],
"currency": "USD",
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"GDPR-Compliance",
"Privacy-Consulting",
"Data-Protection",
"Regulatory-Compliance",
"Privacy-Compliance",
"Senior-GDPR-Consultant",
"Data-Protection-Consultant"
],
"parentCategories": [],
"description": "<h3>Job Description </h3><p>Role Title: <strong>GDPR Compliance Consultant </strong></p><p>Department / Seat Name: TAC</p><h3>Reports To (LMA): TBD</h3><p>Type: Contractor/1099/Project Based</p><h3>Pay Range: $100-$125/hr</h3><h3>— </h3><h3>About <a href=\"https://himalayas.app/companies/rsi-security\">RSI Security</a> </h3><p><a href=\"https://himalayas.app/companies/rsi-security\">RSI Security</a> is a leading cybersecurity and compliance consulting firm helping organizations navigate complex regulatory and security requirements. Our consultants partner with clients across healthcare, life sciences, financial services, technology, manufacturing, and other regulated industries to build practical, scalable compliance programs that reduce risk while enabling business growth. </p><h3>Position Summary </h3><p>The GDPR Compliance Consultant serves as a trusted advisor responsible for helping organizations achieve and maintain compliance with the European Union General Data Protection Regulation (EU GDPR) and UK GDPR. </p><p>Working directly with executive leadership, legal counsel, privacy teams, IT, security, HR, and business stakeholders, this consultant conducts privacy assessments, develops compliance programs, prepares required documentation, and implements practical privacy governance processes. </p><p>The ideal candidate possesses deep knowledge of international privacy regulations, strong consulting experience, and the ability to translate complex legal requirements into actionable business controls. </p><h3>Primary Responsibilities </h3><ul>\n<li>Conduct GDPR and UK GDPR readiness assessments and gap analyses. ● Develop and implement GDPR compliance programs and remediation roadmaps. ● Prepare and maintain Records of Processing Activities (ROPA). </li>\n<li>Perform Data Protection Impact Assessments (DPIAs), Legitimate Interest Assessments (LIAs), and Transfer Impact Assessments (TIAs).</li>\n<li>Draft, review, and negotiate Data Processing Agreements (DPAs). ● Review privacy notices, consent mechanisms, cookie disclosures, and privacy documentation. </li>\n<li>Design and implement Data Subject Rights (DSAR) processes. </li>\n<li>Advise clients on international data transfer requirements including EU Standard Contractual Clauses (SCCs), UK IDTA/Addendum, and the EU-U.S. Data Privacy Framework. </li>\n<li>Assess third-party privacy risks and support vendor due diligence activities. ● Develop privacy policies, governance documentation, and operational procedures. ● Support organizations processing special category data, including healthcare and clinical research information. </li>\n<li>Provide guidance regarding Article 27 representative requirements and supervisory authority interactions. </li>\n<li>Deliver client workshops, executive presentations, and privacy awareness training. ● Collaborate with cybersecurity consultants to align privacy and security controls. ● Remain current on GDPR guidance, enforcement actions, and evolving privacy regulations. </li>\n</ul><h3>Required Qualifications </h3><h3>Education </h3><p>Bachelor's degree in Information Security, Privacy, Law, Business, Computer Science, Healthcare Administration, or a related field (or equivalent professional experience). </p><h3>Professional Experience </h3><ul>\n<li>Five (5) or more years of GDPR consulting or privacy compliance experience. ● Demonstrated experience implementing GDPR compliance programs. ● Experience conducting GDPR readiness assessments and gap analyses. ● Experience preparing and maintaining ROPA documentation. </li>\n<li>Experience performing DPIAs, LIAs, and TIAs. </li>\n<li>Experience drafting and reviewing Data Processing Agreements. ● Experience developing privacy governance programs. </li>\n<li>Experience advising executive leadership and client stakeholders. ● Experience supporting multinational organizations is preferred. </li>\n<li>Previous consulting experience strongly preferred. </li>\n</ul><h3>Technical Knowledge </h3><h3>Strong working knowledge of: </h3><h3>● EU GDPR </h3><h3>● UK GDPR </h3><ul>\n<li>Records of Processing Activities (ROPA) </li>\n<li>Data Protection Impact Assessments (DPIAs) </li>\n<li>Legitimate Interest Assessments (LIAs) </li>\n</ul><h3>● Transfer Impact Assessments (TIAs) </h3><h3>● Data Subject Rights (DSAR) </h3><h3>● Data Processing Agreements (DPAs) </h3><h3>● International Data Transfers </h3><ul>\n<li>EU Standard Contractual Clauses (SCCs) </li>\n</ul><h3>● UK IDTA/Addendum </h3><h3>● EU-U.S. Data Privacy Framework </h3><h3>● Vendor Risk Management </h3><h3>● Privacy by Design </h3><h3>● Privacy Governance Frameworks </h3><ul>\n<li>Article 27 Representative Requirements </li>\n</ul><h3>● Consent Management </h3><h3>● Privacy Notices </h3><h3>● Data Mapping </h3><h3>● Data Retention </h3><h3>● Special Category Data Processing </h3><h3>Preferred Industry Experience </h3><p>Experience supporting organizations within one or more of the following industries is highly desirable: </p><h3>● Healthcare </h3><h3>● Life Sciences </h3><h3>● Biotechnology </h3><h3>● Clinical Research </h3><h3>● Pharmaceutical </h3><h3>● Medical Device </h3><h3>● SaaS </h3><h3>● Technology </h3><p>Knowledge of the following is preferred: </p><h3>● ICH-GCP </h3><h3>● Clinical Trial Regulations </h3><h3>● Informed Consent Requirements </h3><h3>● HIPAA </h3><ul>\n<li>Processing of Special Category Health Data </li>\n</ul><h3>Preferred Certifications </h3><p>One or more of the following certifications is preferred: </p><h3>● CIPP/E </h3><h3>● CIPM </h3><h3>● CIPT </h3><h3>● ISO/IEC 27701 Lead Implementer </h3><h3>● ISO/IEC 27701 Lead Auditor </h3><h3>● ISO/IEC 27001 Lead Implementer </h3><h3>● ISO/IEC 27001 Lead Auditor </h3><h3>● Equivalent IAPP Privacy Certification </h3><h3>Core Competencies </h3><h3>● Privacy Consulting </h3><h3>● Regulatory Interpretation </h3><h3>● Risk Assessment </h3><h3>● Executive Communication </h3><h3>● Client Relationship Management </h3><h3>● Documentation Development </h3><h3>● Problem Solving </h3><h3>● Project Management </h3><h3>● Cross-functional Collaboration </h3><h3>● Presentation Skills </h3><h3>● Critical Thinking </h3><h3>● Attention to Detail </h3><h3>Success Measures </h3><p>Success in this role will be measured by the consultant's ability to: </p><ul>\n<li>Deliver GDPR consulting engagements on time and within scope. ● Produce high-quality compliance documentation requiring minimal revisions. ● Successfully guide clients toward GDPR compliance. </li>\n<li>Maintain high client satisfaction ratings. </li>\n<li>Identify privacy risks and recommend practical remediation strategies. ● Build trusted advisor relationships with executive stakeholders. </li>\n<li>Stay current with evolving privacy regulations and enforcement guidance. </li>\n</ul><h3>Top Roles &amp; Responsibilities </h3><ul>\n<li>Conduct GDPR and UK GDPR gap assessments and compliance reviews. ● Develop client privacy compliance programs and remediation roadmaps. ● Create and maintain GDPR documentation including ROPA, DPIAs, LIAs, TIAs, and DPAs. </li>\n<li>Advise clients on international data transfers and cross-border privacy requirements. ● Design processes supporting Data Subject Rights Requests (DSARs) and privacy governance. </li>\n<li>Review privacy notices, consent mechanisms, vendor agreements, and third-party privacy risks. </li>\n<li>Deliver consulting, training, and executive guidance while translating regulatory requirements into practical business controls. </li>\n</ul><h3>Non-Negotiables </h3><ul>\n<li>Demonstrated GDPR consulting experience. </li>\n<li>Strong working knowledge of EU GDPR and UK GDPR. </li>\n<li>Experience conducting DPIAs, LIAs, TIAs, and preparing ROPA. </li>\n<li>Experience drafting and reviewing Data Processing Agreements. </li>\n<li>Excellent written and verbal communication skills. </li>\n<li>Ability to work directly with executive-level clients. </li>\n<li>Professional privacy certification (CIPP/E, CIPM, CIPT, or equivalent) strongly preferred</li>\n</ul><br><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242701,
"expiryDate": 1791426700,
"applicationLink": "https://himalayas.app/companies/rsi-security/jobs/gdpr-compliance-consultant",
"guid": "https://himalayas.app/companies/rsi-security/jobs/gdpr-compliance-consultant"
},
{
"title": "Prescription Service Doctor",
"excerpt": "Prescription Services Doctor - Anywhere in Ireland (Remote) Who we are:Webdoctor is Ireland’s largest online primary care provider, offering telemedicine services which provide access to world-class medical care through computer or mobile phone applications.",
"companyName": "name",
"companySlug": "medihive",
"companyLogo": "thumbnail_url",
"employmentType": "Part Time",
"minSalary": 40000,
"maxSalary": 40000,
"salaryPeriod": "annual",
"seniority": [
"Senior"
],
"currency": "EUR",
"locationRestrictions": [
"Ireland"
],
"timezoneRestrictions": [
1
],
"categories": [
"Medical",
"Telemedicine",
"Prescription-Services",
"Healthcare",
"Remote-Healthcare",
"Medical-Prescriber",
"Prescribing-Provider",
"Pharmaceutical-Physician",
"Doctor",
"Prescribing-Clinician"
],
"parentCategories": [],
"description": "<p>Prescription Services Doctor - Anywhere in Ireland (Remote)</p><h3>Who we are:</h3><p>Webdoctor is Ireland’s largest online primary care provider, offering telemedicine services which provide  access to world-class medical care through computer or mobile phone applications. The role of a Prescription Services doctor is to provide high quality clinical care and efficient service to our network of patients through our written online prescription services. </p><p>Webdoctor has developed a bespoke medical platform that provides patients with convenient access to a variety of prescription-only treatments for conditions such as hay fever, acne, thrush, rosacea and contraception within the limitations of specific clinical criteria. In this role at Webdoctor you will be responsible for the clinical assessment and safe prescribing of medicines through our platform. </p><h3>.  </h3><h3>What is the role?</h3><p>You will be involved in the daily review of prescription requests from patients through our service. You will be responsible for the medical review of the patient’s application, and the prescription of medicines if the application is approved. You will also review and share clinical reports and perform other duties as agreed by the medical management team.</p><p>The role will involve reporting to our Chief Medical Officer to ensure a safe level of care for all our patients. </p><p>This is your job if you are looking for a Primary Care position which is well supported by an experienced clinical team with flexible working hours, done 100% remotely from the comfort of your own home office.</p><h3>Responsibilities &amp; Duties: </h3><p>Responsibilities will include, but are not limited to: </p><ol>\n<li>Daily review of prescription service requests through our virtual clinic. </li>\n<li>Sharing of clinical reports on our patient’s profile and answering patient messages.</li>\n<li>Safe and accurate assessment of patient requests and the prescription of medication if deemed appropriate. </li>\n<li>Escalating or flagging issues to the medical director team or management teams as necessary. </li>\n<li>To assist the clinical team with other service related duties as they arise.</li>\n</ol><h3>What are we looking for?</h3><ul>\n<li>Essential requirements:<ul>\n<li>A doctor currently registered with the Irish Medical Council. </li>\n<li>Excellent standard of written English.</li>\n<li>Working hours are Monday Friday - 4 hours per day 2pm/3pm - 6pm/7pm</li>\n<li>Computer literate (Prior experience with Apple products is a bonus). </li>\n<li>Must be currently living in the Republic of Ireland.</li>\n<li>3+ years of clinical experience post primary qualification </li>\n</ul>\n</li>\n<li>Desirable requirements: <ul><li>Primary Care/General Practice experience.</li></ul>\n</li>\n</ul><h3>Benefits:</h3><p>Our greatest asset as a company is our people and we understand the importance of the selection of great talent. As part of the position you will have access to: </p><ul>\n<li>Company laptop with full remote working capability.</li>\n<li>Full clinical and technical training with ongoing support. </li>\n<li>Full medical indemnity cover as part of your employment. </li>\n<li>Free GP consultations and prescriptions for you and direct family members.</li>\n<li>Company Pension contribution </li>\n<li>Discounted Group Laya Healthcare and Dental </li>\n<li>Free EAP </li>\n<li>Active virtual CSR</li>\n<li>Home office start up budget of €250 </li>\n<li>Pro rata of 22 days holidays </li>\n</ul><h3>Salary: €40,000 per annum</h3><p>Weekly working hours commitment: 20 hours per week, with days and times as noted</p><h3>Job-type: Part-time</h3>Salary: €40,000 per annum<p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242695,
"expiryDate": 1791426694,
"applicationLink": "https://himalayas.app/companies/medihive/jobs/prescription-service-doctor",
"guid": "https://himalayas.app/companies/medihive/jobs/prescription-service-doctor"
},
{
"title": "Onco Clinician (Contractor)-Shanghai/Beijing",
"excerpt": "Job Title: Onco Clinician (Contractor)-Shanghai/Beijing Job Location: China - Beijing - Beijing; China - Shanghai - STIT Job Location Type: Remote Job Contract Type: Full-time Job Seniority Level: Role Summary:The Development China Clinician is responsible for high quality and timely delivery of one or more interventional clinical trials for R&D.",
"companyName": "name",
"companySlug": "lifelancer",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Senior"
],
"currency": null,
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"Clinical-Development",
"Clinical-Research",
"Oncology",
"Clinical-Trial-Management",
"Medical-Affairs",
"Oncology-Clinical-Project-Manager",
"Oncology-Clinical-Research-Specialist",
"Oncology-Clinical-Trials-Specialist",
"Oncology-Consultant",
"Oncology-Clinical-Research-Associate"
],
"parentCategories": [],
"description": "<p><b>Job Title: </b>Onco Clinician (Contractor)-Shanghai/Beijing</p><p><b>Job Location: </b>China - Beijing - Beijing; China - Shanghai - STIT</p><p><b>Job Location Type: </b>Remote</p><p><b>Job Contract Type: </b>Full-time</p><h3>Job Seniority Level: </h3><h3><i>Role Summary:</i></h3><p>The Development China Clinician is responsible for high quality and timely delivery of one or more interventional clinical trials for R&amp;D. They apply technical excellence in the design of cost-efficient clinical trials to meet the needs of internal and external customers, ensure effective conduct and medical/scientific oversight of studies (in partnership with CTM) and support appropriate interpretation and communication of clinical trial data (including high quality regulatory submissions and product defense activities). They ensure compliance with internal and external standards, proactively mitigate risk and manage emerging clinical issues.</p><p>The China Clinician may act as a site liaison and point of contact to expedite study start-up and conduct and to support clinical training, compliance and overall study quality.</p><h3><i>Responsibilities:</i></h3><p>ClinicalTrials</p><p>Co-chairs clinical study team and works collaboratively with other study team members.</p><p>Point of accountability to the BU for design, conduct, interpretation and reporting of one or more clinical studies (or elements of those studies).</p><p>Provides clinical and scientific expertise to the clinical trial strategy and protocol development process, including acquisition of knowledge of competitor products.</p><p>Through application of Enhanced Clinical Trial Design (ECTD)/ Enhanced Quantitative Drug Development (EQDD), ensures the most efficient clinical protocols are developed.</p><p>Designs/writes clinical trial outlines, protocols and amendments, in collaboration with internal contributors (e.g. statisticians, Outcomes Research(OR) specialists, clinical pharmacologists, clinical project managers, Regional Clinical Site Leads (RCSLs), market access colleagues, commercial development colleagues), internal experts (e.g. clinical program lead, global clinical lead, global clinical strategy lead), and external experts (e.g. investigators, key opinion leaders, advisory board members); ensures design is consistent with objectives.</p><p>Proactive in authoring efficient protocols that minimize the likelihood of amendments. Identifies and assesses study risks to good clinical practices, subject rights/safety and data integrity throughout protocol development and study conduct; creates, implements and assesses effectiveness of mitigation plans.</p><p>Provides clinical input to Study Team for monitoring guidelines, iq RAMP, statistical analysis plans, informed consent documents, clinical review forms, data edit checks, data quality planning, Regional Medical Monitor - Medical Oversight Plan as needed (ultimately oversees work of Study Team).</p><p>Contributes to CRO / vendor selection to ensure study is conducted consistent with protocol requirements, clinical plan expectations, and study timelines; this includes ensuring medical/technical requirements for data integrity are applied (e.g. lab specifications).</p><p>Approves selection of countries, clinical sites and investigators with appropriate qualifications, patient populations, and recruitment strategy to meet goals in a timely, high quality and cost effective manner.</p><p>Ensures study is registered on www.ClinicalTrials.gov, study details are kept up-to-date and basic results are disclosed as required.</p><p>Creates (and where appropriate, delivers) clinical/protocol training materials for study and site management and for use during site initiation visits and investigator meetings.</p><p>Helps establish and oversees Data Monitoring Committees (DMCs) and endpoint adjudication committees, including chartering, contracts, provision of relevant data and documentation of outcomes.</p><p>Jointly accountable with study team for study enrollment and adherence to agreed timelines for study deliverables.</p><p>Maintains direct contact with investigative sites through site visits, telephone contacts, email etc., in order to facilitate investigator engagement, address investigator questions regarding the protocol or the investigational product, and support enrolment activities. This is done in conjunction with RCSLs (when assigned) for sites outside US, Canada, Japan and China. For some studies the clinician may take on an expanded role as described below for the site liaison responsibilities.</p><p>Consistent with Safety Review Plan (SRP), performs and documents regular review of individual subject safety data and cumulative safety data with the safety risk lead (as delegated by the China Clinical Program Lead or the Global Clinical Lead). For all studies, clinical safety review should be performed in consultation with a designated medically-qualified Medical Monitor.</p><p>Responsible for identifying emerging safety trends and raising them forward for further discussion with the Clinical Program Lead and/or Global Clinical Lead; follows up with investigators for specific safety findings (e.g. SAEs).</p><h3>Reviews and manages protocol deviations.</h3><p>Works with study team to ensure high quality of data, e.g. appropriate patient population, adequacy of clinical assessments etc., as study is ongoing.</p><p>Conducts clinical review and interpretation of efficacy and safety data from clinical trials; this includes delivery of top-line report in collaboration with study statistician, and delivery of clinical study report in collaboration with medical writer; accountable for overall quality and timeliness of analysis and reporting.</p><p>Responsible for clinical and scientific validity of study report, especially conclusions regarding efficacy and safety. Responsible for disclosure of appropriate safety and efficacy data and conclusions.</p><p>Ensures narrative strategy for clinical trial(s) is consistent with program narrative strategy; writes (or oversees writingof) safety narratives.</p><p>Assists in ensuring regulatory compliance for clinical trials and reporting. Contributes to primary publication of clinical trial results.</p><p>May act as primary contact with external investigators and internal study team for questions relating to the clinical/medical aspects of the protocol.</p><p>Responsible for keeping the Development China Clinical Program Lead and/or Development China Category Development Lead informed of any critical issues relating to benefit:risk evaluation, or study delivery in line with agreed budget, timelines and quality.</p><p>Presents to internal and external advisory committees (e.g. Technical Review Committee, advisory boards) on design of clinical trials and data from clinical trials.</p><p>Site Liaison Responsibilities (if applicable)</p><p>The China Clinician may have site liaison responsibilities:</p><p>Serve as clinical site liaison to support trial conduct through virtual meetings or teleconferences (as appropriate) and essential face-to-face contact, working directly with site staff. Maintain the ‘Face of Pfizer’ at each site. Create and maintain positive relationships and enthusiasm.</p><p>Understand the work environment and key relationships at clinical sites, use analytical and influencing skills to improve communications and collaboration between key stakeholders.</p><p>Ensure site staff have thorough understanding of protocol requirements (technical and logistic), partner with site staff and study team members to overcome feasibility barriers and operational obstacles and ensure successful subject recruitment/enrollment/retention, protocol compliance and clinical trial quality.</p><p>Conduct frank discussions and set clear expectations for site performance and monitor site performance through metrics.</p><p>Identify quality issues and discuss with Pfizer clinical/operations study team members so that corrective actions may be instituted. Escalate protocol-related issues requiring medical expertise to the RCSL or medically-qualified China Clinical Program Lead, if needed. Escalate operational issues to the appropriate operations study team member.</p><p>Identify the need for and provide supportive coaching and/or training to site staff, as appropriate.</p><p>Identify methods, techniques, key relationships and logistic approaches employed by most successful sites and translate/transfer these best practices to aspiring sites.</p><p>General</p><p>Motivates and engages colleagues in an understanding of disease and commitment and excitement to an indication and mechanism.</p><p>Coaches and mentors less experienced clinicians; may directly manage clinicians.</p><p>Maintains and enhances knowledge in relevant disease area and/or technical area (e.g. pediatrics, regional clinical trials) and practice guidelines relevant to the regions in which clinical trials are being</p><h3>conducted.</h3><p>Interfaces with other Pfizer sites, other BUs and other functions to develop and share best practices, as appropriate.</p><p>May organize expert panel, consultant or advisory board meetings to provide input to protocols, clinical plans or data analysis.</p><p>Provides clinical assistance regarding Scientific and Commercialization Support (SCS) for approved medicines, co-promotions, product defense, and clinical consultation on epidemiology and OR studies.</p><p>Assists in the development of publications, abstracts, and/or presentations.</p><p>Leads or assists in the preparations of the clinical content of regulatory submissions/documents (e.g. NDA, MAA, IND, sNDA, IB, AR).</p><p>Assists in discussions with regulators and with the resolution of queries from drug regulatory agencies / ethics committees; leads or contributes to writing and review responses to regulatory queries.</p><p>May support technical review of licensing opportunities, including due diligence activities.</p><p>Ensures compliance with global and local training requirements and adherence to relevant global / local clinical and medical controlled documents (CMCDs).</p><p>Contributes to (or leads) continuous improvement activities, and to education and training of clinical staff in areas of competence/experience.</p><p>Pfizer is an equal opportunity employer and complies with all applicable equal employment opportunity legislation in each jurisdiction in which it operates.</p><p>To learn more about acceptable and prohibited uses of AI during the recruitment process, please review our candidate AI-use guidelines available on Pfizer Careers.</p><br><br><h3>This job is curated by <a href=\"https://himalayas.app/companies/lifelancer\">Lifelancer</a>.</h3><p><strong><a href=\"https://himalayas.app/companies/lifelancer\">Lifelancer</a> is a talent-hiring platform in Life Sciences, Pharma and IT. The platform connects talent with opportunities in pharma, biotech, health sciences, healthtech and IT domains.</strong></p><p><strong>Please apply via <a href=\"https://himalayas.app/companies/lifelancer\">Lifelancer</a> platform to get connected to the application page and to find  similar roles.</strong></p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242689,
"expiryDate": 1791426688,
"applicationLink": "https://himalayas.app/companies/lifelancer/jobs/onco-clinician-contractor-shanghai-beijing",
"guid": "https://himalayas.app/companies/lifelancer/jobs/onco-clinician-contractor-shanghai-beijing"
},
{
"title": "Senior Director, Development (Data Center Construction)",
"excerpt": "Who we are:It's pretty exciting to find yourself standing in a pivotal moment in time.",
"companyName": "name",
"companySlug": "qts-data-centers",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Director",
"Executive"
],
"currency": null,
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"Data-Center-Construction",
"Development",
"Project-Management",
"Construction-Management",
"Mission-Critical-Facilities",
"Director-Of-Data-Center-Development",
"Director-Of-Data-Center-Design-and-Construction",
"Director-Of-Data-Center-Infrastructure",
"Senior-Director-Development"
],
"parentCategories": [],
"description": "<h3>Who we are:</h3><p>It's pretty exciting to find yourself standing in a pivotal moment in time. It’s even more exciting to be out front leading it. At QTS, our world-class data centers are supporting our customers’ most strategic growth initiatives, positioning us at the forefront of today’s dynamic digital transformation. </p><p>As AI and cloud drive the demand for increased speed, capacity and capability, QTS has emerged as the global digital infrastructure leader, committed to connecting the world for good. Driven by purpose and fueled by a spirit of innovation, QTS designs, builds and operates some of the world’s most advanced, forward-thinking data centers. QTS is a portfolio company of Blackstone.</p><p>QTS is Powered by People. People who play a vital role in our company’s culture, innovation and growth. People who are committed to contributing to the communities where we operate and work. People who are knowledgeable, resourceful and mission driven. Together, we do great things.</p><h3>Who You Are: </h3><p>The <b>Senior </b><b>Director, Development (Data Center Construction) </b>requires strong interpersonal, communication and organizational skills, ability to self-direct, strong background in data center design, engineering, controls, and operational requirements, with an emphasis on project/construction management.  In this role, you will function as QTS’ point of contact for new client builds and implementations and liaise between the QTS Sales Team (Account Exec and Sales Engineer), the QTS Operations Team, the QTS Property Development Team, and the Customer.  The PSCM will work closely with existing Development Construction Project Managers to ensure the customers’ needs are carried out to high levels of expectation. </p><p>The position will report into the QTS Property Development department and work closely with the CHO and CRO, depending on the origin of the project.  </p><h3>What You Will Do and the Impact You Will Have:</h3><ul>\n<li><p>Manage the customer deployment project delivery for each sold deal within each QTS location  </p></li>\n<li><p>Coordinate with the QTS Property Development team, and supporting specialty consultants, to support customer’s design needs, pricing, customer approvals, &amp; implementation of specific deployment scopes </p></li>\n<li><p>Manage the delivery of these projects, this position aligns clients’ objectives, business processes, vendor management strategies, and cross-group collaboration efforts across the QTS organization</p></li>\n<li><p>Drive effective client relationship management and efficient cost management, with the ultimate goal of delivering the project on time and on budget</p></li>\n<li><p>Serve as a single contact for Federal sales support on potential secured deals</p></li>\n</ul><p><b>What You Will Need to be Successful (basic qualifications):</b></p><ul>\n<li><p>Bachelor’s Degree and/or professional licenses in Construction Management or Electrical/Mechanical Engineering or Architecture</p></li>\n<li><p>Ten or more years of progressive responsibility in development of Mission Critical Facilities</p></li>\n<li><p>Five or more years of responsibility of data center project construction with large-scale data centers or DC lease providers</p></li>\n<li><p>Be able to travel as needed for the business</p></li>\n</ul><h3>Other Key Skills:</h3><ul>\n<li><p>Experience managing multiple large, multi-faceted projects</p></li>\n<li><p>Experience with Construction Health &amp; Safety Knowledge</p></li>\n<li><p>Experience with Customer Deployment Technologies and Equipment, RCDD a plus.</p></li>\n<li><p>Strong Verbal and Written Communication Skills</p></li>\n<li><p>Ability to independently manage deadlines and support staff</p></li>\n<li><p>Ability to influence cross-discipline teams</p></li>\n<li><p>Ability to be flexible and adapt to changing situations at a high growth company</p></li>\n</ul><h3>The Perks (and these are just a few!):</h3><ul>\n<li><h3>Q-Rest Sabbatical      </h3></li>\n<li><h3>Employee Stock Purchase Plan</h3></li>\n<li><h3>QTS scholarship for dependents</h3></li>\n<li><h3>Eagle Club Award Trip Eligibility</h3></li>\n<li><h3>Paid Volunteer and Floating days </h3></li>\n<li><p>Tuition Assistance, Parental Leave and Military Leave Assistance</p></li>\n</ul><p>We conform to all the laws, statutes, and regulations concerning equal employment opportunities and affirmative action.  We strongly encourage women, minorities, individuals with disabilities and veterans to apply to all of our job openings.  We are an equal opportunity employer and all qualified applicants will receive consideration for employment without regard to race, color, religion, gender, sexual orientation, gender identity, or national origin, age, disability status, Genetic Information &amp; Testing, Family &amp; Medical Leave, protected veteran status, or any other characteristic protected by law.  We prohibit retaliation against individuals who bring forth any complaint, orally or in writing, to the employer or the government, or against any individuals who assist or participate in the investigation of any complaint or discrimination claim.</p><p>The \"Know Your Rights\" Poster is included here:</p><p>Know Your Rights (English)</p><p>Know Your Rights (Spanish)</p><p>The pay transparency policy is available here:</p><p>Pay Transparency Nondiscrimination Poster-Formatted</p><p>QTS is committed to working with and providing reasonable accommodations to individuals with disabilities. If you need a reasonable accommodation because of a disability for any part of the employment process, please send an e-mail to  and let us know the nature of your request and your contact information.</p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242687,
"expiryDate": 1791426686,
"applicationLink": "https://himalayas.app/companies/qts-data-centers/jobs/senior-director-development-data-center-construction",
"guid": "https://himalayas.app/companies/qts-data-centers/jobs/senior-director-development-data-center-construction"
},
{
"title": "Logistics & Dispatch Coordinator Full-time | 20218",
"excerpt": "Please whitelist the domains \"lever. co\" and \"hire.",
"companyName": "name",
"companySlug": "wing-assistant",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": 40000,
"maxSalary": 48000,
"salaryPeriod": "monthly",
"seniority": [
"Entry-level",
"Mid-level"
],
"currency": "PHP",
"locationRestrictions": [
"Philippines"
],
"timezoneRestrictions": [
8
],
"categories": [
"Logistics-and-Dispatch-Coordinator",
"Logistics-Coordinator",
"Dispatch-Coordinator",
"Freight-Dispatcher",
"Trucking-Dispatcher",
"Logistics-Dispatcher",
"Freight-And-Logistics-Coordinator",
"Entry-Level-Logistics-Coordinator"
],
"parentCategories": [
"Logistics"
],
"description": "<div>\n<p>Please whitelist the domains \"lever.co\" and \"hire.lever.co\" with your email provider to make sure you get our emails.</p>\n<p>Disclaimer: This is a generic job description for the position stated below. Actual tasks and tools will be discussed further when you reach the final interview stage. Please ensure you apply for the right job based on your location and experience. We prioritize people who can do this successfully!</p>\n<h3>Logistics &amp; Dispatch Coordinator</h3>\n<p>Wing is on the exciting mission of redefining the future of work for companies worldwide! We are looking to be the one-stop shop for companies that are looking to build world-class teams &amp; place their operations on autopilot.</p>\n<p>And we’re looking for a <strong>Logistics &amp; Dispatch Coordinator</strong> to start immediately!</p>\n<p><strong>Duties and Responsibilities include but are not limited to:</strong></p>\n<ul>\n<li><p>Outreach &amp; Communication: Cold and warm calls to truckers, plus handling inbound/outbound phone, SMS, and email. You'll introduce and explain the dispatch service and do repetitive follow-ups with truckers and brokers.</p></li>\n<li><p>Dispatch &amp; Coordination: Monitor dashboards for freight/load opportunities, coordinate and match loads with truckers, and contact brokers to negotiate rates on behalf of the truckers.</p></li>\n<li><p>Scheduling &amp; Tracking: Schedule pickups and deliveries (ensuring window accuracy), track driver availability/location/preferred lanes, and manage multiple drivers simultaneously.</p></li>\n<li><p>System Management: Maintain and update CRM/tracking systems, operate internal AI/copilot dispatch tools, use automation tools (while maintaining human oversight), and keep communication records updated.</p></li>\n</ul>\n<br><h3>Required Tools: </h3>\n<ul>\n<li><h3>Slack</h3></li>\n<li><h3>Internal AI/copilot dispatch tools</h3></li>\n<li><h3>Internal CRM/tracking systems</h3></li>\n<li><h3>General automation tools</h3></li>\n</ul>\n<h3>Qualifications:</h3>\n<ul>\n<li><h3>Strong/native-level English fluency</h3></li>\n<li><p>Highly organized and able to multitask under pressure for time-sensitive operations</p></li>\n<li><p>Tech-comfortable and highly adaptable to rapidly evolving tools and workflows.</p></li>\n<li><p>Strong communication and customer service skills, with the ability to read between the lines during conversations.</p></li>\n</ul>\n<br><h3>Technical Requirements:</h3>\n<ul>\n<li><p>USB Headset with Noise Cancellation feature</p></li>\n<li><h3>Working Webcam</h3></li>\n<li><p>Computer with at least 1.8 GHz processor and at least 4GB RAM</p></li>\n<li><p>Main Internet Service Speed: at least 25 Mbps cable connection</p></li>\n<li><p>Backup Internet Service Speed: at least 10 Mbps</p></li>\n</ul>\n<h3>Benefits:</h3>\n<ul>\n<li><h3>Performance Incentives</h3></li>\n<li><h3>Job Security and Stability</h3></li>\n<li><h3>Paid Training</h3></li>\n<li><h3>Inclusive Culture</h3></li>\n<li><h3>Upskilling Opportunities</h3></li>\n<li><h3>100% Work-From-Home</h3></li>\n<li><h3>Exceptionally Supportive Team</h3></li>\n<li><h3>Opportunities for Career Growth</h3></li>\n<li><h3>Fun Work Environment</h3></li>\n<li><h3>Holiday &amp; Overtime Pay</h3></li>\n</ul>\n<p><strong>Schedule: US work hours (40 hours per week, Full-time)</strong></p>\n<h3>Location: 100% Remote</h3>\n<h3>Salary Package: Up to ₱48,000/mo</h3>\n<h3>Please note:</h3>\n<p>• Only qualified candidates will be invited to take the assessment &amp; scheduled for an interview.</p>\n<p>• We have other vacancies that might interest your friends &amp; colleagues. They can check us out at our Jobs Website.</p>\n<p>• You may also refer your friends using our Affiliate Marketing Program and earn up to $30 if your referral is hired.</p>\n<br><p><em>We may use artificial intelligence (AI) tools to support parts of the hiring process, such as reviewing applications, analyzing resumes, or assessing responses and identifying potential inconsistencies or verification signals in application materials based on available information. These tools assist our recruitment team but do not replace human judgment. Final hiring decisions are ultimately made by humans. If you would like more information about how your data is processed, please contact us.</em></p>\n</div><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242679,
"expiryDate": 1791426678,
"applicationLink": "https://himalayas.app/companies/wing-assistant/jobs/logistics-dispatch-coordinator-full-time-20218",
"guid": "https://himalayas.app/companies/wing-assistant/jobs/logistics-dispatch-coordinator-full-time-20218"
},
{
"title": "Assistant Service Sales Manager, Imaging & IGT",
"excerpt": "Job TitleAssistant Service Sales Manager, Imaging & IGTJob Description服务销售助理经理（Assistant Service Sales Manager, Imaging & IGT） 在这个岗位上，您将有机会负责区域服务销售业务及重点客户经营，通过制定客户策略、推动复杂项目落地和拓展区域业务机会，持续提升客户价值及业务增长，并为未来承担更大的业务领导责任做好准备。 您的职责是 区域业务发展 负责指定区域的服务销售业务增长。 制定重点客户业务计划并推动执行。 完成销售收入、合同续约及新增业务目标。 重点客户管理建立和维护区域重点客户关系。 深入理解客户运营需求，提供服务解决方案。 提升客户服务产品覆盖率和合同渗透率。 项目推动与资源整合主导复杂销售项目及客户合作项目。 协调销售、服务、市场等相关团队资源。 推动项目按计划落地并实现业务目标。 业务机会开发分析区域市场及客户需求变化。 挖掘新业务增长机会。 支持区域重点项目及战略业务推进。 团队影响力建设分享最佳实践和成功案例。 指导和支持Junior Sales成长。 作为区域业务骨干推动团队协作和经验传承。 您将适合这个岗位，如果您具备 Must Have 5年以上医疗行业销售经验。 具备独立管理重点客户和销售项目的经验。 较强的客户影响力和商务谈判能力。 优秀的业务规划和机会管理能力。 出色的跨部门协作和资源整合能力。 结果导向，能够独立推动复杂业务达成。 Nice to Have服务销售（Service Sales）经验。 医疗设备行业经验。 FSE、临床应用或技术支持背景。 KOL及重点客户管理经验。 有 Team Lead、项目负责人或人才培养经验。 关键绩效指标（KPI）Orders Intake (OI) Sales Revenue Win Rate Service Contract Renewal Rate New Business Growth Salesforce Accuracy & Opportunity Management Key Account Penetration",
"companyName": "name",
"companySlug": "philips",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Manager"
],
"currency": null,
"locationRestrictions": [
"China"
],
"timezoneRestrictions": [
6,
8
],
"categories": [
"Service-Sales-Management",
"Key-Account-Sales",
"Medical-Device-Sales",
"Healthcare-Sales",
"Sales-Management",
"Service-Sales-Manager",
"Assistant-Sales-Manager",
"Assistant-Manager-Sales",
"Sales-Manager"
],
"parentCategories": [
"Sales"
],
"description": "<h3>Job Title</h3>Assistant Service Sales Manager, Imaging &amp; IGT<h3>Job Description</h3><p><b>服务销售助理经理（Assistant Service Sales Manager, Imaging &amp; IGT</b><b>）</b></p><h3>在这个岗位上，您将有机会</h3><p>负责区域服务销售业务及重点客户经营，通过制定客户策略、推动复杂项目落地和拓展区域业务机会，持续提升客户价值及业务增长，并为未来承担更大的业务领导责任做好准备。</p><h3>您的职责是</h3><p></p><p><b>区域业务发展</b></p><p><b>负责指定区域的服务销售业务增长。 制定重点客户业务计划并推动执行。 完成销售收入、合同续约及新增业务目标。</b></p><h3><b>重点客户管理</b></h3><p><b>建立和维护区域重点客户关系。 深入理解客户运营需求，提供服务解决方案。 提升客户服务产品覆盖率和合同渗透率。</b></p><h3><b>项目推动与资源整合</b></h3><p><b>主导复杂销售项目及客户合作项目。 协调销售、服务、市场等相关团队资源。 推动项目按计划落地并实现业务目标。</b></p><h3><b>业务机会开发</b></h3><p><b>分析区域市场及客户需求变化。 挖掘新业务增长机会。 支持区域重点项目及战略业务推进。</b></p><h3><b>团队影响力建设</b></h3><p><b>分享最佳实践和成功案例。 指导和支持Junior Sales成长。 作为区域业务骨干推动团队协作和经验传承。</b></p><h3><b>您将适合这个岗位，如果您具备</b></h3><p></p><p><b>Must Have</b></p><p><b>5年以上医疗行业销售经验。 具备独立管理重点客户和销售项目的经验。 较强的客户影响力和商务谈判能力。 优秀的业务规划和机会管理能力。 出色的跨部门协作和资源整合能力。 结果导向，能够独立推动复杂业务达成。</b></p><h3><b>Nice to Have</b></h3><p><b>服务销售（Service Sales）经验。 医疗设备行业经验。 FSE、临床应用或技术支持背景。 KOL及重点客户管理经验。 有 Team Lead、项目负责人或人才培养经验。</b></p><h3>\n<b>关键绩效指标（KPI</b><b>）</b>\n</h3><p><b>Orders Intake (OI) Sales Revenue Win Rate Service Contract Renewal Rate New Business Growth Salesforce Accuracy &amp; Opportunity Management Key Account Penetration</b></p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242665,
"expiryDate": 1791426664,
"applicationLink": "https://himalayas.app/companies/philips/jobs/assistant-service-sales-manager-imaging-igt",
"guid": "https://himalayas.app/companies/philips/jobs/assistant-service-sales-manager-imaging-igt"
},
{
"title": "AWS Cloud Engineer - Platform Operations",
"excerpt": "Miratech is looking for an experienced AWS Cloud Engineer – Platform Operations to support and optimize AWS infrastructure powering Amazon Connect and enterprise cloud platforms.",
"companyName": "name",
"companySlug": "miratech",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Senior"
],
"currency": null,
"locationRestrictions": [
"Canada",
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
-4,
-3.5,
14
],
"categories": [
"Cloud-Engineer",
"AWS-Cloud-Engineer",
"Platform-Engineering",
"Site-Reliability-Engineering",
"DevOps-Engineer",
"AWS-Platform-Engineer",
"AWS-Operations-Engineer",
"Platform-Operations-Engineer",
"Cloud-Operations-Engineer",
"CloudOps-Engineer"
],
"parentCategories": [
"Developer"
],
"description": "<p><a href=\"https://himalayas.app/companies/miratech\">Miratech</a> is looking for an experienced AWS Cloud Engineer – Platform Operations to support and optimize AWS infrastructure powering Amazon Connect and enterprise cloud platforms. This role combines AWS Cloud Operations, Site Reliability Engineering (SRE), Infrastructure Automation, and Observability to deliver highly available, secure, and scalable cloud solutions. The ideal candidate will have strong experience with AWS services, Terraform, Infrastructure as Code, cloud automation, production support, and observability across enterprise environments.</p><h3>Responsibilities</h3><ul>\n<li>Support and enhance AWS infrastructure for Amazon Connect and related platform services.</li>\n<li>Manage Infrastructure as Code (IaC) using Terraform and automate operational tasks using Python and AWS CLI.</li>\n<li>Improve platform reliability by supporting incident response, RCA, disaster recovery, and production readiness activities.</li>\n<li>Build self-healing automation and operational runbooks to reduce manual effort.</li>\n<li>Develop dashboards, alerts, and monitoring solutions using CloudWatch, Dynatrace, Splunk, Grafana, and OpenTelemetry.</li>\n<li>Support CI/CD pipelines, cloud deployments, and release management activities.</li>\n<li>Collaborate with engineering and operations teams to improve cloud scalability, security, and operational excellence.</li>\n</ul><ul>\n<li>5+ years of experience in AWS Cloud Operations, Platform Engineering, or Site Reliability Engineering (SRE).</li>\n<li>Strong hands-on experience with AWS services including Lambda, CloudWatch, IAM, VPC, Route 53, S3, SNS, SQS, EventBridge, and DynamoDB.</li>\n<li>Strong experience with Terraform and Infrastructure as Code (IaC).</li>\n<li>Experience with Python, AWS CLI, PowerShell, or similar automation tools.</li>\n<li>Experience with GitHub, GitHub Actions, Jenkins, and CI/CD pipelines.</li>\n<li>Hands-on experience with observability tools such as Dynatrace, Splunk, CloudWatch, Grafana, or OpenTelemetry.</li>\n<li>Experience supporting production environments, incident management, change management, and release management.</li>\n<li>Strong communication and stakeholder management skills.</li>\n</ul><h3>Nice To Have</h3><ul>\n<li>AWS Certification (Solutions Architect, DevOps Engineer, or equivalent).</li>\n<li>Experience with Amazon Connect, NICE CXone, Genesys Cloud, or other CCaaS platforms.</li>\n<li>Experience with ServiceNow and automated remediation solutions.</li>\n<li>Understanding of High Availability, Disaster Recovery, and operational resiliency.</li>\n</ul><h3>We offer:</h3><ul>\n<li>\n<strong>Culture of Relentless Performance:</strong> join an unstoppable technology development team with a 99% project success rate and more than 30% year-over-year revenue growth.</li>\n<li>\n<strong>Competitive Pay and Benefits:</strong> enjoy a comprehensive compensation and benefits package, including health insurance, language courses, and a relocation program.</li>\n<li>\n<strong>Work From Anywhere Culture:</strong> make the most of the flexibility that comes with remote work.</li>\n<li>\n<strong>Growth Mindset:</strong> reap the benefits of a range of professional development opportunities, including certification programs, mentorship and talent investment programs, internal mobility and internship opportunities.</li>\n<li>\n<strong>Global Impact:</strong> collaborate on impactful projects for top global clients and shape the future of industries.</li>\n<li>\n<strong>Welcoming Multicultural Environment:</strong> be a part of a dynamic, global team and thrive in an inclusive and supportive work environment with open communication and regular team-building company social events.</li>\n<li>\n<strong>Social Sustainability Values:</strong> join our sustainable business practices focused on five pillars, including IT education, community empowerment, fair operating practices, environmental sustainability, and gender equality.</li>\n</ul><p><em><a href=\"https://himalayas.app/companies/miratech\">Miratech</a> is an equal opportunity employer and does not discriminate against any employee or applicant for employment on the basis of race, color, religion, sex, national origin, age, disability, veteran status, sexual orientation, gender identity, or any other protected status under applicable law.</em></p><p>All your information will be kept confidential according to EEO guidelines.</p><p><a href=\"https://himalayas.app/companies/miratech\">Miratech</a> helps visionaries change the world. We are a global IT services and consulting company that brings together enterprise and start-up innovation. Today, we support digital transformation for some of the world's largest enterprises. By partnering with both large and small players, we stay at the leading edge of technology, remain nimble even as a global leader, and create technology that helps our clients further enhance their business. We are a values-driven organization and our culture of Relentless Performance has enabled over 99% of <a href=\"https://himalayas.app/companies/miratech\">Miratech</a>'s engagements to succeed by meeting or exceeding our scope, schedule, and/or budget objectives since our inception in 1989.<br><a href=\"https://himalayas.app/companies/miratech\">Miratech</a> has coverage across 5 continents and operates in over 25 countries around the world. <a href=\"https://himalayas.app/companies/miratech\">Miratech</a> retains nearly 1000 full-time professionals, and our annual growth rate exceeds 25%.</p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242657,
"expiryDate": 1791426656,
"applicationLink": "https://himalayas.app/companies/miratech/jobs/aws-cloud-engineer-platform-operations",
"guid": "https://himalayas.app/companies/miratech/jobs/aws-cloud-engineer-platform-operations"
},
{
"title": "Customer Support Specialist",
"excerpt": "*This is a fully remote role that is based in Ukraine.",
"companyName": "name",
"companySlug": "healthjoy",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Entry-level",
"Mid-level"
],
"currency": null,
"locationRestrictions": [
"Ukraine"
],
"timezoneRestrictions": [
2,
3
],
"categories": [
"Customer-Support-Specialist",
"Member-Services",
"Healthcare-Support",
"Customer-Success",
"Technical-Support",
"Customer-Specialist",
"User-Support-Specialist",
"Support-Specialist",
"Senior-Customer-Support-Specialist",
"Customer-Support-Expert",
"Consumer-Support-Specialist",
"Customer-Support",
"Customer-Service"
],
"parentCategories": [
"Customer Service"
],
"description": "<p><strong>*This is a fully remote role that is based in Ukraine. Job applicant must reside in Ukraine.</strong></p><h3>Come for the mission. Stay for the experience.</h3><p>Let’s keep things simple: we are an unbelievably talented, hard-working, and compassionate team driving towards a mission that impacts a huge amount of people who use Healthcare benefits in the US. </p><p>Healthcare benefits are complex, underutilized and a mystery for most users in the USA. We’re removing that complexity. Our industry-changing technology solution puts a simplified benefits experience in the hands of users, saving them time and money.</p><p>Following an explosive 2019 (raising $30M in Series C funding, awards for Chicago’s Best Tech Startup and Chicago’s Best Place to Work, adding 50+ key team members and more), we’re continuing down the path of high growth and high impact. </p><h3>Your impact.</h3><ul>\n<li>\n<strong>Member Care &amp; Ticket Processing:</strong> Assist in handling member inquiries (tickets) accurately and efficiently, ensuring members understand their benefits and feel supported.</li>\n<li>\n<strong>Smart Automation &amp; AI:</strong> Actively leverage automation tools and AI software to speed up resolution times while maintaining high-quality outcomes.</li>\n<li>\n<strong>Priority Management: </strong>Assess the urgency of incoming requests to prioritize critical cases and manage escalations with empathy and objective reasoning.</li>\n<li>\n<strong>Provider &amp; Member Outreach</strong>: Conduct outbound calls to healthcare providers and members to help schedule appointments, verify information, and close gaps in care.</li>\n<li>\n<strong>Proactive Problem Solving:</strong> Identify scheduling bottlenecks or workflow trends, flag issues early, and suggest improvements to team leadership.</li>\n<li>\n<strong>Member Experience</strong>: Deliver a high-standard \"WOW\" service tailored to the US customer base.</li>\n<li>\n<strong>Communicate scheduling </strong>challenges or trends that may negatively impact outcomes</li>\n<li>\n<strong>Transparent &amp; Proactive Communication</strong>: Keep team leadership and members updated in real time. Proactively communicate progress and flag blockers early, rather than getting stuck silently on a single ticket.</li>\n<li>\n<strong>Commitment to KPIs:</strong> Own your daily performance targets — including number of tickets, quality scores, and member satisfaction — and take full responsibility for hitting your metrics.</li>\n</ul><h3>Your experience and expected skill set.</h3><ul>\n<li>\n<strong>Language Proficiency:</strong> Upper-Intermediate+ English (B2/C1) with exceptional written and verbal communication skills.</li>\n<li>\n<strong>High Autonomy &amp; Ownership: </strong>Strong self-management skills — you take full responsibility for your commitments, track your own time, and deliver results without constant supervision.</li>\n<li>\n<strong>Resourceful Problem-Solving:</strong> A \"solution-first\" mindset with the drive to research internal documentation, AI tools, and knowledge bases to solve issues independently before asking for help.</li>\n<li>\n<strong>Fast &amp; Self-Driven Learning:</strong> Ability to quickly absorb complex concepts, adapt to new processes, and continuously learn from feedback with minimal hand-holding.</li>\n<li>\n<strong>Adaptability:</strong> Comfort navigating frequent changes, fast-paced environments, and evolving priorities without losing focus.</li>\n<li>\n<strong>Tech &amp; AI Literacy: </strong>Proficient computer skills and a rapid learning curve for software; hands-on experience using AI tools (ChatGPT, prompt engineering, or automation tools) is a strong plus.</li>\n<li>\n<strong>Empathy &amp; Customer Orientation: </strong>Genuine empathy with strong interpersonal skills; prior customer service or support experience is a major plus.</li>\n</ul><h3>Role details.</h3><ul>\n<li>Working schedule 5/2 – 15:30 to 24:00;</li>\n<li>20 paid vacation days per 12-month period, paid days for sick leaves.</li>\n</ul><h3>Our rewards.</h3><p>Work should be meaningful and rewarding. <a href=\"https://himalayas.app/companies/healthjoy\">HealthJoy</a> offers a robust package of employee perks and benefits, including:</p><ul><li><strong>Employment:</strong></li></ul><p><a href=\"https://himalayas.app/companies/healthjoy\">HealthJoy</a> LLC is part of the Ukraine Diia City legal framework. On your first day, you will sign a Gig-Contract via the Vchasno system, gaining a status of a Gig-Specialist.</p><ul><li><strong>Competitive compensation: </strong></li></ul><p>The compensation grows as you grow with <a href=\"https://himalayas.app/companies/healthjoy\">HealthJoy</a>, with the potential to double it within 1.5 years. Top performers earn KPI-based bonuses.</p><ul><li><strong>Great career growth opportunities: </strong></li></ul><p>You will have a chance to go through a career path from Junior to Middle, and Senior Specialist, and eventually grow into a Team Leader. Alternatively, it may be possible to grow horizontally and take the position of Learning&amp;Development Leader, Quality Assurance Analyst or Process Analyst.</p><ul><li>\n<strong>Healthcare</strong>:</li></ul><p>As a healthcare-focused company, we provide 100% health insurance coverage for our employees, with the option to insure their family members at a reduced rate.</p><ul><li><strong>Education: </strong></li></ul><p>Benefit from company-sponsored English classes, a corporate learning platform “Udemy” for professional development, and internal/external educational events. Our L&amp;D department provides broad knowledge of the American healthcare system and cultural peculiarities.</p><ul><li>\n<strong>Mental health support program</strong>:</li></ul><p>Employees have access to personal therapy sessions and additional virtual mental health lectures - all from the comfort of home.</p><ul><li>\n<strong>Company events</strong>:</li></ul><p>To stay in touch with the team we hold happy hours,team buildings, as well as recreational events.</p><ul><li><strong>Gym:</strong></li></ul><p>Access corporate discounts and special offers at Sport Life, one of Ukraine's largest sports hubs.</p><ul><li>\n<strong>Remote work</strong>:</li></ul><p>Being a remote-first company, we provide the needed essential equipment for comfortable work from home (or anywhere!)</p><h3>Commitment to Equal Pay</h3><p>At <a href=\"https://himalayas.app/companies/healthjoy\">HealthJoy</a>, we are committed to creating a diverse and inclusive workplace where everyone has the opportunity to succeed and thrive.</p><p>We believe that everyone should be paid based on their qualifications, experience, and the work that they do, and not on their gender, race, or any other personal characteristic. Our compensation practices are essential to fostering a diverse and inclusive culture where we value the contributions of all our employees.</p><p>We conduct thorough annual reviews of employee pay and our pay practices to ensure we reward the right behaviors and are providing equal pay for equal work.</p><p>Additionally, we assess the external market and internal equity across like roles. As part of our regular review of pay practices, <a href=\"https://himalayas.app/companies/healthjoy\">HealthJoy</a> examines employee pay for potential disparities between persons of different genders, races and ethnicities that are not explainable by objective factors such as performance, experience level, credentials, or location, and are committed to correcting any issues and reviewing practices from unintended outcomes.</p><h3>Commitment to Equal Opportunity</h3><p><a href=\"https://himalayas.app/companies/healthjoy\">HealthJoy</a> is committed to creating a diverse environment and is proud to be an equal opportunity employer.</p><p>All qualified applicants receive consideration for employment without regard to race, color, religion, gender, gender identity or expression, sexual orientation, national origin, genetics, disability, age, or any other basis forbidden under federal, state, or local law.</p><p>Don’t meet every single requirement? We know the confidence gap and imposter syndrome can get in the way of meeting spectacular candidates, so please don’t hesitate to apply — we’d love to hear from you. <a href=\"https://himalayas.app/companies/healthjoy\">HealthJoy</a> is dedicated to building a diverse, inclusive, and authentic workplace, so if you’re excited about this role and <a href=\"https://himalayas.app/companies/healthjoy\">HealthJoy</a>, we encourage you to apply. You may be just the right candidate for this or other roles.</p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242642,
"expiryDate": 1791426641,
"applicationLink": "https://himalayas.app/companies/healthjoy/jobs/customer-support-specialist",
"guid": "https://himalayas.app/companies/healthjoy/jobs/customer-support-specialist"
},
{
"title": "Head of AI Safety",
"excerpt": "Moonshot believes that marginalized people in society, including people of colour, Indigenous people, people from diverse socioeconomic backgrounds, women, Disabled people, and LGBTQIA+ people, must be centred in the work we do.",
"companyName": "name",
"companySlug": "moonshot-money",
"companyLogo": "thumbnail_url",
"employmentType": "Full Time",
"minSalary": 115000,
"maxSalary": 140000,
"salaryPeriod": "annual",
"seniority": [
"Director"
],
"currency": "CAD",
"locationRestrictions": [
"Canada"
],
"timezoneRestrictions": [
-8,
-7,
-6,
-5,
-4,
-3.5
],
"categories": [
"AI-Safety",
"Trust-and-Safety",
"Public-Safety",
"Policy-Advisory",
"Program-Management",
"Director-Of-AI-Safety",
"Head-Of-AI"
],
"parentCategories": [],
"description": "<p><a href=\"https://himalayas.app/companies/moonshot-money\">Moonshot</a> believes that marginalized people in society, including people of colour, Indigenous people, people from diverse socioeconomic backgrounds, women, Disabled people, and LGBTQIA+ people, must be centred in the work we do. We strongly encourage applications from people with these identities, or from other communities currently underrepresented in our workforce.</p><p>All qualified applicants will be afforded equal employment opportunities without discrimination based on race, creed, colour, national origin, sex, age, disability, or marital status. We know a diverse workforce will enable us to understand the drivers behind violent extremism and online harms in greater depth, and to do better work to counter them.</p><h3>About the role</h3><p><a href=\"https://himalayas.app/companies/moonshot-money\">Moonshot</a> is recruiting a Head of AI Safety to lead the delivery, development, and growth of our AI Safety portfolio. The role combines <a href=\"https://himalayas.app/companies/moonshot-money\">Moonshot</a>'s expertise in violence prevention, behavioural risk, and online harms with the emerging practice of evaluating and improving the safety of AI systems. The portfolio addresses harm categories including pathways to violence, extremism, child sexual exploitation, abuse and grooming (CSEA), mental health and crisis, and risks affecting children and teenagers.</p><p>The Head of AI Safety will serve as <a href=\"https://himalayas.app/companies/moonshot-money\">Moonshot</a>'s primary applied AI safety counterpart for frontier AI companies, governments, and regulators. The role will work closely with model, policy, trust and safety, product, research, and engineering teams. This is not an engineering or data-science role, but it is a hands-on position requiring the successful candidate to lead and participate directly in red teaming and adversarial evaluation, working in detail with evaluation methodologies, test scenarios, model responses, safety policies, and intervention frameworks. The role holds responsibility for client and partner relationships, project and staff management, methodological quality, and business development. The Head of AI Safety will build and maintain relationships across the wider AI safety ecosystem, including with governments, foundations, regulators, academics, researchers, and civil society organizations.</p><p>This is a remote position. Candidates must be based in Ontario, Canada, due to employment and regulatory requirements.</p><h3>Your responsibilities will include:</h3><h3>Applied AI Safety, Evaluation, and Advisory</h3><ul>\n<li>Lead and quality-assure <a href=\"https://himalayas.app/companies/moonshot-money\">Moonshot</a>'s applied AI safety work across harm categories including pathways to violence, extremism, CSEA, abuse and grooming, mental health and crisis, and risks affecting children and teens, using methods such as red teaming and adversarial evaluation of AI systems.</li>\n<li>Advise frontier AI companies on how to improve the safety of their models, products, policies, and intervention systems.</li>\n<li>Translate insights from psychologists, child-safety specialists, violence-prevention practitioners, safeguarding experts, and other subject-matter experts into clear, actionable guidance for model safety, policy, product, research, and engineering teams.</li>\n<li>Set the methodological approach for the portfolio, translating violence-prevention, safeguarding, and behavioural-risk expertise into structured and testable evaluation frameworks.</li>\n<li>Lead and participate directly in red teaming and adversarial evaluation, working in detail with test scenarios, model responses, scoring criteria, safety policies, and evaluation results.</li>\n<li>Identify patterns, edge cases, and potential safety failures, and develop practical recommendations for improving model behaviour and user protections.</li>\n<li>Maintain rigour and clear documentation across the team's technical deliverables, suitable for technical, government, and foundation audiences.</li>\n<li>Ensure work is delivered within a clear ethical framework and in compliance with contractual, legal, data protection, and ethics obligations.</li>\n<li>Identify, manage, and escalate operational, reputational, delivery, and partnership risks.</li>\n</ul><h3>Client &amp; Partner Management</h3><ul>\n<li>Serve as <a href=\"https://himalayas.app/companies/moonshot-money\">Moonshot</a>'s primary applied AI safety counterpart for frontier AI company partners, governments, regulators, and the wider ecosystem invested in AI safety.</li>\n<li>Build trusted relationships with model, policy, trust and safety, product, research, and engineering teams.</li>\n<li>Build and sustain relationships across the wider AI safety ecosystem, including governments, foundations, regulators, academics, researchers, civil society organizations, and specialist practitioners.</li>\n<li>Represent <a href=\"https://himalayas.app/companies/moonshot-money\">Moonshot</a> externally in meetings, briefings, workshops, and sector engagement, including with regulators and policymaker audiences.</li>\n</ul><h3>Team Leadership &amp; Management</h3><ul>\n<li>Provide direct leadership, coaching, and management to <a href=\"https://himalayas.app/companies/moonshot-money\">Moonshot</a>'s AI safety team.</li>\n<li>Foster a collaborative, accountable, and mission-driven team culture, with particular attention to wellbeing given the sensitive nature of the work.</li>\n<li>Support workforce planning, performance management, and professional development across the team.</li>\n<li>Ensure effective coordination with internal teams supporting the portfolio, including operations, finance, research, and technical teams.</li>\n</ul><h3>Portfolio Development &amp; Growth</h3><ul>\n<li>Develop <a href=\"https://himalayas.app/companies/moonshot-money\">Moonshot</a>'s AI safety portfolio, identifying strategic opportunities, partnerships, and funding.</li>\n<li>Lead proposal development, scoping, and renewals with technical credibility, using precise, defensible language suited to technical and government audiences.</li>\n<li>Develop repeatable methodologies, service offerings, and partnerships that allow the portfolio to grow while maintaining methodological rigour and delivery quality.</li>\n<li>Support external communications, publications, briefings, and thought leadership that establish <a href=\"https://himalayas.app/companies/moonshot-money\">Moonshot</a> as a credible voice in applied AI safety.</li>\n<li>Oversee project planning, staffing, budgeting, forecasting, and delivery timelines across the portfolio.</li>\n</ul><h3>Requirements</h3><p></p><p><strong>Essential:</strong></p><ul>\n<li><strong>Experience in trust &amp; safety, online harms, or a closely related field such as violence prevention, safeguarding, or public health, and the ability to adapt that knowledge to AI systems.</strong></li>\n<li><strong>Curiosity about AI and the ability to build technical fluency quickly, enough to engage credibly with technical counterparts at AI companies. Much of this work is new, so comfort learning as you go matters more than existing AI safety expertise.</strong></li>\n<li><strong>Experience designing research, evaluation frameworks, or interventions for harm categories such as violent extremism, CSEA, self-harm and crisis, or targeted violence.</strong></li>\n<li><strong>Demonstrated experience managing projects, teams, budgets, partners, and clients, with strong people management skills.</strong></li>\n<li><strong>Excellent written communication, with experience producing credible (not promotional) material for government, foundation, or enterprise audiences.</strong></li>\n<li><strong>Comfort and demonstrated resilience working with highly sensitive or graphic content (CSEA, extremist material, crisis content), with awareness of wellbeing practices for this kind of work.</strong></li>\n<li><strong>Strong judgment and the ability to navigate ambiguity, competing priorities, and sensitive stakeholder environments, including representing organizations externally.</strong></li>\n<li><strong>Willingness to travel and work outside regular hours where needed to accommodate clients or respond to incidents.</strong></li>\n<li><strong>Highly trustworthy, with discretion and diplomacy, and willing to undertake relevant security clearance procedures.</strong></li>\n<li><strong>Experience supporting business development, grant funding, or procurement.</strong></li>\n<li><strong>Commitment to <a href=\"https://himalayas.app/companies/moonshot-money\">Moonshot</a>'s mission.</strong></li>\n<li><strong>Candidates must be eligible to work in Canada, and will be required to undertake and pass a standard background check, along with any relevant security clearance procedures per client needs.</strong></li>\n</ul><h3><strong>Desirable:</strong></h3><ul>\n<li><strong>Direct experience in model safety, red teaming, or adversarial evaluation of LLMs or other AI systems.</strong></li>\n<li><strong>Understanding of LLM architecture, safety tooling, or trust &amp; safety policy.</strong></li>\n<li><strong>Prior experience in child safety evaluation, teen-safety product work, or grooming and CSEA detection.</strong></li>\n<li><strong>Familiarity with government or regulatory engagement, such as briefing officials or supporting policy submissions.</strong></li>\n<li><strong>Experience with intervention or diversion programme design that can transfer to AI-mediated interventions.</strong></li>\n<li><strong>Academic or applied background in radicalization studies, forensic psychology, or violence risk assessment.</strong></li>\n<li><strong>Familiarity with taxonomy or classifier development, including how testing data feeds a classifier.</strong></li>\n</ul><h3><strong>Benefits</strong></h3><ul>\n<li><strong>25 days paid vacation leave, plus Statutory Holiday</strong></li>\n<li><strong>Flexible public holiday policy with the option to work statutory holidays in exchange for a day off at another time.</strong></li>\n<li><strong>Group healthcare package, including coverage for partners and children (80% Co-Insurance).</strong></li>\n<li><strong>HSA is restricted to mental health practitioners only</strong></li>\n<li><strong>Dental &amp; Vision Insurance (80% Co-Insurance).</strong></li>\n<li><strong>Life &amp; LTD Disability Insurance.</strong></li>\n<li><strong>24/7 access to counselling via our Employee Assistance Program.</strong></li>\n<li><strong>Generous maternity and paternity leave: 26 weeks paid maternity leave, 8 weeks paid paternity leave.</strong></li>\n<li><strong>All permanent employees are granted share options upon employment.</strong></li>\n</ul><p><strong><strong>Salary: $115,000 - $140,000 CAD (depending on skills and experience).</strong></strong></p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786242636,
"expiryDate": 1791426636,
"applicationLink": "https://himalayas.app/companies/moonshot-money/jobs/head-of-ai-safety-6706139870",
"guid": "https://himalayas.app/companies/moonshot-money/jobs/head-of-ai-safety-6706139870"
}
]
}

{
"comments": "13/03/2026: The API has been updated to include the companySlug field in the response.",
"updatedAt": 1786251385,
"offset": 10,
"limit": 20,
"totalCount": 100618,
"jobs": [
{
"title": "Stagiaire en architecture technologique — Socle IA corporatif",
"excerpt": "Titre : Stagiaire en architecture technologique — Socle IA corporatif (Ouvert) Lieu : Télétravail, mode hybride ou en présentiel au bureau de Rimouski Période : 8 septembre au 18 décembre 2026PG Solutions est en train de poser les bases de son futur corporatif en intelligence artificielle, et nous souhaitons que tu en fasses partie.",
"companyName": "Harris Global Business Services Inc.",
"companySlug": "harris-global-business-services-inc",
"companyLogo": "",
"employmentType": "Intern",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Entry-level"
],
"currency": null,
"locationRestrictions": [
"Canada"
],
"timezoneRestrictions": [
-8,
-7,
-6,
-5,
-4,
-3.5
],
"categories": [
"AI-Architecture",
"Software-Architecture",
"AI-ML-Engineering",
"Technology:-Architecture",
"AI-Consulting",
"Stagiaire-En-Technologie-De-L'Information",
"Stagiaire-En-Systèmes-Et-Réseaux",
"Stagiaire-En-Développement-DevOps"
],
"parentCategories": [],
"description": "<p><b>Titre : Stagiaire en architecture technologique — Socle IA corporatif (Ouvert)</b></p><p><b>Lieu : Télétravail, mode hybride ou en présentiel au bureau de Rimouski</b></p><h3>Période : 8 septembre au 18 décembre 2026</h3><p>PG Solutions est en train de poser les bases de son futur corporatif en intelligence artificielle, et nous souhaitons que tu en fasses partie. Sous la supervision d’un expert en développement logiciel et en IA, tu auras l’opportunité rare de participer à un chantier stratégique qui façonnera la façon dont notre organisation exploitera l’intelligence artificielle dans ses produits et ses services. Ce stage n’est pas un stage d’observation — tu y contribueras concrètement, tu laisseras une trace durable et tu repartiras avec une expérience réelle en architecture IA.</p><h3>Tes responsabilités :</h3><ul>\n<li><p>Contribuer à définir l’architecture de référence du socle IA corporatif de PG Solutions ;</p></li>\n<li><p>Évaluer et comparer les technologies clés (LLM, orchestration, stockage vectoriel, API, etc.) en lien avec notre vision IA-first ;</p></li>\n<li><p>Concevoir et réaliser un prototype fonctionnel permettant de valider les concepts architecturaux retenus ;</p></li>\n<li><p>Produire des livrables documentés, clairs et réutilisables par l’équipe interne ;</p></li>\n<li><p>Proposer une feuille de route technique pour accélérer le déploiement de futures solutions et assistants IA ;</p></li>\n<li><p>Collaborer activement avec l’équipe dans un esprit d’ouverture et de partage.</p></li>\n</ul><h3>Profil recherché :</h3><h3>Compétences techniques :</h3><ul>\n<li><p>Connaissance des fondements de l’intelligence artificielle et du machine learning (LLM, RAG, agents IA, etc.) ;</p></li>\n<li><p>Aptitude à concevoir ou à analyser des architectures logicielles (microservices, API REST, cloud) ;</p></li>\n<li><p>Familiarité avec des environnements Python et les écosystèmes IA courants (LangChain, OpenAI, HuggingFace ou équivalents) ;</p></li>\n<li><p>À l’aise avec les outils de versionnement (Git) et la documentation technique.</p></li>\n</ul><h3>Compétences analytiques :</h3><ul><li><p>Capacité à analyser des options technologiques, à formuler des recommandations claires et à documenter tes conclusions de façon structurée.</p></li></ul><h3>Travail d’équipe :</h3><ul>\n<li><p>Aisance à communiquer tes idées et à recevoir de la rétroaction ;</p></li>\n<li><p>Capacité à avancer de façon autonome tout en restant aligné avec l’équipe ;</p></li>\n<li><p>Ouverture d’esprit et volonté de partager tes apprentissages.</p></li>\n</ul><h3>Curiosité et proactivité :</h3><ul>\n<li><p>Intérêt marqué pour l’intelligence artificielle et les architectures modernes ;</p></li>\n<li><p>Motivation à contribuer à quelque chose de concret et de structurant ;</p></li>\n<li><p>Débrouillardise, initiative et envie d’apprendre en faisant.</p></li>\n</ul><h3>Ce que nous offrons :</h3><ul>\n<li><p><b>Impact réel</b> : Tu contribueras directement à un projet stratégique — ton travail sera utilisé, pas archivé ;</p></li>\n<li><p><b>Encadrement expert</b> : Un expert t’accompagnera au quotidien, avec son expérience en développement logiciel et en IA ;</p></li>\n<li><p><b>Apprentissage accéléré</b> : Tu seras au cœur des technologies IA les plus actuelles, appliquées à un contexte d’entreprise réel ;</p></li>\n<li><p><b>Flexibilité</b> : Horaires flexibles et possibilité de télétravail ;</p></li>\n<li><p><b>Ambiance collaborative</b> : Une équipe accessible, transparente et engagée qui valorise tes idées.</p></li>\n</ul><p>Si tu as envie de mettre tes connaissances en IA et en architecture au service d’un projet qui compte vraiment, et que tu souhaites évoluer dans un environnement stimulant où ton apport sera reconnu et valorisé, nous serions ravis de t’accueillir dans l’équipe pour un stage qui marquera ton parcours.</p><p><b>Harris souscrit à un programme d’accès à l’égalité en emploi.</b></p><p>Les candidatures des femmes, des personnes handicapées, des personnes autochtones et des minorités visibles sont encouragées. Si vous êtes une personne handicapée, vous pouvez recevoir, sur demande, de l’assistance pour le processus de présélection et de sélection.</p><p>L’équipe de recrutement de talents de Harris ne communique jamais par message texte pour solliciter des informations confidentielles. Nous encourageons tous les candidats à postuler uniquement aux postes publiés. Les personnes retenues seront contactées par un gestionnaire de Harris ou un membre de l’équipe de recrutement pour une entrevue.</p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251385,
"expiryDate": 1791435384,
"applicationLink": "https://himalayas.app/companies/harris-global-business-services-inc/jobs/stagiaire-en-architecture-technologique-socle-ia-corporatif",
"guid": "https://himalayas.app/companies/harris-global-business-services-inc/jobs/stagiaire-en-architecture-technologique-socle-ia-corporatif"
},
{
"title": "Senior Director, Brand & Communications",
"excerpt": "The Senior Director of Brand & Communications is a strategic and creative leader responsible for shaping and stewarding the voice, brand, and narrative of the organization across all internal and external channels, ensuring that every communication advances the organization’s mission, reflects its values, and tells the story of its impact and commitment to justice-centered philanthropy around the globe.",
"companyName": "Rockefeller Philanthropy Advisors",
"companySlug": "rockefeller-philanthropy-advisors",
"companyLogo": "",
"employmentType": "Full Time",
"minSalary": 195000,
"maxSalary": 205000,
"salaryPeriod": "annual",
"seniority": [
"Director",
"Executive"
],
"currency": "USD",
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"Brand-and-Communications-Director",
"Strategic-Communications",
"Corporate-Communications",
"Public-Relations-Leadership",
"Communications-Executive",
"Senior-Communications-Director",
"Senior-Director-Of-Communications-Marketing",
"Senior-Brand-Director",
"Director-Of-Marketing-Communications",
"Director-Of-Marketing-And-Communications",
"Marketing-And-Communications-Director",
"Marketing-Communications-Director",
"Senior-Director-Of-Marketing"
],
"parentCategories": [
"Marketing"
],
"description": "The Senior Director of Brand &amp; Communications is a strategic and creative leader responsible for shaping and stewarding the voice, brand, and narrative of the organization across all internal and external channels, ensuring that every communication advances the organization’s mission, reflects its values, and tells the story of its impact and commitment to justice-centered philanthropy around the globe. This role leads the development and execution of a comprehensive communications strategy that advances the organization’s mission and business development, strengthens its visibility and credibility, and fosters alignment and engagement among staff, partners, and the broader philanthropic and social impact ecosystem.<br><br>Reporting to the Co-Chief Executive Officer, the Director oversees all aspects of brand management, digital and media strategy, Office of the CEO and executive leadership communications, storytelling, and internal communications. This role ensures the organization’s communications reflect its values, highlight its work and impact, elevate its voice and visibility, and connect authentically with diverse philanthropy audiences—including grantees, funders, staff, global collaborators, and the public. The Senior Director understands the power of narrative to; drive systems change, promote RPA’s mission, commitment to equity, community-centered messaging.  the proven ability to translate complex work into compelling, accessible content.<h3>Accountabilities</h3><h3>Strategic Communications Strategy and Execution</h3><ul>\n<li><p>Develop a communications and branding strategy aligned with the organization’s mission and strategic plan.</p></li>\n<li><p>Partner with leadership as relevant to ensure clear, cohesive messaging in RPA’s voice across all internal and external platforms including newsletters, website, social media, and publications.</p></li>\n<li><p>Refine the organization’s voice, brand, and narrative in a way that centers justice and equity and is grounded in cultural competence.</p></li>\n<li><p>Determine approaches and messages that align with mission and brand that support RPA’s continued viability and sustainability, including key audience channels and aligned messages that support donor development and partnerships.</p></li>\n<li><p>Elevate the visibility of RPA’s thought leadership in partnership with Inquiry and Insights.</p></li>\n<li><p>Serve as strategic advisor to the Co-CEOs on messaging and public speaking.</p></li>\n</ul><h3>External Communications and Public Engagement</h3><ul>\n<li><p>Lead media relations, including proactive press outreach, rapid response, and relationship management with journalists and sector influencers.</p></li>\n<li><p>Oversee the digital strategy and content, including website, social media, newsletters, and multimedia storytelling and provide direction to the team on implementation.</p></li>\n<li><p>Partner with executive leadership and teams across the organization, including core teams, Advisory, and Sponsored Project leadership to support communication efforts around key initiatives, events, and campaigns and amplify programmatic, core operations, and thought leadership work.</p></li>\n<li><p>Maintains enterprise-wide awareness, including major sponsored project communications and provides executive counsel and risk-based communications guidance for complex, high-visibility, or sensitive matters that may impact the organization's reputation, stakeholders, or strategic objectives.</p></li>\n<li><p>Develop and oversee processes for tracking initiatives, campaigns, and outreach.</p></li>\n</ul><h3>Internal Communications</h3><ul>\n<li><p>Design and implement internal communications systems that strengthen employee connection, clarity, and alignment.</p></li>\n<li><p>Collaborate with core teams to ensure transparent and timely communication during change, growth, or strategic planning efforts.</p></li>\n<li><p>Build resources to support staff in communications opportunities and engagements (e.g., media training, message alignment, sharing on social media, etc.).</p></li>\n</ul><h3>Media, Brand Stewardship, &amp; Visibility</h3><ul>\n<li><p>Refine and protect the organization’s brand identity and voice across all touchpoints, ensuring alignment with values of justice, equity, trust, and community.</p></li>\n<li><p>Oversee brand assets and ensure consistency across visual design, tone, and messaging.</p></li>\n<li><p>Manage organizational media presence, including pitching, placements, and media relationships.</p></li>\n<li><p>Partner with functional leaders to develop, manage, and curate strategic visibility opportunities for Co-CEOs, executive leadership, and colleagues, thoughtfully positioning them to represent RPA externally.</p></li>\n<li><p>Maintain and strengthen a coherent, values-aligned brand identity and experience.</p></li>\n</ul><h3>Complexity and Problem-solving</h3><ul>\n<li><p>Uses expertise to act as an organizational authority on planning, organizing, prioritizing, and overseeing communications activities to efficiently meet RPA’s objectives.</p></li>\n<li><p>Exercises independent judgment in developing solutions to apply a comprehensive understanding of the sector environment and the organization’s objectives, developing solutions while providing guidance to others.</p></li>\n<li><p>Applies expertise to act as the organizational authority on maximizing RPA’s brand impact and market value by managing and developing all aspects of the brand.</p></li>\n<li><p>Works at an advanced level and exercises broad decision-making authority in developing communications and brand strategies, navigating ambiguity, balancing competing priorities, and aligning leaders to achieve organizational objectives.</p></li>\n</ul><h3>Supervisory Responsibility </h3><ul>\n<li><p>Direct supervision of communications staff</p></li>\n<li><p>Management of external vendors, agencies, and consultants</p></li>\n<li><p>Collaboration with cross-functional leaders on integrated campaigns and messaging.</p></li>\n</ul><h3>Travel Requirements</h3><h3>Some travel may be required.</h3><h3>Key Qualifications and Experiences</h3><ul>\n<li><p>Bachelor's degree in communications, journalism, marketing, public relations, or related field or equivalent experience required (12+ years).</p></li>\n<li><p>Exceptional writing, editing, and verbal communications skills</p></li>\n<li><p>Proven senior level experience developing and executing communications strategies, including digital strategy, in a nonprofit, philanthropic, or mission-driven organization.</p></li>\n<li><p>Strong understanding of social justice, equity-focused language, and narrative change principles.</p></li>\n<li><p>Track record of managing media relationships, digital platforms, and brand identity systems.</p></li>\n<li><p>Familiarity with philanthropy sector audiences and the communications nuances of donor/grantee/stakeholder engagement.</p></li>\n</ul><p><i>At <a href=\"https://himalayas.app/companies/rockefeller-philanthropy-advisors\">Rockefeller Philanthropy Advisors</a>, our mission is to accelerate philanthropy in pursuit of a just world, by providing deep global expertise to make philanthropy more thoughtful, equitable and effective.</i></p><ul>\n<li><p><i>We believe that philanthropy can help create a better world</i></p></li>\n<li><p><i>We make decisions that center people and communities.</i></p></li>\n<li><p><i>We believe philanthropy has a responsibility to pursue equity.</i></p></li>\n<li><p><i>We uphold the highest standards of integrity and trust.</i></p></li>\n<li><p><i>We are committed to learning and sharing knowledge.</i></p></li>\n</ul><p>If our mission resonates with you, we encourage you to apply even if you don’t meet every qualification listed. You may bring valuable perspectives and experiences that aren’t captured here but could contribute meaningfully to our work. We’re excited to learn what you can offer.</p><p>Compensation &amp; Benefits</p><p><a href=\"https://himalayas.app/companies/rockefeller-philanthropy-advisors\">Rockefeller Philanthropy Advisors</a> offers a competitive compensation and benefits package including health coverage, retirement benefits, paid sick leave, vacationand holidays, tuitionreimbursement and access to professional development resources.</p><p>The salary range is one component of the total compensation package for employees.</p><p>Pay Range: $195,000 - $205,000 salary per year</p><p>Application Process</p><p>Applications will be reviewed as received. In order to be considered, all applications must include a cover letter describing your interest and qualifications and your resume. The position will remain open until filled.</p><p><a href=\"https://himalayas.app/companies/rockefeller-philanthropy-advisors\">Rockefeller Philanthropy Advisors</a> celebrates the uniqueness of our staff, our partners, and the communities we serve. We are committed to inclusion with the goal of cultivating a culture of belonging and acceptance. We strive to embed this value in our philanthropic work to advance a more just, equitable and sustainable world.</p><p><i>RPA is an equal opportunity employer.</i></p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251362,
"expiryDate": 1791435361,
"applicationLink": "https://himalayas.app/companies/rockefeller-philanthropy-advisors/jobs/senior-director-brand-communications",
"guid": "https://himalayas.app/companies/rockefeller-philanthropy-advisors/jobs/senior-director-brand-communications"
},
{
"title": "Project Assistant - Sales",
"excerpt": "Job Summary:Assists a project manager in applying process and project management skills within an area of business or technical specialty.",
"companyName": "Cummins",
"companySlug": "cummins",
"companyLogo": "https://cdn-images.himalayas.app/shpftekah0y9svh1us5kvcxq7041",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Entry-level"
],
"currency": null,
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"Project-Assistant",
"Project-Coordinator",
"Sales-Support",
"Project-Management",
"Administrative-Support",
"Projects-Assistant",
"Project-Management-Assistant",
"Sales-Assistant"
],
"parentCategories": [
"Operations",
"Sales"
],
"description": "<h3>Job Summary:</h3><p>Assists a project manager in applying process and project management skills within an area of business or technical specialty. Supports the management of small portions of well defined projects. Provides administrative and logistics support for a project team and project manager.</p><p>We are looking for a talented Remote Project Assistant (Sales) to join our Distribution business. </p><h3>100% Remote</h3><p>Will make an impact in the following ways:</p><ul>\n<li>Support project managers with project planning, execution, tracking, and reporting activities.</li>\n<li>Assist in monitoring project schedules, budgets, risks, and deliverables to ensure successful project completion.</li>\n<li>Maintain project records, databases, documentation, and status updates.</li>\n<li>Coordinate communication between project teams, stakeholders, and customers.</li>\n<li>Support issue and risk management activities and help drive timely resolution of project-related concerns.</li>\n<li>Prepare reports, analyze project data, and provide administrative support for project initiatives.</li>\n<li>Adhere to <a href=\"https://himalayas.app/companies/cummins\">Cummins</a> Health, Safety &amp; Environmental policies.</li>\n</ul><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251353,
"expiryDate": 1791435352,
"applicationLink": "https://himalayas.app/companies/cummins/jobs/project-assistant-sales",
"guid": "https://himalayas.app/companies/cummins/jobs/project-assistant-sales"
},
{
"title": "Senior Data Governance Analyst",
"excerpt": "What is this position about? • Execute and support enterprise Data Governance initiatives and governance processes end to end • Create and maintain governance documentation, standards, and procedures • Perform data analysis and data profiling to identify quality issues and opportunities for improvement • Assist with metadata management activities, including documenting and maintaining business and technical metadata • Leverage AI-powered data governance tools to automate data classification and tagging, identify sensitive or non-compliant data, and support governance workflows • Monitor data assets for compliance with governance policies, identifying potential violations and recommending corrective actions • Support the implementation and validation of AI-assisted data retention, archival, and lifecycle management policies • Validate data governance controls and ensure compliance with established governance policies and regulatory requirements • Document business definitions, data rules, and governance requirements in collaboration with business stakeholders • Support data stewardship activities and contribute to improving data quality across critical data domains • Collaborate with cross-functional teams to gather requirements and translate business needs into governance documentation • Monitor governance activities and contribute to continuous process improvements • Communicate governance updates, findings, and recommendations effectively to both technical and non-technical stakeholders • Bachelor’s degree in Information Systems, Computer Science, Data Analytics, Business, or a related field.",
"companyName": "Blend360",
"companySlug": "blend360",
"companyLogo": "https://cdn-images.himalayas.app/00gyachjaqmrba03b1psqunwrrjd",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Senior"
],
"currency": null,
"locationRestrictions": [
"Mexico"
],
"timezoneRestrictions": [
-8,
-7,
-6,
-5
],
"categories": [
"Data-Governance",
"Data-Governance-Analyst",
"Data-Management",
"Metadata-Management",
"Data-Quality",
"Senior-Data-Governance-Developer",
"Senior-Data-Governance-and-Metadata-Scientist",
"Data-Governance-Lead",
"Senior-Data-Steward",
"Data-Governance-Manager"
],
"parentCategories": [
"Data Science"
],
"description": "<h3>What is this position about?</h3><ul>\n<li>Execute and support enterprise Data Governance initiatives and governance processes end to end</li>\n<li>Create and maintain governance documentation, standards, and procedures</li>\n<li>Perform data analysis and data profiling to identify quality issues and opportunities for improvement</li>\n<li>Assist with metadata management activities, including documenting and maintaining business and technical metadata</li>\n<li>Leverage AI-powered data governance tools to automate data classification and tagging, identify sensitive or non-compliant data, and support governance workflows</li>\n<li>Monitor data assets for compliance with governance policies, identifying potential violations and recommending corrective actions</li>\n<li>Support the implementation and validation of AI-assisted data retention, archival, and lifecycle management policies</li>\n<li>Validate data governance controls and ensure compliance with established governance policies and regulatory requirements</li>\n<li>Document business definitions, data rules, and governance requirements in collaboration with business stakeholders</li>\n<li>Support data stewardship activities and contribute to improving data quality across critical data domains</li>\n<li>Collaborate with cross-functional teams to gather requirements and translate business needs into governance documentation</li>\n<li>Monitor governance activities and contribute to continuous process improvements</li>\n<li>Communicate governance updates, findings, and recommendations effectively to both technical and non-technical stakeholders</li>\n</ul><ul>\n<li>Bachelor’s degree in Information Systems, Computer Science, Data Analytics, Business, or a related field.</li>\n<li>Approximately <strong>3+ years of experience</strong> in Data Governance, Data Management, Business/Data Analysis, or related areas.</li>\n<li>Experience with data governance platforms such as <strong>Atlan</strong>,<strong> Collibra</strong>, <strong>Alation</strong>, or similar governance workflow and metadata management tools.</li>\n<li>Experience in PII discovery and confidence scoring (required)</li>\n<li>Experience with data masking through AI agents (required)</li>\n<li>Hands-on AWS experience, including S3, cleanup processes, Glue, AgentCore, and Lambda functions (required)</li>\n<li>Knowledge of CoCo and Cortex is a plus</li>\n</ul><h3>What about languages?</h3><ul><li>Advanced English (written and verbal) preferred.</li></ul><h3>How much experience must I have?</h3><ul><li>Approximately <strong>3+ years</strong> of professional experience in Data Governance, Data Analysis, Business Analysis, Data Management, or related disciplines.</li></ul><h3>Our perks and benefits:</h3><h3>📚 Learning Opportunities:</h3><ul>\n<li>Certifications in AWS (we are AWS Partners), Databricks, and Snowflake.</li>\n<li>Access to AI learning paths to stay up to date with the latest technologies.</li>\n<li>Study plans, courses, and additional certifications tailored to your role.</li>\n<li>Access to Udemy Business, offering thousands of courses to boost your technical and soft skills.</li>\n<li>English lessons to support your professional communication.</li>\n</ul><p>👨🏽‍💻 Travel opportunities to attend industry conferences and meet clients.</p><h3>👩‍🏫 Mentoring and Development:</h3><ul><li>Career development plans and mentorship programs to help shape your path.</li></ul><h3>🎁 Celebrations &amp; Support:</h3><ul>\n<li>Special day rewards to celebrate birthdays, work anniversaries, and other personal milestones.</li>\n<li>Company-provided equipment.</li>\n</ul><p>⚖️ Flexible working options to help you strike the right balance.</p><h3>🏥 Statutory Benefits:</h3><ul>\n<li>Social security coverage (IMSS).</li>\n<li>Christmas bonus (Aguinaldo) as per Mexican law.</li>\n<li>Vacation premium (Prima Vacacional).</li>\n<li>Remote work bonus.</li>\n<li>Paid leaves as per Federal Labor Law (LFT).</li>\n<li>Additional benefits as required by Mexican labor regulations.</li>\n</ul><p>Other benefits may vary. For detailed information, please consult with one of our recruiters.</p><p>Blend is a premier AI services provider, committed to co-creating meaningful impact for its clients through the power of data science, AI, technology, and people. With a mission to fuel bold visions, Blend tackles significant challenges by seamlessly aligning human expertise with artificial intelligence. The company is dedicated to unlocking value and fostering innovation for its clients by harnessing world-class people and data-driven strategy. We believe that the power of people and AI can have a meaningful impact on your world, creating more fulfilling work and projects for our people and clients. For more information, visit www.blend360.com<br><br>We are seeking a <strong>Senior</strong><strong>Data Governance Analyst</strong> to contribute to our next level of growth and expansion.</p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251351,
"expiryDate": 1791435350,
"applicationLink": "https://himalayas.app/companies/blend360/jobs/senior-data-governance-analyst",
"guid": "https://himalayas.app/companies/blend360/jobs/senior-data-governance-analyst"
},
{
"title": "Enterprise Generative AI Platform Engineer",
"excerpt": "Job Title: Enterprise Generative AI Platform Engineer Job Location: Washington D.",
"companyName": "Lifelancer",
"companySlug": "lifelancer",
"companyLogo": "https://cdn-images.himalayas.app/ztdsyzatuliky237a5zq922sir0k",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Mid-level"
],
"currency": null,
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"Enterprise-Generative-AI-Platform-Engineer",
"AI-Platform-Engineering",
"Technical-Enablement",
"AI-Product-Management",
"Enterprise-AI-Adoption",
"AI-Platform-Engineer",
"Generative-AI-Engineer",
"Senior-Generative-AI-Engineer",
"Enterprise-AI-Engineer",
"Lead-AI-Platform-Engineer",
"Senior-AI-Platform-Engineer"
],
"parentCategories": [
"Data Science"
],
"description": "<p><b>Job Title: </b>Enterprise Generative AI Platform Engineer</p><p><b>Job Location: </b>Washington D.C., District of Columbia, United States</p><p><b>Job Location Type: </b>Remote</p><p><b>Job Contract Type: </b>Full-time</p><h3>Job Seniority Level: </h3><h3>Join Amgen’s Mission of Serving Patients</h3><p>At Amgen, if you feel like you’re part of something bigger, it’s because you are. Our shared mission—to serve patients living with serious illnesses—drives all that we do.</p><p>Since 1980, we’ve helped pioneer the world of biotech in our fight against the world’s toughest diseases. With our focus on four therapeutic areas –Oncology, Inflammation, General Medicine, and Rare Disease– we reach millions of patients each year. Amgen is advancing a broad and deep pipeline of medicines to treat cancer, heart disease, inflammatory conditions, rare diseases, and obesity and obesity-related conditions. As a member of the Amgen team, you’ll help make a lasting impact on the lives of patients as we research, manufacture, and deliver innovative medicines to help people live longer, fuller happier lives.</p><p>Our award-winning culture is collaborative, innovative, and science based. If you have a passion for challenges and the opportunities that lay within them, you’ll thrive as part of the Amgen team. Join us and transform the lives of patients while transforming your career.</p><h3>Enterprise Generative AI Platform Engineer</h3><h3><b>What you will do</b></h3><p>Let’s do this. Let’s change the world. In this vital role you will help Amgen turn approved AI capabilities into practical, responsible and repeatable solutions. This individual contributor will support platforms such as ChatGPT Enterprise, custom GPTs and related services; connect user needs with platform capability; guide use-case intake; and create reusable guidance. You will partner with Product, Engineering, Security, Privacy, Compliance, Legal and business teams to improve adoption and measurable value.</p><h3>Roles &amp; Responsibilities: </h3><ul>\n<li>Support enterprise generative AI capabilities, including ChatGPT Enterprise, custom GPTs and related tools.</li>\n<li>Help teams clarify use cases, assess fit and risk, and identify an appropriate delivery path.</li>\n<li>Turn user feedback into prioritized requirements, reusable patterns, templates and self-service guidance.</li>\n<li>Partner with Product, Engineering, Security, Privacy, Compliance and Legal teams to support responsible use and practical governance.</li>\n<li>Support pilots, workshops, office hours and demonstrations that build confidence and surface adoption barriers.</li>\n<li>Track adoption and feedback, then communicate platform updates and recommendations for improvement.</li>\n</ul><h3><b>What we expect of you</b></h3><p>We are all different, yet we all use our unique contributions to serve patients. The professional we seek is an Enterprise Generative AI Platform Engineer with these qualifications:</p><h3>Must-Have Skills:</h3><ul>\n<li>Experience in enterprise technology, technical enablement, internal tools, product, solutions or a related field.</li>\n<li>Practical familiarity with generative AI platforms, custom assistants or GPTs, and common enterprise use cases.</li>\n<li>Ability to assess use cases for user value, feasibility, risk and scalability.</li>\n<li>Strong communication and stakeholder skills, including translating technical capabilities into clear guidance.</li>\n<li>Ability to collaborate effectively with business, engineering, security and governance partners.</li>\n</ul><h3>Good-to-Have Skills:</h3><ul>\n<li>Experience with ChatGPT Enterprise, custom GPTs or comparable generative AI platforms.</li>\n<li>Experience supporting technology adoption through training, office hours or communities of practice.</li>\n<li>Familiarity with responsible AI, privacy, information security or access management.</li>\n<li>Experience in biotechnology, pharmaceuticals, healthcare or another regulated industry.</li>\n</ul><h3>Education and Professional Certifications</h3><ul>\n<li>Master’s degree with 2+ years of experience in Computer Science, Information Technology, Engineering, Product Management, Business or a related field</li>\n<li>OR</li>\n<li>Bachelor’s degree with 5+ years of experience in Computer Science, Information Technology, Engineering, Product Management, Business or a related field</li>\n<li>Relevant certifications in generative AI, cloud platforms, product management, program management, change management or information security are a plus.</li>\n</ul><h3>Soft Skills:</h3><ul>\n<li>Clear written, verbal, facilitation and presentation skills.</li>\n<li>Curiosity, initiative and the ability to learn new capabilities quickly.</li>\n<li>Organized approach to managing priorities and following through on commitments.</li>\n<li>Collaborative, team-oriented approach with global and virtual partners.</li>\n</ul><h3><b>What you can expect of us</b></h3><p>As we work to develop treatments that take care of others, we also work to care for your professional and personal growth and well-being. From our competitive benefits to our collaborative culture, we’ll support your journey every step of the way.</p><p>The expected annual salary range for this role in the U.S. (excluding Puerto Rico) is posted. Actual salary will vary based on several factors including but not limited to, relevant skills, experience, and qualifications.</p><p>In addition to the base salary, Amgen offers a Total Rewards Plan, based on eligibility, comprising of health and welfare plans for staff and eligible dependents, financial plans with opportunities to save towards retirement or other goals, work/life balance, and career development opportunities that may include:</p><ul>\n<li>A comprehensive employee benefits package, including a Retirement and Savings Plan with generous company contributions, group medical, dental and vision coverage, life and disability insurance, and flexible spending accounts</li>\n<li>A discretionary annual bonus program, or for field sales representatives, a sales-based incentive plan</li>\n<li>Stock-based long-term incentives</li>\n<li>Award-winning time-off plans</li>\n<li>Flexible work models where possible. Refer to the Work Location Type in the job posting to see if this applies.</li>\n</ul><h3>Apply now and make a lasting impact with the Amgen team.</h3><h3><b>careers.amgen.com</b></h3><p>In any materials you submit, you may redact or remove age-identifying information such as age, date of birth, or dates of school attendance or graduation. You will not be penalized for redacting or removing this information.</p><h3>Application deadline</h3><p>Amgen does not have an application deadline for this position; we will continue accepting applications until we receive a sufficient number or select a candidate for the position.</p><h3>Sponsorship</h3><p>Sponsorship for this role is not guaranteed.</p><p>As an organization dedicated to improving the quality of life for people around the world, Amgen fosters an inclusive environment of diverse, ethical, committed and highly accomplished people who respect each other and live the Amgen values to continue advancing science to serve patients. Together, we compete in the fight against serious disease.</p><p>Amgen is an Equal Opportunity employer and will consider all qualified applicants for employment without regard to race, color, religion, sex, sexual orientation, gender identity, national origin, protected veteran status, disability status, or any other basis protected by applicable law.</p><p>We will ensure that individuals with disabilities are provided reasonable accommodation to participate in the job application or interview process, to perform essential job functions, and to receive other benefits and privileges of employment. Please contact us to request accommodation.</p><br><br><h3>This job is curated by <a href=\"https://himalayas.app/companies/lifelancer\">Lifelancer</a>.</h3><p><strong><a href=\"https://himalayas.app/companies/lifelancer\">Lifelancer</a> is a talent-hiring platform in Life Sciences, Pharma and IT. The platform connects talent with opportunities in pharma, biotech, health sciences, healthtech and IT domains.</strong></p><p><strong>Please apply via <a href=\"https://himalayas.app/companies/lifelancer\">Lifelancer</a> platform to get connected to the application page and to find  similar roles.</strong></p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251271,
"expiryDate": 1791435269,
"applicationLink": "https://himalayas.app/companies/lifelancer/jobs/enterprise-generative-ai-platform-engineer",
"guid": "https://himalayas.app/companies/lifelancer/jobs/enterprise-generative-ai-platform-engineer"
},
{
"title": "Insurance Follow-Up Representative",
"excerpt": "Imagine a career at one of the nation's most advanced health networks.",
"companyName": "Lehigh Valley Health Network",
"companySlug": "lehigh-valley-health-network",
"companyLogo": "https://cdn-images.himalayas.app/b7jngaggay94u4syrptw3hg4eon2",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Entry-level"
],
"currency": null,
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"Insurance-Follow-Up-Representative",
"Medical-Billing",
"Patient-Accounting",
"Healthcare-Revenue-Cycle",
"Accounts-Receivable-Specialist",
"Insurance-Follow-Up-Specialist",
"Claims-Follow-Up-Representative",
"Billing-Follow-Up-Representative",
"Insurance-Customer-Service-Representative"
],
"parentCategories": [],
"description": "<p>Imagine a career at one of the nation's most advanced health networks.</p><p>Be part of an exceptional health care experience. Join the inspired, passionate team at <a href=\"https://himalayas.app/companies/lehigh-valley-health-network\">Lehigh Valley Health Network</a>, a nationally recognized, forward-thinking organization offering plenty of opportunity to do great work.</p><p>LVHN has been ranked among the \"Best Hospitals\" by U.S. News &amp; World Report for 23 consecutive years. We're a Magnet(tm) Hospital, having been honored five times with the American Nurses Credentialing Center's prestigious distinction for nursing excellence and quality patient outcomes in our Lehigh Valley region. Finally, Lehigh Valley Hospital - Cedar Crest, Lehigh Valley Hospital - Muhlenberg, Lehigh Valley Hospital- Hazleton, and Lehigh Valley Hospital - Pocono each received an 'A' grade on the Hospital Safety Grade from The Leapfrog Group in 2020, the highest grade in patient safety. These recognitions highlight LVHN's commitment to teamwork, compassion, and technology with an unrelenting focus on delivering the best health care possible every day.</p><p>Whether you're considering your next career move or your first, you should consider <a href=\"https://himalayas.app/companies/lehigh-valley-health-network\">Lehigh Valley Health Network</a>.</p><br><b>Summary</b><br>Works collaboratively with department leadership to review and manage open Accounts Receivable, accurately documenting follow-up activities resulting in the resolution of underpayments and denials.  Conducts root cause analysis of denials and takes the action necessary to resolve the denial escalating accounts to management that need to be submitted to the provider representative for contracting action.  Identifies denial and underpayment trends that require computer system modifications and recommends necessary to implement corrective action.  Prepares reports for meetings with provider representative and senior leadership, as required.<br><br><b>Job Duties</b><ul>\n<li>Demonstrates knowledge of insurance carrier reimbursement requirements to evaluate underpayments that are related to insurance carrier clinical and payment policies.</li>\n<li>Demonstrates the ability to apply LVHN insurance contracts terms to claim payment reviews and the ability to determine if the source of an underpayment is related to a contract management discrepancy, an underpayment, or a line item denial.</li>\n<li>Conducts a root cause analysis of denials, taking the appropriate corrective action as required, escalating denial trends to management, and routing denials to the appropriate area for resolution.</li>\n<li>Calculates and submits adjustment and refund requests utilizing the appropriate adjustment code, refund reason, and clearly documents the account history.</li>\n<li>Identifies the patient out of pocket expense related to non-covered services, co-pays, deductible, and co-insurance allocating the patient responsibility to the patient within the timely filing limit.</li>\n<li>Demonstrates knowledge of and compliance with established organizational and departmental policies, procedures, objectives and goals.</li>\n<li>Works collaboratively with management to establish issue logs and account examples for meetings with the insurance carrier provider rep.</li>\n<li>Responds and reviews all emails and correspondence within 24-48 hours, manages mail received from patients and insurance carriers for appropriate distribution.</li>\n</ul><br><b>Minimum Qualifications</b><ul>\n<li>High School Diploma/GED    </li>\n<li>2 years of professional or facility billing and/or collections for all major third party payers or work experience in healthcare related field.  </li>\n<li>Excellent follow-up and verification skills. </li>\n<li>Excellent verbal and written communication skills. </li>\n<li>Knowledge of insurance contracts, and regulations. </li>\n<li>Proficient with Microsoft Excel, Word, and PowerPoint applications. </li>\n<li>Strong analytical, mathematical and organizational skills. </li>\n<li>Successful Completion of DOE and Revenue Cycle Education Training within 3 months of hire. </li>\n</ul><br><b>Preferred Qualifications</b><ul>\n<li>Associate’s Degree in Health Care Science, Business or related field.   </li>\n<li>CPAT - Certified Patient Accounting Technician - State of Pennsylvania    </li>\n</ul><br><b>Physical Demands</b><br>Lift and carry 25 lbs. frequent sitting/standing, frequent keyboard use, *patient care providers may be required to perform activities specific to their role including kneeling, bending, squatting and performing CPR.<br><br>Job Description Disclaimer:  This position description provides the major duties/responsibilities, requirements and working conditions for the position. It is intended to be an accurate reflection of the current position, however management reserves the right to revise or change as necessary to meet organizational needs. Other responsibilities may be assigned when circumstances require.<p><a href=\"https://himalayas.app/companies/lehigh-valley-health-network\">Lehigh Valley Health Network</a> is an equal opportunity employer. In accordance with, and where applicable, in addition to federal, state and local employment regulations, <a href=\"https://himalayas.app/companies/lehigh-valley-health-network\">Lehigh Valley Health Network</a> will provide employment opportunities to all persons without regard to race, color, religion, sex, age, national origin, sexual orientation, gender identity, disability or other such protected classes as may be defined by law. All personnel actions and programs will adhere to this policy. Personnel actions and programs include, but are not limited to recruitment, selection, hiring, transfers, promotions, terminations, compensation, benefits, educational programs and/or social activities.</p><p></p><p><a href=\"https://himalayas.app/companies/lehigh-valley-health-network\">Lehigh Valley Health Network</a> does not accept unsolicited agency resumes. Agencies should not forward resumes to our job aliases, our employees or any other organization location. <a href=\"https://himalayas.app/companies/lehigh-valley-health-network\">Lehigh Valley Health Network</a> is not responsible for any agency fees related to unsolicited resumes.</p><h3>Work Shift:</h3>Day Shift<h3>Address:</h3>1200 S Cedar Crest Blvd<h3>Primary Location: </h3>REMOTE IN PENNSYLVANIA<h3>Position Type:</h3>Remote<h3>Union:</h3>Not Applicable<h3>Work Schedule:</h3>Monday-Friday; 8:00a-4:30p<h3>Department:</h3>1004-13054 CSS-Patient Accounting<p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251261,
"expiryDate": 1791435260,
"applicationLink": "https://himalayas.app/companies/lehigh-valley-health-network/jobs/insurance-follow-up-representative",
"guid": "https://himalayas.app/companies/lehigh-valley-health-network/jobs/insurance-follow-up-representative"
},
{
"title": "Creative Marketing Team Lead",
"excerpt": "Хочеш будувати команду та створювати найкращі рекламні креативи на ринку?",
"companyName": "Honeytech",
"companySlug": "honeytech",
"companyLogo": "https://cdn-images.himalayas.app/g2rvptetn2fszlpqw4021ku3df94",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Manager"
],
"currency": null,
"locationRestrictions": [
"Ukraine"
],
"timezoneRestrictions": [
2,
3
],
"categories": [
"Creative-Marketing-Team-Lead",
"Marketing-Team-Lead",
"Digital-Marketing-Manager",
"Performance-Marketing",
"Marketing-Leadership",
"Creative-Marketing-Lead",
"Creative-Team-Lead",
"Creative-Marketing-Manager"
],
"parentCategories": [
"Marketing"
],
"description": "<p><strong>Хочеш будувати команду та створювати найкращі рекламні креативи на ринку? Ми у пошуках амбітного та креативного Сreative Marketing Team Lead!</strong></p><p>Ми, <strong><a href=\"https://himalayas.app/companies/honeytech\">Honeytech</a></strong> – динамічний, швидкозростаючий проект, що створив платформу з коміксами в азійській стилістиці та вже став № 1 у своїй ніші! Уяви Netflix, але для коміксів – лише за кілька років ми зібрали 10+ мільйонів користувачів, кинули виклик гігантам з Південної Кореї й довели, що можемо будувати продукт світового рівня з України!</p><h3>Що чекає на тебе з нами?</h3><ul>\n<li><p>🚀 Динамічний розвиток: минулого року наш проект виріс у 10 разів і ми продовжуємо набирати оберти – запускаємо нові продукти та плануємо зрости ще втричі!</p></li>\n<li><p>📈 Можливості твого швидкого карʼєрного зростання: це позиція з горизонтом зростання, ширшою зоною впливу, стратегічними рішеннями та побудовою напрямку під себе.</p></li>\n<li><p>🎯 Глибоке розуміння перформансу: наші креативні маркетологи напряму працюють з UAM-командою: знають, як і де запускаються їхні креативи, бачать результати в реальному часі та можуть самостійно лити трафік за бажанням і для прокачки експертизи.</p></li>\n<li><p>🤩Пряма комунікація та прозорі процеси: ми любимо здоровий глузд більше, ніж заплутані процедури та уникаємо зайву бюрократію.</p></li>\n<li><p>📊Сильна аналітика та підтримка data-команди: доступ до ключових метрик, продумана аналітична інфраструктура та окрема аналітична команда. Працюємо з Tableau, тому всі рішення – на основі цифр, а не інтуїції.</p></li>\n</ul><h3>Твоя майбутня зона відповідальності:</h3><ul>\n<li><p>Менеджмент Creative Marketing team та участь у всіх процесах повʼязаних з управлінням, мотивацією та розвитком команди.</p></li>\n<li><p>Впровадження та створення інноваційних і успішних креативних методів.</p></li>\n<li><p>Проведення якісного аналізу ринкових трендів і конкурентів, визначення основних тенденцій для створення рекламних креативів, можливостей для зростання та перспектив масштабування.</p></li>\n<li><p>Співпраця з product та user acquisition командами для забезпечення ефективного планування та виконання цілей.</p></li>\n<li><p>Оцінка ефективності поточних креативів і розробка стратегій для покращення результатів.</p></li>\n</ul><h3>Ти наш ідеальний кандидат, якщо маєш:</h3><ul>\n<li><p>Від <strong>2 років</strong> досвіду в креативному маркетингу з розумінням, як креатив впливає на перформанс.</p></li>\n<li><p><strong>Досвід менторства</strong> або <strong>менеджменту</strong> команди/молодших колег.</p></li>\n<li><p>Орієнтація на метрики та <strong>Data-driven підхід</strong> в роботі.</p></li>\n<li><p><strong>Лідерські якості</strong> та вміння вести команду за собою – мотивувати, задавати напрямок і рухатись до спільного результату.</p></li>\n<li><p>Володіння англійською мовою на рівні <strong>Upper-Intermediate</strong> та вище.</p></li>\n</ul><h3>Цікаво, що ще пропонуємо?</h3><ul>\n<li><p>Робота на найбільш конкурентних ринках Tier1 (США, Канада, Британія, Австралія і т.д), що дозволяє стати експертом у своїй справі.</p></li>\n<li><p>Віддалена робота або можливість працювати з нашого офісу в Києві, що повністю обладнаний для роботи під час відключень світла + можливість користуватись коворкінгом у Варшаві та Львові.</p></li>\n<li><p>20 робочих днів відпустки на рік (після 3 місяців співпраці) та до 30 днів sick leave з медичним підтвердженням. А також можливість трансферу робочих днів та days off по державних святах України.</p></li>\n<li><p>Веселі тімбілдінги та корпоративні подорожі.</p></li>\n<li><p>Програма HoneyFit — компенсація спортивних активностей та івентів, оффлайн/онлайн тренувань тощо (по завершенню випробувального терміну).</p></li>\n<li><p>Допомога в релокації, оплата коворкінгів або допомога у придбанні зарядних станцій для комфортної роботи під час відключення електропостачання (після 3х місяців співпраці).</p></li>\n<li><p>Різноманітні можливості для навчання: доповіді спікерів у різноманітних напрямах, велика корпоративна бібліотека, компенсація зовнішніх курсів і, звичайно, уроки англійської мови + speaking clubs.</p></li>\n<li><p>Внутрішня корпоративна валюта Boosta coins.</p></li>\n<li><p>Але найголовніше: <a href=\"https://himalayas.app/companies/honeytech\">Honeytech</a> — це команда професіоналів, де кожний відчуває підтримку та досягає своїх цілей!</p></li>\n</ul><p><strong>Відчуваєш метч? Це не випадково 😉Надсилай своє резюме та давай знайомитись!</strong></p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251247,
"expiryDate": 1791435247,
"applicationLink": "https://himalayas.app/companies/honeytech/jobs/creative-marketing-team-lead",
"guid": "https://himalayas.app/companies/honeytech/jobs/creative-marketing-team-lead"
},
{
"title": "HR Operations Manager",
"excerpt": "About BJAKThe original mission of BJAK is we believe people deserve smarter ways to plan, save and grow their money.",
"companyName": "Bjak",
"companySlug": "bjak",
"companyLogo": "https://cdn-images.himalayas.app/8ub8wtihrfrm3vfivlkcojai4np3",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Manager"
],
"currency": null,
"locationRestrictions": [
"China"
],
"timezoneRestrictions": [
6,
8
],
"categories": [
"HR-Operations-Manager",
"People-Operations-Manager",
"Senior-HR-Operations-Manager",
"Operations-and-HR-Manager",
"HR-Operations-Lead"
],
"parentCategories": [
"Human Resources"
],
"description": "<h3>About BJAK</h3><p>The original mission of BJAK is we believe people deserve smarter ways to plan, save and grow their money. This is the origin of our name.</p><p>Started in 2019, we built the first mobile-first insurance platform, enabling insurance to be accessible online by millions in the region. Today, it's the leading insurance platform in Southeast Asia.</p><p>Today, we are expanding ways to help people in the region — this includes spending, saving, investing, exchanging, travelling, and more. Our mission is to help people get more from their money every day.</p><p>We have teams working around the world, with over 20 nationalities across our offices and remote locations. We are looking for people who enjoy building, improving, and solving problems.</p><h3>About the Role</h3><p>You will lead HR Operations for BJAK's global team.</p><p>You will own the operational foundation that supports employees across multiple countries, ensuring HR processes are accurate, compliant, and scalable as the company grows.</p><p>This is a hands-on role. You will build and improve HR processes, manage global HR operations, and work with local partners and vendors to ensure a consistent employee experience across different markets.</p><h3>What You Will Be Doing</h3><ul>\n<li><p>Own HR operations across the global employee lifecycle, including onboarding, transfers, promotions, and offboarding</p></li>\n<li><p>Build and improve HR processes, policies, and SOPs that can scale across multiple countries</p></li>\n<li><p>Oversee global HR systems, employee records, reporting, and data governance</p></li>\n<li><p>Manage payroll coordination, benefits administration, employment documentation, and statutory compliance with local partners and EOR providers where applicable</p></li>\n<li><p>Ensure HR operations remain accurate, compliant, and audit-ready across all locations</p></li>\n<li><p>Improve operational efficiency through process redesign, automation, and system improvements</p></li>\n<li><p>Lead and develop the HR Operations function while partnering with leadership to support global expansion</p></li>\n</ul><h3>What You Will Need</h3><ul>\n<li><p>7+ years of experience in HR Operations, People Operations, or HR Administration</p></li>\n<li><p>Experience supporting employees across multiple countries or regions</p></li>\n<li><p>Strong understanding of global HR operations, employment documentation, payroll coordination, HR systems, and compliance</p></li>\n<li><p>Experience building and improving HR processes in a fast-growing company</p></li>\n<li><p>Strong operational mindset with high attention to detail</p></li>\n<li><p>Comfortable balancing hands-on execution with process improvement</p></li>\n<li><p>Strong communication and stakeholder management skills</p></li>\n<li><p>Ability to work across different countries, cultures, and time zones</p></li>\n</ul><h3>Location</h3><p>This role is remote, but candidates must be based in China. We are hiring specifically for this market, so applicants should already be based in China.</p><h3>Language</h3><p>English is our main working language across global teams. Strong English communication is required.</p><h3>Interview Process</h3><h3>Our process is designed to move fast:</h3><h3>1. Online assessment or practical task</h3><h3>2. Role-specific interview</h3><h3>3. CEO / final round</h3><p>For strong candidates, we aim to complete the process and make an offer within 1 week from the start of the interview process. Candidates who complete assessments quickly will be prioritized.</p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251243,
"expiryDate": 1791435242,
"applicationLink": "https://himalayas.app/companies/bjak/jobs/hr-operations-manager",
"guid": "https://himalayas.app/companies/bjak/jobs/hr-operations-manager"
},
{
"title": "IT Service Desk Analyst I",
"excerpt": "Department: 12263 Enterprise Corporate - Service DeskStatus: Full timeBenefits Eligible: YesHours Per Week: 40Schedule Details/Additional Information: • Wednesday 8am to 6pm, Thursday 8am to 7pm, Friday 8am to 7pm, Saturday 7am to 7pm but are subject to change.",
"companyName": "Aurrera Health Group",
"companySlug": "aurrera-health-group",
"companyLogo": "https://cdn-images.himalayas.app/x5oo1e8ooizbkcv9hyg0qa0cl7iy",
"employmentType": "Full Time",
"minSalary": 24.1,
"maxSalary": 36.15,
"salaryPeriod": "hourly",
"seniority": [
"Entry-level"
],
"currency": "USD",
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"IT-Service-Desk",
"Helpdesk-Analyst",
"Technical-Support",
"IT-Support-Specialist",
"Service-Desk-Analyst",
"IT-Helpdesk-Analyst",
"Service-Desk-Associate",
"Service-Desk-Technician"
],
"parentCategories": [
"Operations"
],
"description": "<div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><h3>Department:</h3></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div>12263 Enterprise Corporate - Service Desk<div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><h3>Status:</h3></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div>Full time<div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><h3>Benefits Eligible:</h3></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div>Yes<div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><h3>Hou<b>rs Per Week:</b>\n</h3></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div><b>40<div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><h3>Schedule Details/Additional Information:</h3></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div>\n<ul>\n<li><p>Wednesday 8am to 6pm, Thursday 8am to 7pm, Friday 8am to 7pm, Saturday 7am to 7pm but are subject to change.</p></li>\n<li><p>Fully Remote Role from these states: AL, AK, AR, AZ, DE, FL, GA, IA, ID, IL, IN, LA, KS, KY, ME, MI, MO, MS, MT, NC, ND, NE, NH, NM, NV, OH, OK, PA, SC, SD, TN, TX, UT, VA, WI, WV, WY.</p></li>\n<li><p>Due to complex requirements, remote work is NOT permitted for short or long periods in: CA, CO, CT, HI, MA, MD, MN, NJ, NY, OR, RI, VT, WA and working Internationally (this includes working while on vacation).</p></li>\n<li><p>No relocation, No Sponsorship or transfer of visa for this position now or in the future.</p></li>\n</ul>\n<h3>Pay Range:</h3>$24.10 - $36.15</b><p>Provides initial technical support to customers while delivering excellent customer experience during interactions regarding computers, servers, applications and hardware issues. Assesses the nature of the issue, responds to Incidents and requests for service, and resolves or escalates using documented procedures and checklists and by simulating or recreating the incident. Documents all calls in the tracking system; escalating complex problems to more experienced support, when necessary.</p><h3>Major Responsibilities:</h3><div><ul><li><p>Always provides exceptional customer service.  This includes treating everyone with respect and dignity.  Demonstrates patience and positivity when working with others in alignment with organizational values.</p></li></ul></div><div><ul><li><p>Provides initial support troubleshooting, answering questions and resolving basic problems and issues related to LAN/WAN-based software, desktop computing equipment, printers, network status and applications. </p></li></ul></div><div><ul><li><p>Gathers information about the issuefrom the customerby asking clarifying questions, presenting options and/or solutions and determining the level of complexity. Assists with simulating user issues to resolve. Escalates unresolved interactions appropriately. </p></li></ul></div><div><ul><li><p>Documents all relevant customer interaction information thoroughly in the service management system. </p></li></ul></div><div><ul><li><p>Analyzes basic issues and arrives at workable solutions. Provides callbacks or follow-up with the customeras necessary to “close” the ticketand maintain a successful call closure rate. </p></li></ul></div><div><ul><li><p>Utilizes the call tracking system; accurately, quickly, and efficiently recording all interactions with customers while consistently meeting established Service Desk Key Performance Indicators (KPI). </p></li></ul></div><div><ul><li><p>Performs routine procedures to remedy issues or when requested. </p></li></ul></div><div><ul><li><p>Escalates unresolved issuesto second-tier support. Keeps customersinformed of the status of their request if an immediate remedy is not available. </p></li></ul></div><div><ul><li><p>Assists with providing technical hints and tips to proactively assist customers. </p></li></ul></div><div><ul><li><p>Adherence to all Advocate Health Policy and Procedures. </p></li></ul></div><p><b>Licensure, Registration, and/or Certification Required:</b></p><ul><li><h3>None Required.</h3></li></ul><h3>Education Required:</h3><ul><li><h3>High School Graduate or equivalent.  ​</h3></li></ul><h3>Experience Required:</h3><ul><li><p>Typically requires 1 year of experience in customer service, call center, or Service Desk support.</p></li></ul><h3>Knowledge, Skills &amp; Abilities Required:</h3><div><ul><li><p>Strong interpersonal, customer service and service recovery skills, as well as basic understanding of call centers and call tracking system.  </p></li></ul></div><div><ul><li><p>Strong technical aptitude with the ability to learn quickly and support software applications.  </p></li></ul></div><div><ul><li><p>Understanding of the technical components of an Information System, including basic hardware, platform, database concepts, and terminology.  </p></li></ul></div><div><ul><li><p>Ability to manage multiple priorities in a dynamic work environment.  </p></li></ul></div><div><ul><li><p>Analytical and problem-solving skills.  Strong written and verbal communication skills including the ability to interact with a diverse customer population and communicate at their level.  </p></li></ul></div><div><ul><li><p>to use/manage a standard multiple-line telephone system.  </p></li></ul></div><div><ul><li><p>Ability to maintain confidentiality and work as a team. </p></li></ul></div><div><ul><li><p>Ability to determine issues that may have an adverse business impact if not properly escalated. </p></li></ul></div><h3>Physical Requirements and Working Conditions:</h3><div><ul><li><p>Must be able to sit for extended periods of time.  </p></li></ul></div><div><ul><li><p>Must be able to perform fine hand manipulation when using a keyboard.  </p></li></ul></div><div><ul>\n<li><p>Position may require occasional travel which may result in exposure to road and weather hazards.  </p></li>\n<li><p>Ability to independently work in a remote work environment free from distractions. Potentially exposed to a normal office environment.  </p></li>\n</ul></div><div><ul><li><p>Operates all equipment necessary to perform the job. </p></li></ul></div><div><ul><li><p>The Service Desk supports the organization 24x7x365.  Flexibility for availability in advance to work other shifts, including evening, overnight &amp; weekends is required. </p></li></ul></div><p><i>This job description indicates the general nature and level of work expected of the incumbent. It is not designed to cover or contain a comprehensive listing of activities, duties or responsibilities required of the incumbent. Incumbent may be required to perform other related duties.</i></p><h3>Our Commitment to You:</h3><p>Advocate Health offers a comprehensive suite of Total Rewards: benefits and well-being programs, competitive compensation, generous retirement offerings, programs that invest in your career development and so much more – so you can live fully at and away from work, including:</p><h3>Compensation</h3><ul>\n<li><p>Base compensation listed within the listed pay range based on factors such as qualifications, skills, relevant experience, and/or training</p></li>\n<li><p>Premium pay such as shift, on call, and more based on a teammate's job</p></li>\n<li><h3>Incentive pay for select positions</h3></li>\n<li><p>Opportunity for annual increases based on performance</p></li>\n</ul><h3>Benefits and more</h3><ul>\n<li><h3>Paid Time Off programs</h3></li>\n<li><p>Health and welfare benefits such as medical, dental, vision, life, and Short- and Long-Term Disability</p></li>\n<li><p>Flexible Spending Accounts for eligible health care and dependent care expenses</p></li>\n<li><p>Family benefits such as adoption assistance and paid parental leave</p></li>\n<li><p>Defined contribution retirement plans with employer match and other financial wellness programs</p></li>\n<li><h3>Educational Assistance Program</h3></li>\n</ul><p>Note: Eligibility for programs listed above may depend on your FTE or status (e.g., full-time, part-time, per diem, temporary, etc.); please ask a Recruiter for more information during an interview.</p><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div><div>\n<h3>About Advocate Health </h3>\n<p>Advocate Health is the third-largest nonprofit, integrated health system in the United States, created from the combination of Advocate Aurora Health and Atrium Health. Providing care under the names Advocate Health Care in Illinois; Atrium Health in the Carolinas, Georgia and Alabama; and Aurora Health Care in Wisconsin, Advocate Health is a national leader in clinical innovation, health outcomes, consumer experience and value-based care. Headquartered in Charlotte, North Carolina, Advocate Health services nearly 6 million patients and is engaged in hundreds of clinical trials and research studies, with Wake Forest University School of Medicine serving as the academic core of the enterprise. It is nationally recognized for its expertise in cardiology, neurosciences, oncology, pediatrics and rehabilitation, as well as organ transplants, burn treatments and specialized musculoskeletal programs. Advocate Health employs 155,000 teammates across 69 hospitals and over 1,000 care locations, and offers one of the nation’s largest graduate medical education programs with over 2,000 residents and fellows across more than 200 programs. Committed to providing equitable care for all, Advocate Health provides more than $6 billion in annual community benefits.</p>\n</div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251242,
"expiryDate": 1791435241,
"applicationLink": "https://himalayas.app/companies/aurrera-health-group/jobs/it-service-desk-analyst-i",
"guid": "https://himalayas.app/companies/aurrera-health-group/jobs/it-service-desk-analyst-i"
},
{
"title": "Creative Strategist",
"excerpt": "Who We Are:We are a tech-enabled growth firm–at the intersection of marketing, consulting & data intelligence–igniting revenue and brand recognition for leading and emerging companies around the world.",
"companyName": "Power Digital Marketing",
"companySlug": "power-digital-marketing",
"companyLogo": "https://cdn-images.himalayas.app/bhkymn9m38zbb5mc33jk9bc450xp",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Mid-level"
],
"currency": null,
"locationRestrictions": [
"Chile"
],
"timezoneRestrictions": [
-6,
-4,
-3
],
"categories": [
"Creative-Strategy",
"Paid-Social",
"Digital-Marketing",
"Social-Media-Marketing",
"Performance-Marketing",
"Advertising-Strategy",
"Creative",
"Creative-Strategist",
"Design---Creative-Strategist",
"Senior-Creative-Strategist",
"Creative-Content-Strategist",
"Creative-Strategy-Lead",
"Social-Media-Creative-Strategist"
],
"parentCategories": [],
"description": "<div class=\"content-intro\">\n<h3>Who We Are:</h3>\n<p>We are a tech-enabled growth firm–at the intersection of marketing, consulting &amp; data intelligence–igniting revenue and brand recognition for leading and emerging companies around the world. As a people-first firm, we value diversity in backgrounds and experiences. We strongly believe our people and culture are key to our success. Our vision is to be recognized as the most valued and respected private growth marketing firm in the world–with a scalable brand, culture and services. Our mission is to power the relentless pursuit of growth and redefine what’s possible through a team of growth-obsessed experts who demand innovation and results - driven by integrity, autonomy, and grit.</p>\n<p>As a full-service growth marketing firm, we offer best-in-class services including: SEO, Content Marketing, Paid Media, Social Media Marketing, Programmatic + CTV, Public Relations, Influencer Marketing, Email + SMS, Conversion Rate Optimization, Retail Marketing, and Creative. Here at Power Digital, we are hyper-focused on helping brands drive revenue growth and brand recognition, ultimately driving irrefutable value for our clients. </p>\n<p>At the heart of Power Digital is our proprietary technology, nova, which analyzes businesses through first-party data, simplifying investment planning for marketing and diligence in M&amp;A––putting marketers in a strategic seat at the table––and providing value in unparalleled ways. </p>\n<p>Managing billions in media, our dynamic team––of consultative marketers, creatives, analysts and technologists––challenge traditional ways of planning and measurement through meticulous testing and data science across each milestone of the customer journey.</p>\n</div><p><strong>Disclaimer: We're currently on the lookout for potential candidates to join our talent pool via this job listing. Your qualifications will be assessed for both present positions and future opportunities. Should your skills align with a role and an opening arise, our recruitment team will reach out to you promptly. However, please keep in mind that this doesn't guarantee immediate placement or communication.<br><br>A day in the life:</strong></p><p>A Creative Strategist will be the lead ideator on strategic accounts. They are required to have a robust understanding of paid social creative best practices, their client’s brand, performance goals, historical data, current ecommerce trends, and consumer behavior, to develop winning paid social advertising that impacts their client's growth.</p><p>Creative Strategists know how to act fast to capitalize on good results, or on the flip side know what to change if an ad isn’t performing to their goal. This means testing with the intention of moving the needle on key performance metrics — from improving CPA, CTR, or ROAS to driving brand awareness. Creative Strategists pitch new ideas and concepts to clients, write scripts, and follow the execution and review of ads through to production and delivery to clients.</p><p>An ideal candidate for the Creative Strategist role is a self-starter who is passionate about maximizing success for their clients through creative strategy, and is eager to take the lead on developing creative concepts that are intentionally produced to generate clear testing results and insights. They have mastered presenting creative reporting to clients and team members through storytelling, and are constantly implementing learnings to enhance future campaign results. Sr. Creative Strategists are zealous about continuously testing various creative concepts to develop a strong understanding of how to not only effectively and efficiently meet client goals, but to surpass them. If creative deliveries are not meeting client expectations, or creative tests are not hitting target goals, Sr. Creative Strategists will be relentless in the pursuit to troubleshoot and problem solve with a growth mindset.</p><h3><strong>Key Responsibilities:</strong></h3><ul>\n<li>Leads the paid social creative strategy for 8-10 clients</li>\n<li>Using data insights along with consumer and brand research to design high performing creative assets</li>\n<li>Collaborating closely with team members across internal departments and roles</li>\n<li>Maintaining client communications and sentiment</li>\n<li>Driven to iterate and ideate towards stated performance goals</li>\n<li>Develops rapport with client to build a foundation of open discussion, including understanding client product and goals, as well as explaining Power Digital processes</li>\n<li>Researches client brand, competitors, and industry trends, and effectively implements performance creative best practices by platform</li>\n<li>Continually audits account to identify winning ads, present data to client, and dictate hypotheses and test strategy via monthly roadmaps</li>\n<li>Writes strategic consumer-centric, direct response copy and messaging strategy</li>\n<li>Manages requests and output with production team using Asana</li>\n<li>Reviews video/image assets and provides clear and actionable feedback to editors</li>\n<li>Leads productive internal creative team syncs and brainstorms</li>\n<li>Works alongside client management team as client POC for all things creative strategy</li>\n<li>Understands scope of requested edits, reshoots, and other deliverables</li>\n<li>Pushes back on client on matters of timeline, scope, feedback, and direction to drive performance based on creative best practices</li>\n<li>Employ AI technologies to enhance and optimize business processes</li>\n<li>Utilize and leverage Power Digital's Nova ecosystem as it relates to your department</li>\n</ul><h3><strong>Role Requirements:</strong></h3><ul>\n<li>Proficiency with Meta Ads Manager, and/or similar performance data tools (TikTok, YouTube, Pinterest, etc)</li>\n<li>Technically skilled at pulling and using creative performance data to analyze trends, insights, and inform creative roadmaps </li>\n<li>Understanding of best practices for performance-driven creative &amp; ability to apply these insights in work</li>\n<li>Ability to write effective ad copy, structure a script, and see through on the execution with corresponding visuals</li>\n<li>Ability to communicate and collaborate with clients, production, and post-production teams to deliver best possible creative output</li>\n<li>Ability to yield strong campaign results for clients through strategizing top performing creative</li>\n</ul><h3>Key Performance Indicators (KPIs)</h3><ul>\n<li>5% or lower client churn</li>\n<li>Manage 8-10 mid level clients </li>\n<li>Maintain $22,000 RPE</li>\n</ul><h3>Most Important Things (MITs)</h3><ul>\n<li>Technically skilled at pulling and using creative performance data to analyze trends and insights and inform the creative roadmap. </li>\n<li>Responsible for using data insights along with consumer and brand research to orchestrate a sales/messaging/visual strategy.</li>\n</ul><div class=\"content-conclusion\">\n<p><em>Power Digital’s people and culture are at the core of our success, which is why diversity in our team’s backgrounds and experiences are paramount. We are an Equal Opportunity Employer and our employees are people with different strengths, experiences, and backgrounds, who strive to make an impact inside and outside of the workplace. Diversity not only includes race and gender identity, but also age, disability status, veteran status, sexual orientation, religion and many other parts of one’s identity. All of our employees' points of view are key to our success, and inclusion is everyone's responsibility.</em></p>\n<p><em>Please be aware of fictitious job openings, consulting engagements, solicitations, or employment offers from suspicious sources. These engagements may be an attempt to obtain private information, or to induce you to pay a fee for services related to recruitment or training. Power Digital does NOT charge any application, processing, or training fee at any stage of the recruitment or hiring process. All genuine job openings will be posted on our careers page at </em><em>. If you have any doubts about the authenticity of any messaging behalf of Power Digital, please send us an email at </em><em></em><em> before taking any further action in relation to the correspondence.</em></p>\n</div><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251121,
"expiryDate": 1791435121,
"applicationLink": "https://himalayas.app/companies/power-digital-marketing/jobs/creative-strategist-8367986002",
"guid": "https://himalayas.app/companies/power-digital-marketing/jobs/creative-strategist-8367986002"
},
{
"title": "RF Firmware Engineer",
"excerpt": "OverviewLMI is seeking an experienced RF Firmware Engineer to support the continued development of our next-generation mesh networking hardware for Department of Defense customers.",
"companyName": "Logistics Management Institute",
"companySlug": "logistics-management-institute",
"companyLogo": "https://cdn-images.himalayas.app/4ihouhoaior7pdc3vaa4yedyvgi7",
"employmentType": "Full Time",
"minSalary": 100000,
"maxSalary": 130000,
"salaryPeriod": "annual",
"seniority": [
"Senior"
],
"currency": "USD",
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"RF-Firmware-Engineer",
"Embedded-Firmware-Engineer",
"RF-Communications-Engineer",
"Defense-Electronics-Engineer",
"Hardware-Firmware-Developer",
"RF-Software-Engineer",
"RF-Engineer",
"Radio-Frequency-Software-Engineer",
"Firmware-Engineer",
"RF-Systems-Engineer",
"Radio-Frequency-Engineer",
"Senior-RF-Design-Engineer"
],
"parentCategories": [
"Hardware Engineer"
],
"description": "<h3>Overview</h3><p>LMI is seeking an experienced <strong>RF Firmware Engineer</strong> to support the continued development of our next-generation mesh networking hardware for Department of Defense customers. This engineer will serve as the technical lead for RF firmware development, working closely with our hardware design partners to integrate new radio technologies into our platform while maintaining performance, reliability, and security.</p><p>This role is ideal for an engineer who enjoys working at the intersection of embedded firmware, RF communications, and hardware development. You will collaborate with internal engineering teams, external design firms, manufacturing partners, and customer stakeholders to deliver production-ready capabilities that support mission-critical deployments.</p><p>U.S. citizenship is required. Candidates must be eligible to obtain a Secret clearance. An active Secret or Top Secret clearance is preferred.</p><p>Approximately <strong>20–30% travel</strong> to customer sites, integration events, hardware design reviews, manufacturing partners, and field testing activities as required.</p><p>LMI is a new breed of digital solutions provider dedicated to accelerating government impact with innovation and speed. Investing in technology and prototypes ahead of need, LMI brings commercial-grade platforms and mission-ready AI to federal agencies at commercial speed. </p><p>Leveraging our mission-ready technology and solutions, proven expertise in federal deployment, and strategic relationships, we enhance outcomes for the government efficiently and effectively. With a focus on agility and collaboration, LMI serves the defense, space, healthcare, and energy sectors, helping agencies navigate complexity and outpace change. Headquartered in Tysons, Virginia, LMI is committed to delivering impactful results that strengthen missions and drive lasting value. </p><h3>Responsibilities</h3><p><strong>Principal Duties and Responsibilities</strong>  </p><ul>\n<li>Lead firmware development for new RF hardware platforms supporting LMI mesh networking products.</li>\n<li>Work directly with external hardware design firms to integrate the <strong>Texas Instruments CC1200 transceiver</strong> into next-generation hardware designs.</li>\n<li>Develop, modify, and maintain embedded firmware to support new RF transceiver capabilities and optimize radio performance.</li>\n<li>Design and implement RF communication protocols, device drivers, and hardware abstraction layers.</li>\n<li>Support hardware bring-up, debugging, and validation of prototype and production hardware.</li>\n<li>Troubleshoot RF performance issues using laboratory test equipment including spectrum analyzers, oscilloscopes, logic analyzers, and RF test equipment.</li>\n<li>Collaborate with hardware, firmware, cybersecurity, and systems engineering teams throughout the product lifecycle.</li>\n<li>Support firmware verification, manufacturing test development, and production readiness.</li>\n<li>Participate in field testing, customer demonstrations, and deployment activities as required.</li>\n<li>Produce technical documentation supporting firmware architecture, integration, testing, and manufacturing.</li>\n<li>Support design reviews and provide technical guidance on RF system architecture and implementation</li>\n</ul><h3>Qualifications</h3><h3>Required Qualifications</h3><ul>\n<li>Bachelor’s degree in Electrical Engineering, Computer Engineering, Computer Science, or a related STEM discipline.</li>\n<li>8+ years of embedded firmware development experience using C/C++.</li>\n<li>Experience developing firmware for RF transceivers or wireless communication systems.</li>\n<li>Experience integrating RF chipsets into embedded hardware platforms.</li>\n<li>Strong understanding of SPI, UART, I2C, GPIO, interrupts, and embedded peripherals.</li>\n<li>Experience debugging embedded systems using JTAG, oscilloscopes, logic analyzers, and RF test equipment.</li>\n<li>Experience working with external hardware vendors and cross-functional engineering teams.</li>\n<li>Strong analytical and troubleshooting skills.</li>\n<li>Excellent written and verbal communication skills.</li>\n<li>U.S. citizenship with the ability to obtain a Secret security clearance.</li>\n</ul><h3>Desired Qualifications</h3><ul>\n<li>Experience with the <strong>Texas Instruments CC1200</strong> transceiver or similar sub-GHz RF devices.</li>\n<li>Experience developing mesh networking or low-power wireless communication systems.</li>\n<li>Familiarity with BLE, LoRa, 802.15.4, or proprietary RF protocols.</li>\n<li>Experience supporting DoD or government technology programs.</li>\n<li>Understanding of secure communications, cryptographic key management, and secure firmware development.</li>\n<li>Experience supporting manufacturing test and production transitions.</li>\n<li>Active Secret or Top Secret security clearance.</li>\n</ul><h3>Travel</h3><ul><li>Approximately <strong>20–30% travel</strong> to customer sites, integration events, hardware design reviews, manufacturing partners, and field testing activities as required.</li></ul><h3>Target salary range: $100,000 - 130,000</h3><p>Disclaimer: The salary range displayed represents the typical salary range for this position and is not a guarantee of compensation. Individual salaries are determined by various factors including, but not limited to location, internal equity, business considerations, client contract requirements, and candidate qualifications, such as education, experience, skills, and security clearances.</p><p>Applicants must meet eligibility requirements for a U.S. Government security clearance. Only US Citizens are eligible for a security clearance. For this position, LMI will only consider applicants with security clearances or applicants who are eligible for security clearances, due to the nature of the work.</p><h3>Job Locations</h3>US-Remote<p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251116,
"expiryDate": 1791435115,
"applicationLink": "https://himalayas.app/companies/logistics-management-institute/jobs/rf-firmware-engineer",
"guid": "https://himalayas.app/companies/logistics-management-institute/jobs/rf-firmware-engineer"
},
{
"title": "Worker Engagement Specialist",
"excerpt": "We are searching for an individual or an organization based in Africa (Algeria, Benin, Burkina Faso, Burundi, Cameroon, Central African Republic, Chad, Comoros, Congo (Republic), Democratic Republic of Congo (D.",
"companyName": "EcoVadis",
"companySlug": "ecovadis",
"companyLogo": "https://cdn-images.himalayas.app/vy7a61rr8vjpg5wtvep9jz6s6hzp",
"employmentType": "Contractor",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Senior"
],
"currency": null,
"locationRestrictions": [
"Tunisia"
],
"timezoneRestrictions": [
1
],
"categories": [
"Employee-Engagement-Specialist",
"Social-Compliance",
"Supply-Chain-Management",
"Client-Services",
"Labor-Rights",
"Sustainability",
"Corporate-Social-Responsibility",
"Workforce-Engagement-Director",
"Employee-Engagement-Manager",
"Employee-Engagement-Director"
],
"parentCategories": [],
"description": "<p>We are searching for an individual or an organization based in Africa (Algeria, Benin, Burkina Faso, Burundi, Cameroon, Central African Republic, Chad, Comoros, Congo (Republic), Democratic Republic of Congo (D. R. C), Cote d'Ivoire, Djibouti, Gabon, Guinea, Madagascar, Mali, Mauritania, Morocco, Niger, Senegal, Togo and Tunisia) with a social compliance background to work with our Client Services team on a freelance or consultancy basis (part-time) and help us effectively collaborate with and service a diverse portfolio of clients and their suppliers in the aforementioned countries. With a workers’ rights and supplier engagement background, and a keen interest and capacity for the use of technology, we are looking for a candidate that will engage with workers, suppliers and brands in the aforementioned countries to drive meaningful impact.  </p><p>Working with the Client Services team, they will be responsible for introducing our digital worker engagement programs to suppliers (both virtually and on site when possible), getting management buy-in, training management on the platform usage, engaging with workers and promoting participation, managing grievance cases, and liaising between all stakeholders to achieve positive outcomes for all. The role will require flexibility and agility to take on various tasks and work remotely with a global team. The role will require some evening meetings to communicate with the team based in Canada and Europe.</p><p>If the role sounds like a good fit for you, we’d love to hear from you. </p><h3>What you’ll do:</h3><ul>\n<li>Lead the deployment of digital worker voice programs in workplaces in French Speaking African Nations.</li>\n<li>Lead supplier platform training and technical support</li>\n<li>Lead case management of grievances in programs that have a digital grievance mechanism - liaising and collaborating with suppliers and brands </li>\n<li>Be available for investigation and remediation support if requested by brands</li>\n<li>Support the development and updating of supplier and worker onboarding materials </li>\n<li>Own regular communication with supplier management - from program introduction to status check-ins</li>\n<li>Liaise with internal stakeholders including the Director of Client Services, Client Services Senior Managers and Managers and Deployment Team to ensure effective deployment</li>\n<li>Gather client and supplier feedback and ideas to inform platform advancements</li>\n</ul><p>*Note: Each project has its unique scope of work. Not all the responsibilities listed above will be needed for every project assigned. The scope of work will outline the specific responsibilities needed.</p><h3>Your preferred profile:</h3><ul>\n<li>Social compliance or labour rights background with knowledge and experience in supply chains, corporate sourcing, ethical procurement, grievance mechanisms, social impact, sustainability, international development, social impact tech, and/or business and human rights</li>\n<li>5+ years’ experience working within the global supply chain industry, delivering social or labour impact projects</li>\n<li><strong>Excellent communication skills, both oral and written, in both English and French is required. </strong></li>\n<li>Organized, conscientious and accountable </li>\n<li>Experience in customer / client services and delivery</li>\n<li>Occasional travel nationally may be required</li>\n</ul><h3>What sets you apart: </h3><ul>\n<li>Understanding of labour, human and community rights issues in global supply chains</li>\n<li>Knowledge and experience in community relations, corporate social responsibility programs </li>\n<li>Experience with adopting new technology and train others to do the same </li>\n<li>Self-motivated with a tolerance for ambiguity and change, with high desire to take ownership of projects</li>\n<li>Passion for equality and safe workplaces</li>\n<li>Familiarity with the auditing industry and international certification standards (i.e. BSCI, ETI, SA8000), internal and external grievance mechanisms, industry associations, and sustainability entities (i.e. SEDEX) is a plus</li>\n</ul><p>If you are interested, please submit your resume, cover letter along with your proposed rates.</p><ul>\n<li>\n<strong>Location: </strong>Tunis, Tunisia</li>\n<li>\n<strong>Start date</strong>: 2026</li>\n<li>\n<strong>External contractor</strong>: If you are interested, please submit your resume, cover letter along with your proposed rates.</li>\n</ul><p><em>Work smart, have fun and make an impact!</em></p><p><strong>Our purpose is to guide all companies toward a sustainable world</strong>. <a href=\"https://himalayas.app/companies/ecovadis\">EcoVadis</a> is the leading provider of business sustainability ratings. Our solutions are backed by an international team of experts and powerful technology. We analyze data and build sustainability scorecards that give companies actionable insights into their environmental, social and ethical risks. </p><p>Ululaaims to improve working conditions in mining, manufacturing and agribusiness by sourcing and processing accurate and timely insights directly from workers and communities around the world. Ulula software and analytics platform connects directly and anonymously with our target stakeholders to obtain honest feedback and create more transparent and responsible supply chains. We have projects across the globe including India, China, Peru, South Africa with clients ranging from Fortune 100 companies to NGOs and government departments.</p><p>Ulula is a subsidiary of <a href=\"https://himalayas.app/companies/ecovadis\">EcoVadis</a>, the leading provider of business sustainability ratings.</p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251107,
"expiryDate": 1791435105,
"applicationLink": "https://himalayas.app/companies/ecovadis/jobs/worker-engagement-specialist-1538110927",
"guid": "https://himalayas.app/companies/ecovadis/jobs/worker-engagement-specialist-1538110927"
},
{
"title": "Senior Clinical Data Manager (Remote US or Canada)",
"excerpt": "Job Title: Senior Clinical Data Manager (Remote US or Canada) Job Location: Remote Canada Job Location Type: Remote Job Contract Type: Full-time Job Seniority Level: Job Overview: Data Management leadership on studies and take responsibility for the development of the project documentation, system set-up, data entry and data validation procedures and processes assigned to more junior staff.",
"companyName": "Lifelancer",
"companySlug": "lifelancer",
"companyLogo": "https://cdn-images.himalayas.app/ztdsyzatuliky237a5zq922sir0k",
"employmentType": "Full Time",
"minSalary": 80000,
"maxSalary": 145000,
"salaryPeriod": "annual",
"seniority": [
"Senior"
],
"currency": "CAD",
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"Clinical-Data-Management",
"Clinical-Data-Manager",
"Senior-Clinical-Data-Manager",
"Clinical-Data-Coordinator",
"Clinical-Data-Analyst",
"Senior-Clinical-Data-Management-Specialist",
"Lead-Clinical-Data-Manager",
"Clinical-Data-Management-Senior-Manager",
"Senior-Manager-Clinical-Data-Management"
],
"parentCategories": [],
"description": "<p><b>Job Title: </b>Senior Clinical Data Manager (Remote US or Canada)</p><p><b>Job Location: </b>Remote Canada</p><p><b>Job Location Type: </b>Remote</p><p><b>Job Contract Type: </b>Full-time</p><h3>Job Seniority Level: </h3><p></p><p><b>Job Overview:</b></p><p><b>Data Management leadership on studies and take responsibility for the development of the project documentation, system set-up, data entry and data validation procedures and processes assigned to more junior staff. Assume responsibility for all DM activities (from study start-up to database lock) according to client quality expectations, within project timelines and budgets. Act as subject matter expert (SME) for DM activities in relationship meetings with Sponsors. Work directly with Sponsors to understand their direct requirements and lead implementation of those requirements. Regularly review client specific process to ensure they remain optimal for Sponsor and Fortrea. The Senior Clinical Data Manager will work with the leadership team to provide guidance, mentoring and training to DM to ensure best working practices are maintained.</b></p><h3><b>Summary of Responsibilities:</b></h3><ul>\n<li><b>Lead studies including (but not limited to) a combination of healthy volunteer and patient populations, multi-site, complex protocol design, strong client management required or reduced timelines. Ability to organize and effectively prioritize workload and deliverables.</b></li>\n<li><b>As the Study Manager, be accountable for all DM deliverables as assigned per the established timeline; providing instruction to their DM study team(s) and review of their study team’s output to ensure the highest quality, while adjusting resource allocations accordingly.</b></li>\n<li><b>Ensure that all allocated projects are carried out in strict accordance with the relevant protocols, global harmonized SOPs, and the specified standards of GCPs.</b></li>\n<li><b>Work with the Project Manager(s) or FSP Lead (or designee) to build timelines to meet contracted milestones by communicating with leads in different disciplines and the full project team as necessary, including at study initiation meetings.</b></li>\n<li><b>Provide DM project team leadership and accountability; leads data focused internal project team meetings; meets frequently with the study leads of EDC Design, SAS Programming, Statistics, and PK to ensure that all deliverables are planned and coordinated intradepartmental; proactively identifies potential risks/mitigations, effectively communicates data-driven discussions in order to achieve database lock dates; keeps the Project Manager or FSP Lead (or designee) apprised of project progress.</b></li>\n<li><b>Maintain awareness of other Biometrics functional group deliverables to be able to support risk and mitigation strategies, including impact on DM resources or deliverables and consult with Project Manager (or designee) and/or functional group management as necessary.</b></li>\n<li><b>Keep Project Manager (or designee), Biometrics management team and/or sponsor services informed of pertinent project or sponsor related information (i.e., budget status, work scope changes, timeline impacts).</b></li>\n<li><b>Coordinates the receipt and inventory of all data related information, from clinical sites and vendors as appropriate to meet timelines for deliverables. Ensure all appropriate documentation and procedures are performed upon project completion.</b></li>\n<li><b>Develop and maintain client relationships and review client satisfaction surveys. Implement appropriate action plans including driving process improvements and team training.</b></li>\n<li><b>Track scope changes and work with the Project Manager or FSP Lead (or designee) to ensure that Sponsor approval is received, and the scope change processed.</b></li>\n<li><b>Provides leadership, mentorship, and coaching in DM related clinical trial processes, department technical capabilities, and associated turnaround durations to the internal study team.</b></li>\n<li><b>Provide support to DM supervisors and managers on the performance evaluation of other team members, provide constructive feedback to aid in career development, interpersonal skills, and achievement of competency standards.</b></li>\n<li><b>Accountable for learning new DM technologies and applied processes, keeping up to date with industry wide technology and feasibility for process improvement at Fortrea.</b></li>\n<li><b>Ensures service and quality meet agreed upon specifications per the DMP and scope of work.</b></li>\n<li><b>Have input in writing, reviewing, and updating SOPs and associated documents as required.</b></li>\n<li><b>Maintain accurate records of all work undertaken.</b></li>\n<li><b>Perform reconciliation of the clinical database against safety data, laboratory data or any other third-party data as appropriate. Utilize local laboratory systems and batch data load facilities where appropriate.</b></li>\n<li><b>Represent DM and where necessary overall Biometrics in new business opportunities.</b></li>\n<li><b>Attend and action client or internal audits as appropriate and resolve all issues within an appropriate timeframe. Address client comments with the study team.</b></li>\n<li><b>Works with management team to develop and implement directional strategy by providing technical input into discussions and rolling out training/mentorship to DM staff (as required).</b></li>\n<li><b>Actively promote Biometrics services to sponsors whenever possible.</b></li>\n<li><b>Performs other related duties as assigned by management.</b></li>\n<li><b>All other duties as needed or assigned.</b></li>\n</ul><h3><b>Qualifications (Minimum Required):</b></h3><ul>\n<li><b>University / college degree.</b></li>\n<li><b>Experience and/or education plus relevant work experience, equating to a bachelor's degree will be accepted in lieu of a bachelor’s degree.</b></li>\n<li><b>Fortrea may consider relevant and equivalent experience in lieu of educational requirements.</b></li>\n<li><b>Minimum of 1-year Veeva EDC experience</b></li>\n<li><b><b>Language Skills Required:</b></b></li>\n<li><b>Speaking/Writing/Reading: English required.</b></li>\n</ul><h3><b>Experience (Minimum Required):</b></h3><ul>\n<li><b>8 years of combined early or late-stage DM experience with minimum 2 years of direct sponsor management and at least 2 years technical mentoring experience. Proven experience in handling customer negotiations and experience with managing Scope of Work and budgets.</b></li>\n<li><b>Thorough knowledge of clinical trial process, DM, clinical operations, biometrics, and system applications to support operations.</b></li>\n<li><b>Proven ability to lead by example on project strategies and achievement of department goals, objectives, and initiatives and to encourage team members to seek solutions.</b></li>\n<li><b>Working knowledge of the relationship and regulatory obligation of the CRO industry with pharmaceutical/biotechnological companies.</b></li>\n<li><b>Time management skill and ability to adhere to project productivity metrics and timelines.</b></li>\n<li><b>Ability to work in a team environment and collaborate with peers.</b></li>\n<li><b>Ability to mentor junior members of the department, providing SME guidance on DM practices.</b></li>\n<li><b>Experience of representing DM in bid defense meetings, providing innovative solutions to meet client needs.</b></li>\n<li><b>Good organizational ability, communication, and interpersonal skills.</b></li>\n<li><b>Constructive problem-solving attitude while deadline focused with time demands, incomplete information or unexpected events.</b></li>\n</ul><h3><b>Preferred Qualifications Include:</b></h3><ul>\n<li><b>University / college degree (life sciences, health sciences, information technology or related subjects preferred).</b></li>\n<li><b>Through knowledge of Fortrea, the overall structure of the organization and Standard Operating Procedures (SOPs).</b></li>\n<li><b>Four or more years of Electronic Data Capture experience.</b></li>\n</ul><h3><b>Physical Demands/Work Environment:</b></h3><ul>\n<li><b>Role is office or remote-based, with associated risks of repetitive strain injury (associated with keyboard operation) and eye strain (associated with VDU screen operation).</b></li>\n<li><b>Potential travel for cross-site support or training needs, meetings up to 10% of the time, with up to 50% of that time requiring an overnight stay.</b></li>\n</ul><p><b><b>Pay Range CAD: </b>$80,000-$145,000/ annually</b></p><p><b><b>Pay Range US: </b>$80,000-$120,000 /annually</b></p><p><b><b>Benefits:</b> All job offers will be based on a candidate’s skills and prior relevant experience, applicable degrees/certifications, as well as internal equity and market data. </b></p><h3><b>Application Deadline: 8/10/2026</b></h3><h3><b>#LI Remote</b></h3><p><b>Learn more about our EEO &amp; Accommodations request here.</b></p><b><br><br><h3>This job is curated by <a href=\"https://himalayas.app/companies/lifelancer\">Lifelancer</a>.</h3></b><p><strong><a href=\"https://himalayas.app/companies/lifelancer\">Lifelancer</a> is a talent-hiring platform in Life Sciences, Pharma and IT. The platform connects talent with opportunities in pharma, biotech, health sciences, healthtech and IT domains.</strong></p><p><strong>Please apply via <a href=\"https://himalayas.app/companies/lifelancer\">Lifelancer</a> platform to get connected to the application page and to find  similar roles.</strong></p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251102,
"expiryDate": 1791435101,
"applicationLink": "https://himalayas.app/companies/lifelancer/jobs/senior-clinical-data-manager-remote-us-or-canada",
"guid": "https://himalayas.app/companies/lifelancer/jobs/senior-clinical-data-manager-remote-us-or-canada"
},
{
"title": "Content Marketing Specialist",
"excerpt": "Job Description:Ironmark is looking for a creative and organized Content Marketing Specialist to help us tell our story across multiple marketing channels.",
"companyName": "Ironmark",
"companySlug": "ironmark",
"companyLogo": "",
"employmentType": "Full Time",
"minSalary": 55000,
"maxSalary": 62000,
"salaryPeriod": "annual",
"seniority": [
"Mid-level"
],
"currency": "USD",
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"Content-Marketing",
"Marketing-Specialist",
"Content-Strategy",
"Digital-Marketing",
"Copywriting",
"Content-Marketing-Specialist",
"Marketing-Content-Specialist",
"Content-Marketer",
"SEO-Content-Specialist",
"Content-Marketing-Strategist"
],
"parentCategories": [
"Marketing",
"Content Creator"
],
"description": "<div><div>\n<h3>Job Description:</h3>\n<h3>\n<a href=\"https://himalayas.app/companies/ironmark\">Ironmark</a> is looking for a creative and organized Content Marketing Specialist to help us tell our story across multiple marketing channels. This role is ideal for someone who enjoys creating engaging content, managing editorial calendars, and finding ways to maximize the impact of every piece of content. As <a href=\"https://himalayas.app/companies/ironmark\">Ironmark</a>’s Content Marketing Specialist, you’ll understand and live the perspective of our ICP and personas, along with <a href=\"https://himalayas.app/companies/ironmark\">Ironmark</a>’s positioning and how we add value to our best prospects. Using that north star, you will plan, create and distribute content that supports brand awareness, customer engagement, and lead generation. From blog posts and webinars to podcasts and social media, you'll help ensure our content is consistent, compelling, and aligned with our business goals.</h3>\n<h3>Responsibilities:</h3>\n<h3>Create High-Quality Content</h3>\n<p>Develop and manage content across multiple channels, including:</p>\n<ul>\n<li>Blog articles</li>\n<li>Customer stories and case studies</li>\n<li>Social media content</li>\n<li>Email campaigns</li>\n<li>Webinar promotion and follow-up</li>\n<li>Podcast production and promotion</li>\n<li>Video scripts and supporting content</li>\n<li>Website copy</li>\n</ul>\n<h3>Manage the Content Process</h3>\n<ul>\n<li>Maintain the editorial calendar</li>\n<li>Coordinate content production from idea to publication</li>\n<li>Work with internal subject matter experts</li>\n<li>Manage freelancers or creative vendors when needed</li>\n<li>Ensure brand voice and messaging remain consistent across channels</li>\n</ul>\n<h3>Measure Performance</h3>\n<ul>\n<li>Track content performance</li>\n<li>Recommend optimization opportunities</li>\n<li>Use analytics to improve future content</li>\n<li>Identify high-performing content to repurpose</li>\n</ul>\n<h3>Growth &amp; Mentorship</h3>\n<p>This role is built to grow. You'll work closely with <a href=\"https://himalayas.app/companies/ironmark\">Ironmark</a>'s AI and Operations leaders to learn how to build AI-assisted content systems that make a small team produce like a large one, a skillset that is quickly becoming one of the most valuable in marketing. As you build that capability and the function grows, so does the role, with a path toward content leadership.</p>\n<h3>Required Skills:</h3>\n<ul>\n<li>Bachelor's degree in Marketing or related field</li>\n<li>At least 3 years of content marketing experience</li>\n<li>Experience creating content for multiple marketing channels</li>\n<li>Excellent writing, editing, and storytelling skills</li>\n<li>Experience managing content calendars</li>\n<li>Ability to interview subject matter experts and translate complex topics into engaging content</li>\n<li>Familiarity with SEO and content optimization</li>\n<li>Experience with video, podcast, or webinar production workflows</li>\n<li>Knowledge of marketing analytics and content performance measurement</li>\n<li>Strong organizational and project management skills</li>\n<li>Ability to work independently in a remote environment</li>\n</ul>\n<h3>Preferred Experience:</h3>\n<ul>\n<li>HubSpot Marketing Hub</li>\n<li>B2B marketing</li>\n<li>WordPress or other CMS</li>\n<li>Graphic design tools such as Canva or Adobe</li>\n</ul>\n</div></div><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251098,
"expiryDate": 1791435097,
"applicationLink": "https://himalayas.app/companies/ironmark/jobs/content-marketing-specialist",
"guid": "https://himalayas.app/companies/ironmark/jobs/content-marketing-specialist"
},
{
"title": "Financial Analyst",
"excerpt": "Job TitleFinancial AnalystJob Description SummaryThe role of the Analyst is to provide analytical support and coordination.",
"companyName": "Cushman & Wakefield",
"companySlug": "cushman-wakefield",
"companyLogo": "https://cdn-images.himalayas.app/l99ajoifddyoghtiroduuhrqpn1y",
"employmentType": "Full Time",
"minSalary": 59500,
"maxSalary": 70000,
"salaryPeriod": "annual",
"seniority": [
"Mid-level"
],
"currency": "USD",
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"Financial-Analyst",
"Financial-Analysis",
"Business-Analyst",
"Data-Analyst",
"Financial-Reporting-Analyst",
"Financial-Analyst-Jobs",
"Financial-Analysis-Specialist",
"Financial-Management-Analyst",
"Business-Financial-Analyst",
"Corporate-Financial-Analyst",
"Financial-Analysis-Jobs",
"Financial-Business-Analyst"
],
"parentCategories": [
"Finance",
"Data Science"
],
"description": "<h3>Job Title</h3>Financial Analyst<h3>Job Description Summary</h3>The role of the Analyst is to provide analytical support and coordination. The role will provide business analysis in support of the account team and client’s business needs. The Analyst will collaborate with the Account Team, Client, and other team members throughout the process to coordinate team members, schedules, and activities in support of the program. The Analyst will gather and assemble data, using analytical and quantitative methods to analyze performance, identify problems, and develop recommendations that support the client and team goals. <br><br>This individual will maintain financial databases by entering, verifying, and backing up data according to client standard operating procedures in support of project management staff for a large communications company. These tasks may include trouble-shooting invoicing, fielding purchase orders queries, tracking and closing open commitments, coordinating, overseeing project closeouts, and completing related documentation and reporting functions.<h3>Job Description</h3><p></p><p><b>KEY ACCOUNTABILITIES </b></p><ul>\n<li><b>Understanding our business - Demonstrate familiarity with all facets of the client’s business and exhibit an understanding of services provided and customers served.  </b></li>\n<li><b>Solutioning - Document requirements and assist in analyzing and reviewing potential solutions.  Examines and analyzes financial information such as budgets, forecasts, income and expense statements and periodic operating results. </b></li>\n<li><b>Project Delivery - Contribute as an active and positive member on project teams to deliver or exceed project outcomes. Researches and prepares reports, analysis and recommendations for financial based analysis. </b></li>\n<li><b>Improvement &amp; Innovation - Constantly look for ways to improve the way we work and the solutions we offer to our business and our client. </b></li>\n<li><b>Reporting - Organize program data into logical communication and messages as part of client presentation materials and management analysis reports. </b></li>\n<li><b>Communicate effectively with work partners and the Client, on financial data related to project creation, budget codes, active projects, closed projects, and historical data findings. Frequent WebEx meetings and phone calls followed-up by emails is required. </b></li>\n<li><b>Validate the accuracy of financial information within multiple systems across client platform. </b></li>\n<li><b>Analyze data from different sources, document and follow-up on variances. </b></li>\n<li><b>Facilitate the transfer of knowledge about the big picture, meeting capital management targets, to others e.g., coach/counsel a project manager on processing financial transactions or publish quick reference guide on how to close projects. </b></li>\n<li><b>Audit project budgets and milestones ensuring that timely project updates are made within project management technology solution. </b></li>\n</ul><h3><b>DETAILED ACCOUNTABILITIES </b></h3><ul>\n<li><b>Ability to interrelate multiple data sources efficiently and effectively.  Maintain reports on performance against internal Service Level Agreements including but not limited to project closeouts, regressions, overspend, suspended projects, purchase order, telephone equipment orders, and commitment evaluation. </b></li>\n<li><b>Perform data entry on a regular basis; keying inputs into required systems and Microsoft Excel spreadsheets; communicate/document results for internal clients. </b></li>\n<li><b>Process and maintain project related documentation such as agreements, contracts, purchase orders, and other work authorizations. </b></li>\n<li><b>Review program data performs quantitative and qualitative analyses and quantitative projections. </b></li>\n<li><b>Leverage and expand use of on-account software platforms to enhance analysis and reporting.  Key applications include the Microsoft Business Suite, Power BI, and other data sources delivering market intelligence, customer analysis and competitor insights. </b></li>\n<li><b>Support and contribute to a collaborative and innovative teamwork environment. </b></li>\n<li><b>Respond to requests in a timely manner, meeting all deadlines </b></li>\n<li><b>Recommend process improvement opportunities– document current state process and create future state process documentation </b></li>\n<li><b>Deliver proactive approach to analytical outcomes with each group by function and geographic team with regard to business process re-engineering, internal control objectives, and best practices to address business needs, identify and solve problems, and enhance service levels. </b></li>\n<li><b>Write, maintain, and support a variety of queries and reports including ad hoc requests </b></li>\n<li><b>Communicates with customer(s) on project and project results. </b></li>\n<li><b>Provides analytical insight to Project Team, serving as data &amp; analytics subject matter expert </b></li>\n<li><b>Creates PowerBI Dashboards, Smartsheet Dashboards/Portals with automation and other data presentation methods </b></li>\n<li><b>Uploads reporting daily from various sources. </b></li>\n<li><b>Create ad-hoc reports. </b></li>\n<li><b>Other duties as assigned. </b></li>\n</ul><h3><b>Qualifications &amp; Requirements </b></h3><p><b>To perform this job successfully, an individual must be able to perform each essential function and assigned duty satisfactorily. The requirements listed below are representative of the knowledge, skills, competency, and/or abilities required. Reasonable accommodations may be made to enable individuals with disabilities to perform the essential functions. </b></p><ul>\n<li><b>Bachelor’s Degree required </b></li>\n<li><b>3-7 Years previous experience preferred </b></li>\n<li><b>Outstanding customer service skills required. </b></li>\n<li><b>Must have basic understanding of PowerBI and other data and dashboard technology. </b></li>\n<li><b>Proficiency in Microsoft Excel (Ability to connect multiple data sets either through Power Query or the use of formulas to create consolidated tables, Familiarity with advanced functions (INDEX, MATCH, XLOOKUP / HLOOKUP / VLOOKUP, UNIQUE, etc.), Expert level pivot table comprehension, Familiarity with dynamic filtering options (slicers, formulas, tables, etc.), Understanding of conditional formatting and general visualization practices, Ability to visually represent information through use of the right charts, tables, and key information callouts, Attention to detail and comprehension of good data analytics practices (check, double check, evaluate the information upstream in the model to ensure that there are no anomalies created through the combination of data, etc.)</b></li>\n<li><b>Must possess excellent time management skills and be adaptable to change </b></li>\n<li><b>Ability to apply basic math, including adding, subtracting, multiplying, and dividing in all units of measure, using whole numbers, common fractions, and decimals </b></li>\n<li><b>Ability to communicate verbally in one-on-one situations with management and co-workers; listen to others without interrupting and get clarification when needed </b></li>\n<li><b>Strong attention to detail and focus on quality and accuracy </b></li>\n<li><b>Ability to take initiative, including asking for and offering help when needed; performs work independently without being prompted </b></li>\n<li><b>Ability to prioritize and plan work activities; use time efficiently; and work within deadlines </b></li>\n</ul><p><b><b>Language Skills</b>:  Ability to read and interpret documents.  Ability to write routine reports and correspondence.  Ability to speak effectively in front of customers or employees.  Ability to read, write and understand the English language.  Ability to communicate verbally in one-on-one situations with customers, management and co-workers, and the ability to listen to others without interrupting and get clarification when needed.   </b></p><p><b><b>Mathematical Skills:</b>  Ability to work with mathematical concepts.  Ability to apply concepts such as fractions, percentages, ratios, and proportions to practical situations.  </b></p><p><b><b>Reasoning Ability: </b> Must be able to solve practical problems involving several concrete variables in situations where limited standardization exists.  Ability to apply common sense understanding to carry out instructions furnished in written, oral, or diagram form.   Ability to read, analyze and interpret simple and complex instructions, work orders, and technical procedures.  Ability to research and resolve issues relating to projects.  Ability to perform repetitive mental functions. </b></p><b><br><br><br>Cushman &amp; Wakefield also provides eligible employees with an opportunity to enroll in a variety of benefit programs, generally including health, vision, and dental insurance, flexible spending accounts, health savings accounts, retirement savings plans, life, and disability insurance programs, and paid and unpaid time away from work. In addition to a comprehensive benefits package, Cushman and Wakefield provide eligible employees with competitive pay, which may vary depending on eligibility factors such as geographic location, date of hire, total hours worked, job type, business line, and applicability of collective bargaining agreements.<br>The compensation that will be offered to the successful candidate will depend on factors such as whether the position is covered by a collective bargaining agreement, the geographic area in which the work will be performed, market pay rates in that area, and the candidate’s experience and qualifications.<br>The company will not pay less than minimum wage for this role.<br>The compensation for the position is: $ 59,500.00 - $70,000.00Cushman &amp; Wakefield is an Equal Opportunity employer to all protected groups, including protected veterans and individuals with disabilities.  Discrimination of any type will not be tolerated.</b><p>In compliance with the Americans with Disabilities Act Amendments Act (ADAAA), if you have a disability and would like to request an accommodation in order to apply for a position at Cushman &amp; Wakefield, please call the ADA line at <b>1-888-365-5406</b> or email . Please refer to the job title and job location when you contact us.</p>INCO: “Cushman &amp; Wakefield”<p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251090,
"expiryDate": 1791435089,
"applicationLink": "https://himalayas.app/companies/cushman-wakefield/jobs/financial-analyst-9898549842",
"guid": "https://himalayas.app/companies/cushman-wakefield/jobs/financial-analyst-9898549842"
},
{
"title": "Quality Assurance (QA) Lead",
"excerpt": "** Note: This is a equity-based compensation until our next funding round.",
"companyName": "Bizmoni Corp.",
"companySlug": "bizmoni-corp",
"companyLogo": "https://cdn-images.himalayas.app/x6zemkxz1fspwxc37054gzcmg2b7",
"employmentType": "Contractor",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Senior"
],
"currency": null,
"locationRestrictions": [
"Brazil"
],
"timezoneRestrictions": [
-5,
-4,
-3,
-2
],
"categories": [
"QA-Lead",
"Quality-Assurance-Lead",
"Test-Automation-Lead",
"Software-Testing",
"QA-Manager",
"Lead-QA",
"Quality-Assurance-Team-Lead",
"QA-Test-Lead",
"QA-Analyst-Lead",
"Lead-QA-Analyst",
"Software-Quality-Assurance-Lead",
"QA-Team-Lead",
"Lead-QA-Engineer"
],
"parentCategories": [
"Developer"
],
"description": "<p>** Note: This is a equity-based compensation until our next funding round.** </p><h3>Location: fully remote</h3><h3>Employment type: part -time contractor</h3><h3>About <a href=\"https://himalayas.app/companies/bizmoni-corp\">Bizmoni Corp.</a> </h3><p>Bizmoni is the worlds first AI Super App designed to help anyone earn, learn, and grow in the AI era. We are building a global, fully remote team to shape the future of financial technology. Our mission is to make powerful AI-driven financial and business tools accessible to everyonefrom individuals starting side hustles to enterprises scaling globally.</p><h3>About the Role:</h3><p>We are seeking an experienced, hands-on QA Lead to lead our QA function and manage a team of up to 5 QA professionals supporting our AI-powered fintech applications.</p><p>You will combine people leadership, QA strategy, and hands-on testing, ensuring quality across our Web, Mobile, AI, and UI/UX products. You will work with fully distributed Technology and Product teams across the US, LATAM, India, and other global locations.</p><h3>What You'll Do:</h3><ul><ul>\n<li>Lead, mentor, and manage a QA team of up to 5 people.</li>\n<li>Own and improve the QA strategy, processes, standards, and testing framework.</li>\n<li>Plan and coordinate testing across Web, Mobile, AI, and UI/UX products.</li>\n<li>Lead UI/UX, functional, regression, exploratory, and accessibility testing.</li>\n<li>Ensure testing aligns with WCAG accessibility guidelines.</li>\n<li>Drive test automation and remain hands-on with automated testing.</li>\n<li>Use AI tools and prompt engineering to improve test creation, coverage, analysis, and QA efficiency.</li>\n<li>Lead defect management, root-cause analysis, and release readiness.</li>\n<li>Track key QA metrics and communicate quality risks to Engineering and Product.</li>\n<li>Collaborate effectively across US, LATAM, India, and multiple time zones.</li>\n<li>Apply OWASP standards/security testing principles where relevant.</li>\n<li>Act as the main QA point of contact for Engineering and Product.</li>\n</ul></ul><h3>What You'll Bring:</h3><ul><ul>\n<li>Min 3+ years of hands on  QA experience with team leadership/people management.</li>\n<li>Experience managing and developing QA professionals.</li>\n<li>Strong experience in Web, Mobile, AI, UI/UX, usability, and accessibility testing.</li>\n<li>Good knowledge of WCAG guidelines.</li>\n<li>Strong knowledge of QA methodologies, SDLC, Agile/Scrum, and test automation.</li>\n<li>Hands-on automation experience with Java, Python, C#, JavaScript/TypeScript, or similar.</li>\n<li>Experience with JIRA, TestRail, or equivalent tools.</li>\n<li>Ability to use AI tools and prompt engineering in QA activities.</li>\n<li>Knowledge of OWASP/security testing is an advantage.</li>\n<li>API testing knowledge is a plus, but UI/UX testing is the primary focus.</li>\n<li>Comfortable balancing people management with hands-on technical QA work.</li>\n<li>Experience working with fully distributed international teams across multiple time zones.</li>\n<li>Excellent English communication skills.</li>\n<li>Fintech, AI, SaaS, or startup experience is a plus.</li>\n</ul></ul><h3>Why You'll Love Working at Bizmoni</h3><ul>\n<li>Be part of a mission-driven company building the future of AI-powered Fintech.</li>\n<li>Fully remote role with a global team.</li>\n<li>Equity-based compensation with the potential for future full-time opportunities.</li>\n<li>Culture of innovation, collaboration, and ownership. </li>\n</ul><h3>Before Applying, Ask Yourself:</h3><ul>\n<li>Are you open to equity + commission-based compensation? </li>\n<li>Are you open to dedicating a min. of 16 hrs weekly on our project? </li>\n</ul><p>If your answers are <strong>YES</strong> then we are happy to meet you!</p><h3>Recruitment Process:</h3><ul>\n<li>Interview with QA Lead &amp; TA Partner.</li>\n<li>Interview with technology department officer and technology department manager. </li>\n<li>Offer (based on final positive feedback).</li>\n</ul><p>Please send us your English CV stating the role you apply. <strong>Only shortlisted candidates are selected for the interview. Thank yo</strong>u.</p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251076,
"expiryDate": 1791435075,
"applicationLink": "https://himalayas.app/companies/bizmoni-corp/jobs/quality-assurance-qa-lead",
"guid": "https://himalayas.app/companies/bizmoni-corp/jobs/quality-assurance-qa-lead"
},
{
"title": "Product Certification Auditor-Built Environment / Digital Construction(BIM)",
"excerpt": "We exist to create positive change for people and the planet.",
"companyName": "BSI",
"companySlug": "bsi",
"companyLogo": "https://cdn-images.himalayas.app/f74z1mr5uszjwrugnidg7lylgfc3",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Mid-level"
],
"currency": null,
"locationRestrictions": [
"United Kingdom"
],
"timezoneRestrictions": [
0
],
"categories": [
"Product-Certification-Auditor",
"Built-Environment-Auditor",
"BIM-Auditor",
"Quality-Management-Auditor",
"Compliance-Auditor",
"BIM-Quality-Assurance",
"Certification-Auditor"
],
"parentCategories": [],
"description": "<p>We exist to create positive change for people and the planet. Join us and make a difference too!</p><p>Job Title: Product Certification Auditor (Client Manager)<br>Reports to: Operations Manager in UK</p><h3>Location: Home based</h3><p><b>Purpose of the position:</b><br>As the face of <a href=\"https://himalayas.app/companies/bsi\">BSI</a>, the role of the Auditor (Client Manager) is to work closely with <a href=\"https://himalayas.app/companies/bsi\">BSI</a> clients to help them improve their performance by assessing their systems and processes against <a href=\"https://himalayas.app/companies/bsi\">BSI</a> standards. At the end of each assessment the Client Manager compiles a business report and presents this to the client.<br><b>Context / Dimensions:</b><br>The scope of the position will typically cover clients within the region of the role holder however some wider UK delivery may be required. The role is home-based.</p><p>Are you ready to be part of a world-renowned organization with nearly 120 years of innovation, growth, and industry leadership? Do you have a passion enabling organisations to continue maintaining high standards of compliance?</p><p>At <a href=\"https://himalayas.app/companies/bsi\">BSI</a>, we are looking for a Built Environment Auditor to play a key role in maintaining product excellence. In this role, you’ll conduct product certification assessments across varied environments, ensuring compliance with <a href=\"https://himalayas.app/companies/bsi\">BSI</a>’s rigorous certification schemes and Kitemark standards.</p><p>We are seeking professionals to deliver Building Information Modelling (BIM) related product assessment in accordance with ISO 19650 framework. Previous auditing experience is a plus, as well as expertise in quality management systems (ISO 9001). Experience with PAS 2080 (Carbon Management in Infrastructure) would also be a distinct benefit.</p><h3>Essential Responsibilities:</h3><ul>\n<li>Prepare assessment reports and deliver findings to clients to ensure client understanding of the assessment decision and clear direction to particular items of corrective action where appropriate</li>\n<li>Recommend the issue, re-issue or withdrawal of certificates, and report recommendations in accordance with <a href=\"https://himalayas.app/companies/bsi\">BSI</a> policy, procedures and prescribed time frame.</li>\n<li>Maintain overall account responsibility and accountability for nominated accounts to ensure an effective partnership, whilst ensuring excellent service delivery and account growth.</li>\n<li>Lead assessment teams as required ensuring that team members are adequately briefed so that quality of service is maintained and that effective working relationships are sustained both with Clients and within the team.</li>\n<li>Provide accurate and prompt information to support services, working closely with them to ensure that client records are up to date and complete and that all other internal information requirements are met.</li>\n<li>Coach colleagues as appropriate especially where those members are inexperienced assessors or unfamiliar with clients' business/technology and assist in the induction and coaching of new colleagues as requested</li>\n<li>Plan/schedule workloads to make best use of own time and maximise revenue-earning activity.</li>\n<li>Responsible for attending any required training and following all procedures/processes/policies within <a href=\"https://himalayas.app/companies/bsi\">BSI</a> for management of clients, management of a home based office, use of <a href=\"https://himalayas.app/companies/bsi\">BSI</a> equipment and communication both internal and external to the organization</li>\n<li>Must be willing to go through extensive onboarding plan in order to reach Lead Assessor status through the prescribed program (based on the knowledge, skills and experience they have as well as the requirements of the appropriate schemes)</li>\n<li>Must be able to demonstrate knowledge and skills, to include preparation for and taking standardized assessments related to knowledge and application of audit practices</li>\n<li>Responsible for managing a portfolio of assigned clients based on location and a match of qualifications and client contract requirements</li>\n<li>Responsible for contacting clients and scheduling the visits, planning the assessments, making travel plans, conducting the assessments and reporting and managing the results in an efficient manner.</li>\n<li>Responsible for monitoring the client accounts to ensure that records, visit cycle, invoicing and other related matters are properly dealt with to assure client satisfaction is maintained</li>\n<li>Responsible for leading teams, when necessary, and mentoring and coaching new or inexperienced colleagues as needed to meet the business needs</li>\n<li>Any other assignments as needed to meet assessment delivery business objectives.</li>\n</ul><h3>Education/Qualifications:</h3><ul>\n<li>A minimum of 4 years’ industry experience gained within BIM, Built Environment, Construction or similar industry sector</li>\n<li>Expertise across ISO 19650, Building Information Modelling (BIM) Framework</li>\n<li>Experience with PAS 2080 Carbon Management in Infrastructure would be desirable</li>\n<li>Previous experience in 3rd party external auditing, against standards</li>\n<li>Can travel frequently</li>\n<li>Knowledge of quality management system (ISO 9001) auditing practices.</li>\n</ul><h3>About Us</h3><p><a href=\"https://himalayas.app/companies/bsi\">BSI</a> is a business improvement and standards company and for over a century <a href=\"https://himalayas.app/companies/bsi\">BSI</a> has been recognized for having a positive impact on organizations and society, building trust and enhancing lives.<br><br>Today <a href=\"https://himalayas.app/companies/bsi\">BSI</a> partners with more than 77,500 clients in 195 countries and engages with a 15,000 strong global community of experts, industry and consumer groups, organizations and governments.<br>Utilizing its extensive expertise in key industry sectors - including automotive, aerospace, built environment, food and retail, and healthcare - <a href=\"https://himalayas.app/companies/bsi\">BSI</a> delivers on its purpose by helping its clients fulfil theirs.<br>Living by our core values of Client-Centricity, Agility, and Collaboration, <a href=\"https://himalayas.app/companies/bsi\">BSI</a> provides organizations with the confidence to grow by partnering with them to tackle society’s critical issues – from climate change to building trust in digital transformation and everything in between - to accelerate progress towards a better society and a sustainable world.</p><p><a href=\"https://himalayas.app/companies/bsi\">BSI</a> is an Equal Opportunity Employer dedicated to fostering a diverse and inclusive workplace.</p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251075,
"expiryDate": 1791435075,
"applicationLink": "https://himalayas.app/companies/bsi/jobs/product-certification-auditor-built-environment-digital-construction-bim",
"guid": "https://himalayas.app/companies/bsi/jobs/product-certification-auditor-built-environment-digital-construction-bim"
},
{
"title": "Salesforce Product Manager - Channel & Enterprise",
"excerpt": "Company OverviewAt Motorola Solutions, we believe that everything starts with our people.",
"companyName": "Motorola Solutions",
"companySlug": "motorola-solutions",
"companyLogo": "https://cdn-images.himalayas.app/wrwjjejxt406bwtydu0acmhx0lhh",
"employmentType": "Full Time",
"minSalary": null,
"maxSalary": null,
"salaryPeriod": "annual",
"seniority": [
"Senior"
],
"currency": null,
"locationRestrictions": [
"Poland"
],
"timezoneRestrictions": [
1
],
"categories": [
"Salesforce-Product-Manager",
"Sales-Operations",
"Channel-Sales",
"Enterprise-Sales",
"CRM-Administration",
"Salesforce-Product-Management",
"Salesforce-Ecosystem-Product-Management",
"CRM-Product-Manager",
"Salesforce-Program-Manager",
"Salesforce-Product-Owner"
],
"parentCategories": [
"Sales"
],
"description": "<h3><b>Company Overview</b></h3><p>At <a href=\"https://himalayas.app/companies/motorola-solutions\">Motorola Solutions</a>, we believe that everything starts with our people. We’re a global close-knit community, united by the relentless pursuit to help keep people safer everywhere. We build and connect technologies to help protect people, property and places. Our solutions foster the collaboration that’s critical for safer communities, safer schools, safer hospitals, safer businesses, and ultimately, safer nations. Connect with a career that matters, and help us build a safer future.</p><h3>\n<br><b>Department Overview</b>\n</h3>At <a href=\"https://himalayas.app/companies/motorola-solutions\">Motorola Solutions</a>, we help people be their best in the moments that matter. We are redesigning public safety to make the world a safer place. <br><br><br>Our team is the Sales Insights &amp; Productivity team within the Global Sales Operations organization. Our mission is to improve the selling experience for global <a href=\"https://himalayas.app/companies/motorola-solutions\">Motorola Solutions</a>’ sellers and sales leaders. Our Salesforce.com platform is the heart of our mission.<br><br><br>We maximize the benefits of Motorola’s investment in digital sales platforms like Salesforce, advocating for strategic next generation projects that will transform and align sales planning across multiple regions.<h3>\n<br>Job Description</h3><p>We are seeking a Salesforce Product Manager - Channel&amp; Enterprise to lead programs that equip Channel and Enterprise sales teams with necessary tools, data, and resources to help boost sales growth across Motorola’s portfolio streamline CRM administration work.</p><p>Will focus on understanding the needs of our Channel and Enterprise sales teams and translate them into specific requirements for our Salesforce IT teams. This requires detailed knowledge of Channel and Enterprise sales goals and operations. In addition, this role will require gathering grassroots ideas cross-regionally, and using them to identify global pain points or opportunities that can be addressed through new projects.</p><p>Responsibilities include identifying improvements, defining solutions, building roadmaps, identifying key data sets, and assisting with implementation. Success will be measured by solution adoption and business impact.</p><h3>Responsibilities</h3><ul>\n<li><p>Develop a keen understanding of the Channel and Enterprise Sales and Sales Ops processes.</p></li>\n<li><p>Own the development, implementation, and roll-out of new business processes and Salesforce solutions that help our global Channel and Enterprise sellers leverage the platform to its full potential.</p></li>\n<li><p>Gather, understand, and document business requirements for Salesforce development initiatives and serve as the voice of Channel and Enterprise sales teams throughout the process.</p></li>\n<li><p>Build and maintain a trusted relationship with front line sellers, sales leaders, operations leaders, and the extended IT team</p></li>\n<li><p>Advocate for the needs of the Channel and Enterprise sales and sales operations teams within the Sales Insights &amp; Productivity team and the broader IT and business groups.</p></li>\n<li><p>Gather and relay feedback to continuously improve the Salesforce experience and enablement strategy for sales teams.</p></li>\n<li><p>Work closely with the different enablement teams to put together training and communication programs to educate Channel and Enterprise sales teams on new and existing Salesforce applications.</p></li>\n<li><p>Assist in generation of Salesforce reports to support the Channel and Enterprise sales and sales operations teams.</p></li>\n</ul><h3>Skills &amp; Abilities</h3><ul>\n<li><p>Understand user needs and  combine them with business objectives and strategy to define specific project requirements.</p></li>\n<li><p>Experience with the the Salesforce Platform </p></li>\n<li><p>Exceptional understanding of the sales process and how Salesforce can enable sales success.  Familiarity with Channel and Enterprise processes is a plus.</p></li>\n<li><p>Good Project Management skills in the form of prioritizing, scheduling, and communicating project status and goals</p></li>\n<li><p>Continuous evaluation of sales processes and how to remove administrative burden from both front line sellers and sales managers/leaders.</p></li>\n<li><p>Able to stay apprised of developing technologies such as AI, Machine Learning, and new Salesforce features, and apply them to modernize Motorola’s business</p></li>\n<li><p>Demonstrated technical aptitude and ability to engage with architects and technical SMEs</p></li>\n<li><p>Team player with strong communication and interpersonal skills.</p></li>\n<li><p>Demonstrated ability to influence a group audience, facilitate solutioning and lead discussions such as implementation methodology, roadmapping,  enterprise transformation strategy, and executive-level requirement gathering sessions</p></li>\n<li><p>Outstanding analytical skills with the ability to see the big picture, define a vision, and execute on it.</p></li>\n<li><p>Understanding of IT Agile development, writing, and submitting Jira stories</p></li>\n<li><p>Maintain working relationships with intra-organization groups including sales, sales operations, IT, and any others required to complete projects..</p></li>\n<li><p>Ability to quickly adapt to new requirements and changing situations.</p></li>\n<li><p>Ability to build strong working relationships across multiple functions/levels; adept at mediating conflict and fostering healthy dialogue</p></li>\n<li><h3>Tableau knowledge a plus</h3></li>\n</ul><h3>\n<br>Basic Requirements</h3><ul>\n<li><p><b>5+ years of direct experience delivering and/or overseeing development of software solutions OR 5+ years of experience in a sales or sales support role</b></p></li>\n<li><h3>Salesforce platform experience</h3></li>\n<li><p><b>Strong understanding of the sales process preferably on the Channel and Enterprise side  </b></p></li>\n<li>\n<p><b>Bachelor’s degree in business or computer science related degree preferred</b><br></p>\n<h3><b>In return for your expertise, we’ll support you in this new challenge with coaching &amp; development every step of the way.  Also, to reward your work, you’ll get the following:</b></h3>\n</li>\n<li><h3>Contract Of Employment (UoP)</h3></li>\n<li><h3>Private medical coverage</h3></li>\n<li><h3>Life insurance, Sport card</h3></li>\n<li><h3>Employee Stock Purchase Plan (ESPP)</h3></li>\n<li><p>Yearly salary increase (depends on individual performance)</p></li>\n<li><p>Yearly bonus (depends on company performance)</p></li>\n<li><p>Remote work possibility, Flexible working hours</p></li>\n<li><p>Comfortable work conditions (high-class offices, parking space, volleyball field on site)</p></li>\n<li><p>Training and broad development opportunities<b>​</b></p></li>\n</ul><h3>\n<br>Travel Requirements</h3>None<h3>\n<br>Relocation Provided</h3>None<h3>\n<br>Position Type</h3>Experienced<h3>Referral Payment Plan</h3>Yes<h3><b>Company</b></h3><a href=\"https://himalayas.app/companies/motorola-solutions\">Motorola Solutions</a> Systems Polska Sp.z.o.o<p><i><b>EEO Statement</b></i></p><p><a href=\"https://himalayas.app/companies/motorola-solutions\">Motorola Solutions</a> is an Equal Opportunity Employer. All qualified applicants will receive consideration for employment without regard to race, color, religion or belief, sex, sexual orientation, gender identity, national origin, disability, veteran status or any other legally-protected characteristic. </p><p>We are proud of our people-first and community-focused culture, empowering every Motorolan to be their most authentic self and to do their best work to deliver on the promise of a safer world. If you’d like to join our team but feel that you don’t quite meet all of the preferred skills, we’d still love to hear why you think you’d be a great addition to our team.</p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251075,
"expiryDate": 1791435074,
"applicationLink": "https://himalayas.app/companies/motorola-solutions/jobs/salesforce-product-manager-channel-enterprise",
"guid": "https://himalayas.app/companies/motorola-solutions/jobs/salesforce-product-manager-channel-enterprise"
},
{
"title": "Nutrition Support Dietitian - Registered Dietitian",
"excerpt": "Job Title: Nutrition Support Dietitian - Registered Dietitian Job Location: Work at Home, Ohio, United States Job Location Type: Remote Job Contract Type: Full-time Job Seniority Level: We’re building a world of health around every individual — shaping a more connected, convenient and compassionate health experience.",
"companyName": "Lifelancer",
"companySlug": "lifelancer",
"companyLogo": "https://cdn-images.himalayas.app/ztdsyzatuliky237a5zq922sir0k",
"employmentType": "Full Time",
"minSalary": 21.1,
"maxSalary": 48.67,
"salaryPeriod": "hourly",
"seniority": [
"Mid-level"
],
"currency": "USD",
"locationRestrictions": [
"United States"
],
"timezoneRestrictions": [
-10,
-9,
-8,
-7,
-6,
-5,
14
],
"categories": [
"Nutrition-Support-Dietitian",
"Registered-Dietitian",
"Clinical-Dietitian",
"Home-Infusion-Dietitian",
"Enteral-Nutrition-Specialist",
"Registered-Dietitian-Nutritionist",
"Nutrition-Support-Specialist",
"Nutritional-Support-Coordinator",
"Healthcare-Nutrition-Specialist"
],
"parentCategories": [],
"description": "<p><b>Job Title: </b>Nutrition Support Dietitian - Registered Dietitian</p><p><b>Job Location: </b>Work at Home, Ohio, United States</p><p><b>Job Location Type: </b>Remote</p><p><b>Job Contract Type: </b>Full-time</p><h3>Job Seniority Level: </h3><p>We’re building a world of health around every individual — shaping a more connected, convenient and compassionate health experience. At CVS Health®, you’ll be surrounded by passionate colleagues who care deeply, innovate with purpose, hold ourselves accountable and prioritize safety and quality in everything we do. Join us and be part of something bigger – helping to simplify health care one person, one family and one community at a time.</p><p>As a Registered Dietitian with Coram CVS Specialty Infusion Services, you will work with internal and external customers including patients, caregivers, case managers, physicians, pharmacists, outpatient dietitians, and vendor representatives to coordinate all aspects of patient home nutrition therapy. You'll use your excellent written and verbal customer service skills and advanced computer skills in order to interact with key partners and patients. You will play an instrumental role in making areal difference by improving the quality of life for patients in need.</p><h3>As a Nutrition Support Dietitian you will:</h3><ul>\n<li>Evaluate and customize enteral parenteral prescriptions including formula (macro and micronutrients), volume, administration and other parameters based on each unique patient needs.</li>\n<li>Perform outbound calls to follow up and complete ongoing assessments with patients and caregivers to monitor patient status, tolerance to therapy, and provide education related to their therapy.</li>\n<li>Review patient medical documentation to support a smooth on-boarding of newly referred nutrition therapy patients.</li>\n<li>Review clinical documentation to assist with qualification and documentation of medical necessity for Medicare and commercial payers as needed.</li>\n<li>Develop patient specific plan of care in coordination with internal and external medical professionals to support optimal patient outcomes. </li>\n<li>Work with sales to develop and maintain nutrition customer relationships. Serve as a content expert for sales support activities.</li>\n<li>Answer incoming calls from patients, caregivers, and other disciplines across the pharmacy to resolve patient questions and issues.</li>\n</ul><h3>Training at this time is fully remote.</h3><h3>Location and schedule</h3><ul>\n<li>One may live anywhere in the Eastern Time Zone in this remotely based role. One will be supporting our patients in the eastern states</li>\n<li>Full-time hours are typically 8a-5p Eastern Time, Monday-Friday</li>\n<li>Telephonic on-call is approximately one week (evenings and the weekend) every nine weeks in case a patient has a question after hours.</li>\n</ul><p>Registered Dietitians with Coram CVS/specialty infusion services have a uniquely rewarding setting to use their exceptional nutritional skills. As a national leader in the home infusion field and a Fortune 500 company, we seek those special Dietitians who possess not only strong clinical expertise with innovative ideas, but who also have the kind of deep compassion and sensitivity it takes to treat people in their homes.</p><h3>Required Qualifications:</h3><ul>\n<li>Current registration by the Commission of Dietetic Registration of the American Dietetic Association</li>\n<li>Registered Dietitian with current license in state of employment. Additional licensure may be required in multi-state service areas.</li>\n<li>2+ years clinical experience in nutrition support (enteral)</li>\n<li>Experience with Microsoft Office, Excel, Outlook and Word to document and track patient care activity</li>\n<li>Participate in on-call rotation as indicated by staffing and business needs</li>\n<li>Ability to hard-wire into the internet</li>\n</ul><h3>Preferred Qualifications:</h3><ul>\n<li>Certified Nutrition Support Clinician - CNSC</li>\n<li>Infusion experience</li>\n<li>Knowledge of Parenteral and Enteral Formulas across manufacturers</li>\n</ul><h3>Education:</h3><ul><li>Bachelor Degree - Nutrition, Dietetics or related field is required</li></ul><h3>Anticipated Weekly Hours</h3>40<h3>Time Type</h3>Full time<h3>Pay Range</h3><h3>The typical pay range for this role is:</h3>$21.10 - $48.67<p>This pay range represents the base hourly rate or base annual full-time salary for all positions in the job grade within which this position falls. The actual base salary offer will depend on a variety of factors including experience, education, geography and other relevant factors. This position is eligible for a CVS Health bonus, commission or short-term incentive program in addition to the base pay range listed above. </p><p>Our people fuel our future. Our teams reflect the customers, patients, members and communities we serve and we are committed to fostering a workplace where every colleague feels valued and that they belong.</p><h3>Great benefits for great people</h3><p>We take pride in offering a comprehensive and competitive mix of pay and benefits that reflects our commitment to our colleagues and their families.<br></p>This full‑time position is eligible for a comprehensive benefits package designed to support the physical, emotional, and financial well‑being of colleagues and their families. The benefits for this position include medical, dental, and vision coverage, paid time off, retirement savings options, wellness programs, and other resources, based on eligibility.<p>Additional details about available benefits are provided during the application process and on Benefits Moments.<br></p>We anticipate the application window for this opening will close on: 08/20/2026<p>Qualified applicants with arrest or conviction records will be considered for employment in accordance with all federal, state and local laws.</p><br><br><h3>This job is curated by <a href=\"https://himalayas.app/companies/lifelancer\">Lifelancer</a>.</h3><p><strong><a href=\"https://himalayas.app/companies/lifelancer\">Lifelancer</a> is a talent-hiring platform in Life Sciences, Pharma and IT. The platform connects talent with opportunities in pharma, biotech, health sciences, healthtech and IT domains.</strong></p><p><strong>Please apply via <a href=\"https://himalayas.app/companies/lifelancer\">Lifelancer</a> platform to get connected to the application page and to find  similar roles.</strong></p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251075,
"expiryDate": 1791435074,
"applicationLink": "https://himalayas.app/companies/lifelancer/jobs/nutrition-support-dietitian-registered-dietitian",
"guid": "https://himalayas.app/companies/lifelancer/jobs/nutrition-support-dietitian-registered-dietitian"
},
{
"title": "Music Producer - AI Evaluation",
"excerpt": "About the jobMercor connects elite creative and technical talent with leading AI research labs.",
"companyName": "mercor",
"companySlug": "mercor",
"companyLogo": "https://cdn-images.himalayas.app/6jo5q9nua35jgtdfm41nq6b7ocqf",
"employmentType": "Contractor",
"minSalary": 39,
"maxSalary": 39,
"salaryPeriod": "hourly",
"seniority": [
"Mid-level"
],
"currency": "USD",
"locationRestrictions": [
"Switzerland"
],
"timezoneRestrictions": [
1
],
"categories": [
"Music-Production",
"AI-Evaluation",
"Audio-Engineering",
"Music-Quality-Assurance",
"Sound-Design",
"AI-Music-Evaluation",
"AI-Music",
"AI-Music-Research"
],
"parentCategories": [],
"description": "<h3>About the job</h3><p><strong>Mercor</strong> connects elite creative and technical talent with leading AI research labs. Headquartered in San Francisco, our investors include <strong>Benchmark</strong>, <strong>General Catalyst</strong>, <strong>Peter Thiel</strong>, <strong>Adam D'Angelo</strong>, <strong>Larry Summers</strong>, and <strong>Jack Dorsey</strong>.</p><p><strong>Position:</strong> Music Audio Expert - French<br><strong>Type:</strong><strong>Contract</strong><br><strong>Compensation:</strong><strong>$39/hour</strong><br><strong>Location:</strong><strong>Remote</strong><br><strong>Duration:</strong><strong>Up to 6 months</strong><br><strong>Commitment:</strong><strong>10+ hours/week</strong></p><h3>Role Responsibilities</h3><ul>\n<li>Evaluate <strong>AI model output lyrics</strong>, voice generation, and other standards in music.</li>\n<li>Score the quality of <strong>musical training data</strong> to enhance model performance.</li>\n<li>Write music in the domain language listed in the title, ensuring high-quality outputs.</li>\n<li>Understand and follow directions in the <strong>English language</strong> for effective collaboration.</li>\n<li>Work <strong>independently and asynchronously</strong> to meet project deadlines.</li>\n</ul><h3>Qualifications</h3><p></p><p><strong>Must-Have</strong></p><ul>\n<li><strong><strong>3+ years</strong> of experience as a music producer, audio engineer, and/or sound mixer.</strong></li>\n<li><strong>College degree in <strong>music</strong>, involving performance, theory, and lyrics.</strong></li>\n<li><strong>Native or near-native proficiency in both <strong>French</strong> and <strong>English</strong>.</strong></li>\n</ul><h3><strong>Preferred</strong></h3><ul>\n<li><strong>Evidence of understanding musical performance, theory, and lyrics.</strong></li>\n<li><strong>Past experience writing lyrical music in the domain language listed in the title.</strong></li>\n</ul><h3><strong>Start Date</strong></h3><ul><li><strong><strong>Immediate</strong></strong></li></ul><h3><strong>Application Process (Takes 20–30 mins to complete)</strong></h3><ul>\n<li><strong>Upload resume and application form</strong></li>\n<li><strong>Complete a 25-minute conversational interview on your background, experience, and motivations</strong></li>\n<li><strong>Receive next steps and onboarding details within a few days</strong></li>\n</ul><h3><strong>Resources &amp; Support</strong></h3><ul>\n<li><strong>For details about the interview process and platform information, please check: </strong></li>\n<li><strong>For any help or support, reach out to: </strong></li>\n</ul><p><strong><em>PS: Our team reviews applications daily. Please complete your AI interview and application steps to be considered for this opportunity.</em></strong></p><p>Originally posted on <a href=\"https://himalayas.app\">Himalayas</a></p>",
"pubDate": 1786251069,
"expiryDate": 1791435068,
"applicationLink": "https://himalayas.app/companies/mercor/jobs/music-producer-ai-evaluation",
"guid": "https://himalayas.app/companies/mercor/jobs/music-producer-ai-evaluation"
}
]
}

jobicy:
async function fetchJobs() {
  try {
    const response = await fetch(
      "https://jobicy.com/api/v2/remote-jobs?count=10&geo=usa&industry=engineering"
    );

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();

    console.log("Jobs:", data.jobs);

    return data.jobs;

  } catch (error) {
    console.error("Failed to fetch jobs:", error);
    return [];
  }
}

fetchJobs();


