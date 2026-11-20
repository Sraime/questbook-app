import 'package:material_ui/material_ui.dart';

import '../design_system/tokens/colors.dart';
import '../design_system/tokens/typography.dart';

ThemeData buildQuestbookTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: QBColors.bgPage,
    colorScheme: ColorScheme.fromSeed(
      seedColor: QBColors.leather700,
      primary: QBColors.leather700,
      secondary: QBColors.gold600,
      surface: QBColors.surfaceCard,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: QBColors.textBody,
      displayColor: QBColors.textStrong,
      fontFamily: QBType.body().fontFamily,
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(color: QBColors.ink900),
    ),
  );
}
