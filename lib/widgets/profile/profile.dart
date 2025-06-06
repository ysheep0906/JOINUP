import 'package:flutter/material.dart';
import 'package:joinup/screens/profile/profile_edit_screen.dart';
import 'package:joinup/services/badge/badge_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Profile extends StatefulWidget {
  final Map<String, dynamic>? userInfo;
  final VoidCallback? onProfileUpdated;

  const Profile({super.key, this.userInfo, this.onProfileUpdated});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final BadgeService _badgeService = BadgeService();
  String _title = '도전자'; // 기본값
  bool _titleLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFirstBadgeTitle();
  }

  @override
  void didUpdateWidget(Profile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // userInfo가 변경되면 다시 배지 정보 로드
    if (oldWidget.userInfo != widget.userInfo) {
      _loadFirstBadgeTitle();
    }
  }

  Future<void> _loadFirstBadgeTitle() async {
    final representativeBadges = widget.userInfo?['representativeBadges'] ?? [];

    if (representativeBadges.isEmpty || representativeBadges is! List) {
      setState(() {
        _title = '도전자';
      });
      return;
    }

    setState(() {
      _titleLoading = true;
    });

    try {
      // order가 가장 작은 배지(첫 번째 배지)를 찾기
      final sortedBadges = List<Map<String, dynamic>>.from(
        representativeBadges.where((badge) => badge is Map<String, dynamic>),
      );

      if (sortedBadges.isEmpty) {
        setState(() {
          _title = '도전자';
          _titleLoading = false;
        });
        return;
      }

      sortedBadges.sort((a, b) {
        final aOrder = a['order'] ?? 999;
        final bOrder = b['order'] ?? 999;
        return aOrder.compareTo(bOrder);
      });

      final firstBadge = sortedBadges.first;
      String badgeId = '';

      // badgeId 추출
      if (firstBadge['badgeId'] is Map<String, dynamic>) {
        // populate된 경우 - 서버에서 배지 정보까지 같이 보내준 경우
        final badgeData = firstBadge['badgeId'] as Map<String, dynamic>;
        setState(() {
          _title = badgeData['name'] ?? '도전자';
          _titleLoading = false;
        });
        return;
      } else if (firstBadge['badgeId'] is String) {
        // populate되지 않은 경우 - 배지 ID만 있는 경우
        badgeId = firstBadge['badgeId'] as String;
      } else {
        // 다른 형태의 경우
        badgeId =
            firstBadge['_id']?.toString() ?? firstBadge['id']?.toString() ?? '';
      }

      if (badgeId.isNotEmpty) {
        // BadgeService로 실제 배지 정보 조회
        final badge = await _badgeService.getBadgesByIds([badgeId]);
        setState(() {
          _title = badge.isNotEmpty ? badge.first['name'] ?? '도전자' : '도전자';
          _titleLoading = false;
        });
      } else {
        setState(() {
          _title = '도전자';
          _titleLoading = false;
        });
      }
    } catch (e) {
      print('첫 번째 배지 정보 로드 실패: $e');
      setState(() {
        _title = '도전자';
        _titleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nickname = widget.userInfo?['nickname'] ?? '사용자';
    final profileImage = widget.userInfo?['profileImage'];
    final grade = widget.userInfo?['grade'] ?? 'BRONZE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 130,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 프로필 이미지
          InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ProfileEditScreen(userInfo: widget.userInfo),
                ),
              );
              if (result == true && widget.onProfileUpdated != null) {
                widget.onProfileUpdated!();
              }
            },
            borderRadius: BorderRadius.circular(60.0),
            child: Container(
              width: 100.0,
              height: 100.0,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _getGradeColor(grade), width: 4.0),
              ),
              child: ClipOval(child: _buildProfileImage(profileImage)),
            ),
          ),

          const SizedBox(width: 16),

          // 프로필 정보
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 등급 배지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: _getGradeColor(grade),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    grade.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // 닉네임
                Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                // 칭호 (첫 번째 배지 이름) - 로딩 상태 처리
                _titleLoading
                    ? SizedBox(
                      width: 80,
                      height: 13,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey[400]!,
                        ),
                      ),
                    )
                    : Text(
                      _title,
                      style: const TextStyle(
                        color: Color(0xFF7D7D7D),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                // 프로필 수정 버튼
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ProfileEditScreen(userInfo: widget.userInfo),
                      ),
                    );
                    if (result == true && widget.onProfileUpdated != null) {
                      widget.onProfileUpdated!();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      '프로필 수정',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? profileImage) {
    if (profileImage != null && profileImage.isNotEmpty) {
      String imageUrl = profileImage;
      // .env에서 서버 URL을 불러와서 사용

      final serverUrl = (dotenv.env['API_URL']?.replaceFirst('/api', '')) ?? '';
      if (profileImage.startsWith('/uploads/')) {
        imageUrl = '$serverUrl$profileImage';
      }

      print(imageUrl);

      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 70, color: Colors.black);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      );
    }

    return const Icon(Icons.person, size: 70, color: Colors.black);
  }

  Color _getGradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFBF8B56);
      case 'silver':
        return const Color(0xFFD9D9D9);
      case 'gold':
        return const Color(0xFFF5DB77);
      case 'diamond':
        return const Color(0xFFC1D9E6);
      default:
        return Colors.black;
    }
  }
}
