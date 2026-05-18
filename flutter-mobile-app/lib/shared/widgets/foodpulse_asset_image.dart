import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class FoodPulseAssetImage extends StatelessWidget {
  const FoodPulseAssetImage({
    super.key,
    required this.imageAsset,
    required this.fallbackLabel,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.fit = BoxFit.cover,
    this.backgroundColor,
    this.fallbackTextStyle,
  });

  final String? imageAsset;
  final String fallbackLabel;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final Color? backgroundColor;
  final TextStyle? fallbackTextStyle;

  @override
  Widget build(BuildContext context) {
    final asset = imageAsset?.trim();
    final fallback = _fallback();
    final image = asset == null || asset.isEmpty
        ? fallback
        : Image.asset(
            asset,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => fallback,
          );

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(width: width, height: height, child: image),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? AppColors.dusk.withAlpha(112),
      alignment: Alignment.center,
      child: Text(
        fallbackLabel,
        textAlign: TextAlign.center,
        style:
            fallbackTextStyle ??
            const TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}
