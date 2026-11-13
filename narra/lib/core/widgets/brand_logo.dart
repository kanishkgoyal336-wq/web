import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';

/// Narra's own mark: five rounded waveform bars, plus the wordmark.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 22});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: Size(height * 1.15, height), painter: _WaveMarkPainter()),
        SizedBox(width: height * 0.36),
        Text(
          'Narra',
          style: narraText(height * 0.98, weight: FontWeight.w700, letterSpacing: -0.3, lineHeight: height),
        ),
      ],
    );
  }
}

class _WaveMarkPainter extends CustomPainter {
  static const _bars = [0.42, 0.78, 1.0, 0.62, 0.34];

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (_bars.length * 2 - 1);
    final paint = Paint()..color = NarraColors.primary;
    for (var i = 0; i < _bars.length; i++) {
      final h = size.height * _bars[i];
      final rect = Rect.fromLTWH(i * barWidth * 2, (size.height - h) / 2, barWidth, h);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
