class Relationship {
  final int id;
  final int person1Id;
  final int person2Id;
  final String relationshipType; // 'PARENT', 'SPOUSE', 'SIBLING', etc.
  final String? notes;

  Relationship({
    required this.id,
    required this.person1Id,
    required this.person2Id,
    required this.relationshipType,
    this.notes,
  });

  bool get isParent => relationshipType.toUpperCase() == 'PARENT';
  bool get isSpouse => relationshipType.toUpperCase() == 'SPOUSE';
  bool get isSibling => relationshipType.toUpperCase() == 'SIBLING';

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
      person1Id: p1,
      person2Id: p2,
      relationshipType: (json['relationship_type'] ?? json['type'] ?? 'PARENT').toString().toUpperCase(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'person1': person1Id,
      'person2': person2Id,
      'relationship_type': relationshipType,
      if (notes != null) 'notes': notes,
    };
  }
}
