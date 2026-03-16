import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../tokens.dart';

/// Animated audio waveform visualizer — used in live onboarding and quiz screens.
///
/// When [amplitude] is provided (0.0–1.0 RMS from real PCM capture), the bars
/// reflect genuine voice energy. When not provided, a sine-wave animation is
/// used as a graceful fallback (e.g. model speaking without local playback level).
class WaveformVisualizer extends StatefulWidget {
  final bool isActive;
  final Color color;
  final int barCount;
  final double height;

  /// Real-time mic/playback amplitude (0.0–1.0 RMS). When provided, the bars
  /// respond to actual audio energy instead of a synthetic sine wave.
  final double? amplitude;

  const WaveformVisualizer({
    super.key,
    this.isActive = false,
    this.color = MimzColors.persimmonHit,
    this.barCount = 7,
    this.height = 80,
    this.amplitude,
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

              double animValue;
              if (!widget.isActive) {
                // Inactive: flat minimal bars
                animValue = 0.08;
              } else if (widget.amplitude != null) {
                // Real amplitude: blend real energy with a small sine offset
                // so adjacent bars look distinct even at the same amplitude.
                final sineOffset =
                    (math.sin((_controller.value + phase) * math.pi * 2) + 1) / 2 * 0.25;
                final realPart = (widget.amplitude! * 0.75).clamp(0.0, 0.75);
                animValue = realPart + sineOffset;
              } else {
                // Fallback: pure sine wave (model speaking, no local amplitude)
                animValue =
                    (math.sin((_controller.value + phase) * math.pi * 2) + 1) / 2;
              }

              final barHeight = widget.height * 0.15 + (widget.height * 0.85 * animValue);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
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
