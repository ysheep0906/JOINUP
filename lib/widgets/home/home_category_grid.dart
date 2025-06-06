import 'package:flutter/material.dart';
import '../../screens/challenge/challenge_list_screen.dart';

class HomeCategoryGrid extends StatelessWidget {
  const HomeCategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'title': '운동', 'type': 'exercise', 'emoji': '💪'},
      {'title': '건강', 'type': 'health', 'emoji': '❤️'},
      {'title': '학습', 'type': 'study', 'emoji': '📚'},
      {'title': '취미', 'type': 'hobby', 'emoji': '🎨'},
      {'title': '라이프', 'type': 'lifestyle', 'emoji': '🌱'},
      {'title': '소셜', 'type': 'social', 'emoji': '👥'},
      {'title': '전체', 'type': 'all', 'emoji': '✨'},
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          return SizedBox(
            width: 85, // 고정 너비로 일관성 유지
            child: _buildCategoryCard(
              category['title']!,
              category['type']!,
              category['emoji']!,
              context,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    String categoryType,
    String emoji,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        // 기존 ChallengeListScreen으로 이동하되, 특정 카테고리로 필터링
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChallengeListScreen(
                  initialCategory: categoryType, // 초기 카테고리 설정
                ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Color(0xFFDEE2E6), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF343A40),
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
