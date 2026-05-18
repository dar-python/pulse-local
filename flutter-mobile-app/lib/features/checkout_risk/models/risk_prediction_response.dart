import '../domain/entities/checkout_risk_result.dart';

class RiskPredictionResponse {
  const RiskPredictionResponse({
    required this.success,
    required this.source,
    required this.riskScore,
    required this.riskLevel,
    required this.recommendation,
    this.etaRange = '30-45 min',
  });

  final bool success;
  final String source;
  final double riskScore;
  final String riskLevel;
  final String recommendation;
  final String etaRange;

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
    );
  }

  CheckoutRiskResult toEntity() {
    return CheckoutRiskResult(
      riskScore: riskScore,
      riskLevel: riskLevel,
      recommendation: recommendation,
      source: source,
      etaRange: etaRange,
    );
  }
}
