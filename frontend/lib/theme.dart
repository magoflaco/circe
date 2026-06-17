import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class CirceBrand {
  static const String name = 'Circe';
  static const String tagline = 'Tu salud, guiada con cuidado';
  static const String logo = 'assets/branding/circe_app.png';
  static const String favicon = 'assets/branding/circe_favicon.png';
  static const String banner = 'assets/branding/circe_banner.jpg';
  static const String bgHorizontal =
      'assets/branding/circe_backgrownd_horizontal.jpeg';
  static const String bgVertical =
      'assets/branding/circe_backgrownd_vertical.jpeg';
  static const String introVideo = 'assets/branding/circe_intro.mp4';
  static const String introLastFrame =
      'assets/branding/circe_ultimo_fotograma.png';
}
class AppColors {
  static const teal = Color(0xFF3FB7A6);
  static const tealSoft = Color(0xFF8FD9CE);
  static const blue = Color(0xFF5BA8E0);
  static const blueSoft = Color(0xFFAFD6F2);
  static const lavender = Color(0xFF9E8FE0);
  static const lavenderSoft = Color(0xFFCFC4F2);
  static const rose = Color(0xFFDB6FA8);
  static const roseSoft = Color(0xFFF1B9D6);
  static const purple = Color(0xFF7E5BC4);
  static const primary = Color(0xFF6AA9DC);
  static const primaryDark = Color(0xFF4F8FD0);
  static const mint = tealSoft;
  static const peach = Color(0xFFF6C9A8);
  static const bg = Color(0xFFF7F5EE); 
  static const bgAlt = Color(0xFFFFFFFF);
  static const card = Colors.white;
  static const ink = Color(0xFF33414F);
  static const inkSoft = Color(0xFF7E8B9C);
  static const ok = Color(0xFF45C39A);
  static const warn = Color(0xFFF5B45C);
  static const danger = Color(0xFFEC6A72);
  static const brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [teal, blue, lavender, rose],
  );
  static const titleGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [purple, lavender, rose],
  );
  static const brandGradientDiagonal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, blue, lavender, rose],
  );
}
class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.lavender,
        primary: AppColors.primaryDark,
        surface: AppColors.bg,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFBFAF6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6E1F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6E1F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lavender, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: AppColors.lavender.withValues(alpha: 0.16),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];
  static List<BoxShadow> get glow => [
        BoxShadow(
          color: AppColors.lavender.withValues(alpha: 0.28),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ];
}