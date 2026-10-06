import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

Future<bool> confirmDiscard(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AppText('Discard your changes?'),
        content: const AppText('Your unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const AppText('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const AppText('Discard'),
          ),
        ],
      ),
    ) ??
    false;

Future<bool> confirmRestoreDraft(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const AppText('Continue your unsaved changes?'),
        content: const AppText(
          'A private draft from this device is available for 24 hours. Restoring it does not save anything to your family.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const AppText('Discard draft'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const AppText('Restore draft'),
          ),
        ],
      ),
    ) ??
    false;

/// Native Back and an explicit Cancel use the same unsaved-change decision.
class EditRecoveryGuard extends StatefulWidget {
  final bool busy, dirty;
  final Widget child;
  final Future<void> Function()? onDiscard;
  const EditRecoveryGuard({
    super.key,
    required this.busy,
    required this.dirty,
    required this.child,
    this.onDiscard,
  });
  @override
  State<EditRecoveryGuard> createState() => _EditRecoveryGuardState();
}

class _EditRecoveryGuardState extends State<EditRecoveryGuard> {
  bool _checking = false, _allowExit = false;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.busy && (!widget.dirty || _allowExit),
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || widget.busy || _checking || !widget.dirty) return;
      _checking = true;
      final discard = await confirmDiscard(context);
      _checking = false;
      if (!mounted || !discard || widget.busy) return;
      await widget.onDiscard?.call();
      if (!mounted) return;
      setState(() => _allowExit = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, result);
      });
    },
    child: widget.child,
  );
}

/// Shows only the fields this editor proposes to change; nothing is saved here.
Future<bool> reviewLatest(
  BuildContext context,
  Map<String, dynamic> latest,
  Map<String, dynamic> draft,
  Map<String, String> labels,
) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const AppText('Review the latest version'),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppText(
              'Compare these fields before retrying. Other changes will be kept. Nothing is saved until you tap Save.',
            ),
            for (final field in draft.keys.where((k) => k != 'revision')) ...[
              const SizedBox(height: 16),
              AppText(
                labels[field] ?? field,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const AppText('Latest saved value'),
              Text('${latest[field] ?? ''}'),
              const AppText('Your change'),
              Text('${draft[field] ?? ''}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const AppText('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const AppText('Use this revision'),
          ),
        ],
      ),
    ) ??
    false;
