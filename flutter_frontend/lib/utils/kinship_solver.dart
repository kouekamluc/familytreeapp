import '../models/person.dart';
import '../models/relationship.dart';

class KinshipResult {
  final String title;
  final String relationship;
  final String summary;
  final String description;
  final String culturalHonorific;
  final int generationDifference;
  final List<Person> path;

  KinshipResult({
    required this.title,
    required this.relationship,
    required this.summary,
    required this.description,
    required this.culturalHonorific,
    required this.generationDifference,
    required this.path,
  });
}

class KinshipSolver {
  static KinshipResult? calculateKinship({
    required int personAId,
    required int personBId,
    required List<Person> people,
    required List<Relationship> relationships,
  }) {
    final persons = {for (final p in people) p.id: p};
    final a = persons[personAId], b = persons[personBId];
    if (a == null || b == null) return null;
    String gendered(String male, String female, String neutral) => b.isMale
        ? male
        : b.isFemale
        ? female
        : neutral;
    KinshipResult result(
      String label,
      List<int> route,
      int difference,
      String explanation,
    ) => KinshipResult(
      title: label,
      relationship: label,
      summary: '${b.fullName}: $label of ${a.fullName}.',
      description: explanation,
      culturalHonorific: (b.traditionalName ?? '').trim(),
      generationDifference: difference,
      path: route.map((id) => persons[id]!).toList(),
    );
    if (a.id == b.id) {
      return result('Same person', [a.id], 0, 'Selected profile.');
    }
    final graph = <int, List<({int target, String direction, String kind})>>{};
    void edge(int from, int to, String direction, String kind) {
      if (persons.containsKey(from) && persons.containsKey(to)) {
        graph.putIfAbsent(from, () => []).add((
          target: to,
          direction: direction,
          kind: kind,
        ));
      }
    }

    final sorted = [...relationships]..sort((x, y) => x.id.compareTo(y.id));
    final direct = sorted
        .where(
          (r) =>
              (r.person1Id == a.id && r.person2Id == b.id) ||
              (r.person2Id == a.id && r.person1Id == b.id),
        )
        .toList();
    for (final r in direct) {
      final parent = r.person1Id == b.id;
      final type = r.relationshipType.toUpperCase();
      String? label;
      var delta = 0;
      if (r.isParent) {
        delta = parent ? 1 : -1;
        label = type == 'ADOPTED'
            ? (parent ? 'Adoptive parent' : 'Adopted child')
            : type == 'STEP'
            ? (parent ? 'Stepparent' : 'Stepchild')
            : parent
            ? gendered('Father', 'Mother', 'Parent')
            : gendered('Son', 'Daughter', 'Child');
      } else if (r.isSpousalLink) {
        label = r.isCurrent
            ? gendered('Husband / partner', 'Wife / partner', 'Partner')
            : gendered('Former husband', 'Former wife', 'Former partner');
      } else if (r.isSibling) {
        label = gendered('Brother', 'Sister', 'Siblings');
      }
      if (label != null) {
        return result(
          label,
          [a.id, b.id],
          delta,
          '${r.label}: recorded connection in this family.',
        );
      }
    }
    for (final r in sorted) {
      if (r.isParent) {
        edge(
          r.person1Id,
          r.person2Id,
          'child',
          r.relationshipType.toUpperCase(),
        );
        edge(
          r.person2Id,
          r.person1Id,
          'parent',
          r.relationshipType.toUpperCase(),
        );
      } else if (r.isSpouse || r.isSibling) {
        final direction = r.isSpouse ? 'spouse' : 'sibling';
        edge(
          r.person1Id,
          r.person2Id,
          direction,
          r.relationshipType.toUpperCase(),
        );
        edge(
          r.person2Id,
          r.person1Id,
          direction,
          r.relationshipType.toUpperCase(),
        );
      }
    }
    final routes = <List<int>>[
      [a.id],
    ];
    final seen = <int>{a.id};
    List<int>? path;
    for (var cursor = 0; cursor < routes.length; cursor++) {
      final route = routes[cursor];
      if (route.last == b.id) {
        path = route;
        break;
      }
      for (final link
          in graph[route.last] ??
              <({int target, String direction, String kind})>[]) {
        if (seen.add(link.target)) routes.add([...route, link.target]);
      }
    }
    if (path == null) {
      return result(
        'Unconnected branches',
        [a.id, b.id],
        0,
        'No family path is recorded between these profiles.',
      );
    }
    final steps = [
      for (var i = 0; i < path.length - 1; i++)
        graph[path[i]]!.firstWhere((e) => e.target == path![i + 1]),
    ];
    final delta = steps.fold<int>(
      0,
      (v, e) =>
          v +
          (e.direction == 'parent'
              ? 1
              : e.direction == 'child'
              ? -1
              : 0),
    );
    final directions = steps.map((e) => e.direction).join(',');
    final social = steps.any((e) => e.kind == 'ADOPTED' || e.kind == 'STEP');
    String label = 'Family relationship';
    if (social) {
      label = steps.any((e) => e.kind == 'ADOPTED')
          ? 'Relationship through adoption'
          : 'Relationship through a blended family';
    } else if (steps.every((e) => e.direction == 'parent')) {
      label = steps.length == 2
          ? gendered('Grandfather', 'Grandmother', 'Grandparent')
          : steps.length == 3
          ? gendered(
              'Great-grandfather',
              'Great-grandmother',
              'Great-grandparent',
            )
          : 'Ancestor';
    } else if (steps.every((e) => e.direction == 'child')) {
      label = steps.length == 2
          ? gendered('Grandson', 'Granddaughter', 'Grandchild')
          : steps.length == 3
          ? gendered(
              'Great-grandson',
              'Great-granddaughter',
              'Great-grandchild',
            )
          : 'Descendant';
    } else if (directions == 'parent,child') {
      label = gendered('Brother', 'Sister', 'Siblings');
    } else if (directions == 'parent,parent,child' ||
        directions == 'parent,sibling') {
      label = gendered('Uncle', 'Aunt', 'Parent’s sibling');
    } else if (directions == 'parent,child,child' ||
        directions == 'sibling,child') {
      label = gendered('Nephew', 'Niece', 'Sibling’s child');
    } else if (directions == 'parent,parent,child,child' ||
        directions == 'parent,sibling,child') {
      label = gendered('Cousin', 'Cousin', 'Cousin');
    } else if (directions == 'spouse,parent') {
      label = gendered('Father-in-law', 'Mother-in-law', 'Partner’s parent');
    } else if (directions == 'child,spouse') {
      label = gendered('Son-in-law', 'Daughter-in-law', 'Child’s partner');
    } else if (directions == 'spouse,spouse') {
      label = 'Shared partner';
    }
    String stepName(String kind, String direction) => switch (kind) {
      'ADOPTED' => direction == 'parent' ? 'adoptive parent' : 'adopted child',
      'STEP' => direction == 'parent' ? 'stepparent' : 'stepchild',
      'PARENT' => direction == 'parent' ? 'parent' : 'child',
      'SIBLING' => 'sibling',
      _ => 'partner',
    };
    final explanation = [
      for (var i = 0; i < steps.length; i++)
        '${persons[path[i]]!.fullName} → ${stepName(steps[i].kind, steps[i].direction)}: ${persons[path[i + 1]]!.fullName}',
    ].join('\n');
    return result(
      label,
      path,
      delta,
      '$explanation\nThis result describes the recorded path; other paths may exist.',
    );
  }
}
