# District-inspired Loyola UI audit

## Reference and scope

Reference: District by Zomato (official listing and public product pages). Public material describes a discovery-first app spanning movies, events, dining, stores, activities, and sports. Public teardown material shows a high-contrast dark onboarding surface, a focused primary action, and a restrained, uncluttered layout.

REA was not available as a connected tool in this environment, and no District APK was supplied. This pass therefore uses public-facing references and source-level inspection of Loyola; it does not claim binary-level or on-device REA findings.

## Existing Loyola app — pre-change source audit

- Flutter app with Material 3 and a centralized `AppTheme`.
- `go_router` StatefulShellRoute keeps five main tabs: Home, Attendance, Subjects, Marks, Profile.
- Authentication uses `AuthProvider`, Firebase/Google sign-in, secure storage, and a route redirect guard.
- Dashboard, attendance, subjects, marks, and profile use existing service/model layers; the dashboard already reads cache first and refreshes API data.
- UI uses a shared glass container/background and responsive helpers. Backdrop blur is used in shared cards and navigation, which can add paint cost and create inconsistent contrast.
- This patch leaves routing, authentication, services, API contracts, models, and feature screen data logic untouched.

## Adopted design direction

- Near-black canvas and solid charcoal surfaces for clear hierarchy.
- Lavender as a restrained interaction/accent color, with Loyola crimson retained as the institutional brand accent.
- Rounded surfaces, thin low-contrast outlines, stronger title hierarchy, and consistent spacing/radius tokens.
- Keep the existing animated tab selection and route transitions.
- Replace the shared blur-heavy container implementation with a solid Material surface while retaining its public constructor fields for compatibility.

## Files changed

- `mobile/lib/core/theme/app_theme.dart`: refined Material 3 dark theme, surfaces, outlines, inputs, and typography.
- `mobile/lib/core/theme/loyola_design.dart`: reusable color, spacing, and radius tokens.
- `mobile/lib/widgets/loyola_surface.dart`: reusable surface and section-heading widgets.
- `mobile/lib/widgets/glass_container.dart`: compatibility-preserving solid surface implementation.

## Validation status

Source-level audit and edits completed. A Flutter build, analyzer run, emulator launch, screenshot review, and visual iteration have **not** been performed in this environment. Run these from `mobile/` before merging:

```bash
flutter pub get
dart format lib/core/theme/app_theme.dart lib/core/theme/loyola_design.dart lib/widgets/loyola_surface.dart lib/widgets/glass_container.dart
flutter analyze
flutter test
flutter run
```

Capture Home, Attendance, Subjects, Marks, Profile, Login, and Splash on a small Android screen and a larger screen. Check contrast, text scaling, bottom navigation safe area, loading/error/empty states, and whether any screens depend on the old translucent background. Do not merge until build/analyzer checks pass and screenshots are reviewed.
