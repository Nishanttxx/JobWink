import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/footer_section.dart';

/// Comprehensive, legally accurate Privacy Policy screen for JobWink.
/// Reflects the exact technical architecture, data storage, AI processing,
/// and authentication flows present in the codebase.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final bgColor = AppTheme.getBgColor(context);
    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF10121A) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF222634) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Top Navigation Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: bgColor.withAlpha(220),
                  border: Border(bottom: BorderSide(color: cardBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryOrange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Back to JobWink',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.primaryOrange.withAlpha(60)),
                          ),
                          child: Text(
                            'Legal Documentation',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Policy Content Body
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Text(
                        'Privacy Policy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last Updated: August 27, 2026',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'This Privacy Policy describes how JobWink ("we", "us", or "our") collects, processes, stores, and handles your information when you visit or use our web application, resume builder, ATS optimization tools, and related career services.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          height: 1.6,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 32),

                      _buildSection(
                        title: '1. Information We Collect',
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        children: [
                          _buildSubItem(
                            subtitle: 'A. Account & Profile Information',
                            content: 'When you create an account or update your profile, we collect your email address, full name, phone number, location, and optional profile links (such as LinkedIn and GitHub URLs). If you upload a profile picture or authenticate via an OAuth provider, your avatar image is stored.',
                            textColor: textColor,
                          ),
                          _buildSubItem(
                            subtitle: 'B. Resume & Professional Content',
                            content: 'When you build, edit, or upload a resume, we process the professional information you provide, including contact details, professional summary, education history, work experience, projects, skills, certifications, extracurricular activities, and embedded URLs.',
                            textColor: textColor,
                          ),
                          _buildSubItem(
                            subtitle: 'C. Job Descriptions & Search Data',
                            content: 'When you use our ATS optimization, job matching, or interview prediction tools, we process the target Job Descriptions, requirements, and job preferences you enter into the application.',
                            textColor: textColor,
                          ),
                          _buildSubItem(
                            subtitle: 'D. Bug Reports & Feedback',
                            content: 'If you voluntarily submit a bug report or feedback, we collect your written description, selected severity level, relevant application screen/route context, and any screenshot images you attach.',
                            textColor: textColor,
                          ),
                          _buildSubItem(
                            subtitle: 'E. Technical Storage Data',
                            content: 'We store your UI display preferences (Dark Mode vs Light Mode) and your encrypted authentication session token in your browser\'s local storage (`localStorage`). We do not use third-party analytics trackers or advertising cookies.',
                            textColor: textColor,
                          ),
                        ],
                      ),

                      _buildSection(
                        title: '2. How We Use Your Information',
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        children: [
                          _buildBulletPoint('Creating and securely authenticating your user account.', textColor),
                          _buildBulletPoint('Parsing uploaded resume files and extracting structured fields for editing.', textColor),
                          _buildBulletPoint('Generating ATS-tailored resume documents and calculating match scores against job descriptions.', textColor),
                          _buildBulletPoint('Saving and retrieving your resume drafts and version history in our database.', textColor),
                          _buildBulletPoint('Providing client-side 1-page PDF rendering and file downloads.', textColor),
                          _buildBulletPoint('Processing bug reports and technical feedback to resolve application issues.', textColor),
                          _buildBulletPoint('Enforcing fair per-user daily resume generation quotas.', textColor),
                        ],
                      ),

                      _buildSection(
                        title: '3. Artificial Intelligence (AI) Processing',
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        children: [
                          Text(
                            'JobWink provides AI-assisted resume parsing, tailoring, and ATS analysis. When you trigger an AI operation (such as tailoring a resume or analyzing a job description), the relevant text content is transmitted to our configured AI service providers to execute the request.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: textColor),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Our AI pipeline utilizes Google Gemini (primary provider), with automated failover routing to OpenAI, Groq, Mistral, Cerebras, xAI, and NVIDIA API endpoints to ensure system availability. Data processed via these APIs is governed by the respective provider\'s API data usage and privacy policies. We do not use your proprietary resume data to train external public foundation models.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: textColor),
                          ),
                        ],
                      ),

                      _buildSection(
                        title: '4. Authentication & Security',
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        children: [
                          Text(
                            'Authentication is powered by Supabase Auth with PKCE (Proof Key for Code Exchange) flow. We support Email & Password authentication as well as third-party OAuth sign-in via Google and GitHub. When using third-party OAuth, we receive your verified email and profile name; we never receive or store your third-party account passwords.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: textColor),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'We implement Row Level Security (RLS) policies within our PostgreSQL database to ensure that users can only access, view, and modify their own resumes and account data.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: textColor),
                          ),
                        ],
                      ),

                      _buildSection(
                        title: '5. Data Storage & Retention',
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        children: [
                          _buildSubItem(
                            subtitle: 'Structured Data Storage:',
                            content: 'User profiles, structured resume data, resume versions, and bug report text are stored in our managed Supabase PostgreSQL database in secured cloud infrastructure.',
                            textColor: textColor,
                          ),
                          _buildSubItem(
                            subtitle: 'File Storage:',
                            content: 'Profile avatars and bug report screenshots are stored in dedicated Supabase Storage buckets (`avatars` and `bug-screenshots`). Uploaded resume documents (PDF/DOCX) are parsed in-memory during extraction; the resulting structured JSON profile is stored in the database, while raw uploaded binary files are not kept in long-term storage.',
                            textColor: textColor,
                          ),
                          _buildSubItem(
                            subtitle: 'Data Retention & Deletion:',
                            content: 'Your resume versions and account profile remain stored as long as your account is active so you can return to edit your resumes. You may edit, overwrite, or clear resume content at any time in the resume editor. If you wish to completely delete your account and all associated database records, please submit a deletion request to na6236786@gmail.com for manual processing.',
                            textColor: textColor,
                          ),
                        ],
                      ),

                      _buildSection(
                        title: '6. Third-Party Service Providers & Data Sharing',
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        children: [
                          Text(
                            'We do not sell your personal information. We share information with third-party service providers solely to the extent necessary to deliver application features:',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: textColor),
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint('Supabase Inc.: Cloud database hosting, user authentication, and media storage.', textColor),
                          _buildBulletPoint('AI Providers (Google Gemini, OpenAI, Groq, Mistral, Cerebras, xAI, NVIDIA): Processing text for resume parsing and ATS matching.', textColor),
                          _buildBulletPoint('GitHub API: Fetching public repository information when you explicitly request a GitHub project import.', textColor),
                          _buildBulletPoint('Google Fonts & CDN Providers (Cloudflare / jsDelivr): Serving frontend typography and visual animation libraries.', textColor),
                        ],
                      ),

                      _buildSection(
                        title: '7. Cookies & Local Storage',
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        children: [
                          Text(
                            'JobWink does not use third-party advertising or tracking cookies. We utilize browser `localStorage` strictly for essential functionality: (1) `sb-*-auth-token` to maintain your authenticated login session, and (2) `user_theme_mode` to remember your Dark/Light mode preference. For full details, see our Cookie Policy.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: textColor),
                          ),
                        ],
                      ),

                      _buildSection(
                        title: '8. Third-Party External Links',
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        children: [
                          Text(
                            'Our application may display links to external job postings, employer websites, LinkedIn, GitHub, or other third-party services. We have no control over and assume no responsibility for the content, privacy policies, or practices of any third-party websites or services.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: textColor),
                          ),
                        ],
                      ),

                      _buildSection(
                        title: '9. Security Measures',
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        children: [
                          Text(
                            'We take reasonable administrative and technical measures designed to protect your personal information from unauthorized access, loss, misuse, alteration, or disclosure. However, no method of transmission over the Internet or electronic storage is 100% secure, and we cannot guarantee absolute security.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: textColor),
                          ),
                        ],
                      ),

                      _buildSection(
                        title: '10. User Rights & Data Requests',
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        children: [
                          Text(
                            'You have the right to access the personal information stored in your account, correct any inaccuracies, or request the deletion of your account and associated resume records. Because automated self-serve account deletion is not currently implemented in the user interface, all account deletion and data export requests are processed manually.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: textColor),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'To make a privacy request or question, please email our designated contact address below.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: textColor),
                          ),
                        ],
                      ),

                      _buildSection(
                        title: '11. Changes to This Privacy Policy',
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        children: [
                          Text(
                            'We may update this Privacy Policy from time to time to reflect changes in our practices or service architecture. When changes are made, we will update the "Last Updated" date at the top of this document.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: textColor),
                          ),
                        ],
                      ),

                      _buildSection(
                        title: '12. Contact Information',
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        children: [
                          Text(
                            'If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us at:',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.6, color: textColor),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, color: AppTheme.primaryOrange, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'na6236786@gmail.com',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Footer
              const FooterSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color textColor,
    required Color mutedColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubItem({
    required String subtitle,
    required String content,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.6,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: Icon(Icons.circle, size: 6, color: AppTheme.primaryOrange),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.5,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
