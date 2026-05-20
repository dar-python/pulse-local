import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/models/risk_info.dart';
import '../../core/theme/app_colors.dart';

class RiskGauge extends StatelessWidget {
  const RiskGauge({super.key, required this.risk});

  final RiskInfo risk;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 136,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 128),
            painter: _RiskGaugePainter(risk: risk),
          ),
          Positioned(
            top: 42,
            child: Column(
              children: [
                Text(
                  '${risk.score}%',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  risk.badgeLabel,
                  style: TextStyle(
                    color: risk.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            bottom: 14,
            child: _ScaleLabel(
              label: '0%',
              alignment: Alignment.centerLeft,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 14,
            child: _ScaleLabel(
              label: '100%',
              alignment: Alignment.centerRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaleLabel extends StatelessWidget {
  const _ScaleLabel({required this.label, required this.alignment});

  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.prussian.withAlpha(165),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white.withAlpha(16)),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: AppColors.silver,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RiskGaugePainter extends CustomPainter {
  const _RiskGaugePainter({required this.risk});

  final RiskInfo risk;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(18, 18, size.width - 36, size.height * 1.42);
    final trackPaint = Paint()
      ..color = AppColors.white.withAlpha(18)
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final progressPaint = Paint()
      ..color = risk.color
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * (risk.score.clamp(0, 100) / 100),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RiskGaugePainter oldDelegate) {
    return oldDelegate.risk.score != risk.score ||
        oldDelegate.risk.color != risk.color;
  }
}
