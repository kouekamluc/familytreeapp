import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/models/person.dart';
import 'package:flutter_frontend/models/relationship.dart';
import 'package:flutter_frontend/utils/family_graph_layout.dart';

Person person(int id, {int tier = 1}) => Person(
  id: id,
  firstName: 'Member$id',
  lastName: '',
  gender: 'O',
  generationTier: tier,
);
Relationship link(int a, int b, String type, {bool current = true}) =>
    Relationship(
      id: a * 100 + b,
      person1Id: a,
      person2Id: b,
      relationshipType: type,
      isCurrent: current,
    );
FamilyGraphLayout layout(List<Person> people, List<Relationship> links) =>
    layoutFamilyGraph(people, links, cardWidth: 144, cardHeight: 172);

void main() {
  test('couples share a row despite outdated tiers and record order', () {
    final graph = layout(
      [person(2, tier: 5), person(1)],
      [link(2, 1, 'SPOUSE')],
    );
    expect(graph.positions[1]!.dy, graph.positions[2]!.dy);
    expect((graph.positions[1]!.dx - graph.positions[2]!.dx).abs(), 184);
  });
  test(
    'multiple partners stay beside their shared partner, independent of gender or order',
    () {
      final people = [person(1), person(2), person(3), person(4), person(5)];
      final links = [
        link(1, 2, 'SPOUSE'),
        link(1, 3, 'SPOUSE'),
        link(1, 4, 'PARENT'),
        link(2, 4, 'PARENT'),
        link(1, 5, 'PARENT'),
        link(3, 5, 'PARENT'),
      ];
      final graph = layout(people, links);
      expect(
        graph.positions,
        layout(people.reversed.toList(), links.reversed.toList()).positions,
      );
      expect(graph.positions[1]!.dy, graph.positions[2]!.dy);
      expect(graph.positions[1]!.dy, graph.positions[3]!.dy);
      expect(graph.positions[1]!.dx, greaterThan(graph.positions[2]!.dx));
      expect(graph.positions[1]!.dx, lessThan(graph.positions[3]!.dx));
      expect(graph.positions[4]!.dy, greaterThan(graph.positions[1]!.dy));
      expect(graph.positions[4]!.dx, lessThan(graph.positions[5]!.dx));
    },
  );
  test(
    'ancestry on both sides and sibling households keep generations aligned without overlap',
    () {
      final people = List.generate(9, (i) => person(i + 1));
      final links = [
        link(1, 3, 'PARENT'),
        link(2, 4, 'PARENT'),
        link(3, 4, 'SPOUSE'),
        link(3, 5, 'PARENT'),
        link(4, 5, 'PARENT'),
        link(5, 6, 'SIBLING'),
        link(6, 7, 'SPOUSE'),
        link(6, 8, 'PARENT'),
        link(7, 8, 'PARENT'),
      ];
      final graph = layout(people, links);
      expect(graph.generations[3], graph.generations[4]);
      expect(graph.generations[5], graph.generations[6]);
      expect(graph.generations[6], graph.generations[7]);
      expect(graph.generations[8], greaterThan(graph.generations[6]!));
      for (final a in people) {
        for (final b in people.where((p) => p.id > a.id)) {
          if (graph.positions[a.id]!.dy == graph.positions[b.id]!.dy) {
            expect(
              (graph.positions[a.id]!.dx - graph.positions[b.id]!.dx).abs(),
              greaterThanOrEqualTo(144),
            );
          }
        }
      }
      expect(
        graph.generations[9],
        0,
        reason: 'An unrelated record is not assigned an invented parent.',
      );
    },
  );
  test(
    'former unions and contradictory ancestry do not lose records or loop',
    () {
      final graph = layout(
        [person(1), person(2), person(3)],
        [
          link(1, 2, 'SPOUSE', current: false),
          link(1, 2, 'PARENT'),
          link(2, 1, 'PARENT'),
        ],
      );
      expect(graph.positions.length, 3);
      expect(graph.positions[1], isNot(graph.positions[2]));
    },
  );
}
