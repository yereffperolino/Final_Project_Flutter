class DashboardProfile {
  const DashboardProfile({
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });

  final String? displayName;
  final String? email;
  final String? photoUrl;

  String get userName {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email?.split('@').first ?? 'Admin';
  }
}
