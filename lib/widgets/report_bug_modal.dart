import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/bug_report_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class ReportBugModal extends StatefulWidget {
  final String? initialRoute;

  const ReportBugModal({super.key, this.initialRoute});

  static Future<void> show(BuildContext context, {String? routeName}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ReportBugModal(initialRoute: routeName),
    );
  }

  @override
  State<ReportBugModal> createState() => _ReportBugModalState();
}

class _ReportBugModalState extends State<ReportBugModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  Uint8List? _screenshotBytes;
  String? _screenshotFileName;
  int? _screenshotSizeBytes;
  String? _fileValidationError;

  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  Map<String, String>? _telemetry;

  String? _authenticatedUserId;
  String? _authenticatedUserName;
  String? _authenticatedUserEmail;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _telemetry ??= BugReportService.instance.collectTelemetry(
      context,
      currentRoute: widget.initialRoute,
    );
    _initUserIdentity();
  }

  void _initUserIdentity() {
    final auth = AuthProviderScope.read(context);
    final user = auth.currentUser;
    final supabaseUser = SupabaseService.instance.currentUser;

    _authenticatedUserId = user?.id ?? supabaseUser?.id;
    _authenticatedUserEmail = (user?.email != null && user!.email.isNotEmpty)
        ? user.email
        : (supabaseUser?.email ?? '');

    String? name = user?.fullName;
    if (name == null || name.trim().isEmpty) {
      name = supabaseUser?.userMetadata?['full_name'] as String? ??
          supabaseUser?.userMetadata?['name'] as String?;
    }
    if (name == null || name.trim().isEmpty) {
      if (_authenticatedUserEmail != null && _authenticatedUserEmail!.contains('@')) {
        name = _authenticatedUserEmail!.split('@').first;
      }
    }
    _authenticatedUserName = name;

    if (_emailController.text.isEmpty &&
        _authenticatedUserEmail != null &&
        _authenticatedUserEmail!.isNotEmpty) {
      _emailController.text = _authenticatedUserEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    setState(() {
      _fileValidationError = null;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final name = file.name;
        final size = file.size;
        final bytes = file.bytes;

        final valErr = BugReportService.instance.validateScreenshot(
          fileName: name,
          fileSizeBytes: size,
        );

        if (valErr != null) {
          setState(() {
            _fileValidationError = valErr;
          });
          return;
        }

        setState(() {
          _screenshotBytes = bytes;
          _screenshotFileName = name;
          _screenshotSizeBytes = size;
          _fileValidationError = null;
        });
      }
    } catch (e) {
      setState(() {
        _fileValidationError = 'Could not select screenshot. Please try again.';
      });
    }
  }

  void _removeScreenshot() {
    setState(() {
      _screenshotBytes = null;
      _screenshotFileName = null;
      _screenshotSizeBytes = null;
      _fileValidationError = null;
    });
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return; // Prevent duplicate clicks

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fileValidationError != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final reporterEmail = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : (_authenticatedUserEmail ?? '');

    final reportData = BugReportData(
      userId: _authenticatedUserId,
      userName: _authenticatedUserName,
      userEmail: reporterEmail,
      title: _titleController.text,
      description: _descriptionController.text,
      pageUrl: _telemetry?['page_url'],
      route: _telemetry?['route'],
      browser: _telemetry?['browser'],
      os: _telemetry?['os'],
      screenSize: _telemetry?['screen_size'],
      screenshotBytes: _screenshotBytes,
      screenshotFileName: _screenshotFileName,
    );

    final res = await BugReportService.instance.submitBugReport(reportData);

    if (!mounted) return;

    if (res['success'] == true) {
      final emailSent = res['email_sent'] == true;
      setState(() {
        _isSubmitting = false;
        _successMessage = res['message'] ??
            (emailSent
                ? 'Bug reported successfully. Thank you for helping us improve JobWink!'
                : 'Bug report saved to database (email delivery unavailable).');
      });

      // Clear form after success
      _titleController.clear();
      _descriptionController.clear();
      _removeScreenshot();

      // Dismiss dialog after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      });
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = res['message'] ?? 'Unable to send the bug report. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final isWebMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWebMobile ? 16 : 40,
        vertical: 24,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bug_report_rounded,
                        color: AppTheme.primaryOrange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report a Bug',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Encountered an error or problem? Let us know so we can fix it.',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              // Form Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Success Feedback Banner
                        if (_successMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _successMessage!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Error Feedback Banner
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // User Email Field
                        _buildLabel('Your Email Address', textPrimary),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.outfit(color: textPrimary, fontSize: 14),
                          decoration: _buildInputDecoration(
                            hint: 'Enter your email address',
                            icon: Icons.email_outlined,
                            inputBg: inputBg,
                            borderColor: borderColor,
                            textSecondary: textSecondary,
                          ),
                          validator: (value) {
                            final val = value?.trim() ?? '';
                            if (val.isEmpty || !val.contains('@')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Bug Title Field
                        _buildLabel('Bug Title', textPrimary),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _titleController,
                          style: GoogleFonts.outfit(color: textPrimary, fontSize: 14),
                          decoration: _buildInputDecoration(
                            hint: 'e.g. Resume preview is showing incorrect information',
                            icon: Icons.title_rounded,
                            inputBg: inputBg,
                            borderColor: borderColor,
                            textSecondary: textSecondary,
                          ),
                          validator: (value) {
                            final val = value?.trim() ?? '';
                            if (val.isEmpty || val.length < 3) {
                              return 'Please provide a clear title (at least 3 characters)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Bug Description Field
                        _buildLabel('Bug Description', textPrimary),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descriptionController,
                          minLines: 4,
                          maxLines: 6,
                          style: GoogleFonts.outfit(color: textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Describe what went wrong, steps to reproduce, or expected behavior...',
                            hintStyle: GoogleFonts.outfit(color: textSecondary, fontSize: 14),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.all(14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFEF4444)),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                            ),
                          ),
                          validator: (value) {
                            final val = value?.trim() ?? '';
                            if (val.isEmpty || val.length < 5) {
                              return 'Please describe the bug details (at least 5 characters)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Screenshot Upload Section
                        _buildLabel('Attach Screenshot (Optional)', textPrimary),
                        const SizedBox(height: 6),

                        if (_screenshotBytes != null) ...[
                          // Selected Image Preview Card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _screenshotBytes!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _screenshotFileName ?? 'screenshot.png',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _screenshotSizeBytes != null
                                            ? '${(_screenshotSizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB'
                                            : 'Attached',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _pickScreenshot,
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Change'),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    textStyle: GoogleFonts.outfit(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: _removeScreenshot,
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                                  tooltip: 'Remove Screenshot',
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Pick Screenshot Button Card
                          InkWell(
                            onTap: _pickScreenshot,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _fileValidationError != null
                                      ? const Color(0xFFEF4444)
                                      : borderColor,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: AppTheme.primaryOrange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'Upload Screenshot (PNG, JPG, WEBP - Max 5MB)',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        if (_fileValidationError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _fileValidationError!,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Telemetry Information Badges
                        if (_telemetry != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: inputBg.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 14, color: textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Technical Telemetry (Auto-detected)',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _buildChip('Route: ${_telemetry!['route']}', textSecondary, borderColor),
                                    _buildChip('Browser: ${_telemetry!['browser']}', textSecondary, borderColor),
                                    _buildChip('OS: ${_telemetry!['os']}', textSecondary, borderColor),
                                    _buildChip('Screen: ${_telemetry!['screen_size']}', textSecondary, borderColor),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryOrange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.send_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Report Bug',
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    required Color inputBg,
    required Color borderColor,
    required Color textSecondary,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: textSecondary, fontSize: 14),
      prefixIcon: Icon(icon, color: textSecondary, size: 20),
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
    );
  }

  Widget _buildChip(String text, Color textSecondary, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          color: textSecondary,
        ),
      ),
    );
  }
}
