/// Typed representation of a row from `public.profiles`.
///
/// All fields are nullable (except [id] and [email]) because a freshly
/// created OAuth user may not yet have filled in optional profile fields.
class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final String? location;
  final String? linkedinUrl;
  final String? githubUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.location,
    this.linkedinUrl,
    this.githubUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an [AppUser] from a Supabase `public.profiles` row map.
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      phone: map['phone'] as String?,
      location: map['location'] as String?,
      linkedinUrl: map['linkedin_url'] as String?,
      githubUrl: map['github_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Serialises the mutable profile fields for upsert/update calls.
  Map<String, dynamic> toUpdateMap() {
    return {
      if (fullName != null) 'full_name': fullName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (phone != null) 'phone': phone,
      if (location != null) 'location': location,
      if (linkedinUrl != null) 'linkedin_url': linkedinUrl,
      if (githubUrl != null) 'github_url': githubUrl,
    };
  }

  /// Returns a copy with overridden fields.
  AppUser copyWith({
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? location,
    String? linkedinUrl,
    String? githubUrl,
  }) {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Convenience: display name falls back to the part before '@' in the email.
  String get displayName =>
      fullName?.isNotEmpty == true ? fullName! : email.split('@').first;

  /// Generates initials from the user's name or display name.
  /// Examples: "Arun Singh" -> "AS", "Nishant Arya" -> "NA", "Arun" -> "A"
  String get initials {
    final nameToUse = (fullName != null && fullName!.trim().isNotEmpty)
        ? fullName!.trim()
        : (displayName.isNotEmpty ? displayName.trim() : '');

    if (nameToUse.isEmpty) return 'U';

    final parts =
        nameToUse.split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
