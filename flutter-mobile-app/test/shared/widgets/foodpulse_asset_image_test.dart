import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/shared/widgets/foodpulse_asset_image.dart';

void main() {
  testWidgets('shows fallback label when no image asset is provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FoodPulseAssetImage(
          imageAsset: null,
          fallbackLabel: 'TG',
          width: 48,
          height: 48,
        ),
      ),
    );

    expect(find.text('TG'), findsOneWidget);
  });

  testWidgets('shows fallback label when image asset cannot be loaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FoodPulseAssetImage(
          imageAsset: 'assets/images/foods/missing-food.webp',
          fallbackLabel: 'MF',
          width: 48,
          height: 48,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
