import 'package:flutter/material.dart';
import 'dart:math';
import '../app_theme.dart';

/// 科技感动态背景 - 网格 + 粒子效果
class AnimatedTechBackground extends StatefulWidget {
  final Widget child;

  const AnimatedTechBackground({super.key, required this.child});

  @override
  State<AnimatedTechBackground> createState() => _AnimatedTechBackgroundState();
}

class _AnimatedTechBackgroundState extends State<AnimatedTechBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 基础渐变背景
        Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
        ),
        // 动态网格
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _GridPainter(
                progress: _controller.value,
                color: AppTheme.primaryCyan.withValues(alpha: 0.03),
              ),
            );
          },
        ),
        // 光晕效果
        ..._buildGlowOrbs(),
        // 实际内容
        widget.child,
      ],
    );
  }

  List<Widget> _buildGlowOrbs() {
    return [
      // 左上角紫色光晕
      Positioned(
        top: -100,
        left: -100,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = sin(_controller.value * 2 * pi) * 20;
            return Transform.translate(
              offset: Offset(offset, offset * 0.5),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryPurple.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // 右下角青色光晕
      Positioned(
        bottom: -150,
        right: -100,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = cos(_controller.value * 2 * pi) * 15;
            return Transform.translate(
              offset: Offset(-offset, offset * 0.7),
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryCyan.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}

/// 网格绘制器
class _GridPainter extends CustomPainter {
  final double progress;
  final Color color;

  _GridPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 60.0;
    final offsetY = (progress * spacing) % spacing;

    // 水平线
    for (double y = -spacing + offsetY; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 垂直线
    for (double x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
