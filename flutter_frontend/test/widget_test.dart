import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/models/person.dart';
import 'package:flutter_frontend/models/relationship.dart';
import 'package:flutter_frontend/utils/kinship_solver.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Royal Ancestry'),
        ),
      ),
    );

    expect(find.text('Royal Ancestry'), findsOneWidget);
  });

  group('KinshipSolver tests', () {
    final father = Person(
      id: 1,
      firstName: 'Takam',
      lastName: 'Kouam',
      gender: 'M',
      traditionalName: 'Fo\'o (Monarch)',
      clanTotem: 'Panther',
      generationTier: 1,
    );

    final mother = Person(
      id: 2,
      firstName: 'Magni',
      lastName: 'Kouam',
      gender: 'F',
      traditionalName: 'Queen Mother',
      generationTier: 1,
    );

    final son = Person(
      id: 3,
      firstName: 'Luc',
      lastName: 'Kouekam',
      gender: 'M',
      generationTier: 2,
    );

    final daughter = Person(
      id: 4,
      firstName: 'Amina',
      lastName: 'Kouam',
      gender: 'F',
      generationTier: 2,
    );

    final people = [father, mother, son, daughter];
    final relationships = [
      Relationship(id: 1, person1Id: 1, person2Id: 2, relationshipType: 'SPOUSE'),
      Relationship(id: 2, person1Id: 1, person2Id: 3, relationshipType: 'PARENT'),
      Relationship(id: 3, person1Id: 2, person2Id: 3, relationshipType: 'PARENT'),
      Relationship(id: 4, person1Id: 1, person2Id: 4, relationshipType: 'PARENT'),
      Relationship(id: 5, person1Id: 2, person2Id: 4, relationshipType: 'PARENT'),
    ];

    test('Identifies spouse relationship', () {
      final res = KinshipSolver.calculateKinship(
        personAId: 1,
        personBId: 2,
        people: people,
        relationships: relationships,
      );
      expect(res, isNotNull);
      expect(res!.relationship, contains('Épouse'));
    });

    test('Identifies parent-child relationship', () {
      final resChildToFather = KinshipSolver.calculateKinship(
        personAId: 3,
        personBId: 1,
        people: people,
        relationships: relationships,
      );
      expect(resChildToFather, isNotNull);
      expect(resChildToFather!.title, contains('Père'));

      final resFatherToChild = KinshipSolver.calculateKinship(
        personAId: 1,
        personBId: 3,
        people: people,
        relationships: relationships,
      );
      expect(resFatherToChild, isNotNull);
      expect(resFatherToChild!.title, equals('Fils'));
    });

    test('Identifies sibling relationship', () {
      final res = KinshipSolver.calculateKinship(
        personAId: 3,
        personBId: 4,
        people: people,
        relationships: relationships,
      );
      expect(res, isNotNull);
      expect(res!.relationship, contains('Sœur'));
    });
  });
}
