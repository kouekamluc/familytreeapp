import 'package:flutter/material.dart';
import '../models/person.dart';
import 'person_summary_panel.dart';

class MobilePersonSheet extends StatelessWidget {
  final Person person;
  final VoidCallback onInspectKinship, onCenterInTree, onOpenFullProfile;
  const MobilePersonSheet({
    super.key,
    required this.person,
    required this.onInspectKinship,
    required this.onCenterInTree,
    required this.onOpenFullProfile,
  });
  static void show(
    BuildContext context, {
    required Person person,
    required VoidCallback onInspectKinship,
    required VoidCallback onCenterInTree,
    required VoidCallback onOpenFullProfile,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => MobilePersonSheet(
      person: person,
      onInspectKinship: () {
        Navigator.pop(ctx);
        onInspectKinship();
      },
      onCenterInTree: () {
        Navigator.pop(ctx);
        onCenterInTree();
      },
      onOpenFullProfile: () {
        Navigator.pop(ctx);
        onOpenFullProfile();
      },
    ),
  );
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .85,
    ),
    child: PersonSummaryPanel(
      person: person,
      onOpenKinship: (_) => onInspectKinship(),
      onCenter: (_) => onCenterInTree(),
      onOpenPersonDetail: (_) => onOpenFullProfile(),
    ),
  );
}
