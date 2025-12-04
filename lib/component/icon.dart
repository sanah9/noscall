import 'package:flutter/material.dart';

class SSIcon extends StatelessWidget {
  const SSIcon({
    super.key,
    required this.icon,
    this.size = 30,
    required this.color,
    this.isWhiteStyle = false,
  });

  final IconData icon;
  final double size;
  final Color color;
  final bool isWhiteStyle;

  @override
  Widget build(BuildContext context) {
    final backgroundBlend = Colors.white.withValues(alpha: isWhiteStyle ? 0.2 : 0.9);
    final iconColor = isWhiteStyle ? Colors.white : color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.alphaBlend(backgroundBlend, color),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: iconColor,
        size: size * 0.6,
      ),
    );
  }
}