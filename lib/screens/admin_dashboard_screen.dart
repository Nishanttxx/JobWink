import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../config/backend_config.dart';
import '../providers/auth_provider.dart';

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

  // Stats
  int _totalUsers = 0;
  int _activeUsersToday = 0;
  int _resumesGeneratedToday = 0;
  int _usersAtLimit = 0;

  // Users List
  List<Map<String, dynamic>> _userList = [];
  int _currentPage = 1;
  final int _pageSize = 10;
  int _totalPages = 1;
  int _totalUsersCount = 0;
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
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email?.toLowerCase().trim() ?? '';
    final targetAdminEmail = BackendConfig.adminEmail.toLowerCase().trim();

    final appRole = user?.appMetadata['role'];
    final safeUserRole = user?.userMetadata?['role'];

    // Check if email or metadata indicates admin
    final isAdmin = auth.isAdmin ||
        (userEmail.isNotEmpty && userEmail == targetAdminEmail) ||
        appRole == 'admin' ||
        safeUserRole == 'admin';

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
      final res = await Supabase.instance.client.rpc('get_admin_dashboard_stats');
      if (res != null && res is Map) {
        final data = Map<String, dynamic>.from(res);
        if (mounted) {
          setState(() {
            _totalUsers = (data['totalUsers'] as num? ?? 0).toInt();
            _activeUsersToday = (data['activeUsersToday'] as num? ?? 0).toInt();
            _resumesGeneratedToday = (data['resumesGeneratedToday'] as num? ?? 0).toInt();
            _usersAtLimit = (data['usersAtLimit'] as num? ?? 0).toInt();
            _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[AdminDashboard] Stats RPC error: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final res = await Supabase.instance.client.rpc('get_admin_users');
      if (res != null && res is List) {
        final allUsers = List<Map<String, dynamic>>.from(
          res.map((item) => Map<String, dynamic>.from(item as Map)),
        );

        List<Map<String, dynamic>> filtered = allUsers;
        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.trim().toLowerCase();
          filtered = allUsers.where((u) {
            final email = (u['email'] as String? ?? '').toLowerCase();
            final userId = (u['user_id'] as String? ?? '').toLowerCase();
            return email.contains(query) || userId.contains(query);
          }).toList();
        }

        final total = filtered.length;
        final totalPages = (total / _pageSize).ceil();
        final safeTotalPages = totalPages < 1 ? 1 : totalPages;
        final safePage = _currentPage.clamp(1, safeTotalPages);
        final startIndex = (safePage - 1) * _pageSize;
        final endIndex = (startIndex + _pageSize).clamp(0, total);
        final pagedUsers = filtered.isEmpty ? <Map<String, dynamic>>[] : filtered.sublist(startIndex, endIndex);

        if (mounted) {
          setState(() {
            _userList = pagedUsers;
            _totalUsersCount = total;
            _totalPages = safeTotalPages;
            _currentPage = safePage;
            _isLoadingUsers = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[AdminDashboard] get_admin_users RPC error: $e');
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
          _userList = [];
        });
      }
    }
  }

  Future<void> _updateUserLimit(String userId, int newLimit) async {
    try {
      await Supabase.instance.client.rpc(
        'update_user_resume_limit',
        params: {
          'p_user_id': userId,
          'p_new_limit': newLimit,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('Updated limit to $newLimit generations/day!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: Text('Reset Daily Usage?', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'This will reset today\'s resume generation counter to 0 for $userEmail.',
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
      await Supabase.instance.client.rpc(
        'reset_user_resume_usage',
        params: {
          'p_user_id': userId,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text('Usage reset successfully!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showEditLimitModal(String userId, String email, int currentLimit) {
    final controller = TextEditingController(text: '$currentLimit');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Daily Limit',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set daily resume generation limit for $email:',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8B949E), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Daily Resume Limit',
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
            ),
          ],
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
                _updateUserLimit(userId, newLim);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: Text('Save Limit', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryOrange),
        ),
      );
    }

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
                  'Admin privileges are required to access user quota controls and usage dashboards.',
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
                  child: Text('Return to Editor', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 10),
            Text(
              'JobWink Admin Dashboard',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryOrange),
            onPressed: () {
              _loadStats();
              _loadUsers();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Overview Cards Row
            Text(
              'System Usage & Quotas',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;
                final cards = [
                  _buildStatCard('Total Users', _isLoadingStats ? '...' : '$_totalUsers', Icons.people_outline, const Color(0xFF3B82F6)),
                  _buildStatCard('Active Today', _isLoadingStats ? '...' : '$_activeUsersToday', Icons.bolt, const Color(0xFF10B981)),
                  _buildStatCard('Resumes Generated', _isLoadingStats ? '...' : '$_resumesGeneratedToday', Icons.file_copy_outlined, AppTheme.primaryOrange),
                  _buildStatCard('Users At Limit', _isLoadingStats ? '...' : '$_usersAtLimit', Icons.lock_clock, const Color(0xFFEF4444)),
                ];

                if (isWide) {
                  return Row(
                    children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList(),
                  );
                } else {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: cards.map((c) => SizedBox(width: (constraints.maxWidth - 12) / 2, child: c)).toList(),
                  );
                }
              },
            ),
            const SizedBox(height: 32),

            // Users Table Controls Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                      'Total Registrations: $_totalUsersCount',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF8B949E)),
                    ),
                  ],
                ),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _currentPage = 1;
                      });
                      _loadUsers();
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
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Users List Table
            if (_isLoadingUsers)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.primaryOrange)))
            else if (_userList.isEmpty)
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
                    ..._userList.map((user) => _buildUserRow(user)),
                    if (_totalPages > 1) ...[
                      const Divider(color: Color(0xFF30363D), height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Page $_currentPage of $_totalPages',
                              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8B949E), fontSize: 13),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _currentPage > 1
                                      ? () {
                                          setState(() => _currentPage--);
                                          _loadUsers();
                                        }
                                      : null,
                                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                                ),
                                IconButton(
                                  onPressed: _currentPage < _totalPages
                                      ? () {
                                          setState(() => _currentPage++);
                                          _loadUsers();
                                        }
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

  Widget _buildUserRow(Map<String, dynamic> user) {
    final userId = user['user_id'] as String? ?? '';
    final email = user['email'] as String? ?? 'User';
    final limit = (user['daily_limit'] as num? ?? 4).toInt();
    final used = (user['resumes_generated_today'] as num? ?? 0).toInt();
    final remaining = (user['remaining'] as num? ?? (limit - used).clamp(0, 99999)).toInt();
    final usageDate = user['usage_date']?.toString() ?? '';

    final isAtLimit = used >= limit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF21262D))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.2),
            child: Text(
              email.isNotEmpty ? email[0].toUpperCase() : 'U',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (usageDate.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Usage Date: $usageDate',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8B949E), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAtLimit
                  ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                  : const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isAtLimit ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$used / $limit Used',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isAtLimit ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
                Text(
                  '($remaining remaining)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: isAtLimit ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              IconButton(
                onPressed: () => _showEditLimitModal(userId, email, limit),
                tooltip: 'Edit Quota Limit',
                icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryOrange, size: 18),
              ),
              IconButton(
                onPressed: () => _resetUserUsage(userId, email),
                tooltip: 'Reset Today\'s Usage',
                icon: const Icon(Icons.restore_rounded, color: Color(0xFF8B949E), size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
