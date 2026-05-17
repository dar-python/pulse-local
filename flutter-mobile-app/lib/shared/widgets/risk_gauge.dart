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
      height: 124,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 124),
            painter: _RiskGaugePainter(risk: risk),
          ),
          Positioned(
            top: 44,
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
          const Positioned(
            left: 16,
            bottom: 12,
            child: Text(
              '0',
              style: TextStyle(color: AppColors.silver, fontSize: 10),
            ),
          ),
          const Positioned(
            right: 10,
            bottom: 12,
            child: Text(
              '100',
              style: TextStyle(color: AppColors.silver, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskGaugePainter extends CustomPainter {
  const _RiskGaugePainter({required this.risk});

  final RiskInfo risk;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(14, 18, size.width - 28, size.height * 1.55);
    final trackPaint = Paint()
      ..color = AppColors.white.withAlpha(18)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final progressPaint = Paint()
      ..color = risk.color
      ..strokeWidth = 14
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
