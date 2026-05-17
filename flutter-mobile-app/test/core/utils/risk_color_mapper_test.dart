import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/core/theme/app_colors.dart';
import 'package:pulse_local_app/core/utils/risk_color_mapper.dart';

void main() {
  test('maps checkout risk levels to UI colors', () {
    expect(RiskColorMapper.colorFor('Low'), AppColors.green);
    expect(RiskColorMapper.colorFor('Medium'), AppColors.orange);
    expect(RiskColorMapper.colorFor('High'), AppColors.tangerine);
    expect(RiskColorMapper.colorFor('Unknown'), AppColors.silver);
  });

  test('maps score thresholds using the official PulseLocal bands', () {
    expect(RiskColorMapper.labelForScore(0), 'Low');
    expect(RiskColorMapper.labelForScore(39), 'Low');
    expect(RiskColorMapper.labelForScore(40), 'Medium');
    expect(RiskColorMapper.labelForScore(68), 'Medium');
    expect(RiskColorMapper.labelForScore(69), 'Medium');
    expect(RiskColorMapper.labelForScore(70), 'High');
    expect(RiskColorMapper.labelForScore(100), 'High');
    expect(RiskColorMapper.labelForScore(101), 'Unknown');
  });
}
