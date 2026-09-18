import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'branding.dart';
import 'domain.dart';
import 'motion.dart';

const blue = Color(0xff2055d6),
    accent = Color(0xff16b8c4),
    ink = Color(0xff10172a),
    muted = Color(0xff69758b),
    canvas = Color(0xfff4f6fa),
    softSurface = Color(0xffeef2f8),
    line = Color(0xffdce3ee),
    green = Color(0xff07936d),
    amber = Color(0xffbd621c),
    danger = Color(0xffd43b4f);
const darkCanvas = Color(0xff07111f),
    darkSurface = Color(0xff111d2d),
    darkRaised = Color(0xff182638),
    darkLine = Color(0xff2a3a4f),
    darkInk = Color(0xfff4f8ff),
    darkMuted = Color(0xff9aabc0),
    neon = Color(0xff6fcbd2);
final appTheme = ThemeData(
  useMaterial3: true,
  materialTapTargetSize: MaterialTapTargetSize.padded,
  visualDensity: VisualDensity.standard,
  colorScheme: ColorScheme.fromSeed(
    seedColor: brandNavy,
    primary: brandNavy,
    secondary: accent,
    surface: Colors.white,
    error: danger,
  ),
  scaffoldBackgroundColor: canvas,
  canvasColor: Colors.white,
  cardColor: Colors.white,
  fontFamily: 'Roboto',
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: DealerPageTransitionsBuilder(),
      TargetPlatform.iOS: DealerPageTransitionsBuilder(),
    },
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    toolbarHeight: 64,
    titleSpacing: 20,
    iconTheme: IconThemeData(color: ink),
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      color: ink,
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: -.2,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Color(0xffe4e9f1)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xcaffffff),
    contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
    labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w500),
    hintStyle: const TextStyle(color: Color(0xff8a96a9)),
    prefixIconColor: const Color(0xff536078),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: accent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: danger),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: brandNavy,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 50),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ).copyWith(foregroundBuilder: buttonPressLayer),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: brandNavy,
      minimumSize: const Size(0, 46),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      side: const BorderSide(color: line),
    ).copyWith(foregroundBuilder: buttonPressLayer),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: blue,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w700,
      ),
    ).copyWith(foregroundBuilder: buttonPressLayer),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: const ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size.square(48)),
      tapTargetSize: MaterialTapTargetSize.padded,
    ).copyWith(foregroundBuilder: buttonPressLayer),
  ),
  dropdownMenuTheme: DropdownMenuThemeData(
    textStyle: const TextStyle(color: ink, fontSize: 14),
    menuStyle: MenuStyle(
      backgroundColor: const WidgetStatePropertyAll(Colors.white),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(8.0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    textStyle: const TextStyle(color: ink, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.white,
    elevation: 0,
    indicatorColor: Color(0xffdff6f7),
    height: 68,
    iconTheme: WidgetStatePropertyAll(IconThemeData(color: Color(0xff485269))),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(
        fontFamily: 'Roboto',
        fontSize: 9.5,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
    ),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white,
    selectedColor: const Color(0xffdff6f7),
    side: const BorderSide(color: line),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    labelStyle: const TextStyle(
      fontFamily: 'Roboto',
      color: ink,
      fontWeight: FontWeight.w600,
    ),
    checkmarkColor: brandNavy,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
  ),
  dividerTheme: const DividerThemeData(color: line, thickness: 1),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: brandNavy,
    contentTextStyle: const TextStyle(color: Colors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    behavior: SnackBarBehavior.floating,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    barrierColor: const Color(0x66100947),
    elevation: 0,
    insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
    modalBackgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    modalBarrierColor: Color(0x66100947),
    showDragHandle: true,
    dragHandleColor: line,
    dragHandleSize: Size(36, 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    clipBehavior: Clip.antiAlias,
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 27,
      fontWeight: FontWeight.w900,
      letterSpacing: -.7,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: -.35,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: ink),
    bodySmall: TextStyle(fontSize: 12, height: 1.4, color: muted),
  ),
);

final darkAppTheme = appTheme.copyWith(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: neon,
    brightness: Brightness.dark,
    primary: neon,
    secondary: const Color(0xff5689ff),
    surface: darkSurface,
    error: const Color(0xffff6f83),
  ),
  scaffoldBackgroundColor: darkCanvas,
  canvasColor: darkRaised,
  cardColor: darkSurface,
  appBarTheme: const AppBarTheme(
    backgroundColor: darkCanvas,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    toolbarHeight: 64,
    titleSpacing: 20,
    iconTheme: IconThemeData(color: darkInk),
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      color: darkInk,
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: -.2,
    ),
  ),
  cardTheme: CardThemeData(
    color: darkSurface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: darkLine),
    ),
  ),
  inputDecorationTheme: appTheme.inputDecorationTheme.copyWith(
    fillColor: darkSurface,
    labelStyle: const TextStyle(color: darkMuted, fontWeight: FontWeight.w500),
    hintStyle: const TextStyle(color: Color(0xff718299)),
    prefixIconColor: darkMuted,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: darkLine),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: neon, width: 1.5),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xff3978ff),
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 50),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w700,
      ),
      shadowColor: const Color(0x443978ff),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ).copyWith(foregroundBuilder: buttonPressLayer),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: darkInk,
      minimumSize: const Size(0, 46),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w700,
      ),
      side: const BorderSide(color: darkLine),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ).copyWith(foregroundBuilder: buttonPressLayer),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: neon,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w700,
      ),
    ).copyWith(foregroundBuilder: buttonPressLayer),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: const ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(darkInk),
      minimumSize: WidgetStatePropertyAll(Size.square(48)),
      tapTargetSize: MaterialTapTargetSize.padded,
    ).copyWith(foregroundBuilder: buttonPressLayer),
  ),
  dropdownMenuTheme: DropdownMenuThemeData(
    textStyle: const TextStyle(color: darkInk, fontSize: 14),
    menuStyle: MenuStyle(
      backgroundColor: const WidgetStatePropertyAll(darkRaised),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(8.0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkLine),
        ),
      ),
    ),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: darkRaised,
    surfaceTintColor: Colors.transparent,
    textStyle: const TextStyle(color: darkInk, fontSize: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: darkLine),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: darkSurface,
    elevation: 0,
    indicatorColor: Color(0xff26384b),
    height: 68,
    iconTheme: WidgetStatePropertyAll(IconThemeData(color: darkMuted)),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(
        fontFamily: 'Roboto',
        fontSize: 9.5,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
    ),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  ),
  chipTheme: appTheme.chipTheme.copyWith(
    backgroundColor: darkSurface,
    selectedColor: const Color(0xff26384b),
    side: const BorderSide(color: darkLine),
    labelStyle: const TextStyle(color: darkInk, fontWeight: FontWeight.w600),
    checkmarkColor: neon,
  ),
  dividerTheme: const DividerThemeData(color: darkLine, thickness: 1),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.selected) ? Colors.white : darkMuted,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? const Color(0xff3d6fc4)
          : darkRaised,
    ),
    trackOutlineColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? neon : darkLine,
    ),
  ),
  sliderTheme: appTheme.sliderTheme.copyWith(
    activeTrackColor: neon,
    inactiveTrackColor: darkLine,
    thumbColor: darkInk,
    overlayColor: neon.withValues(alpha: .10),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: darkRaised,
    contentTextStyle: const TextStyle(color: darkInk),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(color: darkLine),
    ),
    behavior: SnackBarBehavior.floating,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: darkRaised,
    surfaceTintColor: Colors.transparent,
    barrierColor: const Color(0xaa020710),
    elevation: 0,
    insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: darkLine),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: darkRaised,
    modalBackgroundColor: darkRaised,
    surfaceTintColor: Colors.transparent,
    modalBarrierColor: Color(0xaa020710),
    showDragHandle: true,
    dragHandleColor: darkMuted,
    dragHandleSize: Size(36, 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    clipBehavior: Clip.antiAlias,
  ),
  textTheme: appTheme.textTheme
      .apply(bodyColor: darkInk, displayColor: darkInk)
      .copyWith(
        bodySmall: const TextStyle(fontSize: 12, height: 1.4, color: darkMuted),
      ),
);

