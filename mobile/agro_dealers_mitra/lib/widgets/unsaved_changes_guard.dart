import 'package:flutter/material.dart';

/// Wraps a form screen and shows a confirmation dialog before the user
/// navigates away via the system back button/gesture or the AppBar back
/// arrow (both route through Navigator.maybePop, which this intercepts)
/// while [hasUnsavedChanges] returns true.
///
/// A direct Navigator.pop() call made by the screen itself - e.g. after a
/// successful save - is a plain pop, not a maybePop, so it is not gated by
/// this and proceeds without the dialog.
class UnsavedChangesGuard extends StatelessWidget {
  final bool Function() hasUnsavedChanges;
  final Widget child;

  const UnsavedChangesGuard({
    super.key,
    required this.hasUnsavedChanges,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!hasUnsavedChanges()) {
          Navigator.of(context).pop();
          return;
        }
        final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
              "You haven't finished this form. If you leave now, your changes will be lost.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (shouldDiscard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}
