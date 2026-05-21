import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/checkout_risk_request.dart';
import '../controllers/checkout_risk_controller.dart';

class CheckoutInputForm extends ConsumerStatefulWidget {
  const CheckoutInputForm({super.key});

  @override
  ConsumerState<CheckoutInputForm> createState() => _CheckoutInputFormState();
}

class _CheckoutInputFormState extends ConsumerState<CheckoutInputForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _riderRatioController;
  late final TextEditingController _merchantPrepController;
  late final TextEditingController _distanceController;

  String _trafficCorridorIntensity = 'high';
  String _addressComplexity = 'medium';
  String _paymentMethod = 'cod';

  @override
  void initState() {
    super.initState();
    final sample = CheckoutRiskController.sampleRequest;
    _riderRatioController = TextEditingController(
      text: sample.riderToOrderRatio.toString(),
    );
    _merchantPrepController = TextEditingController(
      text: sample.merchantPrepTime.toString(),
    );
    _distanceController = TextEditingController(
      text: sample.deliveryDistanceKm.toString(),
    );
    _trafficCorridorIntensity = sample.trafficCorridorIntensity;
    _addressComplexity = sample.addressComplexity;
    _paymentMethod = sample.paymentMethod;
  }

  @override
  void dispose() {
    _riderRatioController.dispose();
    _merchantPrepController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutRiskControllerProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _riderRatioController,
            decoration: const InputDecoration(
              labelText: 'Rider to order ratio',
              hintText: '0.45',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _validateDouble,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _merchantPrepController,
            decoration: const InputDecoration(
              labelText: 'Merchant prep time',
              suffixText: 'minutes',
            ),
            keyboardType: TextInputType.number,
            validator: _validateInt,
          ),
          const SizedBox(height: 12),
          _DropdownField(
            label: 'Traffic corridor intensity',
            value: _trafficCorridorIntensity,
            values: const ['low', 'medium', 'high'],
            onChanged: (value) {
              setState(() => _trafficCorridorIntensity = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _distanceController,
            decoration: const InputDecoration(
              labelText: 'Delivery distance',
              suffixText: 'km',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _validateDouble,
          ),
          const SizedBox(height: 12),
          _DropdownField(
            label: 'Address complexity',
            value: _addressComplexity,
            values: const ['low', 'medium', 'high'],
            onChanged: (value) {
              setState(() => _addressComplexity = value);
            },
          ),
          const SizedBox(height: 12),
          _DropdownField(
            label: 'Payment method',
            value: _paymentMethod,
            values: const ['cod', 'cash', 'gcash', 'card'],
            onChanged: (value) {
              setState(() => _paymentMethod = value);
            },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: state.isLoading ? null : _submit,
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Calculate Fulfillment Risk'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final request = CheckoutRiskRequest(
      riderToOrderRatio: double.parse(_riderRatioController.text.trim()),
      merchantPrepTime: int.parse(_merchantPrepController.text.trim()),
      trafficCorridorIntensity: _trafficCorridorIntensity,
      deliveryDistanceKm: double.parse(_distanceController.text.trim()),
      addressComplexity: _addressComplexity,
      paymentMethod: _paymentMethod,
    );

    ref.read(checkoutRiskControllerProvider.notifier).calculateRisk(request);
  }

  String? _validateDouble(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null) {
      return 'Enter a valid number.';
    }

    return null;
  }

  String? _validateInt(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) {
      return 'Enter a valid whole number.';
    }

    return null;
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Select $label.';
        }

        return null;
      },
    );
  }
}
