import 'package:flutter/material.dart';
import '../models/person.dart';
import 'person_summary_panel.dart';

class NodeActionSheet extends StatelessWidget {
  final Person person;
  final VoidCallback? onClose;
  final Function(Person)? onNavigateToPerson, onOpenKinship, onOpenPersonDetail;
  const NodeActionSheet({
    super.key,
    required this.person,
    this.onClose,
    this.onNavigateToPerson,
    this.onOpenKinship,
    this.onOpenPersonDetail,
  });
  @override
  Widget build(BuildContext context) => PersonSummaryPanel(
    person: person,
    onClose: onClose,
    onNavigateToPerson: onNavigateToPerson,
    onOpenKinship: onOpenKinship,
    onOpenPersonDetail: onOpenPersonDetail,
  );
}
