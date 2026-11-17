import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoyolaTheme {
  const LoyolaTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.foreground,
    required this.muted,
    required this.isLight,
  });

  final String id;
  final String name;
  final String description;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color foreground;
  final Color muted;
  final bool isLight;

  ThemeData toThemeData() {
    final brightness = isLight ? Brightness.light : Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isLight ? Colors.white : const Color(0xFF101116),
      secondary: secondary,
      onSecondary: isLight ? Colors.white : const Color(0xFF101116),
      error: const Color(0xFFE45B66),
      onError: Colors.white,
      surface: surface,
      onSurface: foreground,
      surfaceContainerHighest: surfaceVariant,
      onSurfaceVariant: muted,
      outline: muted.withValues(alpha: .35),
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: foreground,
      onInverseSurface: background,
      inversePrimary: secondary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: muted.withValues(alpha: .22),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        textColor: foreground,
        subtitleTextStyle: TextStyle(color: muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: muted.withValues(alpha: .25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: muted.withValues(alpha: .25)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isLight ? Colors.white : const Color(0xFF101116),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textTheme: (isLight ? ThemeData.light() : ThemeData.dark()).textTheme.apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
    );
  }
}

class LoyolaThemes {
  LoyolaThemes._();

  static const all = <LoyolaTheme>[
    LoyolaTheme(
      id: 'classic', name: 'Loyola Classic',
      description: 'The original calm, modern campus look.',
      primary: Color(0xFFB9F36B), secondary: Color(0xFF72E4D2),
      background: Color(0xFF0B1014), surface: Color(0xFF18232B),
      surfaceVariant: Color(0xFF111920), foreground: Color(0xFFF3F7F4),
      muted: Color(0xFF94A5AA), isLight: false,
    ),
    LoyolaTheme(
      id: 'spider', name: 'Web-Slinger',
      description: 'Comic-book red, midnight navy and electric blue.',
      primary: Color(0xFFE63946), secondary: Color(0xFF42A5F5),
      background: Color(0xFF090F1C), surface: Color(0xFF151F32),
      surfaceVariant: Color(0xFF202D43), foreground: Color(0xFFF5F7FC),
      muted: Color(0xFF9EACC2), isLight: false,
    ),
    LoyolaTheme(
      id: 'gotham', name: 'Gotham Nights',
      description: 'Stealthy charcoal with warm signal-yellow accents.',
      primary: Color(0xFFF4C542), secondary: Color(0xFF8FA3B8),
      background: Color(0xFF090B10), surface: Color(0xFF171B24),
      surfaceVariant: Color(0xFF222936), foreground: Color(0xFFF2F4F7),
      muted: Color(0xFF9AA5B4), isLight: false,
    ),
    LoyolaTheme(
      id: 'grand-line', name: 'Grand Line',
      description: 'Ocean blues, sunlit gold and adventure.',
      primary: Color(0xFFFFC857), secondary: Color(0xFF42C6D8),
      background: Color(0xFF071923), surface: Color(0xFF102B3A),
      surfaceVariant: Color(0xFF193B4B), foreground: Color(0xFFF4FAFC),
      muted: Color(0xFFA0BBC5), isLight: false,
    ),
    LoyolaTheme(
      id: 'cursed-energy', name: 'Cursed Energy',
      description: 'Indigo shadows with violet and cyan highlights.',
      primary: Color(0xFF9B7BFF), secondary: Color(0xFF55D6E8),
      background: Color(0xFF0D0B1B), surface: Color(0xFF1C1830),
      surfaceVariant: Color(0xFF292341), foreground: Color(0xFFF5F1FF),
      muted: Color(0xFFB2A9CE), isLight: false,
    ),
    LoyolaTheme(
      id: 'inferno', name: 'Inferno',
      description: 'A bold volcanic palette of ember and graphite.',
      primary: Color(0xFFFF6542), secondary: Color(0xFFFFB454),
      background: Color(0xFF130C0B), surface: Color(0xFF251613),
      surfaceVariant: Color(0xFF38201A), foreground: Color(0xFFFFF4EF),
      muted: Color(0xFFC5A69B), isLight: false,
    ),
    LoyolaTheme(
      id: 'halloween', name: 'Haunted Campus',
      description: 'Midnight purple, pumpkin orange and eerie accents.',
      primary: Color(0xFFFF8A3D), secondary: Color(0xFFB18CFF),
      background: Color(0xFF100B1B), surface: Color(0xFF21162F),
      surfaceVariant: Color(0xFF30203F), foreground: Color(0xFFFFF6F0),
      muted: Color(0xFFB9A8C8), isLight: false,
    ),
    LoyolaTheme(
      id: 'winter', name: 'Winter Lights',
      description: 'Frosted blue, evergreen and festive warmth.',
      primary: Color(0xFF78C8FF), secondary: Color(0xFF72D6A1),
      background: Color(0xFF091522), surface: Color(0xFF142638),
      surfaceVariant: Color(0xFF20374A), foreground: Color(0xFFF1F8FF),
      muted: Color(0xFFA6BBCB), isLight: false,
    ),
    LoyolaTheme(
      id: 'paper', name: 'Campus Paper',
      description: 'A bright, warm and minimal light appearance.',
      primary: Color(0xFF315DAB), secondary: Color(0xFF168779),
      background: Color(0xFFF5F6F8), surface: Color(0xFFFFFFFF),
      surfaceVariant: Color(0xFFE9EDF2), foreground: Color(0xFF182230),
      muted: Color(0xFF657386), isLight: true,
    ),
  ];

  static LoyolaTheme byId(String id) =>
      all.firstWhere((theme) => theme.id == id, orElse: () => all.first);
}

class ThemeProvider extends ChangeNotifier {
  static const _storageKey = 'loyola_selected_theme';
  LoyolaTheme _selected = LoyolaThemes.all.first;

  LoyolaTheme get selected => _selected;
  ThemeData get themeData => _selected.toThemeData();

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _selected = LoyolaThemes.byId(preferences.getString(_storageKey) ?? 'classic');
    notifyListeners();
  }

  Future<void> select(String id) async {
    _selected = LoyolaThemes.byId(id);
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, id);
  }

  Future<void> reset() => select('classic');
}
