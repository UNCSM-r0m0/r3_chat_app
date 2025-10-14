import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import '../../../core/utils/logger.dart';

/// Servicio de autenticación para OAuth (Google y GitHub)
class AuthService {
  static const String _backendUrl =
      'https://jeanett-uncolorable-pickily.ngrok-free.dev';

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Usar el Client ID de tu configuración
    serverClientId:
        '879782902938-2uafilq8en2mhertill5218t5hdct0i8.apps.googleusercontent.com',
  );

  /// Iniciar sesión con Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      AppLogger.auth(
        '🔐 Iniciando autenticación con Google',
        tag: 'AUTH_SERVICE',
      );

      // Intentar iniciar sesión con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        AppLogger.warning(
          '❌ Usuario canceló el inicio de sesión con Google',
          tag: 'AUTH_SERVICE',
        );
        return AuthResult.cancelled();
      }

      AppLogger.auth(
        '✅ Usuario autenticado con Google: ${googleUser.email}',
        tag: 'AUTH_SERVICE',
      );

      // Obtener tokens de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      AppLogger.debug('🔑 Tokens obtenidos de Google', tag: 'AUTH_SERVICE');

      // Enviar tokens al backend para validación
      final backendResult = await _sendTokensToBackend(
        accessToken: googleAuth.accessToken ?? '',
        idToken: googleAuth.idToken ?? '',
        provider: 'google',
        userInfo: {
          'email': googleUser.email,
          'name': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
        },
      );

      if (backendResult.success) {
        AppLogger.success(
          '🎉 Autenticación exitosa con backend',
          tag: 'AUTH_SERVICE',
        );
        return AuthResult.success(
          user: User(
            id: backendResult.userId ?? '',
            email: googleUser.email ?? '',
            name: googleUser.displayName ?? '',
            photoUrl: googleUser.photoUrl,
            provider: 'google',
          ),
          token: backendResult.token ?? '',
        );
      } else {
        AppLogger.error(
          '❌ Error en autenticación con backend: ${backendResult.error}',
          tag: 'AUTH_SERVICE',
        );
        return AuthResult.error(backendResult.error ?? 'Error desconocido');
      }
    } catch (error) {
      AppLogger.error(
        '💥 Error en Google Sign-In',
        tag: 'AUTH_SERVICE',
        error: error,
      );
      return AuthResult.error('Error al iniciar sesión con Google: $error');
    }
  }

  /// Iniciar sesión con GitHub
  Future<AuthResult> signInWithGitHub() async {
    try {
      AppLogger.auth(
        '🔐 Iniciando autenticación con GitHub',
        tag: 'AUTH_SERVICE',
      );

      // Construir URL de autorización de GitHub
      const String clientId = 'your_github_client_id'; // TODO: Configurar
      const String redirectUri =
          'https://jeanett-uncolorable-pickily.ngrok-free.dev/api/auth/github/callback';
      const String scope = 'user:email';

      final String authUrl =
          'https://github.com/login/oauth/authorize'
          '?client_id=$clientId'
          '&redirect_uri=$redirectUri'
          '&scope=$scope'
          '&state=flutter_app';

      AppLogger.network(
        '🌐 Abriendo navegador para GitHub OAuth: $authUrl',
        tag: 'AUTH_SERVICE',
      );

      // Abrir navegador para autenticación
      final Uri uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // TODO: Implementar captura del callback
        // Por ahora, retornamos un error indicando que necesita implementación
        return AuthResult.error(
          'GitHub OAuth requiere implementación adicional',
        );
      } else {
        return AuthResult.error('No se pudo abrir el navegador');
      }
    } catch (error) {
      AppLogger.error(
        '💥 Error en GitHub Sign-In',
        tag: 'AUTH_SERVICE',
        error: error,
      );
      return AuthResult.error('Error al iniciar sesión con GitHub: $error');
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      AppLogger.auth('🚪 Cerrando sesión', tag: 'AUTH_SERVICE');

      // Cerrar sesión de Google
      await _googleSignIn.signOut();

      // TODO: Cerrar sesión en backend

      AppLogger.success('✅ Sesión cerrada exitosamente', tag: 'AUTH_SERVICE');
    } catch (error) {
      AppLogger.error(
        '❌ Error al cerrar sesión',
        tag: 'AUTH_SERVICE',
        error: error,
      );
    }
  }

  /// Enviar tokens al backend para validación
  Future<BackendAuthResult> _sendTokensToBackend({
    required String? accessToken,
    required String? idToken,
    required String provider,
    required Map<String, dynamic> userInfo,
  }) async {
    try {
      AppLogger.network('📡 Enviando tokens al backend', tag: 'AUTH_SERVICE');

      final dio = Dio();

      final response = await dio.post(
        '$_backendUrl/api/auth/oauth/verify',
        data: {
          'accessToken': accessToken,
          'idToken': idToken,
          'provider': provider,
          'userInfo': userInfo,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return BackendAuthResult.success(
          token: data['access_token'],
          userId: data['user']['id'],
        );
      } else {
        return BackendAuthResult.error(
          'Error del servidor: ${response.statusCode}',
        );
      }
    } catch (error) {
      AppLogger.error(
        '💥 Error al comunicarse con backend',
        tag: 'AUTH_SERVICE',
        error: error,
      );
      return BackendAuthResult.error('Error de conexión: $error');
    }
  }
}

/// Resultado de autenticación
class AuthResult {
  final bool success;
  final String? error;
  final User? user;
  final String? token;

  AuthResult._({required this.success, this.error, this.user, this.token});

  factory AuthResult.success({required User user, required String token}) {
    return AuthResult._(success: true, user: user, token: token);
  }

  factory AuthResult.error(String error) {
    return AuthResult._(success: false, error: error);
  }

  factory AuthResult.cancelled() {
    return AuthResult._(
      success: false,
      error: 'Autenticación cancelada por el usuario',
    );
  }
}

/// Resultado de autenticación del backend
class BackendAuthResult {
  final bool success;
  final String? error;
  final String? token;
  final String? userId;

  BackendAuthResult._({
    required this.success,
    this.error,
    this.token,
    this.userId,
  });

  factory BackendAuthResult.success({
    required String token,
    required String userId,
  }) {
    return BackendAuthResult._(success: true, token: token, userId: userId);
  }

  factory BackendAuthResult.error(String error) {
    return BackendAuthResult._(success: false, error: error);
  }
}

/// Modelo de usuario
class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String provider;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.provider,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'provider': provider,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      photoUrl: json['photoUrl'],
      provider: json['provider'],
    );
  }
}
