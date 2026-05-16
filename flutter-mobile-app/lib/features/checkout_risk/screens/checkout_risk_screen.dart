import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/risk_color_mapper.dart';
import '../models/checkout_risk_request.dart';
import '../models/risk_prediction_response.dart';
import '../services/checkout_risk_api_service.dart';

class CheckoutRiskScreen extends StatefulWidget {
  const CheckoutRiskScreen({super.key, CheckoutRiskApiService? apiService})
    : _apiService = apiService;

  final CheckoutRiskApiService? _apiService;

  @override
  State<CheckoutRiskScreen> createState() => _CheckoutRiskScreenState();
}

class _CheckoutRiskScreenState extends State<CheckoutRiskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _riderRatioController = TextEditingController(text: '0.45');
  final _merchantPrepController = TextEditingController(text: '25');
  final _distanceController = TextEditingController(text: '4.2');

  late final CheckoutRiskApiService _apiService;
  String _trafficCorridorIntensity = 'high';
  String _weatherCategory = 'rainy';
  String _addressComplexity = 'medium';
  String _paymentMethod = 'cod';
  bool _isLoading = false;
  RiskPredictionResponse? _prediction;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = widget._apiService ?? CheckoutRiskApiService();
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
            _buildForm(),
            const SizedBox(height: 24),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null) _ErrorMessage(message: _errorMessage!),
            if (!_isLoading && _prediction != null)
              _RiskPredictionCard(prediction: _prediction!),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
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
          _DropdownField(
            label: 'Weather category',
            value: _weatherCategory,
            values: const ['clear', 'rainy', 'stormy'],
            onChanged: (value) {
              setState(() => _weatherCategory = value);
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
            onPressed: _isLoading ? null : _submit,
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Calculate Fulfillment Risk'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _prediction = null;
      _errorMessage = null;
    });

    final request = CheckoutRiskRequest(
      riderToOrderRatio: double.parse(_riderRatioController.text.trim()),
      merchantPrepTime: int.parse(_merchantPrepController.text.trim()),
      trafficCorridorIntensity: _trafficCorridorIntensity,
      weatherCategory: _weatherCategory,
      deliveryDistanceKm: double.parse(_distanceController.text.trim()),
      addressComplexity: _addressComplexity,
      paymentMethod: _paymentMethod,
    );

    try {
      final prediction = await _apiService.predictRisk(request);
      if (!mounted) {
        return;
      }
      setState(() => _prediction = prediction);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = _friendlyErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  String _friendlyErrorMessage(Object error) {
    if (error is ApiException) {
      return 'Unable to calculate fulfillment risk. ${error.message}';
    }

    return 'Unable to calculate fulfillment risk. Check the Laravel API and try again.';
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

class _RiskPredictionCard extends StatelessWidget {
  const _RiskPredictionCard({required this.prediction});

  final RiskPredictionResponse prediction;

  @override
  Widget build(BuildContext context) {
    final color = RiskColorMapper.colorFor(prediction.riskLevel);
    final riskPercent = (prediction.riskScore * 100).round();

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Level: ${prediction.riskLevel}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text('Risk Score: $riskPercent%'),
            const SizedBox(height: 8),
            Text(prediction.recommendation),
            const SizedBox(height: 12),
            Text(
              'Source: ${prediction.source}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

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
                message,
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
