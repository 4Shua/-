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
  final Future<bool> Function()? onTap;
  final bool enabled;
  final double size;

  @override
  State<SegmentedRingButton> createState() => _SegmentedRingButtonState();
}

class _SegmentedRingButtonState extends State<SegmentedRingButton> {
  double _scale = 1;
  int? _optimisticCount;

  @override
  void didUpdateWidget(SegmentedRingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_optimisticCount != null && widget.count == _optimisticCount) {
      _optimisticCount = null;
    }
  }

  Future<void> _handleTap() async {
    if (widget.onTap == null) return;

    if (!widget.enabled) {
      setState(() => _scale = 0.92);
      HapticFeedback.selectionClick();
      await widget.onTap!();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (mounted) setState(() => _scale = 1);
      return;
    }

    final n = widget.segments.clamp(1, 12);
    final current = _optimisticCount ?? widget.count;
    final next = current >= n ? 0 : current + 1;

    setState(() {
      _scale = 0.88;
      _optimisticCount = next;
    });
    HapticFeedback.lightImpact();

    final ok = await widget.onTap!();
    if (!ok && mounted) setState(() => _optimisticCount = null);

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (mounted) setState(() => _scale = 1);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.segments.clamp(1, 12);
    final filled = (_optimisticCount ?? widget.count).clamp(0, n);
    final isFull = filled >= n;

    return GestureDetector(
      onTap: _handleTap,
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
    final rect = Rect.fromCircle(center: center, radius: radius);
    final isComplete = filled >= segments;

    canvas.drawCircle(
      center,
      radius - _strokeWidth * 0.3,
      Paint()..color = color.withValues(alpha: enabled ? 0.12 : 0.06),
    );

    if (isComplete) {
      _drawArc(
        canvas,
        rect,
        start: -math.pi / 2 + _gapRadians / 2,
        sweep: 2 * math.pi - _gapRadians,
        color: color.withValues(alpha: enabled ? 1.0 : 0.4),
      );
      return;
    }

    final segmentSweep = (2 * math.pi / segments) - _gapRadians;

    for (var i = 0; i < segments; i++) {
      final start =
          -math.pi / 2 + i * (2 * math.pi / segments) + _gapRadians / 2;
      final isDone = i < filled;

      _drawArc(
        canvas,
        rect,
        start: start,
        sweep: segmentSweep,
        color: isDone
            ? color.withValues(alpha: enabled ? 0.92 : 0.38)
            : (enabled ? const Color(0xFFE5E5EA) : const Color(0xFFF0F0F0)),
      );
    }
  }

  void _drawArc(
    Canvas canvas,
    Rect rect, {
    required double start,
    required double sweep,
    required Color color,
  }) {
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_SegmentedRingPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.filled != filled ||
        oldDelegate.color != color ||
        oldDelegate.enabled != enabled;
  }
}
