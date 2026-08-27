import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/avatar_image_helper.dart';

/// Dynamic, interactive User Profile Card with avatar photo upload capability.
class UserProfileCard extends StatefulWidget {
  final AppUser? user;
  final bool isLoading;
  final bool compact;

  const UserProfileCard({
    super.key,
    this.user,
    this.isLoading = false,
    this.compact = false,
  });

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  bool _isHoveringAvatar = false;
  bool _isUploadingAvatar = false;

  Future<void> _handleAvatarPick(AppUser? effectiveUser) async {
    if (effectiveUser == null || _isUploadingAvatar) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final fileExtension = file.extension?.toLowerCase() ?? '';
      final bytes = file.bytes;
      final size = file.size;

      // 1. Extension Validation
      if (!_allowedExtensions.contains(fileExtension)) {
        _showSnackBar(
          'Please select a JPG, JPEG, PNG, or WEBP image.',
          isError: true,
        );
        return;
      }

      // 2. File Size Validation (Max 5MB)
      if (size > _maxFileSizeBytes || bytes == null) {
        _showSnackBar(
          'Image size exceeds 5MB. Please choose a smaller photo.',
          isError: true,
        );
        return;
      }

      // 3. Upload Profile Photo
      if (!mounted) return;
      setState(() => _isUploadingAvatar = true);

      final auth = AuthProviderScope.read(context);
      final success = await auth.uploadAvatar(
        fileBytes: bytes,
        fileExtension: fileExtension,
      );

      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        if (success) {
          _showSnackBar('Profile photo updated successfully!');
        } else {
          _showSnackBar(
            auth.errorMessage ?? 'Failed to upload profile photo.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        _showSnackBar('Error picking photo: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthProviderScope.of(context);
    final effectiveUser = widget.user ?? auth.currentUser;
    final isDark = AppTheme.isDarkMode(context);

    if (widget.isLoading || effectiveUser == null) {
      return _buildSkeletonCard(context);
    }

    final initials = effectiveUser.initials;
    final displayName = effectiveUser.displayName;
    final email = effectiveUser.email;

    final avatarSize = widget.compact ? 44.0 : 64.0;
    final fontSizeName = widget.compact ? 14.0 : 18.0;
    final fontSizeEmail = widget.compact ? 11.0 : 13.0;
    final cardPadding = widget.compact ? const EdgeInsets.all(12.0) : const EdgeInsets.all(20.0);
    final cardRadius = widget.compact ? 14.0 : 20.0;

    return Container(
      padding: cardPadding,
      decoration: BoxDecoration(
        color: widget.compact ? const Color(0xFF161B22) : AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: widget.compact ? const Color(0xFF30363D) : AppTheme.getBorderColor(context),
        ),
        boxShadow: widget.compact
            ? null
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          // ── Circular Avatar with Click/Hover Action ───────────────────────
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHoveringAvatar = true),
            onExit: (_) => setState(() => _isHoveringAvatar = false),
            child: GestureDetector(
              onTap: () => _handleAvatarPick(effectiveUser),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Base Avatar
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: AvatarImageHelper.buildAvatarImage(
                        avatarUrl: effectiveUser.avatarUrl,
                        initials: initials,
                        width: avatarSize,
                        height: avatarSize,
                        fallbackBuilder: (context, initVal) => Center(
                          child: Text(
                            initVal,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: widget.compact ? 15 : 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Hover Overlay (Camera Icon)
                  if (_isHoveringAvatar && !_isUploadingAvatar)
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: widget.compact ? 14 : 20,
                          ),
                          if (!widget.compact) ...[
                            const SizedBox(height: 2),
                            const Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Upload Progress Overlay
                  if (_isUploadingAvatar)
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.65),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: widget.compact ? 16 : 22,
                          height: widget.compact ? 16 : 22,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: widget.compact ? 12 : 16),

          // ── User Information (Name, Email ONLY - No fake job titles) ──────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: fontSizeName,
                    fontWeight: FontWeight.w800,
                    color: widget.compact ? Colors.white : AppTheme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 2),

                // Email Address
                Tooltip(
                  message: email,
                  child: Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: fontSizeEmail,
                      color: widget.compact
                          ? const Color(0xFF8B949E)
                          : AppTheme.getMutedTextColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final avatarSize = widget.compact ? 44.0 : 64.0;
    final cardPadding = widget.compact ? const EdgeInsets.all(12.0) : const EdgeInsets.all(20.0);
    final cardRadius = widget.compact ? 14.0 : 20.0;

    return Container(
      padding: cardPadding,
      decoration: BoxDecoration(
        color: widget.compact ? const Color(0xFF161B22) : AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: widget.compact ? const Color(0xFF30363D) : AppTheme.getBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.getBorderColor(context).withValues(alpha: 0.5),
            ),
          ),
          SizedBox(width: widget.compact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: widget.compact ? 14 : 16,
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(context).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 160,
                  height: widget.compact ? 10 : 12,
                  decoration: BoxDecoration(
                    color: AppTheme.getBorderColor(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
