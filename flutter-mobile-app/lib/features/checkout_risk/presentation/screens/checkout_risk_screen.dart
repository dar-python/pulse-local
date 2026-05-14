import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/checkout_risk_controller.dart';
import '../widgets/checkout_input_form.dart';
import '../widgets/risk_result_card.dart';

class CheckoutRiskScreen extends ConsumerWidget {
  const CheckoutRiskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutRiskControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PulseLocal Checkout')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Fulfillment Risk Check',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Estimate checkout fulfillment risk through the Laravel API before placing the order.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            const CheckoutInputForm(),
            const SizedBox(height: 24),
            if (state.status == CheckoutRiskStatus.loading)
              const Center(child: CircularProgressIndicator()),
            if (state.status == CheckoutRiskStatus.success &&
                state.result != null)
              RiskResultCard(result: state.result!),
            if (state.status == CheckoutRiskStatus.error)
              _ErrorMessage(message: state.errorMessage),
          ],
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message ??
                    'Unable to calculate fulfillment risk. Check the inputs and try again.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
