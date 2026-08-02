import 'package:flutter/material.dart';

/// Opens a fully live Flutter surface without keeping a transition snapshot.
///
/// Settings pages can contain native ad views. On a few Android renderers a
/// cached route snapshot can remain visible after the route has been popped,
/// even though the home screen underneath is already receiving taps. A jump
/// cut keeps navigation deterministic and guarantees that the visible frame is
/// produced by the active route.
Route<T> livePageRoute<T>({required WidgetBuilder builder}) {
  return PageRouteBuilder<T>(
    allowSnapshotting: false,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, _, __) => builder(context),
  );
}
