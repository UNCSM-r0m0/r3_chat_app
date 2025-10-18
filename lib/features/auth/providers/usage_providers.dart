import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/usage_service.dart';

/// Provider para el servicio de estadísticas de uso
final usageServiceProvider = Provider<UsageService>((ref) {
  return UsageService();
});

/// Provider para las estadísticas de uso del usuario
final usageStatsProvider = FutureProvider<UsageStats>((ref) async {
  try {
    final usageService = ref.read(usageServiceProvider);
    return await usageService.getUsageStats();
  } catch (error) {
    // En caso de error, devolver estadísticas por defecto para evitar crashes
    return const UsageStats(
      todayMessages: 0,
      todayTokens: 0,
      totalMessages: 0,
      totalTokens: 0,
      tier: 'FREE',
      limits: UsageLimits(
        messagesPerDay: 20,
        maxTokensPerMessage: 4096,
        canUploadImages: false,
      ),
    );
  }
});

/// Provider para el estado de carga de las estadísticas
final usageStatsStateProvider =
    StateNotifierProvider<UsageStatsNotifier, AsyncValue<UsageStats>>((ref) {
      return UsageStatsNotifier(ref.read(usageServiceProvider));
    });

/// Notifier para manejar el estado de las estadísticas de uso
class UsageStatsNotifier extends StateNotifier<AsyncValue<UsageStats>> {
  final UsageService _usageService;

  UsageStatsNotifier(this._usageService) : super(const AsyncValue.loading()) {
    loadStats();
  }

  /// Cargar estadísticas de uso
  Future<void> loadStats() async {
    try {
      state = const AsyncValue.loading();
      final stats = await _usageService.getUsageStats();
      state = AsyncValue.data(stats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refrescar estadísticas
  Future<void> refresh() async {
    await loadStats();
  }
}
