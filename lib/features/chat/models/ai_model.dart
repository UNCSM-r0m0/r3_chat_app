/// Modelo para representar un modelo de IA disponible
class AIModel {
  final String id;
  final String name;
  final String provider;
  final bool available;
  final bool isPremium;
  final List<String> features;
  final String description;
  final String defaultModel;

  const AIModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.available,
    required this.isPremium,
    required this.features,
    required this.description,
    required this.defaultModel,
  });

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      provider: json['provider'] ?? '',
      available: json['available'] ?? false,
      isPremium: json['isPremium'] ?? false,
      features: List<String>.from(json['features'] ?? []),
      description: json['description'] ?? '',
      defaultModel: json['defaultModel'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      'available': available,
      'isPremium': isPremium,
      'features': features,
      'description': description,
      'defaultModel': defaultModel,
    };
  }

  @override
  String toString() {
    return 'AIModel(id: $id, name: $name, provider: $provider, available: $available, isPremium: $isPremium)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Respuesta del endpoint de modelos disponibles
class AvailableModelsResponse {
  final List<AIModel> models;

  const AvailableModelsResponse({required this.models});

  factory AvailableModelsResponse.fromJson(Map<String, dynamic> json) {
    final modelsList = json['models'] as List<dynamic>? ?? [];
    return AvailableModelsResponse(
      models: modelsList.map((model) => AIModel.fromJson(model)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'models': models.map((model) => model.toJson()).toList()};
  }
}