bool isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;
Color surfaceColor(BuildContext context) =>
    isDarkMode(context) ? darkSurface : Colors.white;
Color raisedColor(BuildContext context) =>
    isDarkMode(context) ? darkRaised : Colors.white;
Color borderColor(BuildContext context) =>
    isDarkMode(context) ? darkLine : line;
Color secondaryTextColor(BuildContext context) =>
    isDarkMode(context) ? darkMuted : muted;

class Brand extends StatelessWidget {
  final bool compact;
  final bool inverse;
  final bool animateText;
  const Brand({
    super.key,
    this.compact = false,
    this.inverse = false,
    this.animateText = false,
  });
  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MotorStockMark(size: compact ? 36 : 56),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StaggeredTextReveal(
                words: 'MOTO STOCK',
                enabled: animateText,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: inverse || dark ? Colors.white : brandNavy,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: compact ? 17 : 27,
                  letterSpacing: .3,
                ),
              ),
              StaggeredTextReveal(
                words: 'DEALERSHIP ERP',
                enabled: animateText,
                delay: const Duration(milliseconds: 60),
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: compact ? 8 : 10,
                  letterSpacing: 1.5,
                  color: inverse || dark ? const Color(0xff8bdde4) : muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x88000000) : const Color(0x12122b4b),
            blurRadius: dark ? 20 : 22,
            spreadRadius: dark ? -8 : -7,
            offset: const Offset(0, 10),
          ),
          if (dark)
            const BoxShadow(
              color: Color(0x70000000),
              blurRadius: 16,
              offset: Offset(8, 10),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: surfaceColor(context).withValues(alpha: dark ? .84 : .70),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: dark
                    ? const Color(0xff33475e)
                    : Colors.white.withValues(alpha: .82),
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final bool animateText;
  final Duration revealDelay;
  const Pill(
    this.text, {
    super.key,
    this.color = blue,
    this.animateText = false,
    this.revealDelay = Duration.zero,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: color.withValues(alpha: .12)),
    ),
    child: StaggeredTextReveal(
      words: text,
      enabled: animateText,
      delay: revealDelay,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    ),
  );
}

