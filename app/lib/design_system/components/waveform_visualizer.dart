import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../tokens.dart';

/// Animated audio waveform visualizer — used in live onboarding and quiz screens
class WaveformVisualizer extends StatefulWidget {
  final bool isActive;
  final Color color;
  final int barCount;
  final double height;

  const WaveformVisualizer({
    super.key,
    this.isActive = false,
    this.color = MimzColors.persimmonHit,
    this.barCount = 7,
    this.height = 80,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final phase = index / widget.barCount;
              final animValue = widget.isActive
                  ? (math.sin((_controller.value + phase) * math.pi * 2) + 1) / 2
                  : 0.15;
              final barHeight = widget.height * 0.2 +
                  (widget.height * 0.8 * animValue);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 5,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
