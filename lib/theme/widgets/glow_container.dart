import 'package:flutter/material.dart';
import '../app_theme.dart';

/// 带发光效果的容器装饰
class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final double glowRadius;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;

  const GlowContainer({
    super.key,
    required this.child,
    this.glowColor,
    this.glowRadius = 20,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient ?? AppTheme.aiBubbleGradient,
        border: Border.all(
          color: (glowColor ?? AppTheme.primaryCyan).withValues(alpha: 0.2),
        ),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.15),
                  blurRadius: glowRadius,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// 渐变边框容器
class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final double borderWidth;

  const GradientBorderContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.gradient,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: AppTheme.surfaceCard != Colors.transparent
            ? LinearGradient(
                colors: [AppTheme.surfaceCard, AppTheme.surfaceCard],
              )
            : null,
        border: Border.all(
          color: Colors.transparent,
          width: borderWidth,
        ),
      ),
      child: child,
    );
  }
}

/// 科技感分隔线
class TechDivider extends StatelessWidget {
  final double height;
  final Color? color;
  final bool showGlow;

  const TechDivider({
    super.key,
    this.height = 1,
    this.color,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? AppTheme.borderSubtle;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            dividerColor,
            dividerColor,
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
    );
  }
}