Color statusColor(String text) =>
    text.toLowerCase().contains('out') || text == 'Cancelled'
    ? Colors.red
    : text == 'Paid' || text == 'Delivered' || text == 'In stock'
    ? green
    : amber;

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const SectionTitle(this.title, {super.key, this.subtitle, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 13),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(left: 13, top: 3),
                  child: Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class Metric extends StatelessWidget {
  final String label, value, hint;
  final IconData icon;
  final num? numericValue;
  final String Function(num)? formatter;

  const Metric(
    this.label,
    this.value,
    this.hint,
    this.icon, {
    super.key,
    this.numericValue,
    this.formatter,
  });

  Widget _amount(BuildContext context) {
    final style = TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w700,
      letterSpacing: -.5,
      color: Theme.of(context).colorScheme.onSurface,
    );
    // Interpolate source values only. Formatted amounts may contain units or
    // abbreviations, so the fallback preserves their exact text and precision.
    if (numericValue != null && formatter != null) {
      return AnimatedAmount(
        value: numericValue!,
        format: formatter!,
        style: style,
      );
    }
    return Semantics(
      label: value,
      child: ExcludeSemantics(
        child: MotionSwitcher(
          child: Text(value, key: ValueKey(value), style: style),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(17),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: secondaryTextColor(context),
                  fontSize: 12,
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDarkMode(context)
                    ? const Color(0xff20394b)
                    : const Color(0xffe9f6f7),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDarkMode(context) ? neon : brandNavy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FittedBox(fit: BoxFit.scaleDown, child: _amount(context)),
        if (hint.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            hint,
            style: TextStyle(fontSize: 11, color: secondaryTextColor(context)),
          ),
        ],
      ],
    ),
  );
}

class MetricGrid extends StatelessWidget {
  final List<Widget> children;
  const MetricGrid({super.key, required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var index = 0; index < children.length; index++)
          SizedBox(
            width: (c.maxWidth - 12) / 2,
            child: MotionEntrance(order: index, child: children[index]),
          ),
      ],
    ),
  );
}

class BikeImage extends StatelessWidget {
  final Vehicle vehicle;
  final double width, height;
  const BikeImage(this.vehicle, {super.key, this.width = 78, this.height = 64});

  @override
  Widget build(BuildContext context) =>
      ItemImage(vehicle.image, width: width, height: height);
}

class ItemImage extends StatelessWidget {
  final String source;
  final double width, height;
  final IconData fallbackIcon;
  const ItemImage(
    this.source, {
    super.key,
    this.width = 78,
    this.height = 64,
    this.fallbackIcon = Icons.two_wheeler,
  });

  Widget _image() {
    final fallback = Icon(fallbackIcon, size: 36, color: blue);
    if (source.isEmpty) return fallback;
    if (source.startsWith('data:image/')) {
      try {
        return Image.memory(
          UriData.parse(source).contentAsBytes(),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      } on FormatException {
        return fallback;
      }
    }
    if (source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode(context)
              ? const [Color(0xff152b3a), Color(0xff202a43)]
              : const [Color(0xffe7f5f7), Color(0xffedf0fb)],
        ),
      ),
      child: _image(),
    ),
  );
}

