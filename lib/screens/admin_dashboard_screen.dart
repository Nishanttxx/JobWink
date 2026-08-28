import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/backend_config.dart';
import '../providers/auth_provider.dart';
import '../services/resume_limit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/theme_toggle_button.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isCheckingAuth = true;
  bool _isAdminAuthorized = false;
  bool _isLoadingStats = true;
  bool _isLoadingUsers = true;

  // Overview Stats
  int _totalUsers = 0;
  int _activeUsersToday = 0;
  int _resumesGeneratedToday = 0;
  int _usersAtLimit = 0;

  // Paged Users List
  List<AdminUserQuotaInfo> _allUsers = [];
  List<AdminUserQuotaInfo> _filteredUsers = [];
  int _currentPage = 1;
  final int _pageSize = 10;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _verifyAdminAccess();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _verifyAdminAccess() async {
    setState(() => _isCheckingAuth = true);
    final auth = AuthProviderScope.read(context);
    final email = auth.currentUser?.email;

    final isAdmin = ResumeLimitService.instance.isUserAdmin(email) || auth.isAdmin;

    if (mounted) {
      setState(() {
        _isAdminAuthorized = isAdmin;
        _isCheckingAuth = false;
      });

      if (isAdmin) {
        _loadStats();
        _loadUsers();
      }
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await ResumeLimitService.instance.getAdminStats();
      if (mounted) {
        setState(() {
          _totalUsers = (stats['totalUsers'] as num? ?? 0).toInt();
          _activeUsersToday = (stats['activeUsersToday'] as num? ?? 0).toInt();
          _resumesGeneratedToday = (stats['resumesGeneratedToday'] as num? ?? 0).toInt();
          _usersAtLimit = (stats['usersAtLimit'] as num? ?? 0).toInt();
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminDashboard] Stats error: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await ResumeLimitService.instance.getAdminUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _applyFilter();
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminDashboard] getAdminUsers error: $e');
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
          _allUsers = [];
          _filteredUsers = [];
        });
      }
    }
  }

  void _applyFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredUsers = List.from(_allUsers);
    } else {
      final query = _searchQuery.trim().toLowerCase();
      _filteredUsers = _allUsers.where((u) {
        final email = u.email.toLowerCase();
        final name = (u.fullName ?? '').toLowerCase();
        final userId = u.userId.toLowerCase();
        return email.contains(query) || name.contains(query) || userId.contains(query);
      }).toList();
    }
  }

  Future<void> _updateUserLimit(String userId, String userEmail, int newLimit) async {
    try {
      await ResumeLimitService.instance.updateDailyLimit(userId, newLimit);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text(
              'Updated daily limit to $newLimit creations for $userEmail',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
        _loadStats();
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Failed to update limit: $e', style: const TextStyle(color: Colors.white)),
          ),
        );
      }
    }
  }

  Future<void> _resetUserUsage(String userId, String userEmail) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Daily Usage?',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will reset today\'s resume creations counter to 0 for $userEmail.',
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8B949E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8B949E))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: Text('Reset Usage', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ResumeLimitService.instance.resetUserUsage(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text('Daily usage reset successfully!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
        _loadStats();
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Reset failed: $e', style: const TextStyle(color: Colors.white)),
          ),
        );
      }
    }
  }

  void _showEditLimitModal(AdminUserQuotaInfo user) {
    final controller = TextEditingController(text: '${user.dailyLimit}');
    int selectedPreset = user.dailyLimit;
    const presets = [1, 2, 4, 5, 10, 20];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161B22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppTheme.primaryOrange, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Change Daily Limit',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User: ${user.fullName ?? user.email}',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  if (user.fullName != null && user.fullName!.isNotEmpty)
                    Text(
                      user.email,
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8B949E), fontSize: 12),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Current Limit: ${user.dailyLimit} | Used Today: ${user.usageCount}',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8B949E), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quick Presets:',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8B949E), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((p) {
                      final isSelected = selectedPreset == p;
                      return ChoiceChip(
                        label: Text('$p'),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryOrange,
                        backgroundColor: const Color(0xFF21262D),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          color: isSelected ? Colors.white : const Color(0xFF8B949E),
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() {
                              selectedPreset = p;
                              controller.text = '$p';
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Custom Daily Resume Limit',
                      labelStyle: const TextStyle(color: AppTheme.primaryOrange),
                      filled: true,
                      fillColor: const Color(0xFF21262D),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF30363D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.primaryOrange),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val.trim());
                      if (parsed != null) {
                        setModalState(() => selectedPreset = parsed);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8B949E))),
              ),
              ElevatedButton(
                onPressed: () {
                  final newLim = int.tryParse(controller.text.trim());
                  if (newLim != null && newLim >= 0) {
                    Navigator.pop(ctx);
                    _updateUserLimit(user.userId, user.email, newLim);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Save Limit', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryOrange),
        ),
      );
    }

    // ── 403 Access Denied Gate ──
    if (!_isAdminAuthorized) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          backgroundColor: const Color(0xFF161B22),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Admin Portal',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEF4444)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gpp_bad_rounded, size: 64, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                Text(
                  '403 Access Denied',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Admin privileges are strictly restricted to the designated admin account. Normal users cannot access this dashboard.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF8B949E),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Return to Application', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final total = _filteredUsers.length;
    final totalPages = (total / _pageSize).ceil();
    final safeTotalPages = totalPages < 1 ? 1 : totalPages;
    final safePage = _currentPage.clamp(1, safeTotalPages);
    final startIndex = (safePage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, total);
    final pagedUsers = _filteredUsers.isEmpty ? <AdminUserQuotaInfo>[] : _filteredUsers.sublist(startIndex, endIndex);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF8B5CF6), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isMobile ? 'Admin Dashboard' : 'JobWink Admin Dashboard',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 15 : 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!isMobile) ...[
            IconButton(
              icon: const Icon(Icons.home_rounded, color: Colors.white),
              tooltip: 'Go to Home',
              onPressed: () => Navigator.pushNamed(context, '/landing'),
            ),
            const SizedBox(width: 4),
          ],
          const ThemeToggleButton(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryOrange),
            tooltip: 'Refresh Data',
            onPressed: () {
              _loadStats();
              _loadUsers();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Stats Overview Cards ──
            Text(
              'Overview & Real-Time Metrics',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final cards = [
                  _buildStatCard('Total Users', _isLoadingStats ? '...' : '$_totalUsers', Icons.people_outline, const Color(0xFF3B82F6)),
                  _buildStatCard('Active Users Today', _isLoadingStats ? '...' : '$_activeUsersToday', Icons.bolt, const Color(0xFF10B981)),
                  _buildStatCard('Resumes Created Today', _isLoadingStats ? '...' : '$_resumesGeneratedToday', Icons.file_copy_outlined, AppTheme.primaryOrange),
                  _buildStatCard('Users At Limit', _isLoadingStats ? '...' : '$_usersAtLimit', Icons.lock_clock, const Color(0xFFEF4444)),
                ];

                if (width >= 900) {
                  return Row(
                    children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList(),
                  );
                } else if (width >= 560) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: cards.map((c) => SizedBox(width: (width - 12) / 2, child: c)).toList(),
                  );
                } else {
                  return Column(
                    children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: SizedBox(width: double.infinity, child: c))).toList(),
                  );
                }
              },
            ),
            const SizedBox(height: 32),

            // ── 2. Users Table Header & Search ──
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 650;
                final titleCol = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Quota Management',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Registrations: ${_allUsers.length}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF8B949E)),
                    ),
                  ],
                );

                final searchBox = SizedBox(
                  width: isMobile ? double.infinity : 280,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _currentPage = 1;
                        _applyFilter();
                      });
                    },
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by email or name...',
                      hintStyle: const TextStyle(color: Color(0xFF8B949E)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF8B949E), size: 18),
                      filled: true,
                      fillColor: const Color(0xFF161B22),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF30363D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.primaryOrange),
                      ),
                    ),
                  ),
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleCol,
                      const SizedBox(height: 12),
                      searchBox,
                    ],
                  );
                } else {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      titleCol,
                      searchBox,
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            // ── 3. Users List Table ──
            if (_isLoadingUsers)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.primaryOrange)))
            else if (_filteredUsers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Center(
                  child: Text(
                    'No users matching "$_searchQuery" found.',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8B949E)),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Column(
                  children: [
                    ...pagedUsers.map((user) => _buildUserRow(user)),
                    if (safeTotalPages > 1) ...[
                      const Divider(color: Color(0xFF30363D), height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Page $safePage of $safeTotalPages (${_filteredUsers.length} total users)',
                              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8B949E), fontSize: 13),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: safePage > 1
                                      ? () => setState(() => _currentPage = safePage - 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                                ),
                                IconButton(
                                  onPressed: safePage < safeTotalPages
                                      ? () => setState(() => _currentPage = safePage + 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF8B949E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(AdminUserQuotaInfo user) {
    final isAtLimit = user.usageCount >= user.dailyLimit;
    final displayName = (user.fullName != null && user.fullName!.trim().isNotEmpty)
        ? user.fullName!.trim()
        : user.email.split('@').first;

    final createdDateStr = user.createdAt != null
        ? '${user.createdAt!.year}-${user.createdAt!.month.toString().padLeft(2, '0')}-${user.createdAt!.day.toString().padLeft(2, '0')}'
        : '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final avatar = CircleAvatar(
          backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.2),
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold),
          ),
        );

        final userDetails = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (BackendConfig.adminEmail.isNotEmpty && user.email == BackendConfig.adminEmail) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF8B5CF6)),
                    ),
                    child: Text(
                      'ADMIN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC4B5FD),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              user.email,
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8B949E), fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (createdDateStr.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Registered: $createdDateStr',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF6E7681), fontSize: 11),
              ),
            ],
          ],
        );

        final quotaBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isAtLimit
                ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                : const Color(0xFF10B981).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isAtLimit ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Text(
                '${user.usageCount} / ${user.dailyLimit} Used',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isAtLimit ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                ),
              ),
              Text(
                '${user.remaining} remaining today',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: isAtLimit ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
                ),
              ),
            ],
          ),
        );

        final actionButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showEditLimitModal(user),
              tooltip: 'Change Daily Limit',
              icon: const Icon(Icons.tune_rounded, color: AppTheme.primaryOrange, size: 20),
            ),
            IconButton(
              onPressed: () => _resetUserUsage(user.userId, user.email),
              tooltip: 'Reset Today\'s Usage',
              icon: const Icon(Icons.restore_rounded, color: Color(0xFF8B949E), size: 20),
            ),
          ],
        );

        if (isMobile) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF21262D))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    avatar,
                    const SizedBox(width: 12),
                    Expanded(child: userDetails),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    quotaBadge,
                    actionButtons,
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF21262D))),
          ),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 14),
              Expanded(child: userDetails),
              quotaBadge,
              const SizedBox(width: 14),
              actionButtons,
            ],
          ),
        );
      },
    );
  }
}
