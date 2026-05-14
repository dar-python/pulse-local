import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_local_app/app/app.dart';

void main() {
  testWidgets('checkout risk screen renders sprint one form', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PulseLocalApp()));

    expect(find.text('PulseLocal Checkout'), findsOneWidget);
    expect(find.text('Fulfillment Risk Check'), findsOneWidget);
    expect(find.text('Rider to order ratio'), findsOneWidget);
    expect(find.text('Merchant prep time'), findsOneWidget);
    expect(find.text('Check fulfillment risk'), findsOneWidget);
  });
}
