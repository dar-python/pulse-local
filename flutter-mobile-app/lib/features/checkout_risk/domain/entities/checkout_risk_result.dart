class CheckoutRiskResult {
  const CheckoutRiskResult({
    required this.riskScore,
    required this.riskLevel,
    required this.recommendation,
    required this.source,
  });

  final double riskScore;
  final String riskLevel;
  final String recommendation;
  final String source;
}
