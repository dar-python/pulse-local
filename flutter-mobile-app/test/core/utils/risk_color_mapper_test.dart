import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/core/utils/risk_color_mapper.dart';

void main() {
  test('maps checkout risk levels to UI colors', () {
    expect(RiskColorMapper.colorFor('Low'), Colors.green);
    expect(RiskColorMapper.colorFor('Medium'), Colors.amber);
    expect(RiskColorMapper.colorFor('High'), Colors.red);
    expect(RiskColorMapper.colorFor('Unknown'), Colors.grey);
  });
}
