import 'package:flutter/material.dart';

class BadgeCardList extends StatelessWidget {
  final Map<String, dynamic>? badgeData;
  final Map<String, dynamic>? userInfo;

  const BadgeCardList({super.key, this.badgeData, this.userInfo});

  @override
  Widget build(BuildContext context) {
    if (badgeData == null) {
      return _buildEmptyBadge();
    }

    // 배지 데이터 처리
    final badgeName = badgeData!['name'] ?? '배지';
    final badgeIcon = badgeData!['iconUrl'] ?? '🏅';
    final badgeRarity = badgeData!['rarity'] ?? 'common';

    return Container(
      width: 110, // 크기 증가
      height: 130, // 크기 증가
      child: Column(
        children: [
          Container(
            width: 80, // 60 -> 80
            height: 80, // 60 -> 80
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF8F9FA)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: _getRarityColor(badgeRarity),
                width: 3, // 2 -> 3
              ),
            ),
            child: Center(
              child: Text(
                badgeIcon,
                style: const TextStyle(fontSize: 36), // 28 -> 36
              ),
            ),
          ),
          const SizedBox(height: 12), // 8 -> 12
          Expanded(
            child: Text(
              badgeName,
              style: const TextStyle(
                fontSize: 12, // 10 -> 12
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A202C),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBadge() {
    return Container(
      width: 110, // 크기 증가
      height: 130, // 크기 증가
      child: Column(
        children: [
          Container(
            width: 80, // 60 -> 80
            height: 80, // 60 -> 80
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Icon(
              Icons.help_outline,
              color: Colors.grey[400],
              size: 32, // 24 -> 32
            ),
          ),
          const SizedBox(height: 12), // 8 -> 12
          Text(
            '배지 없음',
            style: TextStyle(
              fontSize: 12, // 10 -> 12
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return Colors.purple;
      case 'epic':
        return Colors.deepPurple;
      case 'rare':
        return Colors.blue;
      case 'common':
      default:
        return const Color(0xFFFFD54F);
    }
  }
}
