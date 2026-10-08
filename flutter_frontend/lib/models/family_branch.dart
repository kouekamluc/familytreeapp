import 'person.dart';
import 'relationship.dart';

class FamilyBranch {
  final int id, rootId, attachmentId, revision;
  final String label, connection, status;
  final List<Person> people;
  final List<Relationship> relationships;
  final bool active;
  final int? sourceTreeId, targetTreeId;
  final String targetName, attachmentName;
  const FamilyBranch({
    required this.id,
    required this.rootId,
    required this.attachmentId,
    required this.revision,
    required this.label,
    required this.connection,
    required this.status,
    required this.people,
    required this.relationships,
    required this.active,
    this.sourceTreeId,
    this.targetTreeId,
    this.targetName = '',
    this.attachmentName = '',
  });
  int get portalId => -1000000000 - id;
  String get connectionLabel => switch (connection) {
    'EXISTING' => 'Same person',
    'CHILD' => 'Child',
    'SIBLING' => 'Sibling',
    _ => 'Partner',
  };
  factory FamilyBranch.fromJson(Map<String, dynamic> data) => FamilyBranch(
    id: data['id'] as int,
    rootId: data['root_id'] as int,
    attachmentId: data['attachment_id'] as int,
    revision: data['revision'] as int,
    label: data['label'] as String,
    connection: data['connection'] as String,
    status: data['status'] as String,
    active: data['active'] == true,
    sourceTreeId: data['source_tree_id'] as int?,
    targetTreeId: data['target_tree_id'] as int?,
    targetName: data['target_name'] as String? ?? '',
    attachmentName: data['attachment_name'] as String? ?? '',
    people: (data['people'] as List)
        .map((p) => Person.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList(),
    relationships: (data['relationships'] as List)
        .map((r) => Relationship.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList(),
  );
}
