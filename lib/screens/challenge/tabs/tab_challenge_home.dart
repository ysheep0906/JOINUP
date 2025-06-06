import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:joinup/services/challenge/challenge_service.dart';
import 'package:joinup/services/auth/auth_service.dart';
import 'package:joinup/services/badge/badge_service.dart';
import 'package:joinup/widgets/challenge/challenge_camera_widget.dart';
import 'package:joinup/widgets/common/challenge_placeholder.dart';

class TabChallengeHome extends StatefulWidget {
  final String? challengeId;
  const TabChallengeHome({super.key, this.challengeId});

  @override
  State<TabChallengeHome> createState() => _TabChallengeHomeState();
}

class _TabChallengeHomeState extends State<TabChallengeHome> {
  final ChallengeService _challengeService = ChallengeService();
  final AuthService _authService = AuthService();
  final BadgeService _badgeService = BadgeService();
  Map<String, dynamic>? challenge;
  Map<String, dynamic>? createdByUser;
  List<Map<String, dynamic>> userBadges = [];
  String? currentUserId;
  bool isLoading = true;
  bool isParticipant = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _getCurrentUser();
    await _loadChallengeDetails();
    await _increaseViewCount(); // 조회수 증가
  }

  Future<void> _getCurrentUser() async {
    try {
      final userInfo = await _authService.getCurrentUser().then(
        (response) => {
          setState(() {
            currentUserId = response['_id'];
          }),
        },
      );
    } catch (e) {
      print('Error getting current user: $e');
    }
  }

  Future<void> _loadChallengeDetails() async {
    if (widget.challengeId == null) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await _challengeService.getChallengeById(
        widget.challengeId!,
      );
      if (response['success']) {
        final challengeData = response['data']['data']['challenge'];
        setState(() {
          challenge = challengeData;
          // 현재 사용자가 참여했는지 확인
          isParticipant = _checkIfUserJoined(challengeData['participants']);
        });

        // 생성자 정보를 별도 API로 조회
        if (challengeData['createdBy'] != null) {
          await _loadCreatorInfo(challengeData['createdBy']['_id'] ?? '');
        }

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response['message'] ?? '챌린지를 불러올 수 없습니다.';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading challenge: $e');
      setState(() {
        errorMessage = '네트워크 오류가 발생했습니다.';
        isLoading = false;
      });
    }
  }

  // 생성자 정보를 별도로 로드
  Future<void> _loadCreatorInfo(String createdById) async {
    try {
      // AuthService를 사용해서 사용자 정보 조회
      final response = await _authService.getUserById(createdById);
      if (response['success']) {
        setState(() {
          createdByUser = response['data']['user'];
        });
      }
    } catch (e) {
      print('Error loading creator info: $e');
      // 생성자 정보 로드 실패 시에도 챌린지는 표시
    }
  }

  bool _checkIfUserJoined(List<dynamic>? participants) {
    if (participants == null || currentUserId == null) return false;

    return participants.any((participant) {
      if (participant is Map<String, dynamic>) {
        // API에서 populate된 구조: {userId: {_id: ..., nickname: ...}, joinedAt: ...}
        final userId = participant['userId'];
        if (userId is Map<String, dynamic>) {
          return userId['_id'] == currentUserId;
        }
        // 또는 직접 userId가 문자열인 경우
        return participant['userId'] == currentUserId;
      }
      return false;
    });
  }

  Future<void> _increaseViewCount() async {
    if (widget.challengeId == null) return;

    try {
      await _challengeService.increaseViewCount(widget.challengeId!);
    } catch (e) {
      print('Error increasing view count: $e');
    }
  }

  Future<void> _loadUserBadges(List<String> badgeIds) async {
    try {
      final badges = await _badgeService.getBadgesByIds(badgeIds);
      setState(() {
        userBadges = badges;
      });
    } catch (e) {
      print('Error loading badges: $e');
    }
  }

  String _getUserBadgeText() {
    if (userBadges.isNotEmpty) {
      return userBadges[0]['name'] ?? '챌린지 생성자';
    }
    return '챌린지 생성자';
  }

  Future<void> _joinChallenge() async {
    if (widget.challengeId == null) return;

    try {
      final response = await _challengeService.joinChallenge(
        widget.challengeId!,
      );

      if (response['success']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('챌린지에 참여했습니다!')));
        _loadChallengeDetails(); // 새로고침
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message'] ?? '참여 실패')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('네트워크 오류가 발생했습니다.')));
    }
  }

  Future<void> _leaveChallenge() async {
    if (widget.challengeId == null) return;

    try {
      final response = await _challengeService.leaveChallenge(
        widget.challengeId!,
      );

      if (response['success']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('챌린지 참여를 취소했습니다.')));
        _loadChallengeDetails(); // 새로고침
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? '참여 취소 실패')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('네트워크 오류가 발생했습니다.')));
    }
  }

  Future<void> _completeChallenge() async {
    if (widget.challengeId == null) return;

    // 카메라 화면으로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ChallengeCameraWidget(
              onPhotoTaken: (File photo) async {
                await _submitChallengeCompletion(photo);
              },
            ),
      ),
    );
  }

  Future<void> _submitChallengeCompletion(File photo) async {
    try {
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('챌린지 완료 처리 중...'),
              ],
            ),
          );
        },
      );

      final response = await _challengeService.completeChallenge(
        widget.challengeId!,
        photo,
      );

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      if (response['success']) {
        // 성공 다이얼로그 표시
        _showCompletionSuccessDialog(response['data']);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message'] ?? '완료 실패')));
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('네트워크 오류가 발생했습니다.')));
    }
  }

  void _showCompletionSuccessDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '챌린지 완료!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '오늘의 챌린지를 성공적으로 완료했습니다!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('획득 점수:'),
                        Text(
                          '+10점',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('연속 달성:'),
                        Text(
                          '${data['data']['currentStreakCount']}일',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('신뢰도 증가:'),
                        Text(
                          '+${data['data']['trustScoreIncrease']}점',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 챌린지 상세 정보 새로고침
                _loadChallengeDetails();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  String _getCategoryText(String? category) {
    switch (category) {
      case 'health':
        return '건강';
      case 'exercise':
        return '운동';
      case 'study':
        return '공부';
      case 'hobby':
        return '취미';
      case 'lifestyle':
        return '라이프스타일';
      case 'social':
        return '소셜';
      case 'other':
        return '기타';
      default:
        return '건강';
    }
  }

  String _getFrequencyText(Map<String, dynamic>? frequency) {
    if (frequency == null) return '매일';

    final type = frequency['type'];
    final interval = frequency['interval'] ?? 1;

    switch (type) {
      case 'daily':
        return interval == 1 ? '매일' : '매일 ${interval}회';
      case 'weekly':
        return '주 ${interval}회';
      case 'monthly':
        return '월 ${interval}회';
      default:
        return '매일';
    }
  }

  Color _getGradeColor(String? grade) {
    switch (grade?.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFBF8B56);
      case 'silver':
        return const Color(0xFFD9D9D9);
      case 'gold':
        return const Color(0xFFF5DB77);
      case 'diamond':
        return const Color(0xFFC1D9E6);
      default:
        return const Color(0xFFD9D9D9);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChallengeDetails,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (challenge == null) {
      return const Center(child: Text('챌린지 정보를 찾을 수 없습니다.'));
    }

    return Stack(
      children: [
        // 메인 콘텐츠
        RefreshIndicator(
          onRefresh: _loadChallengeDetails,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isParticipant ? 128.0 : 88.0, // 버튼 개수에 따라 조정
              ),
              child: Column(
                children: [
                  // Challenge Header
                  _buildChallengeHeader(),

                  // Challenge Content
                  _buildChallengeContent(),
                ],
              ),
            ),
          ),
        ),

        // 하단 고정 버튼
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(16), // 패딩 줄임 (20 -> 16)
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 참여 또는 완료 버튼
                  if (!isParticipant) ...[
                    // 참여하기 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _joinChallenge,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '챌린지 참여하기',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // 완료하기 버튼 (참여자용)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _completeChallenge,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '오늘 챌린지 완료하기',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 탈퇴하기 버튼 (빨간색, 아래 위치)
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: TextButton(
                        onPressed: _showLeaveConfirmDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '챌린지 탈퇴하기',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeHeader() {
    final String imageUrl =
        challenge!['image'] != null
            ? '${dotenv.env['API_URL']?.replaceFirst('/api', '')}${challenge!['image']}'
            : '';

    return Column(
      children: [
        // 챌린지 이미지
        imageUrl.isNotEmpty
            ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
              errorBuilder: (context, error, stackTrace) {
                return ChallengePlaceholder(
                  category: challenge!['category'],
                  width: double.infinity,
                  height: 250,
                  iconSize: 100,
                );
              },
            )
            : ChallengePlaceholder(
              category: challenge!['category'],
              width: double.infinity,
              height: 250,
              iconSize: 100,
            ),

        // 챌린지 제목과 카테고리
        Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 25, top: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  challenge!['title'] ?? '챌린지',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getCategoryText(challenge!['category']),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 25),
            ],
          ),
        ),

        // 빈도와 참여자 수
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '빈도',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _getFrequencyText(challenge!['frequency']),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBDBDB).withAlpha(128),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      '${challenge!['participants']?.length ?? 0}/${challenge!['maxParticipants'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 챌린지 생성자 정보
        if (createdByUser != null) _buildCreatorInfo(),

        const Divider(thickness: 1, color: Color(0xFFF2F2F2)),
      ],
    );
  }

  Widget _buildCreatorInfo() {
    final String profileImageUrl =
        createdByUser!['profileImage'] != null
            ? '${dotenv.env['API_URL']?.replaceFirst('/api', '')}${createdByUser!['profileImage']}'
            : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: _getGradeColor(createdByUser!['grade']),
                width: 4.0,
              ),
            ),
            child: ClipOval(
              child:
                  profileImageUrl.isNotEmpty
                      ? Image.network(
                        profileImageUrl,
                        fit: BoxFit.cover,
                        width: 60,
                        height: 60,
                        errorBuilder: (context, error, stackTrace) {
                          return ChallengePlaceholder(
                            index: 0,
                            width: 60,
                            height: 60,
                            iconSize: 30,
                            isCircular: true,
                          );
                        },
                      )
                      : ChallengePlaceholder(
                        index: 0,
                        width: 60,
                        height: 60,
                        iconSize: 30,
                        isCircular: true,
                      ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: _getGradeColor(createdByUser!['grade']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (createdByUser!['grade'] ?? 'bronze').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: 20),
                    Text(
                      createdByUser!['nickname'] ?? '사용자',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                // Text(
                //   _getUserBadgeText(),
                //   style: const TextStyle(fontSize: 16, color: Colors.grey),
                //   overflow: TextOverflow.ellipsis,
                // ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.visibility, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                '${challenge!['viewCount'] ?? 0}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeContent() {
    return Column(
      children: [
        _buildChallengeExplanation(),
        const Divider(height: 1, color: Color(0xFFF2F2F2)),
        _buildChallengeRule(),
        const Divider(height: 1, color: Color(0xFFF2F2F2)),
        _buildChallengeCaution(),
        const Divider(height: 1, color: Color(0xFFF2F2F2)),
      ],
    );
  }

  Widget _buildChallengeExplanation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '챌린지 설명',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            challenge!['description'] ?? '챌린지 설명이 없습니다.',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeRule() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '챌린지 규칙',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            challenge!['rules'] ?? '챌린지 규칙이 없습니다.',
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCaution() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '주의사항',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2DA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFF2DA), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA500),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.warning,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '안전한 챌린지를 위해',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFA500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  challenge!['cautions'] ?? '주의사항이 없습니다.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 탈퇴 확인 다이얼로그
  Future<void> _showLeaveConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            '챌린지 탈퇴',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '정말로 이 챌린지에서 탈퇴하시겠습니까?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red[600],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '주의사항',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '• 탈퇴 시 지금까지의 진행 기록이 삭제됩니다.\n• 탈퇴 후 재참여가 가능하지만 기록은 복구되지 않습니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                '취소',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '탈퇴하기',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    // 사용자가 '탈퇴하기'를 선택한 경우
    if (result == true) {
      await _leaveChallenge();
    }
  }
}
