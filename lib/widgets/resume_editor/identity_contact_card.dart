import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class IdentityContactCard extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController roleController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController locationController;
  final TextEditingController linkedinController;
  final TextEditingController githubController;
  final VoidCallback? onChanged;

  const IdentityContactCard({
    super.key,
    required this.nameController,
    required this.roleController,
    required this.phoneController,
    required this.emailController,
    required this.locationController,
    required this.linkedinController,
    required this.githubController,
    this.onChanged,
  });

  @override
  State<IdentityContactCard> createState() => _IdentityContactCardState();
}

class _IdentityContactCardState extends State<IdentityContactCard> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF131720) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Identity & Contact',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _isEditing = !_isEditing),
                icon: Icon(
                  _isEditing ? Icons.check_circle_rounded : Icons.edit_rounded,
                  color: _isEditing ? const Color(0xFF10B981) : AppTheme.getMutedTextColor(context),
                  size: 20,
                ),
                tooltip: _isEditing ? 'Save Changes' : 'Edit Contact Details',
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3-Column Responsive Grid Layout (Matching Screenshot Exactly)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 768;
              final isMedium = constraints.maxWidth >= 500;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Col 1: Full Name, Email Address, LinkedIn Profile
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldItem(context, 'Full Name', widget.nameController, 'e.g. Syed Jabbar'),
                          const SizedBox(height: 14),
                          _buildFieldItem(context, 'Email Address', widget.emailController, 'e.g. syed@example.com'),
                          const SizedBox(height: 14),
                          _buildFieldItem(context, 'LinkedIn Profile', widget.linkedinController, 'https://linkedin.com/in/...'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Col 2: Role / Job Title, Phone Number, Github / Portfolio
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldItem(context, 'Role / Job Title', widget.roleController, 'e.g. AI / Machine Learning Engineer'),
                          const SizedBox(height: 14),
                          _buildFieldItem(context, 'Phone Number', widget.phoneController, 'e.g. +92 4200002556'),
                          const SizedBox(height: 14),
                          _buildFieldItem(context, 'Github / Portfolio', widget.githubController, 'https://github.com/...'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Col 3: Location(s)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldItem(context, 'Location(s)', widget.locationController, 'e.g. DHA 1, Okara, Punjab'),
                        ],
                      ),
                    ),
                  ],
                );
              } else if (isMedium) {
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFieldItem(context, 'Full Name', widget.nameController, 'e.g. John Doe')),
                        const SizedBox(width: 14),
                        Expanded(child: _buildFieldItem(context, 'Email Address', widget.emailController, 'e.g. john@example.com')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFieldItem(context, 'Role / Job Title', widget.roleController, 'e.g. Software Engineer')),
                        const SizedBox(width: 14),
                        Expanded(child: _buildFieldItem(context, 'Phone Number', widget.phoneController, 'e.g. +1 (555) 000-0000')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFieldItem(context, 'Location(s)', widget.locationController, 'e.g. New York, NY')),
                        const SizedBox(width: 14),
                        Expanded(child: _buildFieldItem(context, 'LinkedIn Profile', widget.linkedinController, 'https://linkedin.com/in/...')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFieldItem(context, 'Github / Portfolio', widget.githubController, 'https://github.com/...')),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldItem(context, 'Full Name', widget.nameController, 'e.g. John Doe'),
                    const SizedBox(height: 12),
                    _buildFieldItem(context, 'Email Address', widget.emailController, 'e.g. john@example.com'),
                    const SizedBox(height: 12),
                    _buildFieldItem(context, 'Role / Job Title', widget.roleController, 'e.g. Software Engineer'),
                    const SizedBox(height: 12),
                    _buildFieldItem(context, 'Phone Number', widget.phoneController, 'e.g. +1 (555) 000-0000'),
                    const SizedBox(height: 12),
                    _buildFieldItem(context, 'Location(s)', widget.locationController, 'e.g. New York, NY'),
                    const SizedBox(height: 12),
                    _buildFieldItem(context, 'LinkedIn Profile', widget.linkedinController, 'https://linkedin.com/in/...'),
                    const SizedBox(height: 12),
                    _buildFieldItem(context, 'Github / Portfolio', widget.githubController, 'https://github.com/...'),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFieldItem(
    BuildContext context,
    String label,
    TextEditingController controller,
    String placeholder,
  ) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.getMutedTextColor(context),
          ),
        ),
        const SizedBox(height: 4),
        if (_isEditing)
          TextField(
            controller: controller,
            onChanged: (_) => widget.onChanged?.call(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              hintText: placeholder,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.getMutedTextColor(context).withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDarkMode ? const Color(0xFF30363D) : const Color(0xFFCBD5E1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
              ),
            ),
          )
        else
          Text(
            controller.text.isNotEmpty ? controller.text : 'Not specified',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: controller.text.isNotEmpty
                  ? AppTheme.getTextColor(context)
                  : AppTheme.getMutedTextColor(context).withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
