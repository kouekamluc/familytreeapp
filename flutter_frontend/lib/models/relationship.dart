class Relationship {
  final int id;
  final int revision;
  final int person1Id;
  final int person2Id;
  final String relationshipType; // 'PARENT', 'SPOUSE', 'SIBLING', etc.
  final String? notes;
  final String? startDate;
  final String? endDate;
  final bool isCurrent;

  Relationship({
    required this.id,
    this.revision = 1,
    required this.person1Id,
    required this.person2Id,
    required this.relationshipType,
    this.notes,
    this.startDate,
    this.endDate,
    this.isCurrent = true,
  });

  bool get isParent =>
      ['PARENT', 'ADOPTED', 'STEP'].contains(relationshipType.toUpperCase());
  bool get isSpouse => relationshipType.toUpperCase() == 'SPOUSE' && isCurrent;
  bool get isSibling => relationshipType.toUpperCase() == 'SIBLING';
  bool get isSpousalLink => relationshipType.toUpperCase() == 'SPOUSE';
  String get label => switch (relationshipType.toUpperCase()) {
    'PARENT' => 'Parent → child',
    'ADOPTED' => 'Adoptive parent → child',
    'STEP' => 'Stepparent → child',
    'SIBLING' => 'Sibling',
    'SPOUSE' => isCurrent ? 'Partners' : 'Former partners',
    _ => relationshipType,
  };

  factory Relationship.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    if (json['id'] is int) {
      parsedId = json['id'];
    } else if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    int p1 = 0;
    if (json['person1'] is int) {
      p1 = json['person1'];
    } else if (json['person1'] is Map) {
      p1 = json['person1']['id'] ?? 0;
    } else if (json['person1_id'] != null) {
      p1 = int.tryParse(json['person1_id'].toString()) ?? 0;
    } else if (json['source'] != null) {
      p1 = int.tryParse(json['source'].toString()) ?? 0;
    }

    int p2 = 0;
    if (json['person2'] is int) {
      p2 = json['person2'];
    } else if (json['person2'] is Map) {
      p2 = json['person2']['id'] ?? 0;
    } else if (json['person2_id'] != null) {
      p2 = int.tryParse(json['person2_id'].toString()) ?? 0;
    } else if (json['target'] != null) {
      p2 = int.tryParse(json['target'].toString()) ?? 0;
    }

    return Relationship(
      id: parsedId,
      revision: json['revision'] as int? ?? 1,
      person1Id: p1,
      person2Id: p2,
      relationshipType: (json['relationship_type'] ?? json['type'] ?? 'PARENT')
          .toString()
          .toUpperCase(),
      notes: json['notes'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      isCurrent: json['is_current'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'revision': revision,
      'person1': person1Id,
      'person2': person2Id,
      'relationship_type': relationshipType,
      'start_date': startDate,
      'end_date': endDate,
      'is_current': isCurrent,
      if (notes != null) 'notes': notes,
    };
  }
}
