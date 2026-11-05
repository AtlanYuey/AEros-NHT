# Local patches (Eros-N)

Vendored from native_liquid_glass 0.3.1 (pub.dev, MIT). Changes:

- `lib/src/liquid_glass_button_group.dart`: pass `isDark` (from the Flutter
  theme) in the creation params. The native view reads it to set
  `overrideUserInterfaceStyle`, but the Dart side never sent it, so button
  groups always rendered light glass in dark mode. The value is part of the
  params hash; the app keys the group by brightness so a theme change
  recreates the native view.
