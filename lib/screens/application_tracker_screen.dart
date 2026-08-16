import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_nav_bar.dart';

class ApplicationTrackerScreen extends StatefulWidget {
  const ApplicationTrackerScreen({super.key});

  @override
  State<ApplicationTrackerScreen> createState() => _ApplicationTrackerScreenState();
}

class TrackerJob {
  final String id;
  final String title;
  final String company;
  final String location;
  final String salary;
  final double matchScore;
  String status; // 'Saved', 'Applied', 'Interviewing', 'Offer'

  TrackerJob({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.matchScore,
    required this.status,
  });
}

class _ApplicationTrackerScreenState extends State<ApplicationTrackerScreen> {
  final List<TrackerJob> _applications = [
    TrackerJob(
      id: 'app_1',
      title: 'Senior Flutter Developer',
      company: 'TechCorp Global',
      location: 'Remote',
      salary: '\$130k - \$160k',
      matchScore: 94.5,
      status: 'Saved',
    ),
    TrackerJob(
      id: 'app_2',
      title: 'AI Full-Stack Engineer',
      company: 'DataWiz AI',
      location: 'San Francisco, CA',
      salary: '\$140k - \$175k',
      matchScore: 89.2,
      status: 'Applied',
    ),
    TrackerJob(
      id: 'app_3',
      title: 'Lead Mobile Architect',
      company: 'NextGen Solutions',
      location: 'Remote',
      salary: '\$150k - \$180k',
      matchScore: 86.8,
      status: 'Interviewing',
    ),
    TrackerJob(
      id: 'app_4',
      title: 'Flutter & Firebase Specialist',
      company: 'Veloce Labs',
      location: 'Austin, TX',
      salary: '\$145k - \$170k',
      matchScore: 92.0,
      status: 'Offer',
    ),
  ];

  void _moveJob(TrackerJob job, String newStatus) {
    setState(() {
      job.status = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isDarkMode = AppTheme.isDarkMode(context);

    final saved = _applications.where((j) => j.status == 'Saved').toList();
    final applied = _applications.where((j) => j.status == 'Applied').toList();
    final interviewing = _applications.where((j) => j.status == 'Interviewing').toList();
    final offer = _applications.where((j) => j.status == 'Offer').toList();

    return Scaffold(
      backgroundColor: AppTheme.getBgColor(context),
      appBar: _buildAppBar(context, isDarkMode),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40 : 16,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1380),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Application Pipeline Tracker 📊',
                            style: AppTheme.getDisplayFont(
                              fontSize: isDesktop ? 28 : 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.getTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kanban board to track job applications from saved matches to offers.',
                            style: AppTheme.getBodyFont(
                              fontSize: 14,
                              color: AppTheme.getMutedTextColor(context),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha:0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha:0.3)),
                        ),
                        child: Text(
                          '${_applications.length} Active Applications',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Kanban Columns Layout
                  isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildKanbanColumn(context, 'Saved Roles', saved, const Color(0xFF3B82F6), 'Saved')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildKanbanColumn(context, 'Applied', applied, AppTheme.primaryOrange, 'Applied')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildKanbanColumn(context, 'Interviewing', interviewing, const Color(0xFF8B5CF6), 'Interviewing')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildKanbanColumn(context, 'Offers', offer, const Color(0xFF10B981), 'Offer')),
                          ],
                        )
                      : Column(
                          children: [
                            _buildKanbanColumn(context, 'Saved Roles', saved, const Color(0xFF3B82F6), 'Saved'),
                            const SizedBox(height: 20),
                            _buildKanbanColumn(context, 'Applied', applied, AppTheme.primaryOrange, 'Applied'),
                            const SizedBox(height: 20),
                            _buildKanbanColumn(context, 'Interviewing', interviewing, const Color(0xFF8B5CF6), 'Interviewing'),
                            const SizedBox(height: 20),
                            _buildKanbanColumn(context, 'Offers', offer, const Color(0xFF10B981), 'Offer'),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKanbanColumn(BuildContext context, String title, List<TrackerJob> jobs, Color accentColor, String statusKey) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${jobs.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cards List
          if (jobs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1B1E26) : const Color(0xFFF8FAF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.getBorderColor(context), style: BorderStyle.solid),
              ),
              child: Center(
                child: Text(
                  'No roles in $title',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.getMutedTextColor(context),
                  ),
                ),
              ),
            )
          else
            Column(
              children: jobs.map((job) => _buildJobCard(context, job, accentColor)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, TrackerJob job, Color accentColor) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1B1E26) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
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
                  job.title,
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
                  color: const Color(0xFF10B981).withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${job.matchScore.toStringAsFixed(0)}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${job.company} • ${job.location}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.getMutedTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            job.salary,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),

          // Move Pipeline Status Dropdown
          PopupMenuButton<String>(
            onSelected: (val) => _moveJob(job, val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Saved', child: Text('Move to Saved')),
              const PopupMenuItem(value: 'Applied', child: Text('Move to Applied')),
              const PopupMenuItem(value: 'Interviewing', child: Text('Move to Interviewing')),
              const PopupMenuItem(value: 'Offer', child: Text('Move to Offer')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withValues(alpha:0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Status: ${job.status}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 16, color: accentColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDarkMode) {
    return AppBar(
      backgroundColor: AppTheme.getSurfaceColor(context),
      elevation: 0,
      scrolledUnderElevation: 0.5,
      title: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.primaryOrange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'JobWink',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          if (MediaQuery.of(context).size.width >= 768)
            const DashboardNavBar(activeRoute: '/tracker'),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => ThemeService.instance.toggleTheme(),
          icon: Icon(
            isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: AppTheme.getTextColor(context),
          ),
          tooltip: 'Toggle Theme',
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
