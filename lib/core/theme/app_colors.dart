import 'package:flutter/material.dart';

/// Colores de la aplicación basados en el frontend React
/// Mantiene consistencia con el diseño existente
class AppColors {
  // Colores base del tema oscuro
  static const Color background = Color(0xFF121212); // rgb(18 18 18)
  static const Color surface = Color(0xFF1F2937); // gray-800
  static const Color surfaceVariant = Color(0xFF374151); // gray-700

  // Colores de texto
  static const Color textPrimary = Color(0xFFFFFFFF); // white
  static const Color textSecondary = Color(0xFFE5E7EB); // gray-100
  static const Color textTertiary = Color(0xFF94A3B8); // gray-400

  // Colores de acento (gradiente púrpura-rosa)
  static const Color primary = Color(0xFF9333EA); // purple-600
  static const Color primaryVariant = Color(0xFFEC4899); // pink-600
  static const Color primaryLight = Color(0xFFA855F7); // purple-500

  // Colores de estado
  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color info = Color(0xFF3B82F6); // blue-500

  // Colores de chat
  static const Color userMessage = Color(0xFF9333EA); // purple-600
  static const Color assistantMessage = Color(0xFF1F2937); // gray-800
  static const Color messageBorder = Color(0xFF374151); // gray-700

  // Colores de botones
  static const Color buttonPrimary = Color(0xFF9333EA);
  static const Color buttonSecondary = Color(0xFF374151);
  static const Color buttonDisabled = Color(0xFF6B7280);

  // Colores de bordes
  static const Color border = Color(0xFF374151); // gray-700
  static const Color borderLight = Color(0xFF4B5563); // gray-600

  // Colores de código
  static const Color codeBackground = Color(0xFF0B1020);
  static const Color codeBorder = Color(0x0FFFFFFF); // rgba(255, 255, 255, .06)
  static const Color codeText = Color(0xFFE5E7EB);
  static const Color inlineCodeBackground = Color(
    0x5427272A,
  ); // rgba(39, 39, 42, .85)

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF9333EA), Color(0xFFEC4899)], // purple-600 to pink-600
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient userMessageGradient = LinearGradient(
    colors: [Color(0xFF9333EA), Color(0xFFEC4899)], // purple-600 to pink-600
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Sombras
  static const List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: Color(0x409333EA), // purple-600 with 25% opacity
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> messageShadow = [
    BoxShadow(
      color: Color(0x801F2937), // gray-800 with 50% opacity
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
}

/// Extension para facilitar el uso de colores en el tema
extension AppColorsExtension on ColorScheme {
  Color get background => AppColors.background;
  Color get surface => AppColors.surface;
  Color get primaryGradientStart => AppColors.primary;
  Color get primaryGradientEnd => AppColors.primaryVariant;
  Color get userMessage => AppColors.userMessage;
  Color get assistantMessage => AppColors.assistantMessage;
}
