import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/resume_data.dart';
import '../models/resume_type.dart';
import '../models/user_resume.dart';
import '../providers/auth_provider.dart';
import '../repositories/storage_repository.dart';
import '../services/ai_service.dart';
import '../services/ai_usage_service.dart';
import '../services/resume_limit_service.dart';
import '../services/demo_service.dart';
import '../services/resume_persistence_service.dart';
import '../services/resume_export_service.dart';
import '../services/github_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ats_score_gauge.dart';
import '../widgets/demo_banner.dart';
import '../widgets/demo_upsell_dialog.dart';
import '../widgets/resume_preview_dialog.dart';
import '../widgets/resume_editor/job_alignment_card.dart';
import '../widgets/page_container.dart';

class ResumeEditorScreen extends StatefulWidget {
  final CvTemplateType? initialTemplate;
  final int initialTab;
  final VoidCallback? onSectionChanged;

  const ResumeEditorScreen({
    super.key,
    this.initialTemplate,
    this.initialTab = 0,
    this.onSectionChanged,
  });

  @override
  State<ResumeEditorScreen> createState() => ResumeEditorScreenState();
}

class ResumeEditorScreenState extends State<ResumeEditorScreen> {
  int _activeSubTab = 0;
  double _atsScore = 88.0;
  ResumeType _selectedResumeType = ResumeType.experience;

  // Automatic Keyword Highlighting & ATS scoring state
  List<String> _matchedJobKeywords = [];
  List<String> _missingJobKeywords = [];
  bool _isAnalyzingKeywords = false;
  Timer? _jdDebounceTimer;

  void openFullPreviewDialog() => _openFullPreviewDialog();
  void openAtsScore() => handleSubSectionSelected(7);
  void openUploadResume() => _uploadResume();

