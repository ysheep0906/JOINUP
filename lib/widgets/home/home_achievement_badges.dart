import 'package:flutter/material.dart';
import 'package:joinup/screens/badge/badges_screen.dart';

class HomeAchievementBadges extends StatelessWidget {
  final Map<String, dynamic>? userInfo;
  const HomeAchievementBadges({super.key, this.userInfo});

  @override
  Widget build(BuildContext context) {
    // TODO: API에서 사용자의 뱃지 데이터 가져오기
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          // Screen 이동
          MaterialPageRoute(
            builder: (context) => BadgesScreen(userInfo: userInfo),
          ),
        );
      },
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8E1), Color(0xFFFFF3C4)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 15,
              offset: const Offset(0, -4),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFF9800).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      '획득한 뱃지 5개',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '다음 뱃지를 획득하세요!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _buildBadge('🏆', true),
                const SizedBox(width: 6),
                _buildBadge('⭐', true),
                const SizedBox(width: 6),
                _buildBadge('💪', true),
                const SizedBox(width: 6),
                _buildMoreBadge('+2'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String emoji, bool isEarned) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient:
            isEarned
                ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF8F9FA)],
                )
                : LinearGradient(
                  colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)],
                ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color:
              isEarned ? Color(0xFFFFD54F).withOpacity(0.6) : Color(0xFFE5E7EB),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: 16,
            color: isEarned ? null : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreBadge(String text) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
        border: Border.all(color: Color(0xFFD1D5DB), width: 1),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
