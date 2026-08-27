import 'resume_data.dart';
import 'user_resume.dart';

/// Represents a historical resume version record for an authenticated user.
class ResumeHistoryItem {
  final String id;
  final String resumeId;
  final String userId;
  final int versionNumber;
  final String title;
  final String? targetRole;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ResumeData resumeData;
  final String? changeSummary;
  final CvTemplateType templateType;

  const ResumeHistoryItem({
    required this.id,
    required this.resumeId,
    required this.userId,
    required this.versionNumber,
    required this.title,
    this.targetRole,
    required this.createdAt,
    required this.updatedAt,
    required this.resumeData,
    this.changeSummary,
    this.templateType = CvTemplateType.nationalAts,
  });

  /// Formatted date string for display (e.g. "Aug 27, 2026")
  String get formattedUpdatedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[updatedAt.month - 1]} ${updatedAt.day}, ${updatedAt.year}';
  }

  /// Formatted created date string for display (e.g. "Aug 27, 2026")
  String get formattedCreatedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }

  /// Constructs a [ResumeHistoryItem] from a Supabase row (from `resume_versions` joined with `resumes`).
  factory ResumeHistoryItem.fromMap(Map<String, dynamic> row) {
    final rawContent = row['parsed_content'] ?? row['extracted_data'] ?? {};
    final contentMap = rawContent is Map<String, dynamic>
        ? rawContent
        : <String, dynamic>{};

    final resumeData = ResumeData.validateAndSanitizeAll(
      ResumeData.fromJson(contentMap),
    );

    final versionNum = (row['version_number'] as num?)?.toInt() ?? 1;

    // Determine target role / job title if available
    String? role;
    if (resumeData.title.trim().isNotEmpty) {
      role = resumeData.title.trim();
    } else if (resumeData.experience.isNotEmpty &&
        resumeData.experience.first.role.trim().isNotEmpty) {
      role = resumeData.experience.first.role.trim();
    }

    // Determine clean display title without inventing fake data
    String displayTitle = '';
    final resumeRow = row['resumes'] as Map<String, dynamic>?;
    final parentTitle = resumeRow?['title'] as String?;

    if (resumeData.title.trim().isNotEmpty) {
      final t = resumeData.title.trim();
      displayTitle = t.toLowerCase().endsWith('resume') ? t : '$t Resume';
    } else if (parentTitle != null &&
        parentTitle.trim().isNotEmpty &&
        parentTitle.trim() != 'Master Resume') {
      displayTitle = parentTitle.trim();
    } else if (resumeData.fullName.trim().isNotEmpty) {
      displayTitle = '${resumeData.fullName.trim()} Resume';
    } else {
      displayTitle = 'Resume v$versionNum';
    }

    final templateStr = (resumeRow?['template_type'] ?? row['template_type']) as String?;
    final template = templateStr == 'INTERNATIONAL_GLOBAL'
        ? CvTemplateType.internationalGlobal
        : CvTemplateType.nationalAts;

    final createdStr = row['created_at']?.toString();
    final updatedStr = row['updated_at']?.toString() ?? createdStr;

    return ResumeHistoryItem(
      id: row['id']?.toString() ?? '',
      resumeId: row['resume_id']?.toString() ?? row['id']?.toString() ?? '',
      userId: row['user_id']?.toString() ?? '',
      versionNumber: versionNum,
      title: displayTitle,
      targetRole: role,
      createdAt: createdStr != null ? (DateTime.tryParse(createdStr) ?? DateTime.now()) : DateTime.now(),
      updatedAt: updatedStr != null ? (DateTime.tryParse(updatedStr) ?? DateTime.now()) : DateTime.now(),
      resumeData: resumeData,
      changeSummary: row['change_summary'] as String?,
      templateType: template,
    );
  }
}