Widget emptyState(String title, String subtitle, IconData icon) => Builder(
  builder: (context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    child: Center(
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: isDarkMode(context)
                  ? const Color(0xff20394b)
                  : const Color(0xffe9f6f7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              size: 34,
              color: isDarkMode(context) ? neon : brandNavy,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryTextColor(context)),
          ),
        ],
      ),
    ),
  ),
);
void notice(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;
Future<void> perform(
  BuildContext context,
  Future<void> Function() action, {
  String success = 'Saved on this device',
}) async {
  try {
    await action();
    if (context.mounted) notice(context, success);
  } catch (e) {
    if (context.mounted) {
      notice(context, e.toString().replaceFirst('Bad state: ', ''));
    }
  }
}

Widget valueRow(
  String label,
  String value, {
  bool bold = false,
  Color? color,
}) => Builder(
  builder: (context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: secondaryTextColor(context)),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    ),
  ),
);

/// Compact, labelled filter with the full set of choices in a dropdown.
class CompactMenu extends StatelessWidget {
  final String label, value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final IconData? icon;
  final Map<String, String> labels;
  final bool animateText;
  const CompactMenu({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
    this.labels = const {},
    this.animateText = false,
  });

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: label,
    initialValue: value,
    position: PopupMenuPosition.under,
    color: raisedColor(context),
    surfaceTintColor: Colors.transparent,
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    popUpAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    onSelected: (v) {
      if (v == value) return;
      HapticFeedback.selectionClick();
      onChanged(v);
    },
    itemBuilder: (_) => options
        .map(
          (v) => PopupMenuItem(
            value: v,
            child: Row(
              children: [
                Expanded(child: Text(labels[v] ?? v)),
                if (v == value)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.check_rounded, size: 18, color: accent),
                  ),
              ],
            ),
          ),
        )
        .toList(),
    child: Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor(context)
            .withValues(alpha: isDarkMode(context) ? .82 : .66),
        border: Border.all(color: borderColor(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: secondaryTextColor(context), size: 17),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: animateText
                ? StaggeredTextReveal(
                    words: labels[value] ?? value,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Text(
                    labels[value] ?? value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: secondaryTextColor(context),
          ),
        ],
      ),
    ),
  );
}

class MenuAction {
  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool destructive, enabled;
  const MenuAction(
    this.label,
    this.icon,
    this.onSelected, {
    this.destructive = false,
    this.enabled = true,
  });
}

class ActionMenu extends StatelessWidget {
  final List<MenuAction> actions;
  final String tooltip;
  const ActionMenu({
    super.key,
    required this.actions,
    this.tooltip = 'More actions',
  });
  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
    tooltip: tooltip,
    icon: Icon(Icons.more_horiz_rounded, color: secondaryTextColor(context)),
    position: PopupMenuPosition.under,
    color: raisedColor(context),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    popUpAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    onSelected: (index) {
      HapticFeedback.selectionClick();
      actions[index].onSelected();
    },
    itemBuilder: (_) => [
      for (var i = 0; i < actions.length; i++)
        PopupMenuItem(
          value: i,
          enabled: actions[i].enabled,
          child: Row(
            children: [
              Icon(
                actions[i].icon,
                size: 19,
                color: actions[i].destructive ? danger : muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  actions[i].label,
                  style: TextStyle(
                    color: actions[i].destructive ? danger : null,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// Keep optional content reachable without filling the initial screen.
class DetailDisclosure extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? leading;
  final ExpansibleController? controller;
  const DetailDisclosure({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.controller,
  });
  @override
  Widget build(BuildContext context) => Panel(
    padding: EdgeInsets.zero,
    child: ExpansionTile(
      key: PageStorageKey('details-$title'),
      controller: controller,
      maintainState: true,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      leading: leading,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: muted,
      expansionAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      children: [child],
    ),
  );
}

/// A soft atmospheric wash gives translucent controls something to blur while
/// keeping the content quiet and readable.
class TactileBackdrop extends StatelessWidget {
  final Widget child;
  const TactileBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-.78, -.9),
          radius: 1.18,
          colors: dark
              ? const [Color(0x263a7c87), Color(0x1818293b), darkCanvas]
              : const [Color(0xffdceff2), Color(0xffedf3f8), canvas],
          stops: const [0, .42, 1],
        ),
      ),
      child: child,
    );
  }
}

class TactileChoice extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const TactileChoice({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label appearance',
        child: PressFeedback(
          child: InkWell(
            key: Key('appearance$label'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
              decoration: BoxDecoration(
                color: selected
                    ? (dark ? const Color(0xff3d608f) : brandNavy)
                    : surfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected && dark
                      ? const Color(0xff7897b8)
                      : borderColor(context),
                  width: selected ? 1.25 : 1,
                ),
                boxShadow: selected && dark
                    ? const [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 14,
                          spreadRadius: -4,
                        ),
                      ]
                    : const [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? Colors.white
                        : secondaryTextColor(context),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
