import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_layout.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryOrange,
      primary: AppColors.primaryDeep,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.lightOrange,
      onPrimaryContainer: AppColors.primaryInk,
      secondary: AppColors.sage,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.sageTint,
      onSecondaryContainer: AppColors.sage,
      surface: AppColors.white,
      onSurface: AppColors.darkText,
      surfaceContainerHighest: AppColors.surfaceMuted,
      outline: AppColors.neutralBorder,
      outlineVariant: AppColors.softBorder,
      error: AppColors.danger,
    );

    final textTheme = const TextTheme(
      headlineSmall: TextStyle(
        color: AppColors.charcoal,
        fontSize: 23,
        height: 1.22,
        letterSpacing: -0.5,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: AppColors.charcoal,
        fontSize: 19,
        height: 1.3,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: AppColors.charcoal,
        fontSize: 15.5,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: AppColors.charcoal,
        fontSize: 13.5,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.darkText,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: AppColors.darkText,
        fontSize: 14,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: AppColors.secondaryText,
        fontSize: 13,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        color: AppColors.white,
        fontSize: 14.5,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: TextStyle(
        color: AppColors.secondaryText,
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        color: AppColors.secondaryText,
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFonts.fontFamily,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      dividerColor: AppColors.softBorder,
      disabledColor: AppColors.neutralBorder,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.charcoal,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.xxl,
        toolbarHeight: kToolbarHeight,
        iconTheme: const IconThemeData(color: AppColors.darkText, size: 22),
        actionsIconTheme: const IconThemeData(
          color: AppColors.darkText,
          size: 22,
        ),
        titleTextStyle: const TextStyle(
          fontFamily: AppFonts.fontFamily,
          color: AppColors.charcoal,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.secondaryText, size: 22),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDeep,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.neutralBorder,
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: controlShape,
          textStyle: const TextStyle(
            fontFamily: AppFonts.fontFamily,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.charcoal,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          side: const BorderSide(color: AppColors.neutralBorder, width: 1.1),
          shape: controlShape,
          textStyle: const TextStyle(
            fontFamily: AppFonts.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryInk,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(
            fontFamily: AppFonts.fontFamily,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDeep,
        foregroundColor: AppColors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        extendedTextStyle: const TextStyle(
          fontFamily: AppFonts.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.softBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xl,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.neutralBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.neutralBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.primaryDeep,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
        labelStyle: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primaryInk,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 14,
        ),
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontSize: 13,
          height: 1.35,
        ),
        helperStyle: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 13,
        ),
        prefixIconColor: AppColors.secondaryText,
        suffixIconColor: AppColors.secondaryText,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.lightOrange,
        disabledColor: AppColors.canvasDeep,
        side: const BorderSide(color: AppColors.softBorder),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        labelStyle: const TextStyle(
          color: AppColors.charcoal,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.primaryInk,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: AppColors.primaryDeep,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryDeep
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
        side: const BorderSide(color: AppColors.neutralBorder, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryDeep
              : AppColors.primaryDeep.withValues(alpha: 0.2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryDeep
              : AppColors.neutralBorder,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.softBorder,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: AppFonts.fontFamily,
          color: AppColors.charcoal,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: AppFonts.fontFamily,
          color: AppColors.secondaryText,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl + 4),
          ),
        ),
        dragHandleColor: AppColors.softBorder,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.charcoal,
        contentTextStyle: const TextStyle(
          fontFamily: AppFonts.fontFamily,
          color: AppColors.white,
          fontSize: 13,
          height: 1.4,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        actionTextColor: AppColors.lightOrange,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryDeep,
        linearTrackColor: AppColors.canvasDeep,
        circularTrackColor: AppColors.canvasDeep,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: const TextStyle(
          fontFamily: AppFonts.fontFamily,
          color: AppColors.white,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        waitDuration: const Duration(milliseconds: 400),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primaryDeep,
        textColor: AppColors.darkText,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.fontFamily,
          color: AppColors.darkText,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: AppFonts.fontFamily,
          color: AppColors.secondaryText,
          fontSize: 12,
          height: 1.4,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primaryDeep,
        selectionColor: AppColors.primaryOrange.withValues(alpha: 0.22),
        selectionHandleColor: AppColors.primaryDeep,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
