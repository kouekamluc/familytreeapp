import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/models/person.dart';
import 'package:flutter_frontend/models/relationship.dart';
import 'package:flutter_frontend/utils/kinship_solver.dart';

void main() {
  final people = [
    for (var i = 1; i <= 4; i++)
      Person(id: i, firstName: 'Person', lastName: '$i', gender: 'O'),
  ];
  Relationship link(int id, int a, int b, String kind, {bool current = true}) =>
      Relationship(
        id: id,
        person1Id: a,
        person2Id: b,
        relationshipType: kind,
        isCurrent: current,
      );
  KinshipResult result(int a, int b, List<Relationship> links) =>
      KinshipSolver.calculateKinship(
        personAId: a,
        personBId: b,
        people: people,
        relationships: links,
      )!;

  test('mixed ancestry preserves adoption and step-parent facts', () {
    for (final kind in ['ADOPTED', 'STEP']) {
      final r = result(3, 1, [link(1, 1, 2, 'PARENT'), link(2, 2, 3, kind)]);
      expect(
        r.relationship,
        kind == 'ADOPTED'
            ? 'Relationship through adoption'
            : 'Relationship through a blended family',
      );
      expect(r.path.map((p) => p.id), [3, 2, 1]);
      expect(r.generationDifference, 2);
      expect(r.culturalHonorific, isEmpty);
    }
  });

  test('unknown-gender siblings use the actual shared parent', () {
    final r = result(2, 3, [link(1, 1, 2, 'PARENT'), link(2, 1, 3, 'PARENT')]);
    expect(r.relationship, 'Siblings');
    expect(r.path.map((p) => p.id), [2, 1, 3]);
  });

  test('a shared partner does not invent marriage or customary roles', () {
    final r = result(1, 3, [link(1, 1, 2, 'SPOUSE'), link(2, 2, 3, 'SPOUSE')]);
    expect(r.relationship, 'Shared partner');
    expect(r.culturalHonorific, isEmpty);
  });

  test(
    'former relationships are reported directly but excluded from indirect paths',
    () {
      final links = [
        link(1, 1, 2, 'SPOUSE', current: false),
        link(2, 2, 3, 'PARENT'),
      ];
      expect(result(1, 2, links).relationship, 'Former partner');
      expect(result(1, 3, links).relationship, 'Unconnected branches');
      expect(result(1, 4, links).relationship, 'Unconnected branches');
    },
  );
}
