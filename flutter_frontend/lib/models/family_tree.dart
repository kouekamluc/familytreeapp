class FamilyTree {
  final int id;
  final String name;
  final String description;
  final String? owner;
  final int membersCount;
  final bool isPublic;
  final bool canEdit;
  final bool canManage;
  final int peopleCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FamilyTree({
    required this.id,
    required this.name,
    this.description = '',
    this.owner,
    this.membersCount = 0,
    this.isPublic = false,
    this.canEdit = false,
    this.canManage = false,
    this.peopleCount = 0,
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
    } else if (json['members'] is List) {
      count = (json['members'] as List).length;
    }

    return FamilyTree(
      id: parsedId,
      name: json['name'] ?? 'Kkevo Family',
      description: json['description'] ?? '',
      owner: json['owner'] is String ? json['owner'] : null,
      membersCount: count,
      isPublic: json['is_public'] == true,
      canEdit: json['can_edit'] == true,
      canManage: json['can_manage'] == true,
      peopleCount: json['people_count'] is int ? json['people_count'] : 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_public': isPublic,
      'owner': owner,
      'members': membersCount,
      'people_count': peopleCount,
      'can_edit': canEdit,
      'can_manage': canManage,
    };
  }

  FamilyTree withPeopleCount(int count) => FamilyTree(
    id: id,
    name: name,
    description: description,
    owner: owner,
    membersCount: membersCount,
    isPublic: isPublic,
    canEdit: canEdit,
    canManage: canManage,
    peopleCount: count,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
