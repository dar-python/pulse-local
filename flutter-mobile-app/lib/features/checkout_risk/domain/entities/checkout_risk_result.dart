class CheckoutRiskResult {
  const CheckoutRiskResult({
    required this.riskScore,
    required this.riskLevel,
    required this.recommendation,
    required this.source,
    this.etaRange = '30-45 min',
    this.weatherCategory,
    this.weatherCondition,
    this.weatherSource,
  });

  final double riskScore;
  final String riskLevel;
  final String recommendation;
  final String source;
  final String etaRange;
  final String? weatherCategory;
  final String? weatherCondition;
  final String? weatherSource;
}
