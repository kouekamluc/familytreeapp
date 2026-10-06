import '../models/person.dart';
import '../models/relationship.dart';

class FamilyKinshipSummary {
  final String
  lineageRole; // e.g., "Great-Grandfather", "Father", "Great-Granddaughter"
  final String
  culturalRole; // e.g., "Patriarch 👑", "Royal Matron", "4th-Gen Princess"
  final Person? father;
  final Person? mother;
  final List<Person> spouses;
  final List<Person> sons;
  final List<Person> daughters;
  final List<Person> brothers;
  final List<Person> sisters;
  final List<Person> otherChildren;
  final List<Person> otherSiblings;

  FamilyKinshipSummary({
    required this.lineageRole,
    required this.culturalRole,
    this.father,
    this.mother,
    required this.spouses,
    required this.sons,
    required this.daughters,
    required this.brothers,
    required this.sisters,
    this.otherChildren = const [],
    this.otherSiblings = const [],
  });

  List<Person> get allChildren => [...sons, ...daughters, ...otherChildren];
  List<Person> get allSiblings => [...brothers, ...sisters, ...otherSiblings];
}

class GenealogyHelper {
  static FamilyKinshipSummary getKinshipSummary(
    Person person,
    List<Person> allPeople,
    List<Relationship> relationships,
  ) {
    final peopleMap = {for (var p in allPeople) p.id: p};

    // Find Parents
    final parentIds = relationships
        .where((r) => r.person2Id == person.id && r.isParent)
        .map((r) => r.person1Id)
        .toList();

    Person? father;
    Person? mother;
    for (final pid in parentIds) {
      final p = peopleMap[pid];
      if (p != null) {
        if (p.isMale && father == null) {
          father = p;
        } else if (p.isFemale && mother == null) {
          mother = p;
        }
      }
    }

    // Find Spouses
    final spouseIds = <int>{};
    for (final r in relationships) {
      if (r.isSpouse) {
        if (r.person1Id == person.id) spouseIds.add(r.person2Id);
        if (r.person2Id == person.id) spouseIds.add(r.person1Id);
      }
    }
    final spouses = spouseIds
        .map((id) => peopleMap[id])
        .whereType<Person>()
        .toList();

    // Find Children
    final childIds = relationships
        .where((r) => r.person1Id == person.id && r.isParent)
        .map((r) => r.person2Id)
        .toList();
    final sons = <Person>[];
    final daughters = <Person>[];
    final otherChildren = <Person>[];
    for (final cid in childIds) {
      final c = peopleMap[cid];
      if (c != null) {
        if (c.isMale) {
          sons.add(c);
        } else if (c.isFemale) {
          daughters.add(c);
        } else {
          otherChildren.add(c);
        }
      }
    }

    final siblingIds = relationships
        .where(
          (r) =>
              r.isParent &&
              parentIds.contains(r.person1Id) &&
              r.person2Id != person.id,
        )
        .map((r) => r.person2Id)
        .toSet();
    for (final r in relationships.where((r) => r.isSibling)) {
      if (r.person1Id == person.id) siblingIds.add(r.person2Id);
      if (r.person2Id == person.id) siblingIds.add(r.person1Id);
    }
    final siblings = siblingIds
        .map((id) => peopleMap[id])
        .whereType<Person>()
        .toList();
    final brothers = siblings.where((p) => p.isMale).toList();
    final sisters = siblings.where((p) => p.isFemale).toList();
    final otherSiblings = siblings
        .where((p) => !p.isMale && !p.isFemale)
        .toList();

    // Generation numbers alone cannot establish grandparenthood or royal titles.
    final hasChildren = childIds.isNotEmpty;
    final lineageRole = hasChildren
        ? (person.isMale
              ? 'Father'
              : person.isFemale
              ? 'Mother'
              : 'Parent')
        : parentIds.isNotEmpty
        ? 'Child'
        : siblingIds.isNotEmpty
        ? 'Siblings'
        : 'Family member';
    final culturalRole = (person.traditionalName ?? '').trim().isNotEmpty
        ? person.traditionalName!.trim()
        : 'Family member';

    return FamilyKinshipSummary(
      lineageRole: lineageRole,
      culturalRole: culturalRole,
      father: father,
      mother: mother,
      spouses: spouses,
      sons: sons,
      daughters: daughters,
      brothers: brothers,
      sisters: sisters,
      otherChildren: otherChildren,
      otherSiblings: otherSiblings,
    );
  }
}
