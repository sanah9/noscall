import 'package:flutter/material.dart';

class VoiceWaveformBar extends StatelessWidget {
  final List<int> peaks;
  final double progress;
  final double height;
  final int maxBars;

  const VoiceWaveformBar({
    super.key,
    required this.peaks,
    this.progress = 0,
    this.height = 22,
    this.maxBars = 32,
  });

  List<int> _normalizedPeaks() {
    if (peaks.isEmpty) {
      return List<int>.filled(maxBars.clamp(8, 64), 24);
    }
    if (peaks.length <= maxBars) return peaks;
    final step = peaks.length / maxBars;
    final sampled = <int>[];
    for (int i = 0; i < maxBars; i++) {
      sampled.add(peaks[(i * step).floor()]);
    }
    return sampled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bars = _normalizedPeaks();
    final safeProgress = progress.clamp(0.0, 1.0);
    final playedBars =
        (bars.length * safeProgress).round().clamp(0, bars.length);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < bars.length; i++) ...[
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: (height * (bars[i].clamp(4, 100) / 100))
                      .clamp(2.0, height),
                  decoration: BoxDecoration(
                    color: i < playedBars
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            if (i != bars.length - 1) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}
