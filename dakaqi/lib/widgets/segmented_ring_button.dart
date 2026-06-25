import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 分段圆环打卡按钮：按 n 分割，依次点亮；满格后再点重置。
class SegmentedRingButton extends StatefulWidget {
  const SegmentedRingButton({
    super.key,
    required this.segments,
    required this.count,
    required this.color,
    this.onTap,
    this.enabled = true,
    this.size = 52,
  });

  final int segments;
  final int count;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;
  final double size;

  @override
  State<SegmentedRingButton> createState() => _SegmentedRingButtonState();
}

class _SegmentedRingButtonState extends State<SegmentedRingButton> {
  double _scale = 1;

  Future<void> _handleTap() async {
    if (!widget.enabled || widget.onTap == null) return;

    setState(() => _scale = 0.88);
    HapticFeedback.lightImpact();
    widget.onTap!();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (mounted) setState(() => _scale = 1);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.segments.clamp(1, 12);
    final filled = widget.count.clamp(0, n);
    final isFull = filled >= n;

    return GestureDetector(
      onTap: widget.enabled ? _handleTap : null,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _SegmentedRingPainter(
              segments: n,
              filled: filled,
              color: widget.color,
              enabled: widget.enabled,
            ),
            child: Center(
              child: Icon(
                isFull ? Icons.check : Icons.add,
                color: widget.enabled
                    ? widget.color
                    : widget.color.withValues(alpha: 0.35),
                size: widget.size * 0.46,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedRingPainter extends CustomPainter {
  _SegmentedRingPainter({
    required this.segments,
    required this.filled,
    required this.color,
    required this.enabled,
  });

  final int segments;
  final int filled;
  final Color color;
  final bool enabled;

  static const _gapRadians = 0.08;
  static const _strokeWidth = 4.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - _strokeWidth;
    final segmentSweep = (2 * math.pi / segments) - _gapRadians;

    // 内圈淡色底
    canvas.drawCircle(
      center,
      radius - _strokeWidth * 0.3,
      Paint()..color = color.withValues(alpha: enabled ? 0.12 : 0.06),
    );

    for (var i = 0; i < segments; i++) {
      final start = -math.pi / 2 + i * (2 * math.pi / segments) + _gapRadians / 2;
      final isDone = i < filled;

      final opacity = isDone
          ? (0.55 + (i + 1) / segments * 0.45).clamp(0.55, 1.0)
          : 1.0;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = isDone
            ? color.withValues(alpha: enabled ? opacity : opacity * 0.4)
            : (enabled
                ? const Color(0xFFE5E5EA)
                : const Color(0xFFF0F0F0));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        segmentSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SegmentedRingPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.filled != filled ||
        oldDelegate.color != color ||
        oldDelegate.enabled != enabled;
  }
}
