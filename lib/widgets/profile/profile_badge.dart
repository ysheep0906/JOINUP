import 'package:flutter/material.dart';
import 'package:joinup/screens/badge/badges_screen.dart';
import 'package:joinup/services/badge/badge_service.dart';
import 'package:joinup/widgets/profile/badge_card.dart';

class ProfileBadge extends StatefulWidget {
  final Map<String, dynamic>? userInfo;
  final VoidCallback? onProfileUpdated; // 새로고침 콜백 추가

  const ProfileBadge({
    super.key,
    this.userInfo,
    this.onProfileUpdated, // 콜백 매개변수 추가
  });

  @override
  State<ProfileBadge> createState() => _ProfileBadgeState();
}

class _ProfileBadgeState extends State<ProfileBadge> {
  final BadgeService _badgeService = BadgeService();
  List<Map<String, dynamic>> badgeDetails = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBadgeDetails();
  }

  @override
  void didUpdateWidget(ProfileBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // userInfo가 변경되면 배지 데이터 새로고침
    if (widget.userInfo != oldWidget.userInfo) {
      _loadBadgeDetails(); // 배지 데이터 로드 메서드 호출
    }
  }

  Future<void> _loadBadgeDetails() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // userInfo에서 대표 배지 ID들 추출 (순서 유지) - 새로운 형태
      final representativeBadges =
          widget.userInfo?['representativeBadges'] ?? [];

      if (representativeBadges is List && representativeBadges.isNotEmpty) {
        // order 순서대로 정렬한 후 배지 ID 추출
        final sortedBadges = List<Map<String, dynamic>>.from(
          representativeBadges.where((badge) => badge is Map<String, dynamic>),
        );

        sortedBadges.sort((a, b) {
          final aOrder = a['order'] ?? 999;
          final bOrder = b['order'] ?? 999;
          return aOrder.compareTo(bOrder);
        });

        // 순서대로 배지 ID 추출
        final badgeIds = <String>[];
        for (final badge in sortedBadges) {
          final badgeId = badge['badgeId'] ?? badge['_id'] ?? badge['id'];
          if (badgeId != null) {
            badgeIds.add(badgeId.toString());
          }
        }

        if (badgeIds.isNotEmpty) {
          // 배지 정보 조회
          final fetchedBadges = await _badgeService.getBadgesByIds(badgeIds);

          // 원래 순서대로 배지 정렬 (order 순서 유지)
          final orderedBadges = <Map<String, dynamic>>[];

          for (final badgeId in badgeIds) {
            // 각 ID에 해당하는 배지를 찾아서 순서대로 추가
            for (final badge in fetchedBadges) {
              final fetchedId =
                  badge['_id']?.toString() ?? badge['id']?.toString() ?? '';
              if (fetchedId == badgeId) {
                orderedBadges.add(badge);
                break; // 찾았으면 다음 ID로
              }
            }
          }

          setState(() {
            badgeDetails = orderedBadges; // 순서가 유지된 배지 목록
            _loading = false;
          });
        } else {
          setState(() {
            badgeDetails = [];
            _loading = false;
          });
        }
      } else {
        setState(() {
          badgeDetails = [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '대표 배지',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => BadgesScreen(userInfo: widget.userInfo),
                  ),
                );
              },
              child: const Text(
                '전체 보기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBDBDBD),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Container(
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            const Text(
              '배지를 불러올 수 없습니다',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadBadgeDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 32),
              ),
              child: const Text('다시 시도', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return _buildBadgeGrid();
  }

  Widget _buildBadgeGrid() {
    // 최대 4개의 배지만 표시하도록 준비
    List<Map<String, dynamic>?> badgesToShow = List.filled(4, null);

    // 실제 배지 데이터로 채우기
    for (int i = 0; i < badgeDetails.length && i < 4; i++) {
      badgesToShow[i] = badgeDetails[i];
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBadgeCard(badgesToShow[0]),
            _buildBadgeCard(badgesToShow[1]),
          ],
        ),
        const SizedBox(height: 24), // 세로 간격 증가
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBadgeCard(badgesToShow[2]),
            _buildBadgeCard(badgesToShow[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic>? badge) {
    if (badge == null) {
      // 빈 배지 슬롯 - 크기 증가
      return Container(
        width: 110, // 80 -> 110
        height: 130, // 100 -> 130
        child: Column(
          children: [
            Container(
              width: 80, // 60 -> 80
              height: 80, // 60 -> 80
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(
                Icons.add,
                color: Colors.grey[400],
                size: 32, // 24 -> 32
              ),
            ),
            const SizedBox(height: 12), // 8 -> 12
            Text(
              '빈 슬롯',
              style: TextStyle(
                fontSize: 12, // 10 -> 12
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 실제 배지 데이터가 있는 경우 - BadgeCardList에 크기 정보 전달
    return SizedBox(
      width: 110, // 크기 제한
      height: 130,
      child: BadgeCardList(badgeData: badge, userInfo: widget.userInfo),
    );
  }
}
