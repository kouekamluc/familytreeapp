import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/widgets/person_editor_dialog.dart';

void main() {
  for (final invalidDate in ['0000-01-01', '10000-01-01', '2025-02-31']) {
    testWidgets('calendar can recover from invalid input $invalidDate', (
      tester,
    ) async {
      final controller = TextEditingController(text: invalidDate);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateFormField(controller: controller, label: 'Date of birth'),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      // Opening or cancelling the picker must not silently normalize a draft.
      expect(controller.text, invalidDate);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(controller.text, invalidDate);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  }
}
