class FamilyTree {
  final int id;
  final String name;
  final String description;
  final String? owner;
  final int membersCount;
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FamilyTree({
    required this.id,
    required this.name,
    this.description = '',
    this.owner,
    this.membersCount = 0,
    this.isPublic = false,
    this.createdAt,
    this.updatedAt,
  });

  factory FamilyTree.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    if (json['id'] is int) {
      parsedId = json['id'];
    } else if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    int count = 0;
    if (json['members'] is int) {
      count = json['members'];
    } else if (json['people'] is List) {
      count = (json['people'] as List).length;
    }

    return FamilyTree(
      id: parsedId,
      name: json['name'] ?? 'Royal Family Tree',
      description: json['description'] ?? '',
      owner: json['owner'] is String ? json['owner'] : null,
      membersCount: count,
      isPublic: json['is_public'] == true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_public': isPublic,
    };
  }
}
