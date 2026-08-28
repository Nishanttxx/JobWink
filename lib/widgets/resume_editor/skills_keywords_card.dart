import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/jd_keyword_engine.dart';
import '../../theme/app_theme.dart';



class SkillsKeywordsCard extends StatefulWidget {
  final List<String> skills;
  final List<JobKeyword>? jobKeywords;
  final List<String> suggestedKeywords;
  final Function(String skill) onAddSkill;
  final Function(String skill) onRemoveSkill;

  const SkillsKeywordsCard({
    super.key,
    required this.skills,
    this.jobKeywords,
    required this.suggestedKeywords,
    required this.onAddSkill,
    required this.onRemoveSkill,
  });

  @override
  State<SkillsKeywordsCard> createState() => _SkillsKeywordsCardState();
}

class _SkillsKeywordsCardState extends State<SkillsKeywordsCard> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _filterQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final text = _searchController.text.trim();
    if (text.isNotEmpty) {
      widget.onAddSkill(text);
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);

    // Map keywords to priority/relevance if available
    final Map<String, String> priorityMap = {};
    if (widget.jobKeywords != null) {
      for (final jk in widget.jobKeywords!) {
        priorityMap[jk.keyword.toLowerCase()] = jk.priority;
      }
    }

    final filteredSkills = widget.skills.where((s) {
      if (_filterQuery.isEmpty) return true;
      return s.toLowerCase().contains(_filterQuery);
    }).toList();

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
          // Card Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Skills & Keywords',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const Spacer(),
              Text(
                '${widget.skills.length} Skills',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getMutedTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dynamic Keyword Analysis Panel
          if (widget.jobKeywords != null && widget.jobKeywords!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics_outlined, size: 14, color: AppTheme.primaryOrange),
                      const SizedBox(width: 6),
                      Text(
                        'AI Keyword Analysis Panel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildSummaryBadge(
                        label: 'MATCHED: ${widget.jobKeywords!.where((k) => k.matched).length}',
                        color: const Color(0xFF10B981),
                      ),
                      _buildSummaryBadge(
                        label: 'MISSING: ${widget.jobKeywords!.where((k) => !k.matched).length}',
                        color: const Color(0xFFEF4444),
                      ),
                      _buildSummaryBadge(
                        label: 'HIGH PRIORITY: ${widget.jobKeywords!.where((k) => k.priority == "high").length}',
                        color: AppTheme.primaryOrange,
                      ),
                      _buildSummaryBadge(
                        label: 'MEDIUM PRIORITY: ${widget.jobKeywords!.where((k) => k.priority == "medium").length}',
                        color: const Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Search & Filter Input Row with Add Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _handleAdd(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.getTextColor(context),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: 'Search or add skills...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.getMutedTextColor(context).withValues(alpha: 0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppTheme.getMutedTextColor(context),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDarkMode ? const Color(0xFF30363D) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _handleAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Add',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Skill Chips Container (Matching Image Badges Exactly)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredSkills.map((skill) {
              final prio = priorityMap[skill.toLowerCase()];
              final isHighRelevance = prio == 'high';
              final isMedRelevance = prio == 'medium';

              Color chipBg;
              Color chipBorder;
              Color textColor;

              if (isHighRelevance) {
                chipBg = AppTheme.primaryOrange.withValues(alpha: 0.22);
                chipBorder = AppTheme.primaryOrange;
                textColor = isDarkMode ? Colors.white : AppTheme.primaryOrange;
              } else if (isMedRelevance) {
                chipBg = AppTheme.primaryOrange.withValues(alpha: 0.12);
                chipBorder = AppTheme.primaryOrange.withValues(alpha: 0.5);
                textColor = isDarkMode ? const Color(0xFFFF9D5C) : const Color(0xFFD97706);
              } else {
                chipBg = isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9);
                chipBorder = isDarkMode ? const Color(0xFF30363D) : const Color(0xFFE2E8F0);
                textColor = AppTheme.getTextColor(context);
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: chipBorder, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skill,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: (isHighRelevance || isMedRelevance)
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => widget.onRemoveSkill(skill),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          // Missing / Recommended Skills Section
          if (widget.suggestedKeywords.isNotEmpty) ...[
            const SizedBox(height: 18),
            Divider(color: isDarkMode ? const Color(0xFF21262D) : const Color(0xFFE2E8F0)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.stars_rounded, size: 14, color: AppTheme.primaryOrange),
                const SizedBox(width: 6),
                Text(
                  'Recommended Job Keywords (Not in Resume):',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getMutedTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.suggestedKeywords.map((keyword) {
                return InkWell(
                  onTap: () => widget.onAddSkill(keyword),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 12, color: AppTheme.primaryOrange),
                        const SizedBox(width: 4),
                        Text(
                          keyword,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
