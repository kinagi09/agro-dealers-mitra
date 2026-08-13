import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Wraps the app and clears text-field focus whenever the on-screen
/// keyboard closes, no matter what closed it (a dialog/date-picker
/// opening over the field, the system back button, swiping it away, or
/// its own Done/dismiss key).
///
/// Without this, a TextField can keep logical focus even after its
/// keyboard is hidden - so the next time something re-requests focus
/// for that route (e.g. a dialog finishing and handing focus back to
/// whatever the framework remembers as "previously focused"), the
/// keyboard pops back open on a field the user is done with.
class KeyboardDismissUnfocus extends StatefulWidget {
  final Widget child;

  const KeyboardDismissUnfocus({super.key, required this.child});

  @override
  State<KeyboardDismissUnfocus> createState() => _KeyboardDismissUnfocusState();
}

class _KeyboardDismissUnfocusState extends State<KeyboardDismissUnfocus>
    with WidgetsBindingObserver {
  double _lastBottomInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final bottomInset = view.viewInsets.bottom / view.devicePixelRatio;
    final keyboardJustClosed = bottomInset == 0 && _lastBottomInset > 0;
    _lastBottomInset = bottomInset;
    if (keyboardJustClosed) {
      // Defer a frame so this doesn't race a field that's legitimately
      // requesting focus right now (e.g. autofocusing the next field).
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Plain unfocus() isn't enough: the enclosing FocusScopeNode keeps
        // this field recorded as its "focused child", so anything that
        // later re-requests focus on that scope (a dropdown/date-picker
        // route closing and handing focus back, for instance) re-focuses
        // this same field and pops the keyboard back open. Requesting
        // focus on a throwaway node overwrites that memory instead.
        FocusScope.of(context).requestFocus(FocusNode());
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
