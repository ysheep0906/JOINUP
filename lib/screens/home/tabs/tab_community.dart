import 'package:flutter/material.dart';
import 'package:joinup/screens/challenge/challenge_create_screen.dart';
import 'package:joinup/widgets/community/community_widget.dart';
import 'package:joinup/services/auth/auth_service.dart';

class TabCommunity extends StatefulWidget {
  final Map<String, dynamic>? userInfo;

  const TabCommunity({super.key, this.userInfo});

  @override
  State<TabCommunity> createState() => _TabCommunityState();
}

class _TabCommunityState extends State<TabCommunity> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _currentUserInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      // widget.userInfo가 있으면 그것을 사용, 없으면 API에서 가져오기
      if (widget.userInfo != null) {
        setState(() {
          _currentUserInfo = widget.userInfo;
          _isLoading = false;
        });
      } else {
        final response = await _authService.getCurrentUser();
        if (response['success']) {
          setState(() {
            _currentUserInfo = response['data']['user'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _currentUserInfo = null;
            _isLoading = false;
          });
          print('사용자 정보 로드 실패: ${response['message']}');
        }
      }
    } catch (e) {
      setState(() {
        _currentUserInfo = null;
        _isLoading = false;
      });
      print('사용자 정보 로드 에러: $e');
    }
  }

  // 새로고침 함수
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserInfo();
  }

  // 챌린지 화면으로 이동하는 함수
  Future<void> _navigateToChallenge(String challengeId) async {
    final result = await Navigator.pushNamed(
      context,
      '/challenge/$challengeId',
    );

    if (result == true) {
      // 새로고침 로직
      await _refreshData();
    }
  }

  // 챌린지 생성 화면으로 이동하는 함수
  Future<void> _navigateToCreateChallenge() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateChallengeScreen()),
    );

    if (result == true) {
      // 새로고침 로직
      await _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 사용자의 신뢰도 점수 확인
    final trustScore = _currentUserInfo?['trustScore'] ?? 0;
    final canCreateChallenge = trustScore >= 90;

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Challenge',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_currentUserInfo != null)
                      Text(
                        '신뢰도: ${trustScore}점',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              trustScore >= 90
                                  ? Colors.green[600]
                                  : Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.add,
                        color:
                            canCreateChallenge
                                ? Colors.black
                                : Colors.grey[400],
                        size: 28,
                      ),
                      onPressed:
                          canCreateChallenge
                              ? _navigateToCreateChallenge
                              : () {
                                _showTrustScoreRequiredDialog(
                                  context,
                                  trustScore,
                                );
                              },
                    ),
                    // 신뢰도 부족 시 경고 표시
                    if (!canCreateChallenge)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 신뢰도 가이드 카드 (90점 미만일 때만 표시)
          if (!canCreateChallenge && _currentUserInfo != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[50]!, Colors.orange[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '챌린지 생성 권한 안내',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '챌린지를 생성하려면 신뢰도 ${90 - trustScore}점이 더 필요합니다.',
                      style: TextStyle(fontSize: 13, color: Colors.orange[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '다른 챌린지에 참여하여 신뢰도를 높여보세요! 💪',
                      style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                    ),
                  ],
                ),
              ),
            ),

          CommunityWidget(onChallengeSelected: _navigateToChallenge),
        ],
      ),
    );
  }

  // 신뢰도 부족 시 표시할 다이얼로그
  void _showTrustScoreRequiredDialog(BuildContext context, int currentScore) {
    final requiredScore = 90;
    final neededScore = requiredScore - currentScore;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[600],
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                '챌린지 생성 불가',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '챌린지를 생성하려면 신뢰도 점수가 ${requiredScore}점 이상이어야 합니다.',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 16),

              // 현재 신뢰도
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '현재 신뢰도:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '$currentScore점',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color:
                            currentScore >= 50
                                ? Colors.orange[700]
                                : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 필요한 점수
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '필요한 점수:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${requiredScore}점 (+${neededScore}점)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 신뢰도 향상 가이드
              const Text(
                '💡 신뢰도를 높이는 방법:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• 챌린지에 꾸준히 참여하기 (+5점/주)\n• 약속한 활동을 성실히 완료하기 (+3점/일)\n• 다른 사용자들과 긍정적인 상호작용하기 (+2점/일)\n• 연속 참여 보너스 받기 (+10점/월)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
