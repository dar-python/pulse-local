import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/app/app.dart';

void main() {
  testWidgets('checkout risk screen renders the Sprint 1 input contract', (
    tester,
  ) async {
    await tester.pumpWidget(const PulseLocalApp());

    expect(find.text('PulseLocal Checkout'), findsOneWidget);
    expect(find.text('Fulfillment Risk Check'), findsOneWidget);
    expect(find.text('Rider to order ratio'), findsOneWidget);
    expect(find.text('Merchant prep time'), findsOneWidget);
    expect(find.text('Traffic corridor intensity'), findsOneWidget);
    expect(find.text('Weather category'), findsOneWidget);
    expect(find.text('Delivery distance'), findsOneWidget);
    expect(find.text('Address complexity'), findsOneWidget);
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.text('Calculate Fulfillment Risk'), findsOneWidget);
    expect(find.text('traffic_level'), findsNothing);
    expect(find.text('heavy'), findsNothing);
  });
}
