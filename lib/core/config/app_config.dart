/// Configuración centralizada de la aplicación
class AppConfig {
  // URL del backend - cambiar según tu configuración
  static const String backendUrl = 'https://api.r0lm0.dev';

  // URLs específicas
  static const String apiBaseUrl = '$backendUrl/api';

  // Configuración de Google OAuth
  static const String googleClientId =
      '1079549506133-2ot3e6ehdv92ms53dji0cb2lspnp6i52.apps.googleusercontent.com';

  // Configuración de GitHub OAuth
  static const String githubClientId =
      'your_github_client_id'; // TODO: Configurar

  // URLs de callback
  static const String googleCallbackUrl =
      '$backendUrl/api/auth/google/callback';
  static const String githubCallbackUrl =
      '$backendUrl/api/auth/github/callback';

  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 120);
}
