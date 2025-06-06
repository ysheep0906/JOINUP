import 'package:flutter/material.dart';

class ChallengePlaceholder extends StatelessWidget {
  final int? index;
  final String? category;
  final double? width;
  final double? height;
  final double iconSize;
  final bool isCircular;
  final BorderRadius? borderRadius;

  const ChallengePlaceholder({
    super.key,
    this.index,
    this.category,
    this.width,
    this.height,
    this.iconSize = 80,
    this.isCircular = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderData = _getPlaceholderData();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderData['color'],
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: !isCircular ? borderRadius : null,
      ),
      child: Center(
        child: Icon(
          placeholderData['icon'],
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }

  Map<String, dynamic> _getPlaceholderData() {
    final colors = [
      const Color(0xFF15CB9A), // 민트
      const Color(0xFF4A90E2), // 블루
      const Color(0xFFE74C3C), // 레드
      const Color(0xFFF39C12), // 오렌지
      const Color(0xFF9B59B6), // 퍼플
    ];

    final icons = [
      Icons.fitness_center, // 운동
      Icons.favorite, // 건강
      Icons.book, // 독서
      Icons.schedule, // 생활습관
      Icons.people, // 함께하기
    ];

    // 카테고리와 인덱스가 모두 null인 경우 완료 이모티콘
    if (category == null) {
      return {
        'color': colors[0].withOpacity(0.7), // 기본 회색
        'icon': Icons.check_circle, // 완료 이모티콘
      };
    }

    if (category == 'person') {
      return {
        'color': Colors.black,
        'icon': Icons.person, // 완료 이모티콘
      };
    }

    // 카테고리 기반 매핑
    if (category != null) {
      switch (category) {
        case 'exercise':
        case 'health':
          return {'color': colors[0], 'icon': icons[0]}; // 민트, 운동
        case 'study':
          return {'color': colors[2], 'icon': icons[2]}; // 레드, 독서
        case 'lifestyle':
          return {'color': colors[3], 'icon': icons[3]}; // 오렌지, 생활습관
        case 'social':
        case 'hobby':
          return {'color': colors[4], 'icon': icons[4]}; // 퍼플, 함께하기
        default:
          return {'color': colors[1], 'icon': icons[1]}; // 블루, 건강
      }
    }

    // 인덱스 기반 순환
    final colorIndex = (index ?? 0) % colors.length;
    return {'color': colors[colorIndex], 'icon': icons[colorIndex]};
  }
}
