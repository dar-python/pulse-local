import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../foodpulse/models/foodpulse_order.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.order});

  final OrderConfirmation order;

  @override
  Widget build(BuildContext context) {
    final itemsLabel = order.items
        .map((item) => '${item.quantity}x ${item.name}')
        .join(', ');
    final activeStepIndex = _activeStepIndex(order.trackingSteps);

    return Scaffold(
      backgroundColor: AppColors.prussian,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Header(order: order),
            const SizedBox(height: 12),
            _TrackingMapCard(order: order),
            const SizedBox(height: 12),
            _EtaProgressCard(order: order, activeStepIndex: activeStepIndex),
            const SizedBox(height: 12),
            _RiderDetailsCard(rider: order.rider),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(label: 'Restaurant', value: order.restaurant.name),
                  _DetailRow(label: 'Items', value: itemsLabel),
                  _DetailRow(
                    label: 'Payment',
                    value: order.paymentMethod.toUpperCase(),
                  ),
                  _DetailRow(label: 'Total', value: 'P${order.total}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _activeStepIndex(List<FoodPulseTrackingStep> steps) {
    if (steps.isEmpty) {
      return 2;
    }

    final lastDone = steps.lastIndexWhere((step) => step.done);
    if (lastDone < 0) {
      return 0;
    }

    return math.min(lastDone + 1, steps.length - 1);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order});

  final OrderConfirmation order;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.arrow_back_rounded, color: AppColors.white),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'On the way',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Order #${order.orderNumber}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.silver, fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.green.withAlpha(24),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.green.withAlpha(72)),
          ),
          child: const Text(
            'LIVE',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackingMapCard extends StatelessWidget {
  const _TrackingMapCard({required this.order});

  final OrderConfirmation order;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 230,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(painter: _TrackingMapPainter()),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: _MapPill(
                icon: Icons.near_me_rounded,
                text: '${_shortEta(order.estimatedArrival)} away',
              ),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: _DestinationPill(label: 'Lnu gate Independencia St'),
            ),
            const Positioned(
              left: 82,
              top: 133,
              child: _MapPoint(icon: Icons.storefront_rounded),
            ),
            Positioned(
              right: 130,
              top: 62,
              child: _RiderMapMarker(rider: order.rider),
            ),
          ],
        ),
      ),
    );
  }

  String _shortEta(String eta) {
    final normalized = eta.trim();
    if (normalized.isEmpty) {
      return '10-15 min';
    }

    return normalized.replaceAll(' min', 'm');
  }
}

class _EtaProgressCard extends StatelessWidget {
  const _EtaProgressCard({
    required this.order,
    required this.activeStepIndex,
  });

  final OrderConfirmation order;
  final int activeStepIndex;

  @override
  Widget build(BuildContext context) {
    final labels = _labels();
    final progress = labels.length <= 1
        ? 0.0
        : activeStepIndex.clamp(0, labels.length - 1) / (labels.length - 1);

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Estimated arrival',
                  style: TextStyle(color: AppColors.white, fontSize: 13),
                ),
              ),
              Text(
                order.estimatedArrival,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 60,
            child: Stack(
              children: [
                Positioned(
                  left: 10,
                  right: 10,
                  top: 13,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: AppColors.white.withAlpha(35),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.green,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var index = 0; index < labels.length; index++)
                      _ProgressStep(
                        label: labels[index],
                        active: index <= activeStepIndex,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _labels() {
    return const ['Order Placed', 'Preparing', 'On the way', 'Delivered'];
  }
}

class _RiderDetailsCard extends StatelessWidget {
  const _RiderDetailsCard({required this.rider});

  final FoodPulseRider rider;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rider Details',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RiderAvatar(size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.name,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your Rider',
                      style: TextStyle(color: AppColors.silver, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _RatingBadge(rating: rider.rating),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _VehiclePill(
                  icon: Icons.two_wheeler_rounded,
                  label: rider.vehicleType,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VehiclePill(
                  icon: Icons.confirmation_number_outlined,
                  label: rider.plateNumber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: Icons.call_outlined,
                  label: 'Call',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackingMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFF0D1B2F);
    canvas.drawRect(Offset.zero & size, background);

    final gridPaint = Paint()
      ..color = AppColors.white.withAlpha(12)
      ..strokeWidth = 1;

    for (var x = 0.0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x + 30, size.height), gridPaint);
    }
    for (var y = 18.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 22), gridPaint);
    }

    final route = Path()
      ..moveTo(size.width * 0.18, size.height * 0.66)
      ..lineTo(size.width * 0.30, size.height * 0.70)
      ..lineTo(size.width * 0.44, size.height * 0.62)
      ..lineTo(size.width * 0.50, size.height * 0.46)
      ..lineTo(size.width * 0.56, size.height * 0.50)
      ..lineTo(size.width * 0.61, size.height * 0.31);

    final shadowPaint = Paint()
      ..color = AppColors.prussian.withAlpha(130)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final routePaint = Paint()
      ..color = AppColors.alabaster
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final completedPaint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(route, shadowPaint);
    canvas.drawPath(route, routePaint);
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.66),
      Offset(size.width * 0.30, size.height * 0.70),
      completedPaint,
    );

    _drawMapText(canvas, 'Tacloban City', Offset(22, size.height * 0.42), 13);
    _drawMapText(canvas, 'Downtown', Offset(size.width * 0.64, 72), 10);
    _drawMapText(canvas, 'LEYTE', Offset(size.width - 58, 86), 10);
  }

  void _drawMapText(Canvas canvas, String text, Offset offset, double size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.alabaster.withAlpha(150),
          fontSize: size,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPill extends StatelessWidget {
  const _MapPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.prussian.withAlpha(210),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.orange.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.orange, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationPill extends StatelessWidget {
  const _DestinationPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.prussian.withAlpha(220),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white.withAlpha(24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: AppColors.alabaster,
            size: 17,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderMapMarker extends StatelessWidget {
  const _RiderMapMarker({required this.rider});

  final FoodPulseRider rider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RiderAvatar(size: 44),
        const SizedBox(height: 3),
        Text(
          rider.name.split(' ').first,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MapPoint extends StatelessWidget {
  const _MapPoint({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.prussian,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.alabaster, width: 2),
      ),
      child: Icon(icon, color: AppColors.alabaster, size: 15),
    );
  }
}

class _RiderAvatar extends StatelessWidget {
  const _RiderAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.green.withAlpha(40),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.alabaster, width: 2),
      ),
      child: Icon(
        Icons.delivery_dining_rounded,
        color: AppColors.green,
        size: size * 0.58,
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: active ? AppColors.green : AppColors.prussian,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? AppColors.green : AppColors.silver,
                width: 2,
              ),
            ),
            child: Icon(
              active ? Icons.check_rounded : Icons.circle_outlined,
              color: active ? AppColors.prussian : AppColors.silver,
              size: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? AppColors.white : AppColors.silver,
              fontSize: 9,
              height: 1.1,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.orange.withAlpha(22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.star_rounded, color: AppColors.orange, size: 13),
        ],
      ),
    );
  }
}

class _VehiclePill extends StatelessWidget {
  const _VehiclePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white.withAlpha(18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.silver, size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.alabaster,
        side: BorderSide(color: AppColors.white.withAlpha(24)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.silver, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
