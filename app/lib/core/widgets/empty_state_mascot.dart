import 'package:flutter/material.dart';

class EmptyStateMascot extends StatelessWidget {
  const EmptyStateMascot({
    super.key,
    required this.message,
    this.imageSize = 88,
    this.spacing = 16,
  });

  final String message;
  final double imageSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Image.asset(
            'assets/icon/4.png',
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: spacing),
        Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFAAAAAA),
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
