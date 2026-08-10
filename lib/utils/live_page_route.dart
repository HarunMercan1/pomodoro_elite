import 'package:flutter/material.dart';

/// Opens a fully live Flutter surface without keeping a transition snapshot.
///
/// Settings pages can contain native ad views. On a few Android renderers a
/// cached route snapshot can remain visible after the route has been popped,
/// even though the home screen underneath is already receiving taps. Disabling
/// snapshotting keeps the surface live while MaterialPageRoute preserves the
/// platform's natural enter and exit animations.
Route<T> livePageRoute<T>({required WidgetBuilder builder}) {
  return MaterialPageRoute<T>(
    allowSnapshotting: false,
    builder: builder,
  );
}
