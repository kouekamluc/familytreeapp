class HeritageKey {
  final int id;
  final String key;
  final int? userId;
  final String? username;
  final String name;
  final String role;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime? lastUsedAt;
  final int usageCount;
  final DateTime? createdAt;

  HeritageKey({
    required this.id,
    required this.key,
    this.userId,
    this.username,
    required this.name,
    required this.role,
    required this.isActive,
    this.expiresAt,
    this.lastUsedAt,
    required this.usageCount,
    this.createdAt,
  });

  String get roleDisplay {
    switch (role) {
      case 'ROYAL_PATRIARCH':
        return 'Family elder';
      case 'CURATOR':
        return 'Editor';
      case 'FAMILY_MEMBER':
        return 'Family member';
      case 'GUEST_VIEWER':
        return 'Viewer';
      default:
        return role;
    }
  }

  factory HeritageKey.fromJson(Map<String, dynamic> json) {
    return HeritageKey(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      key: json['key'] ?? '',
      userId: json['user'],
      username: json['username'],
      name: json['name'] ?? 'Personal key',
      role: json['role'] ?? 'FAMILY_MEMBER',
      isActive: json['is_active'] ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.tryParse(json['last_used_at'])
          : null,
      usageCount: json['usage_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'user': userId,
      'username': username,
      'name': name,
      'role': role,
      'is_active': isActive,
      'expires_at': expiresAt?.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'usage_count': usageCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
