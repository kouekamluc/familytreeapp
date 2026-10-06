import 'package:flutter/material.dart';

/// Phone forms use a full screen route with a reachable, keyboard-safe footer.
class AdaptiveFormDialog extends StatelessWidget {
  final Widget title, content;
  final List<Widget> actions;
  final bool scrollable;
  const AdaptiveFormDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).shortestSide >= 600) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleLarge!,
                  child: title,
                ),
              ),
              Flexible(
                child: scrollable
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: content,
                      )
                    : content,
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: title),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            child: content,
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: actions,
            ),
          ),
        ),
      ),
    );
  }
}
