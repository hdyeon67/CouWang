// 빈 화면에서 마스코트와 안내 문구를 함께 보여주는 공통 위젯.
import 'package:flutter/material.dart';

// EmptyStateMascot 관련 역할을 담당하는 클래스.
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
  // 현재 상태를 기준으로 화면 UI를 구성한다.
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
