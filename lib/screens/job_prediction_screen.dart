import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/job_prediction_model.dart';
import '../services/job_prediction_service.dart';
import '../services/resume_persistence_service.dart';
import '../theme/app_theme.dart';
import '../widgets/demo_banner.dart';
import '../widgets/page_container.dart';

class JobPredictionScreen extends StatefulWidget {
  final String initialResumeId;

  const JobPredictionScreen({
    super.key,
    this.initialResumeId = 'res_master_001',
  });

  @override
  State<JobPredictionScreen> createState() => _JobPredictionScreenState();
}

class _JobPredictionScreenState extends State<JobPredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _activeResumeId;
  final TextEditingController _jobTitleController = TextEditingController(
    text: 'Senior Flutter & Backend Architect',
  );
  final TextEditingController _jobDescController = TextEditingController(
    text: '''We are seeking a Lead Mobile & Backend Engineer to build scalable cross-platform applications and microservices.
Key Requirements:
- 4+ years of professional experience with Flutter, Dart, Python, and FastAPI.
- Deep expertise in PostgreSQL, Supabase, state management, and REST APIs.
- Experience with Cloud deployment (AWS/Docker), CI/CD pipelines, and automated testing.
- Strong analytical skills, technical problem solving, and architecture design.''',
  );

  // Extracted Structured Feature Controllers (for user review and correction)
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _certsController = TextEditingController();
  final TextEditingController _eduController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _expYearsController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _projCountController = TextEditingController();

  bool _isLoadingFeatures = false;
  bool _isPredicting = false;
  bool _showFeaturesPanel = true;

  JobPredictionResult? _predictionResult;

  @override
  void initState() {
    super.initState();
    _activeResumeId = widget.initialResumeId;
    _loadDefaultFeatures();
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _jobDescController.dispose();
    _skillsController.dispose();
    _certsController.dispose();
    _eduController.dispose();
    _roleController.dispose();
    _expYearsController.dispose();
    _salaryController.dispose();
    _projCountController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultFeatures() async {
    setState(() => _isLoadingFeatures = true);
    try {
      final savedResume = await ResumePersistenceService.instance.loadLatestParsedResume();
      if (savedResume != null && savedResume.hasUsableData) {
        final skillsStr = savedResume.skills.isNotEmpty
            ? savedResume.skills.join(', ')
            : 'Flutter, Dart, Python, FastAPI, PostgreSQL';
        final certsStr = savedResume.skills.where((k) => k.toLowerCase().contains('cert') || k.toLowerCase().contains('aws')).join(', ');

        String eduStr = 'B.Tech Computer Science';
        if (savedResume.education.isNotEmpty) {
          final topEdu = savedResume.education.first;
          eduStr = '${topEdu.degree} ${topEdu.fieldOfStudy}'.trim();
          if (eduStr.isEmpty) eduStr = topEdu.institution;
        }

        String roleStr = savedResume.title.isNotEmpty ? savedResume.title : 'Software Engineer';
        if (savedResume.experience.isNotEmpty && savedResume.experience.first.role.isNotEmpty) {
          roleStr = savedResume.experience.first.role;
        }

        final expYears = max(savedResume.experience.length * 1.5, 1.0);

        _skillsController.text = skillsStr;
        _certsController.text = certsStr.isNotEmpty ? certsStr : 'AWS Certified Developer';
        _eduController.text = eduStr.isNotEmpty ? eduStr : 'B.Tech Computer Science';
        _roleController.text = roleStr;
        _expYearsController.text = expYears.toStringAsFixed(1);
        _salaryController.text = '135000';
        _projCountController.text = savedResume.projects.length.toString();
      } else {
        final res = await JobPredictionClientService.instance.fetchExtractedFeatures(_activeResumeId);
        final feats = Map<String, dynamic>.from(res['structured_features'] as Map? ?? {});

        _skillsController.text = feats['Skills']?.toString() ?? 'Flutter, Dart, Python, FastAPI, PostgreSQL';
        _certsController.text = feats['Certifications']?.toString() ?? 'AWS Certified Developer';
        _eduController.text = feats['Education']?.toString() ?? 'B.Tech Computer Science';
        _roleController.text = feats['Job Role']?.toString() ?? 'Senior Software Engineer';
        _expYearsController.text = feats['Experience (Years)']?.toString() ?? '4.0';
        _salaryController.text = feats['Salary Expectation (\$)']?.toString() ?? '135000';
        _projCountController.text = feats['Projects Count']?.toString() ?? '5';
      }
    } catch (e) {
      debugPrint('Error loading initial features: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFeatures = false);
    }
  }

  Future<void> _runPrediction() async {
    if (_jobDescController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a target Job Description first.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isPredicting = true);

    final overriddenFeatures = {
      'Skills': _skillsController.text.trim(),
      'Certifications': _certsController.text.trim(),
      'Education': _eduController.text.trim(),
      'Job Role': _roleController.text.trim(),
      'Experience (Years)': double.tryParse(_expYearsController.text.trim()) ?? 4.0,
      'Salary Expectation (\$)': double.tryParse(_salaryController.text.trim()) ?? 135000.0,
      'Projects Count': int.tryParse(_projCountController.text.trim()) ?? 5,
    };

    try {
      final result = await JobPredictionClientService.instance.predictJobMatch(
        resumeId: _activeResumeId,
        jobDescription: _jobDescController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        structuredFeaturesOverride: overriddenFeatures,
      );

      if (mounted) {
        setState(() {
          _predictionResult = result;
          _isPredicting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPredicting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prediction failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title Section
                _buildPageHeader(context, isDesktop),
                const SizedBox(height: 24),

                // Active Resume & Staleness Notice Banner
                _buildResumeStatusBanner(context, isDarkMode),
                const SizedBox(height: 24),

                // Main Workspace Grid (Left: Job & Features Form, Right: Match Result Gauge)
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _buildInputFormSection(context, isDarkMode),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 5,
                            child: _buildResultSection(context, isDarkMode),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildInputFormSection(context, isDarkMode),
                          const SizedBox(height: 24),
                          _buildResultSection(context, isDarkMode),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader(BuildContext context, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.analytics_rounded, size: 16, color: AppTheme.primaryOrange),
                  const SizedBox(width: 6),
                  Text(
                    'ML Model Bundle v1.0',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.isDarkMode(context) ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Structured (65%) + Fit (35%)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getMutedTextColor(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Job Match Prediction Dashboard',
          style: AppTheme.getDisplayFont(
            fontSize: isDesktop ? 32 : 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Run statistical machine learning predictions combining your structured candidate features and tailored resume content against target job descriptions.',
          style: AppTheme.getBodyFont(
            fontSize: 15,
            color: AppTheme.getMutedTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildResumeStatusBanner(BuildContext context, bool isDarkMode) {
    final isStale = _predictionResult?.isStale ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isStale
            ? const Color(0xFFFEF3C7)
            : AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isStale ? const Color(0xFFF59E0B) : AppTheme.getBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isStale ? Icons.warning_amber_rounded : Icons.description_rounded,
            color: isStale ? const Color(0xFFD97706) : AppTheme.primaryOrange,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isStale
                      ? 'Resume Updated — Prediction Stale'
                      : 'Active Tailored Resume Version',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isStale
                        ? const Color(0xFF92400E)
                        : AppTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isStale
                      ? 'Your resume content was edited after this prediction was made. Re-run prediction to evaluate latest match score.'
                      : 'Active Candidate Profile • Synchronized with your latest resume features & ML model.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isStale
                        ? const Color(0xFFB45309)
                        : AppTheme.getMutedTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          if (isStale)
            ElevatedButton(
              onPressed: _runPrediction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              ),
              child: const Text('Re-evaluate Now'),
            ),
        ],
      ),
    );
  }

  Widget _buildInputFormSection(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Target Job Details',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jobTitleController,
              textAlign: TextAlign.start,
              decoration: InputDecoration(
                labelText: 'Job Title',
                hintText: 'e.g. Senior Backend Engineer',
                prefixIcon: const Icon(Icons.work_outline_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jobDescController,
              textAlign: TextAlign.start,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Job Description Text',
                hintText: 'Paste the target job description requirements here...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              ),
            ),
            const SizedBox(height: 24),

            // Features review expandable toggle - aligned cleanly
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '2. Extracted Features Review',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Protected demographic attributes (name, gender, age, race) are excluded.',
                      child: Icon(Icons.info_outline, size: 16, color: AppTheme.getMutedTextColor(context)),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showFeaturesPanel = !_showFeaturesPanel),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                  icon: Icon(_showFeaturesPanel ? Icons.expand_less : Icons.expand_more, size: 18),
                  label: Text(_showFeaturesPanel ? 'Hide Fields' : 'Review & Edit Features'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Review and manually correct the features extracted from your tailored resume prior to model evaluation.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.getMutedTextColor(context),
              ),
            ),
            const SizedBox(height: 14),

            if (_showFeaturesPanel) _buildFeaturesReviewPanel(context, isDarkMode),
            const SizedBox(height: 24),

            // Action submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isPredicting ? null : _runPrediction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                ),
                child: _isPredicting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Evaluating ML Pipelines...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Predict Match Probability',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesReviewPanel(BuildContext context, bool isDarkMode) {
    if (_isLoadingFeatures) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1F222B) : const Color(0xFFF8F5EE),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.getBorderColor(context)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 10),
            Text('Extracting features from resume...'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F222B) : const Color(0xFFF8F5EE),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField('Extracted Job Role', _roleController),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField('Experience (Years)', _expYearsController, isNumeric: true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Multi-line skills field to avoid clipping
          _buildTextField('Skills (Comma separated)', _skillsController, maxLines: 3),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField('Certifications', _certsController),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField('Education Degree', _eduController),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField('Salary Expectation (\$)', _salaryController, isNumeric: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField('Projects Count', _projCountController, isNumeric: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumeric = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.start,
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
      style: GoogleFonts.plusJakartaSans(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
        alignLabelWithHint: maxLines > 1,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      ),
    );
  }

  Widget _buildResultSection(BuildContext context, bool isDarkMode) {
    final result = _predictionResult;

    if (result == null) {
      return Container(
        height: 480,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.getBorderColor(context)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 48,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ready to Predict Job Match',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter target job details and click "Predict Match Probability" to run the scikit-learn model bundle.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.getMutedTextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final structPct = (result.structuredProbability * 100).toStringAsFixed(1);
    final fitPct = (result.fitProbability * 100).toStringAsFixed(1);

    Color matchColor;
    if (result.combinedProbability >= 0.70) {
      matchColor = const Color(0xFF10B981); // Green
    } else if (result.combinedProbability >= 0.50) {
      matchColor = const Color(0xFFF59E0B); // Amber
    } else {
      matchColor = const Color(0xFF64748B); // Slate
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ML Match Evaluation',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: matchColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(color: matchColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  result.estimatedMatchLevel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: matchColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Gauge Score Display with Smooth Tween Sweeping
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: result.combinedProbability),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                final animatedPct = (animatedValue * 100).toStringAsFixed(1);
                return Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: animatedValue,
                            strokeWidth: 14,
                            backgroundColor: isDarkMode ? Colors.white10 : Colors.black12,
                            valueColor: AlwaysStoppedAnimation<Color>(matchColor),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$animatedPct%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.getTextColor(context),
                              ),
                            ),
                            Text(
                              'Combined Match',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getMutedTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Sub-Probabilities breakdown with dynamic semantic colors
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1F222B) : const Color(0xFFF8F5EE),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              children: [
                _buildProbRow('Structured Feature Match (65%)', '$structPct%', result.structuredProbability),
                const SizedBox(height: 12),
                _buildProbRow('Resume & Job Text Fit (35%)', '$fitPct%', result.fitProbability),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Decision Threshold',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.getMutedTextColor(context)),
                    ),
                    Text(
                      '50.0% (Positive Match >= 50%)',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.getTextColor(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Extracted Features Breakdown - Formatted as clean scannable tag chips
          Text(
            'Evaluated Feature Breakdown',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1F222B) : const Color(0xFFF8F5EE),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.extractedFeatures.entries.map((e) {
                final isList = e.value.toString().contains(',');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.key,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getMutedTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isList)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: e.value.toString().split(',').map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.white10 : Colors.white,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: AppTheme.getBorderColor(context)),
                              ),
                              child: Text(
                                item.trim(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.getTextColor(context),
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.white10 : Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: AppTheme.getBorderColor(context)),
                          ),
                          child: Text(
                            e.value.toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextColor(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Model Recommendations & Skill Gap Analysis
          Text(
            'Model Recommendations & Skill Gap Analysis',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1F222B) : const Color(0xFFF8FAF4),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_outline_rounded, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      'High Impact Skills Found:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['Flutter', 'Dart', 'FastAPI', 'PostgreSQL', 'REST APIs'].map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        '✓ $s',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF10B981)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 16, color: AppTheme.primaryOrange),
                    const SizedBox(width: 6),
                    Text(
                      'Suggested Additions to boost score +15%:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['Kubernetes', 'GraphQL', 'Microservices Architecture'].map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        '+ $s',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryOrange),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Mandatory Legal Disclaimer Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.gavel_rounded, size: 20, color: AppTheme.primaryOrange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.disclaimer,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: isDarkMode ? const Color(0xFFFFD4C2) : const Color(0xFF9E3609),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Safe bottom breathing room
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildProbRow(String label, String pctText, double ratio) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: ratio),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, animatedRatio, _) {
        final animPct = (animatedRatio * 100).toStringAsFixed(1);
        // Dynamic semantic color for progress bar and percentage
        final rowColor = animatedRatio >= 0.70
            ? const Color(0xFF10B981) // Green for high match
            : (animatedRatio >= 0.50 ? const Color(0xFFF59E0B) : const Color(0xFF64748B));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
                Text(
                  '$animPct%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: rowColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: LinearProgressIndicator(
                value: animatedRatio,
                minHeight: 6,
                backgroundColor: AppTheme.isDarkMode(context) ? Colors.white10 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(rowColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
