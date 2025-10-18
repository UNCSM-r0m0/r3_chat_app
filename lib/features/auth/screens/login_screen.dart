import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:feather_icons/feather_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../services/auth_service.dart';
import '../providers/auth_providers.dart';
import '../../chat/screens/chat_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    AppLogger.info('🎨 Construyendo pantalla de login', tag: 'LOGIN');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Color(0xFF9333EA), // Purple glow
              Color(0xFF121212), // Background
            ],
            stops: [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back to Chat link
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        // TODO: Navigate back to chat
                      },
                      icon: const Icon(
                        FeatherIcons.chevronLeft,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      label: Text(
                        'Back to Chat',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  // Login Card
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(maxWidth: 400.w),
                    padding: EdgeInsets.all(32.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome text
                        Text(
                          'Welcome to',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: 8.h),

                        // R3.chat title with gradient
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: Text(
                            'R3.chat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Description
                        Text(
                          'Sign in below (we\'ll increase your message limits if you do) 😊',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),

                        SizedBox(height: 32.h),

                        // Google Sign In Button
                        _buildGoogleButton(context),

                        SizedBox(height: 16.h),

                        // GitHub Sign In Button
                        _buildGitHubButton(context),

                        if (_isLoading) ...[
                          SizedBox(height: 16.h),
                          const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ],

                        SizedBox(height: 24.h),

                        // Terms and Privacy
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              const TextSpan(
                                text: 'By continuing, you agree to our ',
                              ),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildGoogleButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _handleGoogleSignIn(context),
          icon: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.g_mobiledata, size: 20, color: Colors.white),
          label: Text(
            _isLoading ? 'Iniciando sesión...' : 'Continue with Google',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGitHubButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _handleGitHubSignIn(context),
        icon: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textPrimary,
                  ),
                ),
              )
            : const Icon(
                FeatherIcons.github,
                size: 20,
                color: AppColors.textPrimary,
              ),
        label: Text(
          _isLoading ? 'Iniciando sesión...' : 'Continue with GitHub',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceVariant,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    if (_isLoading) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    AppLogger.auth(
      '🔐 Usuario intenta iniciar sesión con Google',
      tag: 'LOGIN',
    );

    try {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final result = await _authService.signInWithGoogle();

      if (result.success && result.user != null) {
        AppLogger.success('🎉 Autenticación exitosa con Google', tag: 'LOGIN');

        // Consultar suscripción real y actualizar estado
        final isPro = await _authService.fetchIsPro();
        ref.read(authStateProvider.notifier).setUser(result.user!, isPro: isPro);

        // Mostrar mensaje y navegar al chat
        messenger.showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido, ${result.user!.name}!'),
            backgroundColor: AppColors.success,
          ),
        );

        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
      } else {
        AppLogger.error(
          '❌ Error en autenticación: ${result.error}',
          tag: 'LOGIN',
        );

        messenger.showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Error desconocido'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (error) {
      AppLogger.error(
        '💥 Error inesperado en Google Sign-In',
        tag: 'LOGIN',
        error: error,
      );

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Error inesperado. Inténtalo de nuevo.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGitHubSignIn(BuildContext context) async {
    if (_isLoading) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    AppLogger.auth(
      '🔐 Usuario intenta iniciar sesión con GitHub',
      tag: 'LOGIN',
    );

    try {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final result = await _authService.signInWithGitHub();

      if (result.success && result.user != null) {
        AppLogger.success('🎉 Autenticación exitosa con GitHub', tag: 'LOGIN');

        // Consultar suscripción real y actualizar estado
        final isPro = await _authService.fetchIsPro();
        ref.read(authStateProvider.notifier).setUser(result.user!, isPro: isPro);

        messenger.showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido, ${result.user!.name}!'),
            backgroundColor: AppColors.success,
          ),
        );

        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
      } else {
        AppLogger.error(
          '❌ Error en autenticación: ${result.error}',
          tag: 'LOGIN',
        );

        messenger.showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Error desconocido'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (error) {
      AppLogger.error(
        '💥 Error inesperado en GitHub Sign-In',
        tag: 'LOGIN',
        error: error,
      );

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Error inesperado. Inténtalo de nuevo.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
