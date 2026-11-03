import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const forest = Color(0xFF103D31);
const ink = Color(0xFF183B32);
const canvas = Color(0xFFF5F6F0);
const lime = Color(0xFFD3F47D);
const muted = Color(0xFF72857A);

class ThemeControl extends InheritedWidget {
  const ThemeControl({super.key, required this.toggle, required super.child});
  final VoidCallback toggle;
  static ThemeControl? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeControl>();
  @override
  bool updateShouldNotify(ThemeControl oldWidget) => toggle != oldWidget.toggle;
}

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});
  @override
  Widget build(BuildContext context) {
    final control = ThemeControl.maybeOf(context);
    if (control == null) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: dark ? 'Aktifkan mode terang' : 'Aktifkan mode gelap',
      onPressed: control.toggle,
      icon: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          child: Icon(
              dark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
              key: ValueKey(dark),
              size: 21)),
    );
  }
}

ThemeData campahTheme({bool dark = false}) {
  final scheme = ColorScheme.fromSeed(
          seedColor: forest,
          brightness: dark ? Brightness.dark : Brightness.light)
      .copyWith(
    primary: dark ? lime : forest,
    secondary: const Color(0xFF7BA75B),
    surface: dark ? const Color(0xFF1C3029) : Colors.white,
    onSurface: dark ? const Color(0xFFE3EFE5) : ink,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(
        color: dark ? const Color(0xFF385248) : const Color(0xFFDCE7DC)),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: dark ? const Color(0xFF101F1A) : canvas,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF101F1A) : canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: dark ? const Color(0xFFE3EFE5) : ink,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF223A30) : const Color(0xFFFAFCF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0xFF72A67B), width: 1.6)),
      labelStyle: const TextStyle(color: muted, fontSize: 13),
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
      backgroundColor: dark ? lime : forest,
      foregroundColor: dark ? forest : Colors.white,
      minimumSize: const Size(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w800,
          fontSize: 13),
    )),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
      foregroundColor: dark ? lime : forest,
      minimumSize: const Size(0, 48),
      side: const BorderSide(color: Color(0xFFD3E1D4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w700,
          fontSize: 12),
    )),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE0F2C5),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 10,
          fontWeight: FontWeight.w700)),
    ),
    snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
  );
}

class CamPahMark extends StatelessWidget {
  const CamPahMark({super.key, this.size = 42});
  final double size;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/brand/campah-mark.svg',
        width: size,
        height: size,
        excludeFromSemantics: true,
      );
}

class SoftPanel extends StatelessWidget {
  const SoftPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20),
      this.color});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF385248)
                  : const Color(0xFFE6EDE4)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x080F392A), blurRadius: 24, offset: Offset(0, 6))
          ],
        ),
        child: child,
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(
      {super.key, required this.eyebrow, required this.title, this.trailing});
  final String eyebrow;
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(eyebrow,
                    style: const TextStyle(
                        color: Color(0xFF7A9988),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
                const SizedBox(height: 5),
                Text(title,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.6)),
              ])),
          if (trailing != null) trailing!,
        ],
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      'Pending' => (const Color(0xFFFFF0D4), const Color(0xFF95680F)),
      'In Progress' => (const Color(0xFFE6F1F8), const Color(0xFF487F9C)),
      'Completed' => (const Color(0xFFE6F4E6), const Color(0xFF3E8050)),
      'Rejected' => (const Color(0xFFFBE9E5), const Color(0xFFA96155)),
      _ => (const Color(0xFFEEF1ED), muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(30)),
      child: Text(status,
          style: TextStyle(
              color: foreground, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}
