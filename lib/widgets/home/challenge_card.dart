import 'package:flutter/material.dart';
import '../common/challenge_placeholder.dart';

class ChallengeCard extends StatelessWidget {
  final String title;
  final String imageAsset;
  final int currentParticipants;
  final int maxParticipants;
  final String? badge;
  final String? category; // 카테고리 추가
  final VoidCallback? onTap;

  const ChallengeCard({
    super.key,
    required this.title,
    required this.imageAsset,
    required this.currentParticipants,
    required this.maxParticipants,
    this.badge,
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // 배경 이미지 또는 플레이스홀더
            _buildBackground(),

            // 제목
            Positioned(
              left: 15,
              bottom: 10,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // 참여자 수
            Positioned(
              left: 15,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '$currentParticipants/$maxParticipants',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 뱃지 (선택사항)
            if (badge != null)
              Positioned(
                right: 15,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (imageAsset.isNotEmpty) {
      // 이미지가 있는 경우
      if (imageAsset.startsWith('http') || imageAsset.startsWith('https')) {
        // 네트워크 이미지
        return Image.network(
          imageAsset,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return ChallengePlaceholder(
              category: category,
              width: double.infinity,
              height: double.infinity,
              iconSize: 60,
              borderRadius: BorderRadius.circular(25),
            );
          },
        );
      } else {
        // 로컬 이미지
        return Image.asset(
          imageAsset,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return ChallengePlaceholder(
              category: category,
              width: double.infinity,
              height: double.infinity,
              iconSize: 60,
              borderRadius: BorderRadius.circular(25),
            );
          },
        );
      }
    } else {
      // 이미지가 없는 경우 플레이스홀더 표시
      return ChallengePlaceholder(
        category: category,
        width: double.infinity,
        height: double.infinity,
        iconSize: 60,
        borderRadius: BorderRadius.circular(25),
      );
    }
  }
}
