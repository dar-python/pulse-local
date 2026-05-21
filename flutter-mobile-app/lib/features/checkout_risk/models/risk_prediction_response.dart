import '../domain/entities/checkout_risk_result.dart';

class RiskAdvisoryReason {
  const RiskAdvisoryReason({required this.code, required this.label});

  final String code;
  final String label;

  bool get isDelayReason {
    return const {
      'stormy_weather',
      'heavy_traffic',
      'long_preparation',
      'long_distance',
      'limited_rider_availability',
      'rainy_weather',
      'peak_hour',
      'medium_traffic',
    }.contains(code);
  }

  factory RiskAdvisoryReason.fromJson(Map<String, dynamic> json) {
    return RiskAdvisoryReason(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class RiskWeather {
  const RiskWeather({
    required this.category,
    this.conditionText,
    this.conditionCode,
    this.temperatureC,
    this.precipMm,
    required this.source,
    this.observedAt,
    this.latitude,
    this.longitude,
  });

  final String category;
  final String? conditionText;
  final int? conditionCode;
  final double? temperatureC;
  final double? precipMm;
  final String source;
  final DateTime? observedAt;
  final double? latitude;
  final double? longitude;

  bool get isFallback => source.toLowerCase() == 'fallback';

  String get displayCategory {
    final normalized = category.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'Unknown';
    }

    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  factory RiskWeather.fromJson(Map<String, dynamic> json) {
    return RiskWeather(
      category: json['category']?.toString() ?? 'clear',
      conditionText: _stringOrNull(json['condition_text']),
      conditionCode: (json['condition_code'] as num?)?.toInt(),
      temperatureC: (json['temperature_c'] as num?)?.toDouble(),
      precipMm: (json['precip_mm'] as num?)?.toDouble(),
      source: json['source']?.toString() ?? 'fallback',
      observedAt: DateTime.tryParse(json['observed_at']?.toString() ?? ''),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class RiskPredictionResponse {
  const RiskPredictionResponse({
    required this.success,
    required this.source,
    required this.riskScore,
    required this.riskLevel,
    required this.recommendation,
    this.etaRange = '30-45 min',
    this.advisoryMessage = '',
    this.advisoryReasons = const [],
    this.weather,
  });

  final bool success;
  final String source;
  final double riskScore;
  final String riskLevel;
  final String recommendation;
  final String etaRange;
  final String advisoryMessage;
  final List<RiskAdvisoryReason> advisoryReasons;
  final RiskWeather? weather;

  int get riskPercent {
    final percent = riskScore <= 1 ? riskScore * 100 : riskScore;
    return percent.round().clamp(0, 100).toInt();
  }

  factory RiskPredictionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Checkout risk response is missing data.');
    }

    final riskScore = data['risk_score'];
    if (riskScore is! num) {
      throw const FormatException('Checkout risk response has invalid score.');
    }

    return RiskPredictionResponse(
      success: json['success'] == true,
      source: json['source']?.toString() ?? 'unknown',
      riskScore: riskScore.toDouble(),
      riskLevel: data['risk_level']?.toString() ?? 'Unknown',
      recommendation:
          data['recommendation']?.toString() ??
          'No recommendation was returned.',
      etaRange: data['eta_range']?.toString() ?? '30-45 min',
      advisoryMessage: data['advisory_message']?.toString() ?? '',
      advisoryReasons: (data['advisory_reasons'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RiskAdvisoryReason.fromJson)
          .toList(growable: false),
      weather: data['weather'] is Map<String, dynamic>
          ? RiskWeather.fromJson(data['weather'] as Map<String, dynamic>)
          : null,
    );
  }

  CheckoutRiskResult toEntity() {
    return CheckoutRiskResult(
      riskScore: riskScore,
      riskLevel: riskLevel,
      recommendation: recommendation,
      source: source,
      etaRange: etaRange,
      weatherCategory: weather?.category,
      weatherCondition: weather?.conditionText,
      weatherSource: weather?.source,
    );
  }
}

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