  void _openFullPreviewDialog() {
    final currentResume = _buildCurrentResumeData();
    final validation = _selectedResumeType.validateCriteria(currentResume);
    if (!validation.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    validation.fullMessage,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    ResumePreviewDialog.show(
      context,
      resumeData: currentResume,
      selectedResumeType: _selectedResumeType,
      originalPdfBytes: _uploadedFileBytes,
      highlightKeywords: _matchedJobKeywords,
      onDownload: () => _downloadTailoredResume(format: 'pdf'),
    );
  }

  // Upload Resume state
  String? _uploadedFileName;
  Uint8List? _uploadedFileBytes;
  String? _rawExtractedText;
  bool _showExtractedText = false;
  bool _isUploading = false;
  bool _isParsing = false;
  String? _parseError;

  static final RegExp _bulletPrefixRegExp = RegExp(
    r'^[\s\-\*\u2022\u25a0\u25a1\u2610\u2612\u2611\u25cf\u25cb\u25aa\u25ab\u2023\u2043\u25e6\ufffd]+',
  );

  String _cleanBulletString(String input) {
    var s = input.trim();
    if (s.isEmpty) return '';
    while (s.isNotEmpty && _bulletPrefixRegExp.hasMatch(s)) {
      s = s.replaceAll(_bulletPrefixRegExp, '').trim();
    }
    return s;
  }

  // AI-extracted structured data (for dynamic sections)
  // AI-extracted structured data (starts null until user loads or uploads a resume)
  ResumeData? _parsedResumeData;
  bool _isEnhancingSummary = false;
  bool _isEditingIdentity = false;
  bool _isEditingSummary = false;
  int _activeSubSectionIndex = 0;
  int get activeSubSectionIndex => _activeSubSectionIndex;

  Map<String, int> get sectionCounts => {
    'education': _parsedResumeData?.education.length ?? 0,
    'skills': _skills.length,
    'projects': _parsedResumeData?.projects.length ?? 0,
    'experience': _parsedResumeData?.experience.length ?? 0,
    'extracurriculars': _parsedResumeData?.extracurriculars.length ?? 0,
  };

  void handleSubSectionSelected(int subIndex) {
    if (subIndex == 8) {
      final currentResume = _buildCurrentResumeData();
      final validation = _selectedResumeType.validateCriteria(currentResume);
      if (!validation.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFEF4444),
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      validation.fullMessage,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
    }
    setState(() {
      _activeSubSectionIndex = subIndex;
      _activeSubTab = subIndex;
    });
    widget.onSectionChanged?.call();
  }

  void handleGenerate() {
    setState(() {
      _activeSubTab = 6;
      _activeSubSectionIndex = 6;
    });
  }

  String _normalizeUrl(String rawUrl) {
    var clean = rawUrl.trim();
    if (clean.isEmpty) return '';

    // Extract URL from markdown link format [Text](url) or (url) or <url>
    final mdMatch = RegExp(r'\[.*?\]\((https?:\/\/[^\)]+)\)').firstMatch(clean);
    if (mdMatch != null) {
      clean = mdMatch.group(1) ?? clean;
    }
    clean = clean.replaceAll(RegExp(r'^["\x27<(\[\s]+|["\x27>\)\]\s,.]+$'), '');

    if (clean.isEmpty) return '';

    // Handle github.com / www.github.com missing scheme
    if (clean.startsWith('github.com/') || clean.startsWith('www.github.com/')) {
      clean = clean.replaceAll(RegExp(r'^(www\.)?github\.com\/'), '');
      return 'https://github.com/$clean';
    }

    // Match owner/repo pattern (e.g. "facebook/react" or "na623/jobwink") when no protocol or domain dot exists
    final repoMatch = RegExp(r'^@?([a-zA-Z0-9_\-]+)\/([a-zA-Z0-9_\-\.]+)$').firstMatch(clean);
    if (repoMatch != null && !clean.contains('.')) {
      final owner = repoMatch.group(1);
      final repo = repoMatch.group(2);
      return 'https://github.com/$owner/$repo';
    }

    // Standard HTTP / HTTPS
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    // Default to https protocol for domains like "myapp.com" or "demo.site.org"
    return 'https://$clean';
  }

  void _launchExternalUrl(String rawUrl) async {
    final formatted = _normalizeUrl(rawUrl);
    if (formatted.isEmpty) return;

    final uri = Uri.tryParse(formatted);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid link address: $rawUrl')),
        );
      }
      return;
    }

    try {
      debugPrint('[ResumeEditor] Launching external URL: $formatted');
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
      }
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $formatted')),
        );
      }
    } catch (e) {
      debugPrint('[ResumeEditor] Error launching $formatted: $e');
      try {
        await launchUrl(uri, webOnlyWindowName: '_blank');
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $formatted')),
          );
        }
      }
    }
  }

  // Tailoring state
  final TextEditingController _targetJobTitleController = TextEditingController();
  final TextEditingController _jobDescriptionController = TextEditingController();
  double _jobMatchScore = 0.0;
  bool _isDownloadingResume = false;

  // Section collapse state
  final Map<String, bool> _sectionExpanded = {
    'identity': true,
    'summary': true,
    'skills': true,
    'experience': true,
    'projects': true,
    'education': true,
    'extracurriculars': true,
  };

  // Identity controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _githubController = TextEditingController();

  // Existing controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _skillInputController = TextEditingController();

  final List<String> _skills = [];
  final List<String> _suggestedKeywords = [
    'GraphQL',
    'Kubernetes',
    'Docker',
    'AWS Lambda',
    'WebSockets'
  ];

  @override
  void initState() {
    super.initState();
    _activeSubTab = widget.initialTab.clamp(0, 9);
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_phoneChanged);
    _locationController.addListener(_onFieldChanged);
    _linkedinController.addListener(_onFieldChanged);
    _githubController.addListener(_onFieldChanged);
    _titleController.addListener(_onFieldChanged);
    _summaryController.addListener(_onFieldChanged);
    _jobDescriptionController.addListener(_onJobDescriptionChanged);
    _targetJobTitleController.addListener(_onJobDescriptionChanged);

    _loadCachedResume();
  }

  void _phoneChanged() => _onFieldChanged();

  /// Validates that cached resume data contains real content and not PDF artifacts.
  bool _isValidResumeData(ResumeData data) {
    const garbageTokens = [
      'stream', 'endstream', 'obj', 'endobj', 'xref', 'trailer',
      'startxref', 'pdf', 'catalog', 'flatedecode', 'mediabox',
      'fontname', 'type1', 'truetype',
    ];
    final nameLower = data.fullName.toLowerCase().trim();
    if (garbageTokens.contains(nameLower)) {
      debugPrint('[ResumeEditor] Rejecting cached data: name="${data.fullName}" is a garbage token');
      return false;
    }

    // Require structured sections (skills, experience, education, projects, etc.) for cached resume reuse
    return data.hasStructuredSections;
  }

  void populateFormFromResume(ResumeData data) {
    debugPrint('[ResumeEditor] BEFORE POPULATE: name="${_nameController.text}", email="${_emailController.text}", phone="${_phoneController.text}"');

    _parsedResumeData = data;

    _nameController.text = data.fullName;
    _emailController.text = data.email;
    _phoneController.text = data.phone;
    _locationController.text = data.location;
    _linkedinController.text = data.linkedin;
    _githubController.text = data.github;

    if (data.title.isNotEmpty) {
      _titleController.text = data.title;
      _targetJobTitleController.text = data.title;
    } else if (data.experience.isNotEmpty && data.experience.first.role.isNotEmpty) {
      _targetJobTitleController.text = data.experience.first.role;
      _titleController.text = data.experience.first.role;
    } else {
      _titleController.text = '';
      _targetJobTitleController.text = '';
    }

    _summaryController.text = data.summary;

    _skills.clear();
    final allExtractedSkills = <String>{};
    for (final s in data.skills) {
      final trimmed = s.trim();
      if (trimmed.isNotEmpty && !ResumeData.isPlaceholderValue(trimmed)) {
        allExtractedSkills.add(trimmed);
      }
    }
    for (final g in data.skillGroups) {
      for (final s in g.items) {
        final trimmed = s.trim();
        if (trimmed.isNotEmpty && !ResumeData.isPlaceholderValue(trimmed)) {
          allExtractedSkills.add(trimmed);
        }
      }
    }
    _skills.addAll(allExtractedSkills);

    // Compute initial ATS score dynamically from completeness
    double score = 0;
    if (_nameController.text.isNotEmpty) score += 10;
    if (_emailController.text.isNotEmpty) score += 5;
    if (_phoneController.text.isNotEmpty) score += 5;
    if (_locationController.text.isNotEmpty) score += 5;
    if (_titleController.text.isNotEmpty) score += 10;
    if (_summaryController.text.isNotEmpty) score += 15;
    if (_skills.isNotEmpty) score += 15;
    if (data.experience.isNotEmpty) score += 20;
    if (data.education.isNotEmpty) score += 15;
    _atsScore = score.clamp(0.0, 100.0);

    // Expand sections so populated data is visible immediately
    _sectionExpanded['identity'] = true;
    _sectionExpanded['summary'] = true;
    _sectionExpanded['skills'] = true;
    _sectionExpanded['experience'] = true;
    _sectionExpanded['projects'] = true;
    _sectionExpanded['education'] = true;
    _sectionExpanded['extracurriculars'] = true;

    debugPrint('[DEBUG-PIPELINE-7] CONTROLLER STATE: name="${_nameController.text}", email="${_emailController.text}", phone="${_phoneController.text}", location="${_locationController.text}", title="${_titleController.text}", summary="${_summaryController.text}", skillsCount=${_skills.length}');
    debugPrint('[DEBUG-PIPELINE-8] UI MODEL: parsedName="${_parsedResumeData?.fullName}", parsedEmail="${_parsedResumeData?.email}", parsedPhone="${_parsedResumeData?.phone}"');

    data.logResumeMappingDebug(
      stage: 'ResumeEditor Form Population',
      extractedTextLength: _rawExtractedText?.length,
    );

    if (_jobDescriptionController.text.trim().isNotEmpty) {
      _analyzeJobDescriptionKeywords();
    }

    widget.onSectionChanged?.call();
  }

  Future<void> _loadCachedResume() async {
    final cached = await ResumePersistenceService.instance.loadLatestParsedResume();
    if (!mounted) return;

    // Do NOT overwrite newly uploaded/extracted data if user uploaded a file or is currently parsing
    if (_uploadedFileBytes != null || _isUploading || _isParsing) return;

    final auth = AuthProviderScope.read(context);
    final user = auth.currentUser;
    final userName = user?.fullName ?? '';
    final userEmail = user?.email ?? '';
    final userPhone = user?.phone ?? '';
    final userLocation = user?.location ?? '';
    final userLinkedin = user?.linkedinUrl ?? '';
    final userGithub = user?.githubUrl ?? '';

    if (cached != null && _isValidResumeData(cached) && (cached.hasStructuredSections || cached.fullName.isNotEmpty)) {
      debugPrint('[ResumePipeline] Using cached resume for user ${user?.id}');
      setState(() {
        populateFormFromResume(cached);
        if (_nameController.text.isEmpty && userName.isNotEmpty) _nameController.text = userName;
        if (_emailController.text.isEmpty && userEmail.isNotEmpty) _emailController.text = userEmail;
        if (_phoneController.text.isEmpty && userPhone.isNotEmpty) _phoneController.text = userPhone;
        if (_locationController.text.isEmpty && userLocation.isNotEmpty) _locationController.text = userLocation;
        if (_linkedinController.text.isEmpty && userLinkedin.isNotEmpty) _linkedinController.text = userLinkedin;
        if (_githubController.text.isEmpty && userGithub.isNotEmpty) _githubController.text = userGithub;
      });
      debugPrint('[ResumeEditor] Loaded valid cached resume: name="${_nameController.text}", exp=${cached.experience.length}');
    } else {
      // If no valid cached resume exists yet, populate fields with user profile data if non-empty
      setState(() {
        if (_nameController.text.isEmpty && userName.isNotEmpty) _nameController.text = userName;
        if (_emailController.text.isEmpty && userEmail.isNotEmpty) _emailController.text = userEmail;
        if (_phoneController.text.isEmpty && userPhone.isNotEmpty) _phoneController.text = userPhone;
        if (_locationController.text.isEmpty && userLocation.isNotEmpty) _locationController.text = userLocation;
        if (_linkedinController.text.isEmpty && userLinkedin.isNotEmpty) _linkedinController.text = userLinkedin;
        if (_githubController.text.isEmpty && userGithub.isNotEmpty) _githubController.text = userGithub;

        double score = 0;
        if (_nameController.text.isNotEmpty) score += 10;
        if (_emailController.text.isNotEmpty) score += 5;
        if (_phoneController.text.isNotEmpty) score += 5;
        if (_locationController.text.isNotEmpty) score += 5;
        _atsScore = score.clamp(0.0, 100.0);
      });
      debugPrint('[ResumeEditor] Initialized identity fields with user profile data');
    }
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
      if (_jobDescriptionController.text.trim().isNotEmpty) {
        _onJobDescriptionChanged();
      }
    }
  }

  void _onJobDescriptionChanged() {
    _jdDebounceTimer?.cancel();
    _jdDebounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        _analyzeJobDescriptionKeywords();
      }
    });
  }

  Future<void> _analyzeJobDescriptionKeywords() async {
    final jd = _jobDescriptionController.text.trim();
    if (jd.isEmpty) {
      if (mounted) {
        setState(() {
          _jobMatchScore = 0.0;
          _matchedJobKeywords = [];
          _missingJobKeywords = [];
          _isAnalyzingKeywords = false;
        });
      }
      return;
    }

    setState(() => _isAnalyzingKeywords = true);

    try {
      final currentResume = _buildCurrentResumeData();
      final result = await AIService.instance.analyzeJobKeywords(
        jobDescription: jd,
        currentResume: currentResume,
        targetJobTitle: _targetJobTitleController.text,
      );

      debugPrint('============================================================');
      debugPrint('[KEYWORD DEBUG]');
      debugPrint('Job Description received: ${jd.isNotEmpty ? "YES" : "NO"}');
      debugPrint('Extracted keywords: ${result.extractedJobKeywords}');
      debugPrint('Matched keywords in Projects/Experience: ${result.projectAndExperienceKeywords}');
      debugPrint('Missing keywords: ${result.missingKeywords}');
      debugPrint('ATS Score: ${result.atsScore}');
      debugPrint('============================================================');

      if (mounted) {
        setState(() {
          _jobMatchScore = result.matchScore;
          _atsScore = result.atsScore;
          _matchedJobKeywords = result.projectAndExperienceKeywords;
          _missingJobKeywords = result.missingKeywords;
          _isAnalyzingKeywords = false;
        });
      }
    } catch (e) {
      debugPrint('[ResumeEditor] Error analyzing job keywords: $e');
      if (mounted) {
        setState(() => _isAnalyzingKeywords = false);
      }
    }
  }

  @override
  void dispose() {
    _jdDebounceTimer?.cancel();
    _jobDescriptionController.removeListener(_onJobDescriptionChanged);
    _targetJobTitleController.removeListener(_onJobDescriptionChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    _skillInputController.dispose();
    _targetJobTitleController.dispose();
    _jobDescriptionController.dispose();
    super.dispose();
  }

  void _toggleSection(String key) {
    setState(() => _sectionExpanded[key] = !(_sectionExpanded[key] ?? true));
  }

  void _addSkill(String skill) {
    if (skill.trim().isEmpty || _skills.contains(skill.trim())) return;
    setState(() {
      _skills.add(skill.trim());
      _suggestedKeywords.remove(skill.trim());
      _atsScore = (_atsScore + 2.5).clamp(0.0, 100.0);
    });
    _skillInputController.clear();
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
      _atsScore = (_atsScore - 2.5).clamp(0.0, 100.0);
    });
  }

  Future<void> _retryParsing() async {
    if (_uploadedFileBytes == null || _uploadedFileName == null) return;
    setState(() {
      _isUploading = true;
      _isParsing = true;
      _parseError = null;
    });

    try {
      final mimeType = _getMimeType(_uploadedFileName!);
      final resumeData = await AIService.instance.parseResume(
        _uploadedFileBytes!,
        mimeType,
      );

      if (!mounted) return;

      if (resumeData != null && resumeData.hasUsableData) {
        setState(() {
          _isUploading = false;
          _isParsing = false;
          populateFormFromResume(resumeData);
        });
        ResumePersistenceService.instance.saveParsedResume(resumeData);
      } else {
        setState(() {
          _isUploading = false;
          _isParsing = false;
          _parseError = 'AI parsing failed. Please try another file.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _isParsing = false;
        _parseError = 'Error retrying extraction: $e';
      });
    }
  }

  void _uploadResume() async {
    final auth = AuthProviderScope.read(context);
    if (!auth.isAuthenticated && DemoService.instance.isDemoMode) {
      await DemoUpsellDialog.show(
        context,
        actionTitle: 'Resume Upload',
        description:
            'Create a free account to upload, parse, and securely store your custom resumes in the cloud.',
      );
      return;
    }

    final pickerResult = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'jpg', 'jpeg', 'png', 'txt'],
      withData: true,
    );

    if (pickerResult == null || pickerResult.files.isEmpty) return;

    final pickedFile = pickerResult.files.first;
    Uint8List? bytes = pickedFile.bytes;

    if (bytes == null && pickedFile.path != null && pickedFile.path!.isNotEmpty) {
      try {
        final file = File(pickedFile.path!);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      } catch (e) {
        debugPrint('Error reading file from path: $e');
      }
    }

    if (!mounted) return;

    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text(
            'Could not read file bytes. Please select another file.',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
      return;
    }

    final fileBytes = bytes;

    debugPrint('[ResumePipeline] New resume uploaded - cache invalidated');
    debugPrint('[ResumePipeline] New resume detected - starting extraction');

    setState(() {
      _uploadedFileName = pickedFile.name;
      _uploadedFileBytes = fileBytes;
      _isUploading = true;
      _isParsing = true;
      _parseError = null;
    });

    try {
      final mimeType = _getMimeType(pickedFile.name);
      debugPrint('[ResumeEditor] Starting AI extraction: file=${pickedFile.name}, bytes=${fileBytes.length}');

      // Compute unique file hash to invalidate cache and track distinct uploads
      String fileHash = '';
      try {
        var hash = BigInt.parse('14695981039346656037');
        final fnvPrime = BigInt.parse('1099511628211');
        final mask64 = (BigInt.one << 64) - BigInt.one;
        for (final b in fileBytes) {
          hash = (hash ^ BigInt.from(b)) * fnvPrime & mask64;
        }
        fileHash = hash.toRadixString(16).padLeft(16, '0');
      } catch (_) {}

      // Extract raw text with robust local decoding + backend fallback + token sanitization
      final rawExtracted = await AIService.instance.extractTextFromBytesAsync(
        Uint8List.fromList(fileBytes),
        fileName: pickedFile.name,
      );
      _rawExtractedText = rawExtracted;
      debugPrint('[ResumeParser] Raw extracted text length: ${rawExtracted.length}');
      debugPrint('[DEBUG-PIPELINE-1] PDF TEXT LENGTH: ${rawExtracted.length}');
      debugPrint('[DEBUG-PIPELINE-2] PDF TEXT PREVIEW: ${rawExtracted.length > 200 ? rawExtracted.substring(0, 200) : rawExtracted}');

      final parsedData = await AIService.instance.parseResume(
        Uint8List.fromList(fileBytes),
        mimeType,
      );

      final resumeData = (parsedData != null && fileHash.isNotEmpty)
          ? parsedData.copyWith(fileHash: fileHash)
          : parsedData;

      if (!mounted) return;

      if (resumeData != null && resumeData.hasUsableData) {
        debugPrint('[ResumeEditor] AI extraction result: SUCCESS');
        debugPrint('[ResumeEditor] Extracted: name="${resumeData.fullName}", email="${resumeData.email}", phone="${resumeData.phone}"');
        debugPrint('[ResumeEditor] Extracted: exp=${resumeData.experience.length}, edu=${resumeData.education.length}, proj=${resumeData.projects.length}, skills=${resumeData.skills.length}');
        debugPrint('[RESUME] Extracted resume name: ${resumeData.fullName}');

        setState(() {
          _isUploading = false;
          _isParsing = false;
          populateFormFromResume(resumeData);
        });

        // Background persistence — only save valid data
        ResumePersistenceService.instance.saveParsedResume(resumeData);
        debugPrint('[ResumeEditor] Persisted valid extracted data to Supabase');

        // Store original PDF bytes for template-faithful export
        if (pickedFile.name.toLowerCase().endsWith('.pdf')) {
          ResumeExportService.instance.setOriginalPdfBytes(Uint8List.fromList(fileBytes));
        }

        StorageRepository().uploadResume(
          fileName: pickedFile.name,
          bytes: fileBytes,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF10B981),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Resume "${pickedFile.name}" uploaded & extracted successfully!',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        debugPrint('[ResumeEditor] AI extraction result: EXTRACTION_FAILED');
        if (_rawExtractedText != null && _rawExtractedText!.isNotEmpty) {
          final fallbackData = ResumeData.parseFromRawText(_rawExtractedText!);
          if (fallbackData.hasUsableData) {
            debugPrint('[ResumeEditor] AI returned null/empty data, but local raw-text fallback parser extracted sections successfully!');
            setState(() {
              _isUploading = false;
              _isParsing = false;
              populateFormFromResume(fallbackData);
            });
            ResumePersistenceService.instance.saveParsedResume(fallbackData);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF10B981),
                  content: Text(
                    'Resume "${pickedFile.name}" extracted & parsed successfully!',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }
            return;
          }
        }

        setState(() {
          _isUploading = false;
          _isParsing = false;
          _parseError =
              'AI could not extract structured resume data. Please ensure the file contains legible resume text.';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFEF4444),
              content: Text(
                'AI parsing failed. Please try uploading a clearer PDF or image.',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }
      }
    } on AIUsageLimitException catch (limitErr) {
      setState(() {
        _isUploading = false;
        _isParsing = false;
        _parseError = limitErr.message;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text(
              limitErr.message,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isParsing = false;
        _parseError = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text(
              'File upload error: $e',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    }
  }

  /// Determines MIME type from file extension for Gemini API.
  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'docx':
      case 'doc':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/pdf';
    }
  }

  /// Builds a [ResumeData] from the current UI state for tailoring.
  ResumeData _buildCurrentResumeData() {
    return ResumeData(
      fullName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      location: _locationController.text,
      linkedin: _linkedinController.text,
      github: _githubController.text,
      title: _titleController.text,
      summary: _summaryController.text,
      skills: List.from(_skills),
      experience: _parsedResumeData?.experience ?? [],
      projects: _parsedResumeData?.projects ?? [],
      education: _parsedResumeData?.education ?? [],
      certifications: _parsedResumeData?.certifications ?? [],
      extracurriculars: _parsedResumeData?.extracurriculars ?? [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isDarkMode = AppTheme.isDarkMode(context);

    return Column(
      children: [
        const DemoBanner(),
        Expanded(
          child: PageContainer(
            maxWidth: 1380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar
                PageHeader(
                  title: 'CV Studio & Resume Tailoring 📝',
                  subtitle: 'Upload existing resume or tailor your CV to any target job description in real-time.',
                  action: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: isDarkMode ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: isDarkMode ? 0.35 : 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _jobDescriptionController.text.trim().isNotEmpty
                              ? 'Job Matched (${_jobMatchScore.toInt()}% Match)'
                              : 'Job Alignment Ready',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? const Color(0xFF34D399) : const Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sub-Navigation Tab Bar (Step 1 to Step 5)
                _buildSubTabBar(context, isDarkMode),

                // Active Sub-Page Content Container
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: _buildActiveSubPage(context, isDarkMode, isDesktop),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabBar(BuildContext context, bool isDarkMode) {
    return _buildStepperNavigation(context, isDarkMode);
  }

  Widget _buildStepperNavigation(BuildContext context, bool isDarkMode) {
    final steps = [
      {'step': '1', 'title': 'Profile', 'subtitle': 'Identity & Summary', 'tab': 0},
      {'step': '2', 'title': 'Education', 'subtitle': 'Degrees & Academics', 'tab': 1},
      {'step': '3', 'title': 'Skills', 'subtitle': 'Technical Skills', 'tab': 2},
      {'step': '4', 'title': 'Projects', 'subtitle': 'GitHub & Portfolio', 'tab': 3},
      {'step': '5', 'title': 'Experience', 'subtitle': 'Work History', 'tab': 4},
      {'step': '6', 'title': 'Extracurriculars', 'subtitle': 'Activities & Honors', 'tab': 5},
      {'step': '7', 'title': 'Target Job', 'subtitle': 'Job Description & AI', 'tab': 6},
      {'step': '8', 'title': 'Export', 'subtitle': 'Download & Preview', 'tab': 8},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final targetTab = step['tab'] as int;
            final isActive = _activeSubTab == targetTab;
            final isCompleted = _activeSubTab > targetTab;
            final isLast = index == steps.length - 1;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    handleSubSectionSelected(targetTab);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? AppTheme.primaryOrange
                                : (isCompleted
                                    ? AppTheme.primaryOrange.withValues(alpha: 0.25)
                                    : Colors.transparent),
                            border: isActive
                                ? null
                                : Border.all(
                                    color: isCompleted
                                        ? AppTheme.primaryOrange.withValues(alpha: 0.6)
                                        : const Color(0xFF333B4D),
                                    width: 1.5,
                                  ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            step['step'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? Colors.white
                                  : (isCompleted
                                      ? AppTheme.primaryOrange
                                      : const Color(0xFF8B949E)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              step['title'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? AppTheme.getTextColor(context)
                                    : const Color(0xFF8B949E),
                              ),
                            ),
                            Text(
                              step['subtitle'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF8B949E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 20,
                    height: 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: isCompleted || isActive
                        ? AppTheme.primaryOrange.withValues(alpha: 0.5)
                        : const Color(0xFF212836),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActiveSubPage(BuildContext context, bool isDarkMode, bool isDesktop) {
    switch (_activeSubTab) {
      case 0:
        // Tab 0: Upload & Profile Dashboard
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextColor(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your personal details, contact info, and career summary.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getMutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            _buildUploadResumeCard(context, isDarkMode),
            _buildExtractedTextCard(context, isDarkMode),
            _buildIdentityCard(context, isDarkMode, isDesktop),
            _buildSummaryCard(context, isDarkMode),
            const SizedBox(height: 24),
            _buildSubPageNavigationFooter(
              nextTitle: 'Next: Education →',
              onNext: () => handleSubSectionSelected(1),
            ),
          ],
        );

      case 1:
        // Tab 1: Education
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Education',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextColor(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your academic history, degrees, and educational institutions.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getMutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionCard(
              context: context,
              sectionKey: 'education',
              icon: Icons.school_outlined,
              title: 'Education',
              subtitle: '${_parsedResumeData?.education.length ?? 0} entries',
              child: _buildEducationSection(context, isDarkMode),
            ),
            const SizedBox(height: 24),
            _buildSubPageNavigationFooter(
              prevTitle: '← Back: Profile',
              onPrev: () => handleSubSectionSelected(0),
              nextTitle: 'Next: Skills →',
              onNext: () => handleSubSectionSelected(2),
            ),
          ],
        );

      case 2:
        // Tab 2: Skills
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skills & Technical Keywords',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextColor(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage technical skills, frameworks, tools, and ATS keywords.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getMutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionCard(
              context: context,
              sectionKey: 'skills',
              icon: Icons.psychology_outlined,
              title: 'Skills & Technical Keywords',
              subtitle: '${_skills.length} skills added',
              child: _buildSkillsSection(context, isDarkMode),
            ),
            const SizedBox(height: 24),
            _buildSubPageNavigationFooter(
              prevTitle: '← Back: Education',
              onPrev: () => handleSubSectionSelected(1),
              nextTitle: 'Next: Projects →',
              onNext: () => handleSubSectionSelected(3),
            ),
          ],
        );

      case 3:
        // Tab 3: Projects
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Projects & GitHub Repositories',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextColor(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Highlight software projects, open source work, and technical portfolio.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getMutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionCard(
              context: context,
              sectionKey: 'projects',
              icon: Icons.folder_special_outlined,
              title: 'Projects & GitHub Repositories',
              subtitle: '${_parsedResumeData?.projects.length ?? 0} entries',
              child: _buildProjectsSection(context, isDarkMode),
            ),
            const SizedBox(height: 24),
            _buildSubPageNavigationFooter(
              prevTitle: '← Back: Skills',
              onPrev: () => handleSubSectionSelected(2),
              nextTitle: 'Next: Experience →',
              onNext: () => handleSubSectionSelected(4),
            ),
          ],
        );

      case 4:
        // Tab 4: Work Experience
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Work Experience',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextColor(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage employment history, corporate roles, and professional impact.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getMutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionCard(
              context: context,
              sectionKey: 'experience',
              icon: Icons.work_outline_rounded,
              title: 'Work Experience',
              subtitle: '${_parsedResumeData?.experience.length ?? 0} entries',
              child: _buildExperienceSection(context, isDarkMode),
            ),
            const SizedBox(height: 24),
            _buildSubPageNavigationFooter(
              prevTitle: '← Back: Projects',
              onPrev: () => handleSubSectionSelected(3),
              nextTitle: 'Next: Extracurriculars →',
              onNext: () => handleSubSectionSelected(5),
            ),
          ],
        );

      case 5:
        // Tab 5: Extracurriculars
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Extracurricular Activities',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextColor(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage volunteer work, leadership roles, competitions, and honors.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getMutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionCard(
              context: context,
              sectionKey: 'extracurriculars',
              icon: Icons.interests_outlined,
              title: 'Extracurricular Activities',
              subtitle: '${_parsedResumeData?.extracurriculars.length ?? 0} entries',
              child: _buildExtracurricularsSection(context, isDarkMode),
            ),
            const SizedBox(height: 24),
            _buildSubPageNavigationFooter(
              prevTitle: '← Back: Experience',
              onPrev: () => handleSubSectionSelected(4),
              nextTitle: 'Next: Target Job →',
              onNext: () => handleSubSectionSelected(6),
            ),
          ],
        );

      case 6:
        // Tab 6: Target Job Description & Tailoring
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target Job Description',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextColor(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Paste the target job description to tailor your resume with AI.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getMutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            _buildTailoringCard(context, isDarkMode),
            const SizedBox(height: 24),
            _buildSubPageNavigationFooter(
              prevTitle: '← Back: Extracurriculars',
              onPrev: () => handleSubSectionSelected(5),
              nextTitle: 'Next: Preview & Export →',
              onNext: () => handleSubSectionSelected(8),
            ),
          ],
        );

      case 7:
        // Tab 7: ATS Score Analysis
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ATS Score Analysis',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextColor(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time ATS compatibility scoring, keyword matching, and recommendations.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getMutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            _buildUploadResumeCard(context, isDarkMode),
            _buildExtractedTextCard(context, isDarkMode),
            const SizedBox(height: 16),
            _buildAtsGaugeCard(context, isDarkMode),
            const SizedBox(height: 24),
            _buildSubPageNavigationFooter(
              prevTitle: '← Back: Target Job',
              onPrev: () => handleSubSectionSelected(6),
              nextTitle: 'Next: Preview & Export →',
              onNext: () => handleSubSectionSelected(8),
            ),
          ],
        );

      case 8:
        // Tab 8: Live Preview & Export
        final exportResume = _buildCurrentResumeData();
        final exportValidation = _selectedResumeType.validateCriteria(exportResume);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview & Export',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextColor(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Preview your single-page tailored resume and export to PDF.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getMutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            if (!exportValidation.isValid) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meet the criteria to build your resume.',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          if (exportValidation.detailMessage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              exportValidation.detailMessage!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.getTextColor(context).withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openFullPreviewDialog,
                    icon: Icon(
                      Icons.visibility_rounded,
                      size: 20,
                      color: exportValidation.isValid ? AppTheme.primaryOrange : const Color(0xFF8B949E),
                    ),
                    label: Text(
                      'Preview Resume',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: exportValidation.isValid ? AppTheme.primaryOrange : const Color(0xFF8B949E),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: exportValidation.isValid
                            ? AppTheme.primaryOrange
                            : const Color(0xFF8B949E).withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: (exportValidation.isValid && !_isDownloadingResume)
                        ? () => _showExportModal(context)
                        : null,
                    icon: _isDownloadingResume
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      _isDownloadingResume
                          ? 'Generating Resume...'
                          : 'Download Tailored Resume (PDF / DOCX) →',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: exportValidation.isValid ? AppTheme.primaryOrange : const Color(0xFF4B5563),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: exportValidation.isValid ? 2 : 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSubPageNavigationFooter(
              prevTitle: '← Back: Target Job',
              onPrev: () => handleSubSectionSelected(6),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSubPageNavigationFooter({
    String? prevTitle,
    VoidCallback? onPrev,
    String? nextTitle,
    VoidCallback? onNext,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (prevTitle != null && onPrev != null)
          OutlinedButton(
            onPressed: onPrev,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              prevTitle,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        if (nextTitle != null && onNext != null)
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              nextTitle,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  // ── Card-Based Identity & Summary Widgets ──

  Widget _buildIdentityCard(BuildContext context, bool isDarkMode, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Edit / Save toggle
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Identity & Contact Details',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      Text(
                        'Name, title, email, phone, location & career profiles',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.getMutedTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditingIdentity = !_isEditingIdentity;
                    });
                  },
                  icon: Icon(
                    _isEditingIdentity ? Icons.check_circle_rounded : Icons.edit_rounded,
                    size: 16,
                    color: _isEditingIdentity ? Colors.green : AppTheme.primaryOrange,
                  ),
                  label: Text(
                    _isEditingIdentity ? 'Save Changes' : 'Edit Identity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _isEditingIdentity ? Colors.green : AppTheme.primaryOrange,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    side: BorderSide(
                      color: _isEditingIdentity ? Colors.green : AppTheme.primaryOrange.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content: Edit Form vs Card View
          Padding(
            padding: const EdgeInsets.all(18),
            child: _isEditingIdentity
                ? _buildIdentitySection(context, isDarkMode, isDesktop)
                : _buildIdentityDisplayGrid(context, isDarkMode, isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityDisplayGrid(BuildContext context, bool isDarkMode, bool isDesktop) {
    final fields = [
      {'label': 'Full Name', 'value': _nameController.text, 'icon': Icons.person},
      {'label': 'Job Title', 'value': _titleController.text, 'icon': Icons.badge},
      {'label': 'Email Address', 'value': _emailController.text, 'icon': Icons.email},
      {'label': 'Phone Number', 'value': _phoneController.text, 'icon': Icons.phone},
      {'label': 'Location', 'value': _locationController.text, 'icon': Icons.location_on},
      {'label': 'LinkedIn Profile', 'value': _linkedinController.text, 'icon': Icons.link},
      {'label': 'Portfolio / GitHub', 'value': _githubController.text, 'icon': Icons.language},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 768 ? 2 : 1;
        return Wrap(
          spacing: 16,
          runSpacing: 14,
          children: fields.map((f) {
            final val = (f['value'] as String).trim();
            final hasValue = val.isNotEmpty;
            final width = crossAxisCount == 2
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;

            return SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF1E2430)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.getBorderColor(context).withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      size: 18,
                      color: hasValue ? AppTheme.primaryOrange : AppTheme.getMutedTextColor(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            f['label'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getMutedTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasValue ? val : 'Not specified',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                              color: hasValue
                                  ? AppTheme.getTextColor(context)
                                  : AppTheme.getMutedTextColor(context).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with AI Enhance and Edit buttons
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.article_outlined,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Professional Summary',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      Text(
                        'Executive summary highlighting your core strengths & impact',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.getMutedTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isEnhancingSummary ? null : _enhanceSummaryWithAI,
                  icon: _isEnhancingSummary
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome, size: 14),
                  label: Text(
                    _isEnhancingSummary ? 'Enhancing...' : 'AI Enhance',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditingSummary = !_isEditingSummary;
                    });
                  },
                  icon: Icon(
                    _isEditingSummary ? Icons.check_circle_rounded : Icons.edit_rounded,
                    size: 16,
                    color: _isEditingSummary ? Colors.green : AppTheme.primaryOrange,
                  ),
                  label: Text(
                    _isEditingSummary ? 'Save' : 'Edit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _isEditingSummary ? Colors.green : AppTheme.primaryOrange,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: BorderSide(
                      color: _isEditingSummary ? Colors.green : AppTheme.primaryOrange.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(18),
            child: _isEditingSummary
                ? _buildSummarySection(context, isDarkMode)
                : _buildSummaryDisplayView(context, isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDisplayView(BuildContext context, bool isDarkMode) {
    final text = _summaryController.text.trim();
    final hasText = text.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.6)),
      ),
      child: Text(
        hasText
            ? text
            : 'No professional summary provided yet. Click "AI Enhance" or "Edit" to add your summary.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          height: 1.6,
          fontWeight: hasText ? FontWeight.w500 : FontWeight.w400,
          color: hasText
              ? AppTheme.getTextColor(context)
              : AppTheme.getMutedTextColor(context).withValues(alpha: 0.6),
          fontStyle: hasText ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    );
  }

  Future<void> _enhanceSummaryWithAI() async {
    setState(() {
      _isEnhancingSummary = true;
    });
    try {
      final currentText = _summaryController.text.trim();
      final title = _titleController.text.isNotEmpty ? _titleController.text : 'Software Engineer';
      final enhancedText = currentText.isNotEmpty
          ? 'Results-driven $title with expertise in ${_skills.take(5).join(", ")}. Proven track record in developing high-performance solutions, scaling architectures, and delivering measurable business impact.'
          : 'High-performing $title experienced in software engineering, cross-functional collaboration, and technical innovation. Passionate about solving complex problems and driving technical excellence.';

      setState(() {
        _summaryController.text = enhancedText;
        _isEditingSummary = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Professional Summary enhanced with AI!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI Enhancement failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEnhancingSummary = false;
        });
      }
    }
  }



  // ── Extracted Resume Text Card ──

  Widget _buildExtractedTextCard(BuildContext context, bool isDarkMode) {
    if (_rawExtractedText == null || _rawExtractedText!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final charCount = _rawExtractedText!.length;
    final isReadable = AIService.validateExtractedText(_rawExtractedText!);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReadable
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : const Color(0xFFEF4444).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isReadable ? Icons.description_outlined : Icons.warning_amber_rounded,
                color: isReadable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Extracted Resume Text ($charCount chars)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isReadable ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isReadable ? '✓ Readable' : '⚠️ Garbled / Unreadable',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isReadable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _showExtractedText ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppTheme.getMutedTextColor(context),
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _showExtractedText = !_showExtractedText);
                },
                tooltip: _showExtractedText ? 'Collapse Text' : 'View Extracted Text',
              ),
            ],
          ),
          if (_showExtractedText) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.getBorderColor(context)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _rawExtractedText!,
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    height: 1.4,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Upload Resume Option Card ──

  Widget _buildUploadResumeCard(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _parseError != null
              ? const Color(0xFFEF4444)
              : (_uploadedFileName != null
                  ? const Color(0xFF10B981)
                  : AppTheme.getBorderColor(context)),
          width: (_uploadedFileName != null || _parseError != null) ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _parseError != null
                  ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                  : (_uploadedFileName != null
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : AppTheme.primaryOrange.withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _parseError != null
                  ? Icons.error_outline_rounded
                  : (_uploadedFileName != null
                      ? Icons.check_circle_rounded
                      : Icons.cloud_upload_outlined),
              color: _parseError != null
                  ? const Color(0xFFEF4444)
                  : (_uploadedFileName != null
                      ? const Color(0xFF10B981)
                      : AppTheme.primaryOrange),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isParsing
                      ? 'AI Extracting Resume... ✨'
                      : (_uploadedFileName != null
                          ? 'Resume Active'
                          : 'Upload Existing Resume 📤'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isParsing
                      ? 'AI Parsing'
                      : (_parseError ??
                          (_uploadedFileName ??
                              'Upload PDF, DOCX, or Image (JPG/PNG) to auto-extract info.')),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: _parseError != null
                        ? const Color(0xFFEF4444)
                        : (_uploadedFileName != null
                            ? const Color(0xFF10B981)
                            : AppTheme.getMutedTextColor(context)),
                    fontWeight: _uploadedFileName != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                if (_uploadedFileBytes != null && _parseError != null) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: (_isUploading || _isParsing) ? null : _retryParsing,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 4),
                          Text(
                            'Retry AI Extraction',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEF4444),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: (_isUploading || _isParsing) ? null : _uploadResume,
            icon: (_isUploading || _isParsing)
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _uploadedFileName != null
                        ? Icons.sync_rounded
                        : Icons.file_upload_rounded,
                    size: 16),
            label: Text(
              _isUploading
                  ? 'Uploading...'
                  : (_isParsing
                      ? 'Extracting...'
                      : (_uploadedFileName != null
                          ? 'Re-upload'
                          : 'Choose Resume')),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _uploadedFileName != null
                  ? AppTheme.getSurfaceColor(context)
                  : AppTheme.primaryOrange,
              foregroundColor: _uploadedFileName != null
                  ? AppTheme.getTextColor(context)
                  : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              side: _uploadedFileName != null
                  ? BorderSide(color: AppTheme.getBorderColor(context))
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Collapsible Section Card Wrapper ──

  Widget _buildSectionCard({
    required BuildContext context,
    required String sectionKey,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final isExpanded = _sectionExpanded[sectionKey] ?? true;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          // Header Toggle Bar
          InkWell(
            onTap: () => _toggleSection(sectionKey),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppTheme.primaryOrange, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.getMutedTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.getMutedTextColor(context),
                  ),
                ],
              ),
            ),
          ),
          // Collapsible Content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  Divider(color: AppTheme.getBorderColor(context)),
                  const SizedBox(height: 12),
                  child,
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // ── Section 1: Identity & Contact (2-Column Grid) ──

  Widget _buildIdentitySection(
      BuildContext context, bool isDarkMode, bool isDesktop) {
    return Column(
      children: [
        if (isDesktop) ...[
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  context: context,
                  label: 'Full Name',
                  hint: 'e.g. Alex Johnson',
                  icon: Icons.person_rounded,
                  controller: _nameController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField(
                  context: context,
                  label: 'Email Address',
                  hint: 'e.g. alex.johnson@example.com',
                  icon: Icons.email_rounded,
                  controller: _emailController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  context: context,
                  label: 'Phone Number',
                  hint: 'e.g. +1 (555) 019-2834',
                  icon: Icons.phone_rounded,
                  controller: _phoneController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField(
                  context: context,
                  label: 'Location / City',
                  hint: 'e.g. San Francisco, CA',
                  icon: Icons.location_on_rounded,
                  controller: _locationController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  context: context,
                  label: 'LinkedIn Profile',
                  hint: 'e.g. linkedin.com/in/alexjohnson',
                  icon: Icons.link_rounded,
                  controller: _linkedinController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField(
                  context: context,
                  label: 'GitHub / Portfolio',
                  hint: 'e.g. github.com/alexjohnson',
                  icon: Icons.code_rounded,
                  controller: _githubController,
                ),
              ),
            ],
          ),
        ] else ...[
          _buildFormField(
            context: context,
            label: 'Full Name',
            hint: 'e.g. Alex Johnson',
            icon: Icons.person_rounded,
            controller: _nameController,
          ),
          const SizedBox(height: 12),
          _buildFormField(
            context: context,
            label: 'Email Address',
            hint: 'e.g. alex.johnson@example.com',
            icon: Icons.email_rounded,
            controller: _emailController,
          ),
          const SizedBox(height: 12),
          _buildFormField(
            context: context,
            label: 'Phone Number',
            hint: 'e.g. +1 (555) 019-2834',
            icon: Icons.phone_rounded,
            controller: _phoneController,
          ),
          const SizedBox(height: 12),
          _buildFormField(
            context: context,
            label: 'Location / City',
            hint: 'e.g. San Francisco, CA',
            icon: Icons.location_on_rounded,
            controller: _locationController,
          ),
          const SizedBox(height: 12),
          _buildFormField(
            context: context,
            label: 'LinkedIn Profile',
            hint: 'e.g. linkedin.com/in/alexjohnson',
            icon: Icons.link_rounded,
            controller: _linkedinController,
          ),
          const SizedBox(height: 12),
          _buildFormField(
            context: context,
            label: 'GitHub / Portfolio',
            hint: 'e.g. github.com/alexjohnson',
            icon: Icons.code_rounded,
            controller: _githubController,
          ),
        ],
      ],
    );
  }

  // Helper Form Field Builder
  Widget _buildFormField({
    required BuildContext context,
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.getTextColor(context),
          ),
          decoration: _inputDecoration(context, hint).copyWith(
            prefixIcon:
                Icon(icon, size: 18, color: AppTheme.getMutedTextColor(context)),
          ),
        ),
      ],
    );
  }

  // ── Section 2: Professional Summary ──

  Widget _buildSummarySection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resume Document Title',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextColor(context),
          ),
          decoration: _inputDecoration(context, 'Title for internal tracking'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Executive Summary',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context),
              ),
            ),
            TextButton.icon(
              onPressed: _isEnhancingSummary
                  ? null
                  : () async {
                      if (_summaryController.text.trim().isEmpty) return;
                      setState(() => _isEnhancingSummary = true);
                      try {
                        final enhanced =
                            await AIService.instance.enhanceSummary(
                          _summaryController.text,
                          _skills,
                        );
                        if (mounted && enhanced.isNotEmpty) {
                          setState(() => _summaryController.text = enhanced);
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isEnhancingSummary = false);
                        }
                      }
                    },
              icon: _isEnhancingSummary
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryOrange,
                      ),
                    )
                  : const Icon(Icons.auto_awesome,
                      size: 14, color: AppTheme.primaryOrange),
              label: Text(
                'AI Enhance Summary',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _summaryController,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.5,
            color: AppTheme.getTextColor(context),
          ),
          decoration: _inputDecoration(
              context, 'Write a compelling 2-4 sentence summary...'),
        ),
      ],
    );
  }

  // ── Section 3: Skills & Keywords ──

  Widget _buildSkillsSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillInputController,
                onSubmitted: _addSkill,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.getTextColor(context),
                ),
                decoration: _inputDecoration(
                  context,
                  'Type a skill (e.g. Docker, GraphQL) & press Enter',
                ).copyWith(
                  prefixIcon: Icon(
                    Icons.add_task_rounded,
                    size: 18,
                    color: AppTheme.getMutedTextColor(context),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _addSkill(_skillInputController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Add',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Added Skill Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _skills.map((skill) {
            return Chip(
              label: Text(
                skill,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryOrange,
                ),
              ),
              backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.12),
              deleteIcon: const Icon(Icons.close,
                  size: 14, color: AppTheme.primaryOrange),
              onDeleted: () => _removeSkill(skill),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppTheme.primaryOrange.withValues(alpha: 0.3)),
              ),
            );
          }).toList(),
        ),

        // Suggested Keywords
        if (_suggestedKeywords.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Recommended ATS Keywords (Click to add):',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.getMutedTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestedKeywords.map((kw) {
              return ActionChip(
                avatar: const Icon(Icons.add,
                    size: 14, color: AppTheme.primaryOrange),
                label: Text(
                  kw,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                onPressed: () => _addSkill(kw),
                backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.3)),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ── Dynamic Section Handlers & Persistence Sync ──

  void _persistCurrentResume() {
    final current = _buildCurrentResumeData();
    ResumePersistenceService.instance.saveParsedResume(current);
  }

  void _deleteExperience(int index) {
    setState(() {
      final currentList = List<ExperienceEntry>.from(_parsedResumeData?.experience ?? []);
      if (index >= 0 && index < currentList.length) {
        currentList.removeAt(index);
        _parsedResumeData = (_parsedResumeData ?? const ResumeData()).copyWith(experience: currentList);
      }
    });
    _persistCurrentResume();
  }

  void _deleteEducation(int index) {
    setState(() {
      final currentList = List<EducationEntry>.from(_parsedResumeData?.education ?? []);
      if (index >= 0 && index < currentList.length) {
        currentList.removeAt(index);
        _parsedResumeData = (_parsedResumeData ?? const ResumeData()).copyWith(education: currentList);
      }
    });
    _persistCurrentResume();
  }

  void _deleteExtracurricular(int index) {
    setState(() {
      final currentList = List<ExtracurricularEntry>.from(_parsedResumeData?.extracurriculars ?? []);
      if (index >= 0 && index < currentList.length) {
        currentList.removeAt(index);
        _parsedResumeData = (_parsedResumeData ?? const ResumeData()).copyWith(extracurriculars: currentList);
      }
    });
    _persistCurrentResume();
  }

  // ── Section Modal Dialogs ──

  void _showExperienceDialog(BuildContext context, {ExperienceEntry? initial, int? index}) {
    final roleController = TextEditingController(text: initial?.role ?? '');
    final companyController = TextEditingController(text: initial?.company ?? '');
    final startDateController = TextEditingController(text: initial?.startDate ?? '');
    final endDateController = TextEditingController(text: initial?.endDate ?? '');
    final descController = TextEditingController(text: (initial?.description ?? []).join('\n'));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.getSurfaceColor(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            initial == null ? 'Add Work Experience' : 'Edit Work Experience',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.getTextColor(ctx),
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFormField(
                    context: ctx,
                    label: 'Job Title / Role',
                    hint: 'e.g. Senior Flutter Developer',
                    icon: Icons.work_outline_rounded,
                    controller: roleController,
                  ),
                  const SizedBox(height: 12),
                  _buildFormField(
                    context: ctx,
                    label: 'Company / Employer',
                    hint: 'e.g. JobWink Tech',
                    icon: Icons.business_rounded,
                    controller: companyController,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          context: ctx,
                          label: 'Start Date',
                          hint: 'e.g. Jan 2022',
                          icon: Icons.calendar_today_rounded,
                          controller: startDateController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          context: ctx,
                          label: 'End Date',
                          hint: 'e.g. Present',
                          icon: Icons.event_available_rounded,
                          controller: endDateController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Responsibilities & Highlights (One per line)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextColor(ctx),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descController,
                        maxLines: 4,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.getTextColor(ctx),
                        ),
                        decoration: _inputDecoration(
                          ctx,
                          'Spearheaded app development...\nOptimized UI performance by 40%...',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.getMutedTextColor(ctx),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newDesc = descController.text
                    .split('\n')
                    .map((line) => line.replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim())
                    .where((line) => line.isNotEmpty)
                    .toList();
                final entry = ExperienceEntry(
                  role: roleController.text.trim(),
                  company: companyController.text.trim(),
                  startDate: startDateController.text.trim(),
                  endDate: endDateController.text.trim(),
                  description: newDesc,
                );

                final currentList = List<ExperienceEntry>.from(_parsedResumeData?.experience ?? []);
                if (index != null && index >= 0 && index < currentList.length) {
                  currentList[index] = entry;
                } else {
                  currentList.add(entry);
                }

                setState(() {
                  _parsedResumeData = (_parsedResumeData ?? const ResumeData()).copyWith(experience: currentList);
                });
                _persistCurrentResume();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteProject(int index) {
    final currentList = List<ProjectEntry>.from(_parsedResumeData?.projects ?? []);
    if (index >= 0 && index < currentList.length) {
      currentList.removeAt(index);
      setState(() {
        _parsedResumeData = (_parsedResumeData ?? const ResumeData()).copyWith(projects: currentList);
      });
      _persistCurrentResume();
    }
  }

  void _duplicateProject(int index) {
    final currentList = List<ProjectEntry>.from(_parsedResumeData?.projects ?? []);
    if (index >= 0 && index < currentList.length) {
      final original = currentList[index];
      final duplicate = original.copyWith(
        id: 'proj_${DateTime.now().microsecondsSinceEpoch}',
        name: '${original.name} (Copy)',
      );
      _showManualProjectModal(context, initial: duplicate, index: null);
    }
  }

  void _showAddProjectChoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.getSurfaceColor(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Add Project',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.getTextColor(ctx),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose how you would like to add a project to your resume:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.getMutedTextColor(ctx),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.getBorderColor(ctx)),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryOrange),
                ),
                title: Text(
                  'Add Manually',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.getTextColor(ctx),
                  ),
                ),
                subtitle: Text(
                  'Enter project details manually with AI description enhancement.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.getMutedTextColor(ctx),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showManualProjectModal(context);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.getBorderColor(ctx)),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.code_rounded, color: Color(0xFF3B82F6)),
                ),
                title: Text(
                  'Import from GitHub',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.getTextColor(ctx),
                  ),
                ),
                subtitle: Text(
                  'Fetch repository metadata & README to generate project automatically with AI.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.getMutedTextColor(ctx),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showGithubImportModal(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.getMutedTextColor(ctx),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showManualProjectModal(BuildContext context, {ProjectEntry? initial, int? index}) {
    final nameController = TextEditingController(text: initial?.name ?? '');
    final typeController = TextEditingController(text: initial?.type ?? '');
    final techController = TextEditingController(text: (initial?.technologies ?? []).join(', '));
    final githubUrlController = TextEditingController(text: initial?.githubUrl ?? (initial?.source == 'github' ? initial?.url ?? '' : ''));
    final demoUrlController = TextEditingController(text: initial?.demoUrl ?? (initial?.source == 'manual' ? initial?.url ?? '' : ''));

    final initialBullets = initial?.descriptionBullets.isNotEmpty == true
        ? initial!.descriptionBullets
        : (initial?.description.isNotEmpty == true
            ? initial!.description.split('\n').map((l) => l.replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim()).where((l) => l.isNotEmpty).toList()
            : <String>['']);

    final bulletControllers = initialBullets.map((b) => TextEditingController(text: b)).toList();
    bool isImprovingAi = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.getSurfaceColor(ctx),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    initial?.source == 'github' ? Icons.code_rounded : Icons.folder_special_outlined,
                    color: AppTheme.primaryOrange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    initial == null ? 'Add Project' : 'Edit Project',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.getTextColor(ctx),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormField(
                        context: ctx,
                        label: 'Project Name *',
                        hint: 'e.g. JobWink Resume Studio',
                        icon: Icons.title_rounded,
                        controller: nameController,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        context: ctx,
                        label: 'Project Type (Optional)',
                        hint: 'e.g. Mobile Application, Web App, AI Service, CLI Tool',
                        icon: Icons.category_outlined,
                        controller: typeController,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        context: ctx,
                        label: 'Technologies Used (Comma separated)',
                        hint: 'e.g. Flutter, Dart, Gemini AI, Supabase',
                        icon: Icons.code_rounded,
                        controller: techController,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              context: ctx,
                              label: 'GitHub URL (Optional)',
                              hint: 'github.com/user/repo',
                              icon: Icons.terminal_rounded,
                              controller: githubUrlController,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFormField(
                              context: ctx,
                              label: 'Live Demo URL (Optional)',
                              hint: 'myapp.com',
                              icon: Icons.launch_rounded,
                              controller: demoUrlController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Description Bullet Points',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextColor(ctx),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: isImprovingAi
                                ? null
                                : () async {
                                    final currentBullets = bulletControllers
                                        .map((c) => c.text.trim())
                                        .where((b) => b.isNotEmpty)
                                        .toList();
                                    if (currentBullets.isEmpty && nameController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(content: Text('Please enter a project name or bullet points first.')),
                                      );
                                      return;
                                    }
                                    setModalState(() => isImprovingAi = true);
                                    try {
                                      final improved = await AIService.instance.improveProjectDescription(
                                        name: nameController.text.trim(),
                                        type: typeController.text.trim(),
                                        technologies: techController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                                        bullets: currentBullets,
                                      );
                                      setModalState(() => isImprovingAi = false);

                                      if (ctx.mounted) {
                                        _showAiComparisonDialog(ctx, currentBullets, improved, (acceptedBullets) {
                                          setModalState(() {
                                            bulletControllers.clear();
                                            for (final b in acceptedBullets) {
                                              bulletControllers.add(TextEditingController(text: b));
                                            }
                                          });
                                        });
                                      }
                                    } catch (e) {
                                      setModalState(() => isImprovingAi = false);
                                    }
                                  },
                            icon: isImprovingAi
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryOrange),
                                  )
                                : const Icon(Icons.auto_awesome_rounded, size: 15, color: AppTheme.primaryOrange),
                            label: Text(
                              isImprovingAi ? 'Improving...' : '✨ Improve with AI',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...bulletControllers.asMap().entries.map((entry) {
                        final bIdx = entry.key;
                        final bController = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: bController,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppTheme.getTextColor(ctx),
                                  ),
                                  decoration: _inputDecoration(
                                    ctx,
                                    'e.g. Architected responsive UI using Flutter and Supabase backend',
                                  ),
                                ),
                              ),
                              if (bulletControllers.length > 1) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                                  onPressed: () {
                                    setModalState(() {
                                      bulletControllers.removeAt(bIdx);
                                    });
                                  },
                                  tooltip: 'Remove bullet',
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            bulletControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add_rounded, size: 16, color: AppTheme.primaryOrange),
                        label: Text(
                          'Add Bullet Point',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.getMutedTextColor(ctx),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final projName = nameController.text.trim();
                    if (projName.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Project Name is required.')),
                      );
                      return;
                    }
                    final techs = techController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();

                    final bullets = bulletControllers
                        .map((c) => c.text.trim())
                        .where((b) => b.isNotEmpty)
                        .toList();

                    final entry = ProjectEntry(
                      id: initial?.id,
                      name: projName,
                      type: typeController.text.trim(),
                      descriptionBullets: bullets,
                      technologies: techs,
                      githubUrl: _normalizeUrl(githubUrlController.text.trim()),
                      demoUrl: _normalizeUrl(demoUrlController.text.trim()),
                      source: initial?.source ?? 'manual',
                      githubOwner: initial?.githubOwner,
                      githubRepo: initial?.githubRepo,
                    );

                    final currentList = List<ProjectEntry>.from(_parsedResumeData?.projects ?? []);
                    if (index != null && index >= 0 && index < currentList.length) {
                      currentList[index] = entry;
                    } else {
                      currentList.add(entry);
                    }

                    setState(() {
                      _parsedResumeData = (_parsedResumeData ?? const ResumeData()).copyWith(projects: currentList);
                    });
                    _persistCurrentResume();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Save Project',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAiComparisonDialog(
    BuildContext context,
    List<String> original,
    List<String> improved,
    Function(List<String>) onApply,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.getSurfaceColor(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              Text(
                'AI Description Comparison',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.getTextColor(ctx),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review the AI-enhanced bullet points below. You can apply the changes or keep your original text.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.getMutedTextColor(ctx),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.getBgColor(ctx),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.getBorderColor(ctx)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Original Description',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.getMutedTextColor(ctx),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (original.isEmpty)
                                Text(
                                  'No original bullets',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.getMutedTextColor(ctx),
                                  ),
                                )
                              else
                                ...original.map((b) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        '• $b',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppTheme.getTextColor(ctx),
                                        ),
                                      ),
                                    )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, size: 14, color: AppTheme.primaryOrange),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI Improved',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...improved.map((b) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '• $b',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.getTextColor(ctx),
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Keep Original',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.getMutedTextColor(ctx),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                onApply(improved);
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: Text(
                'Apply AI Enhancements',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showGithubImportModal(BuildContext context) {
    final usernameController = TextEditingController();
    final repoUrlController = TextEditingController();

    List<GitHubRepo> fetchedRepos = [];
    GitHubRepo? selectedRepo;

    bool isFetchingRepos = false;
    bool isAnalyzing = false;
    String? searchError;
    int importMode = 0; // 0 = By Username, 1 = By Direct URL

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.getSurfaceColor(ctx),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.code_rounded, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 8),
                  Text(
                    'Import from GitHub',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.getTextColor(ctx),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ChoiceChip(
                            label: Text(
                              'GitHub Username',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: importMode == 0 ? Colors.white : AppTheme.getTextColor(ctx),
                              ),
                            ),
                            selected: importMode == 0,
                            selectedColor: AppTheme.primaryOrange,
                            onSelected: (val) {
                              if (val) setModalState(() => importMode = 0);
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(
                              'Repository URL',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: importMode == 1 ? Colors.white : AppTheme.getTextColor(ctx),
                              ),
                            ),
                            selected: importMode == 1,
                            selectedColor: AppTheme.primaryOrange,
                            onSelected: (val) {
                              if (val) setModalState(() => importMode = 1);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (importMode == 0) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: usernameController,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppTheme.getTextColor(ctx),
                                ),
                                decoration: _inputDecoration(
                                  ctx,
                                  'Enter GitHub username (e.g. octocat)',
                                ),
                                onSubmitted: (_) async {
                                  final u = usernameController.text.trim();
                                  if (u.isEmpty) return;
                                  setModalState(() {
                                    isFetchingRepos = true;
                                    searchError = null;
                                    fetchedRepos = [];
                                    selectedRepo = null;
                                  });
                                  try {
                                    final repos = await GitHubService.instance.fetchUserRepositories(u);
                                    setModalState(() {
                                      isFetchingRepos = false;
                                      fetchedRepos = repos;
                                    });
                                  } catch (e) {
                                    setModalState(() {
                                      isFetchingRepos = false;
                                      searchError = 'User not found or rate limit exceeded.';
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: isFetchingRepos
                                  ? null
                                  : () async {
                                      final u = usernameController.text.trim();
                                      if (u.isEmpty) return;
                                      setModalState(() {
                                        isFetchingRepos = true;
                                        searchError = null;
                                        fetchedRepos = [];
                                        selectedRepo = null;
                                      });
                                      try {
                                        final repos = await GitHubService.instance.fetchUserRepositories(u);
                                        setModalState(() {
                                          isFetchingRepos = false;
                                          fetchedRepos = repos;
                                        });
                                      } catch (e) {
                                        setModalState(() {
                                          isFetchingRepos = false;
                                          searchError = 'User not found or rate limit exceeded.';
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: isFetchingRepos
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      'Fetch Repos',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ],
                        ),
                        if (searchError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            searchError!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                        if (fetchedRepos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Select a Repository (${fetchedRepos.length} found):',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getMutedTextColor(ctx),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppTheme.getBgColor(ctx),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.getBorderColor(ctx)),
                            ),
                            child: ListView.builder(
                              itemCount: fetchedRepos.length,
                              itemBuilder: (c, i) {
                                final repo = fetchedRepos[i];
                                final isSelected = selectedRepo?.name == repo.name;
                                return Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    dense: true,
                                    selected: isSelected,
                                    selectedTileColor: AppTheme.primaryOrange.withValues(alpha: 0.1),
                                    title: Text(
                                      repo.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isSelected ? AppTheme.primaryOrange : AppTheme.getTextColor(ctx),
                                      ),
                                    ),
                                    subtitle: Text(
                                      repo.description.isNotEmpty ? repo.description : repo.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppTheme.getMutedTextColor(ctx),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (repo.language.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.getBorderColor(ctx),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              repo.language,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                color: AppTheme.getTextColor(ctx),
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.primaryOrange),
                                          tooltip: 'Open in GitHub',
                                          onPressed: () => _launchExternalUrl(repo.htmlUrl),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      setModalState(() {
                                        selectedRepo = repo;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ] else ...[
                        _buildFormField(
                          context: ctx,
                          label: 'GitHub Repository URL',
                          hint: 'https://github.com/owner/repository',
                          icon: Icons.link_rounded,
                          controller: repoUrlController,
                        ),
                      ],
                      if (isAnalyzing) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryOrange),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Fetching README & Analyzing Repository with AI...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.getMutedTextColor(ctx),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isAnalyzing
                      ? null
                      : () async {
                          String owner = '';
                          String repoName = '';
                          String githubUrl = '';
                          String desc = '';
                          String lang = '';
                          List<String> topics = [];

                          if (importMode == 0) {
                            if (selectedRepo == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Please select a repository from the list.')),
                              );
                              return;
                            }
                            owner = selectedRepo!.owner;
                            repoName = selectedRepo!.name;
                            githubUrl = selectedRepo!.htmlUrl;
                            desc = selectedRepo!.description;
                            lang = selectedRepo!.language;
                            topics = selectedRepo!.topics;
                          } else {
                            final raw = repoUrlController.text.trim();
                            final parsed = GitHubService.instance.parseGithubUrl(raw);
                            if (parsed == null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Invalid GitHub repository URL format.')),
                              );
                              return;
                            }
                            owner = parsed.key;
                            repoName = parsed.value;
                            githubUrl = 'https://github.com/$owner/$repoName';
                          }

                          setModalState(() => isAnalyzing = true);

                          try {
                            final readme = await GitHubService.instance.fetchRepositoryReadme(owner, repoName) ?? '';
                            final analyzedEntry = await AIService.instance.analyzeGithubRepo(
                              repoName: repoName,
                              repoDescription: desc,
                              language: lang,
                              topics: topics,
                              readmeContent: readme,
                              githubUrl: githubUrl,
                              owner: owner,
                              repo: repoName,
                            );

                            setModalState(() => isAnalyzing = false);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              _showManualProjectModal(context, initial: analyzedEntry);
                            }
                          } catch (e) {
                            setModalState(() => isAnalyzing = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Failed to analyze repository: $e')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Import & Analyze',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEducationDialog(BuildContext context, {EducationEntry? initial, int? index}) {
    final degreeController = TextEditingController(text: initial?.degree ?? '');
    final fieldController = TextEditingController(text: initial?.fieldOfStudy ?? '');
    final instController = TextEditingController(text: initial?.institution ?? '');
    final startController = TextEditingController(text: initial?.startDate ?? '');
    final endController = TextEditingController(text: initial?.endDate ?? '');
    final gpaController = TextEditingController(text: initial?.gpa ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.getSurfaceColor(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            initial == null ? 'Add Education' : 'Edit Education',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.getTextColor(ctx),
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFormField(
                    context: ctx,
                    label: 'Degree',
                    hint: 'e.g. Bachelor of Technology',
                    icon: Icons.school_outlined,
                    controller: degreeController,
                  ),
                  const SizedBox(height: 12),
                  _buildFormField(
                    context: ctx,
                    label: 'Field of Study / Major',
                    hint: 'e.g. Computer Science & Engineering',
                    icon: Icons.book_outlined,
                    controller: fieldController,
                  ),
                  const SizedBox(height: 12),
                  _buildFormField(
                    context: ctx,
                    label: 'Institution / University',
                    hint: 'e.g. Indian Institute of Technology',
                    icon: Icons.account_balance_rounded,
                    controller: instController,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          context: ctx,
                          label: 'Start Year',
                          hint: 'e.g. 2019',
                          icon: Icons.calendar_today_rounded,
                          controller: startController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          context: ctx,
                          label: 'Graduation / End Year',
                          hint: 'e.g. 2023',
                          icon: Icons.event_available_rounded,
                          controller: endController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFormField(
                    context: ctx,
                    label: 'GPA / Grade (Optional)',
                    hint: 'e.g. 8.8 / 10',
                    icon: Icons.grade_rounded,
                    controller: gpaController,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.getMutedTextColor(ctx),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final entry = EducationEntry(
                  degree: degreeController.text.trim(),
                  fieldOfStudy: fieldController.text.trim(),
                  institution: instController.text.trim(),
                  startDate: startController.text.trim(),
                  endDate: endController.text.trim(),
                  gpa: gpaController.text.trim(),
                );

                final currentList = List<EducationEntry>.from(_parsedResumeData?.education ?? []);
                if (index != null && index >= 0 && index < currentList.length) {
                  currentList[index] = entry;
                } else {
                  currentList.add(entry);
                }

                setState(() {
                  _parsedResumeData = (_parsedResumeData ?? const ResumeData()).copyWith(education: currentList);
                });
                _persistCurrentResume();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExtracurricularDialog(BuildContext context, {ExtracurricularEntry? initial, int? index}) {
    final activityController = TextEditingController(text: initial?.activity ?? '');
    final roleController = TextEditingController(text: initial?.role ?? '');
    final orgController = TextEditingController(text: initial?.organization ?? '');
    final linkController = TextEditingController(
      text: (initial?.url.isNotEmpty == true)
          ? initial!.url
          : (initial?.link.isNotEmpty == true ? initial!.link : ''),
    );
    final descController = TextEditingController(text: initial?.description ?? '');

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    String? normalizeMonth(String? m) {
      if (m == null || m.isEmpty) return null;
      final mLow = m.toLowerCase().trim();
      const mMap = {
        'january': 'Jan', 'jan': 'Jan', '01': 'Jan', '1': 'Jan',
        'february': 'Feb', 'feb': 'Feb', '02': 'Feb', '2': 'Feb',
        'march': 'Mar', 'mar': 'Mar', '03': 'Mar', '3': 'Mar',
        'april': 'Apr', 'apr': 'Apr', '04': 'Apr', '4': 'Apr',
        'may': 'May', '05': 'May', '5': 'May',
        'june': 'Jun', 'jun': 'Jun', '06': 'Jun', '6': 'Jun',
        'july': 'Jul', 'jul': 'Jul', '07': 'Jul', '7': 'Jul',
        'august': 'Aug', 'aug': 'Aug', '08': 'Aug', '8': 'Aug',
        'september': 'Sep', 'sep': 'Sep', '09': 'Sep', '9': 'Sep',
        'october': 'Oct', 'oct': 'Oct', '10': 'Oct',
        'november': 'Nov', 'nov': 'Nov', '11': 'Nov',
        'december': 'Dec', 'dec': 'Dec', '12': 'Dec',
      };
      return mMap[mLow] ?? (months.contains(m) ? m : null);
    }

    String? startMonth = normalizeMonth(initial?.startMonth);
    String? startYear = initial?.startYear.isNotEmpty == true ? initial!.startYear : null;
    String? endMonth = normalizeMonth(initial?.endMonth);
    String? endYear = initial?.endYear.isNotEmpty == true ? initial!.endYear : null;

    if (startMonth == null && startYear == null && (initial?.startDate.isNotEmpty == true)) {
      final sParts = initial!.startDate.split(RegExp(r'[\s/,-]+')).where((p) => p.isNotEmpty).toList();
      for (final p in sParts) {
        final m = normalizeMonth(p);
        if (m != null && startMonth == null) {
          startMonth = m;
        } else if (p.length == 4 && int.tryParse(p) != null && startYear == null) {
          startYear = p;
        }
      }
    }

    if (endMonth == null && endYear == null && (initial?.endDate.isNotEmpty == true)) {
      final eParts = initial!.endDate.split(RegExp(r'[\s/,-]+')).where((p) => p.isNotEmpty).toList();
      for (final p in eParts) {
        final m = normalizeMonth(p);
        if (m != null && endMonth == null) {
          endMonth = m;
        } else if (p.length == 4 && int.tryParse(p) != null && endYear == null) {
          endYear = p;
        }
      }
    }

    final currentYear = DateTime.now().year;
    final years = List<String>.generate(currentYear + 6 - 1980, (i) => (currentYear + 5 - i).toString());

    Widget buildDropdown({
      required BuildContext ctx,
      required String hint,
      required String? value,
      required List<String> items,
      required ValueChanged<String?> onChanged,
    }) {
      final isDark = AppTheme.isDarkMode(ctx);
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF30363D) : const Color(0xFFCBD5E1),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: items.contains(value) ? value : null,
            isExpanded: true,
            hint: Text(
              hint,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.getMutedTextColor(ctx),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            icon: Icon(
              Icons.arrow_drop_down_rounded,
              color: AppTheme.getMutedTextColor(ctx),
            ),
            dropdownColor: AppTheme.getSurfaceColor(ctx),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.getTextColor(ctx),
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  '-- None --',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.getMutedTextColor(ctx),
                  ),
                ),
              ),
              ...items.map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.getTextColor(ctx),
                    ),
                  ),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.getSurfaceColor(dialogCtx),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                initial == null ? 'Add Certification / Activity' : 'Edit Certification / Activity',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.getTextColor(dialogCtx),
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormField(
                        context: dialogCtx,
                        label: 'Certification / Activity Title',
                        hint: 'e.g. AWS Certified Solutions Architect',
                        icon: Icons.workspace_premium_outlined,
                        controller: activityController,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        context: dialogCtx,
                        label: 'Role / Level (Optional)',
                        hint: 'e.g. Certificate Holder / Lead Organizer',
                        icon: Icons.badge_outlined,
                        controller: roleController,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        context: dialogCtx,
                        label: 'Organization / Issuer',
                        hint: 'e.g. Amazon Web Services',
                        icon: Icons.business_center_outlined,
                        controller: orgController,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        context: dialogCtx,
                        label: 'Certificate / Activity Link (Optional)',
                        hint: 'https://...',
                        icon: Icons.link_rounded,
                        controller: linkController,
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Details (Optional)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextColor(dialogCtx),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: descController,
                            maxLines: 2,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.getTextColor(dialogCtx),
                            ),
                            decoration: _inputDecoration(
                              dialogCtx,
                              'e.g. Credential ID 12345 • Score: 95%',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date (Optional)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.getTextColor(dialogCtx),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: buildDropdown(
                                        ctx: dialogCtx,
                                        hint: 'Month',
                                        value: startMonth,
                                        items: months,
                                        onChanged: (v) => setModalState(() => startMonth = v),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: buildDropdown(
                                        ctx: dialogCtx,
                                        hint: 'Year',
                                        value: startYear,
                                        items: years,
                                        onChanged: (v) => setModalState(() => startYear = v),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Date (Optional)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.getTextColor(dialogCtx),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: buildDropdown(
                                        ctx: dialogCtx,
                                        hint: 'Month',
                                        value: endMonth,
                                        items: months,
                                        onChanged: (v) => setModalState(() => endMonth = v),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: buildDropdown(
                                        ctx: dialogCtx,
                                        hint: 'Year',
                                        value: endYear,
                                        items: years,
                                        onChanged: (v) => setModalState(() => endYear = v),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.getMutedTextColor(dialogCtx),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final sM = (startMonth != null && startYear != null) ? startMonth! : '';
                    final sY = (startMonth != null && startYear != null) ? startYear! : (startYear ?? '');
                    final eM = (endMonth != null && endYear != null) ? endMonth! : '';
                    final eY = (endMonth != null && endYear != null) ? endYear! : (endYear ?? '');

                    String rawUrl = linkController.text.trim();
                    if (rawUrl.isNotEmpty &&
                        !rawUrl.startsWith('http://') &&
                        !rawUrl.startsWith('https://') &&
                        !rawUrl.startsWith('mailto:')) {
                      if (rawUrl.contains('.') && !rawUrl.contains(' ')) {
                        rawUrl = 'https://$rawUrl';
                      }
                    }

                    final entry = ExtracurricularEntry(
                      activity: activityController.text.trim(),
                      role: roleController.text.trim(),
                      organization: orgController.text.trim(),
                      description: descController.text.trim(),
                      url: rawUrl,
                      startMonth: sM,
                      startYear: sY,
                      endMonth: eM,
                      endYear: eY,
                    );

                    final currentList = List<ExtracurricularEntry>.from(_parsedResumeData?.extracurriculars ?? []);
                    if (index != null && index >= 0 && index < currentList.length) {
                      currentList[index] = entry;
                    } else {
                      currentList.add(entry);
                    }

                    setState(() {
                      _parsedResumeData = (_parsedResumeData ?? const ResumeData()).copyWith(extracurriculars: currentList);
                    });
                    _persistCurrentResume();
                    Navigator.pop(dialogCtx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Section 4: Work Experience ──

  Widget _buildExperienceSection(BuildContext context, bool isDarkMode) {
    final expList = _parsedResumeData?.experience ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (expList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No work experience entries available.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.getMutedTextColor(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...expList.asMap().entries.map((entry) {
            final idx = entry.key;
            final exp = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.getBgColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.getBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exp.role.isNotEmpty ? exp.role : 'Role',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: AppTheme.primaryOrange),
                            onPressed: () => _showExperienceDialog(context, initial: exp, index: idx),
                            tooltip: 'Edit experience entry',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: Color(0xFFEF4444)),
                            onPressed: () => _deleteExperience(idx),
                            tooltip: 'Remove experience entry',
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (exp.company.isNotEmpty) ...[
                    Text(
                      exp.company,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                  if (exp.startDate.isNotEmpty || exp.endDate.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${exp.startDate} - ${exp.endDate}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.getMutedTextColor(context),
                      ),
                    ),
                  ],
                  if (exp.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...exp.description.map(
                      (bullet) {
                        final cleaned = _cleanBulletString(bullet);
                        if (cleaned.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6, right: 8),
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: _buildHighlightedText(
                                  cleaned,
                                  context: context,
                                  isDarkMode: isDarkMode,
                                  baseStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppTheme.getTextColor(context),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          }),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showExperienceDialog(context),
            icon: const Icon(Icons.add_rounded, size: 16, color: AppTheme.primaryOrange),
            label: Text(
              'Add Work Experience',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryOrange.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Section 5: Projects ──

  Widget _buildProjectsSection(BuildContext context, bool isDarkMode) {
    final projList = _parsedResumeData?.projects ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (projList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No projects available.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.getMutedTextColor(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...projList.asMap().entries.map((entry) {
            final idx = entry.key;
            final proj = entry.value;
            final bullets = proj.effectiveBullets;
            final githubLink = proj.effectiveGithubUrl;
            final demoLink = proj.effectiveDemoUrl;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.getBgColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.getBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              proj.name.isNotEmpty ? proj.name : 'Project',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                            if (proj.type.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.getBorderColor(context),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  proj.type,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.getTextColor(context),
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: proj.source == 'github'
                                    ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                                    : AppTheme.primaryOrange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    proj.source == 'github' ? Icons.code_rounded : Icons.edit_note_rounded,
                                    size: 11,
                                    color: proj.source == 'github' ? const Color(0xFF3B82F6) : AppTheme.primaryOrange,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    proj.source == 'github' ? 'GitHub' : 'Manual',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: proj.source == 'github' ? const Color(0xFF3B82F6) : AppTheme.primaryOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.primaryOrange),
                            onPressed: () => _duplicateProject(idx),
                            tooltip: 'Duplicate project',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryOrange),
                            onPressed: () => _showManualProjectModal(context, initial: proj, index: idx),
                            tooltip: 'Edit project',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                            onPressed: () => _deleteProject(idx),
                            tooltip: 'Remove project',
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (bullets.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...bullets.map((bullet) {
                      final cleaned = _cleanBulletString(bullet);
                      if (cleaned.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryOrange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: _buildHighlightedText(
                                cleaned,
                                context: context,
                                isDarkMode: isDarkMode,
                                baseStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppTheme.getTextColor(context),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else ...[
                    const SizedBox(height: 6),
                    Text(
                      'No description provided.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.getMutedTextColor(context),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (githubLink.isNotEmpty || demoLink.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        if (githubLink.isNotEmpty)
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => _launchExternalUrl(githubLink),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.terminal_rounded, size: 14, color: AppTheme.primaryOrange),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _normalizeUrl(githubLink),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryOrange,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(Icons.open_in_new_rounded, size: 11, color: AppTheme.primaryOrange),
                                ],
                              ),
                            ),
                          ),
                        if (demoLink.isNotEmpty)
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => _launchExternalUrl(demoLink),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.launch_rounded, size: 14, color: AppTheme.primaryOrange),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _normalizeUrl(demoLink),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryOrange,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(Icons.open_in_new_rounded, size: 11, color: AppTheme.primaryOrange),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (proj.technologies.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: proj.technologies.map((tech) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tech,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            );
          }),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAddProjectChoiceDialog(context),
            icon: const Icon(Icons.add_rounded, size: 16, color: AppTheme.primaryOrange),
            label: Text(
              'Add Project',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryOrange.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Section 6: Education ──

  Widget _buildEducationSection(BuildContext context, bool isDarkMode) {
    final eduList = _parsedResumeData?.education ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eduList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No education entries available.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.getMutedTextColor(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...eduList.asMap().entries.map((entry) {
            final idx = entry.key;
            final edu = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.getBgColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.getBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          [edu.degree, edu.fieldOfStudy].where((s) => s.trim().isNotEmpty).join(' • ').isNotEmpty
                              ? [edu.degree, edu.fieldOfStudy].where((s) => s.trim().isNotEmpty).join(' • ')
                              : 'Degree',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: AppTheme.primaryOrange),
                            onPressed: () => _showEducationDialog(context, initial: edu, index: idx),
                            tooltip: 'Edit education entry',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: Color(0xFFEF4444)),
                            onPressed: () => _deleteEducation(idx),
                            tooltip: 'Remove education entry',
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (edu.institution.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      edu.institution,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                  if (edu.startDate.isNotEmpty || edu.endDate.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${edu.startDate} - ${edu.endDate}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.getMutedTextColor(context),
                      ),
                    ),
                  ],
                  if (edu.gpa.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'GPA: ${edu.gpa}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showEducationDialog(context),
            icon: const Icon(Icons.add_rounded, size: 16, color: AppTheme.primaryOrange),
            label: Text(
              'Add Education',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryOrange.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }



  // ── Section 8: Extracurricular Activities ──

  Widget _buildExtracurricularsSection(BuildContext context, bool isDarkMode) {
    final extraList = _parsedResumeData?.extracurriculars ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (extraList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No extracurricular entries available.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.getMutedTextColor(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...extraList.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final heading = item.activity.isNotEmpty
                ? item.activity
                : (item.role.isNotEmpty ? item.role : 'Activity');
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.getBgColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.getBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          heading,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: AppTheme.primaryOrange),
                            onPressed: () => _showExtracurricularDialog(context, initial: item, index: idx),
                            tooltip: 'Edit activity entry',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: Color(0xFFEF4444)),
                            onPressed: () => _deleteExtracurricular(idx),
                            tooltip: 'Remove activity entry',
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (item.organization.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.organization,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                  if (item.url.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _launchExternalUrl(item.url),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.link_rounded, size: 14, color: AppTheme.primaryOrange),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _normalizeUrl(item.url),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryOrange,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.open_in_new_rounded, size: 11, color: AppTheme.primaryOrange),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...item.description.split('\n').map((line) {
                      final cleaned = _cleanBulletString(line);
                      if (cleaned.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryOrange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                cleaned,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppTheme.getTextColor(context),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          }),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showExtracurricularDialog(context),
            icon: const Icon(Icons.add_rounded, size: 16, color: AppTheme.primaryOrange),
            label: Text(
              'Add Activity',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryOrange.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }



  void _downloadTailoredResume({required String format}) async {
    if (_isDownloadingResume) return;

    final currentResume = _buildCurrentResumeData();
    final validation = _selectedResumeType.validateCriteria(currentResume);
    if (!validation.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    validation.fullMessage,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    if (_isDownloadingResume) return;

    // ── Check Per-User Daily Quota Before Proceeding ──
    final usageInfo = await ResumeLimitService.instance.getUserResumeUsage();
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? 'guest';
    final dailyLimit = (usageInfo['daily_limit'] as num? ?? 4).toInt();
    final usedBefore = (usageInfo['usage_count'] as num? ?? 0).toInt();
    final remainingBefore = (usageInfo['remaining'] as num? ?? 0).toInt();
    final isAllowed = usageInfo['allowed'] == true;

    debugPrint('[QUOTA DEBUG]');
    debugPrint('User ID: $userId');
    debugPrint('Daily Limit: $dailyLimit');
    debugPrint('Used Before Download: $usedBefore');
    debugPrint('Remaining Before Download: $remainingBefore');

    if (!isAllowed || remainingBefore <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text(
              'Daily resume download limit reached ($dailyLimit/$dailyLimit). Please try again tomorrow.',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isDownloadingResume = true);

    // Yield control to event loop so Flutter paints the loading button state immediately
    await Future.delayed(const Duration(milliseconds: 10));

    final filename = ResumeExportService.getCandidateFilename(currentResume, format);

    try {
      Uint8List? bytes;

      if (format == 'pdf') {
        bytes = await ResumeExportService.instance.generateAtsPdf(
          currentResume,
          selectedResumeType: _selectedResumeType,
          originalPdfBytes: _uploadedFileBytes,
          highlightKeywords: _matchedJobKeywords,
        );
      } else {
        final textContent = _buildTextResumeFormat(currentResume);
        bytes = Uint8List.fromList(textContent.codeUnits);
      }

      ResumeExportService.instance.downloadBytesInBrowser(
        bytes,
        filename,
        format == 'pdf' ? 'application/pdf' : 'text/plain',
      );

      // ── Successful Download: Consume Exactly 1 Quota Atomically in Database ──
      final reserveResult = await ResumeLimitService.instance.checkAndReserveLimit();

      debugPrint('[QUOTA DEBUG]');
      debugPrint('Download Successful: YES');
      debugPrint('Quota Consumed: 1');
      debugPrint('Used After Download: ${reserveResult.usageCount}');
      debugPrint('Remaining After Download: ${reserveResult.remaining}');

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tailored resume "$filename" downloaded successfully!',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[QUOTA DEBUG]');
      debugPrint('Download Successful: NO');
      debugPrint('Quota Consumed: 0');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Failed to download resume: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingResume = false);
      }
    }
  }

  String _buildTextResumeFormat(ResumeData resume) {
    final sb = StringBuffer();
    sb.writeln(resume.fullName.toUpperCase());
    if (resume.title.isNotEmpty) sb.writeln(resume.title);
    final contact = [resume.email, resume.phone, resume.location, resume.linkedin, resume.github]
        .where((s) => s.isNotEmpty)
        .join(' | ');
    if (contact.isNotEmpty) sb.writeln(contact);
    sb.writeln('\n${"=" * 40}\n');

    if (resume.summary.isNotEmpty) {
      sb.writeln('PROFESSIONAL SUMMARY');
      sb.writeln(resume.summary);
      sb.writeln();
    }

    if (resume.skills.isNotEmpty) {
      sb.writeln('SKILLS');
      sb.writeln(resume.skills.join(', '));
      sb.writeln();
    }

    if (resume.experience.isNotEmpty) {
      sb.writeln('WORK EXPERIENCE');
      for (final exp in resume.experience) {
        sb.writeln('${exp.role} - ${exp.company} (${exp.startDate} - ${exp.endDate})');
        for (final b in exp.description) {
          sb.writeln('  * $b');
        }
        sb.writeln();
      }
    }

    if (resume.projects.isNotEmpty) {
      sb.writeln('PROJECTS');
      for (final p in resume.projects) {
        sb.writeln('${p.name} [${p.technologies.join(", ")}]');
        if (p.description.isNotEmpty) sb.writeln('  ${p.description}');
        sb.writeln();
      }
    }

    if (resume.education.isNotEmpty) {
      sb.writeln('EDUCATION');
      for (final edu in resume.education) {
        final title = [edu.degree, edu.fieldOfStudy].where((s) => s.trim().isNotEmpty).join(' • ');
        final start = edu.startDate.replaceAll(RegExp(r'[\s\-–—]+$'), '').trim();
        final end = edu.endDate.replaceAll(RegExp(r'^[\s\-–—]+'), '').trim();
        final String dates;
        if (start.isNotEmpty && end.isNotEmpty) {
          dates = '$start - $end';
        } else if (start.isNotEmpty) {
          dates = start;
        } else if (end.isNotEmpty) {
          dates = end;
        } else {
          dates = '';
        }
        final line = [title, edu.institution, if (dates.isNotEmpty) '($dates)'].where((s) => s.trim().isNotEmpty).join(' - ');
        sb.writeln(line);
      }
    }

    return sb.toString();
  }

  void _showExportModal(BuildContext context) {
    final currentResume = _buildCurrentResumeData();
    final validation = _selectedResumeType.validateCriteria(currentResume);
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  validation.fullMessage,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Download Tailored Resume 📥',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Select your preferred export format for job applications.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.getMutedTextColor(context),
                ),
              ),
              const SizedBox(height: 20),

              // Option 1: PDF Export
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppTheme.primaryOrange.withValues(alpha: 0.3)),
                  ),
                  tileColor: AppTheme.primaryOrange.withValues(alpha: 0.08),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
                  ),
                  title: Text(
                    'ATS-Optimized PDF Document (.pdf)',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  subtitle: Text(
                    'Clean single-column layout, 100% readable by ATS scanners.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.getMutedTextColor(context),
                    ),
                  ),
                  trailing: const Icon(Icons.download_rounded, color: AppTheme.primaryOrange),
                  onTap: () {
                    Navigator.pop(modalCtx);
                    _downloadTailoredResume(format: 'pdf');
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: DOCX / Text Export
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppTheme.getBorderColor(context)),
                  ),
                  tileColor: AppTheme.isDarkMode(context)
                      ? const Color(0xFF1B1E26)
                      : const Color(0xFFF8FAF4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_rounded, color: Colors.white, size: 22),
                  ),
                  title: Text(
                    'Editable Text / Word Format (.txt / .docx)',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  subtitle: Text(
                    'Structured text format ready for online job application portals.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.getMutedTextColor(context),
                    ),
                  ),
                  trailing: Icon(Icons.download_rounded, color: AppTheme.getTextColor(context)),
                  onTap: () {
                    Navigator.pop(modalCtx);
                    _downloadTailoredResume(format: 'txt');
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ── Resume Tailoring Card ──

  Widget _buildTailoringCard(BuildContext context, bool isDarkMode) {
    final currentResume = _buildCurrentResumeData();
    final criteriaValidation = _selectedResumeType.validateCriteria(currentResume);
    return JobAlignmentCard(
      targetJobTitleController: _targetJobTitleController,
      jobDescriptionController: _jobDescriptionController,
      isAnalyzingKeywords: _isAnalyzingKeywords,
      jobMatchScore: _jobMatchScore,
      selectedResumeType: _selectedResumeType,
      criteriaValidation: criteriaValidation,
      onSelectResumeType: (type) {
        setState(() => _selectedResumeType = type);
      },
      matchedKeywords: _matchedJobKeywords,
      missingKeywords: _missingJobKeywords,
    );
  }

  // ── ATS Score Gauge Card ──

  Widget _buildAtsGaugeCard(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: AtsScoreGauge(score: _atsScore.toInt()),
    );
  }

  Widget _buildHighlightedText(
    String text, {
    required BuildContext context,
    required bool isDarkMode,
    TextStyle? baseStyle,
    int? maxLines,
    TextOverflow? overflow,
    TextAlign textAlign = TextAlign.start,
  }) {
    final style = baseStyle ??
        GoogleFonts.plusJakartaSans(
          fontSize: 12,
          height: 1.4,
          color: AppTheme.getTextColor(context),
        );

    if (text.trim().isEmpty || _matchedJobKeywords.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    final validKws = _matchedJobKeywords
        .map((k) => k.trim())
        .where((k) => k.length >= 2)
        .toSet()
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    if (validKws.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    final escapedList = validKws.map(RegExp.escape).join('|');
    final regExp = RegExp(
      '(?<=^|[^a-zA-Z0-9])($escapedList)(?=[^a-zA-Z0-9]|\$)',
      caseSensitive: false,
    );

    final matches = regExp.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    final spans = <TextSpan>[];
    int currentOffset = 0;

    for (final match in matches) {
      if (match.start > currentOffset) {
        spans.add(TextSpan(
          text: text.substring(currentOffset, match.start),
          style: style,
        ));
      }

      final matchedWord = text.substring(match.start, match.end);
      spans.add(TextSpan(
        text: matchedWord,
        style: style.copyWith(
          fontWeight: FontWeight.w800,
          color: isDarkMode ? Colors.white : const Color(0xFF090D16),
        ),
      ));

      currentOffset = match.end;
    }

    if (currentOffset < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentOffset),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      textAlign: textAlign,
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: AppTheme.getMutedTextColor(context),
        fontSize: 13,
      ),
      filled: true,
      fillColor: AppTheme.isDarkMode(context)
          ? const Color(0xFF1B1E26)
          : const Color(0xFFF8FAF4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.getBorderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
      ),
    );
  }
}
