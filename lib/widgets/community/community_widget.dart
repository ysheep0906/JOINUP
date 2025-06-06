import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:joinup/services/challenge/challenge_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CommunityWidget extends StatefulWidget {
  final Function(String)? onChallengeSelected;

  const CommunityWidget({super.key, this.onChallengeSelected});

  @override
  State<CommunityWidget> createState() => _CommunityWidgetState();
}

class _CommunityWidgetState extends State<CommunityWidget> {
  final ChallengeService _challengeService = ChallengeService();
  List<Map<String, dynamic>> _myChallenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyChallenges();
  }

  Future<void> _loadMyChallenges() async {
    try {
      // 참여 중인 챌린지 가져오기
      final response = await _challengeService.getParticipatingChallenges();

      if (response['success']) {
        final challenges = List<Map<String, dynamic>>.from(
          response['data']['data']['challenges'] ?? [],
        );

        // 완료 날짜 수 기준으로 정렬 (달성률 높은 순)
        challenges.sort((a, b) {
          final aCompletedDates =
              (a['userChallenge']['completedDates'] as List?)?.length ?? 0;
          final bCompletedDates =
              (b['userChallenge']['completedDates'] as List?)?.length ?? 0;
          return bCompletedDates.compareTo(aCompletedDates);
        });

        // mounted 체크 추가
        if (mounted) {
          setState(() {
            _myChallenges = challenges; // 전체 리스트 저장
            _isLoading = false;
          });
        }
      } else {
        // mounted 체크 추가
        if (mounted) {
          setState(() {
            _myChallenges = [];
            _isLoading = false;
          });
        }
        print('참여 중인 챌린지 로드 실패: ${response['message']}');
      }
    } catch (e) {
      // mounted 체크 추가
      if (mounted) {
        setState(() {
          _myChallenges = [];
          _isLoading = false;
        });
      }
      print('참여 중인 챌린지 로드 에러: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_myChallenges.isEmpty) {
      return Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                '참여 중인 챌린지가 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '새로운 챌린지에 참여해보세요!',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    // 참여 중인 챌린지들을 세로 스크롤로 표시
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: _myChallenges.length * 180.0, // 챌린지 개수에 따라 높이 조정
        minHeight: 160,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // 부모 스크롤에 맡김
        itemCount: _myChallenges.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildChallengeCard(_myChallenges[index]);
        },
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challengeData) {
    final userChallenge = challengeData['userChallenge'];
    final challenge = challengeData['challenge'];

    final completedDates = List<String>.from(
      userChallenge['completedDates'] ?? [],
    );

    // 오늘 완료 여부 계산
    bool isCompletedToday = false;
    final today = DateTime.now();

    isCompletedToday = completedDates.any((dateStr) {
      try {
        final date = DateTime.parse(dateStr);
        return date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      } catch (e) {
        return false;
      }
    });

    // 달성률 계산
    final startDateStr = userChallenge['startDate'];
    double achievementRate = 0.0;
    if (startDateStr != null) {
      final startDate = DateTime.parse(startDateStr);
      final now = DateTime.now();
      final daysPassed = now.difference(startDate).inDays + 1;
      achievementRate = (completedDates.length / daysPassed * 100).clamp(
        0.0,
        100.0,
      );
    }

    return GestureDetector(
      onTap: () async {
        final challengeId = challenge['_id'];
        if (widget.onChallengeSelected != null) {
          widget.onChallengeSelected!(challengeId);
        } else {
          // 기본 동작 - 결과를 받아서 새로고침 처리
          final result = await Navigator.pushNamed(
            context,
            '/challenge/$challengeId',
          );

          if (result == true) {
            // 새로고침 로직
            setState(() {
              _isLoading = true;
            });
            await _loadMyChallenges();
          }
        }
      },
      child: Container(
        width: double.infinity,
        height: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Flexible(
                    child: Text(
                      challenge['title'] ?? '챌린지',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A202C),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // 참여자 수와 오늘 완료 상태
                  Row(
                    spacing: 15,
                    children: [
                      // 참여자 수
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${(challenge['participants'] as List?)?.length ?? 0}/${challenge['maxParticipants'] ?? "∞"}명',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 오늘 완료 상태
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color:
                                  isCompletedToday
                                      ? const Color(0xFF10B981)
                                      : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCompletedToday ? '오늘 완료' : '미완료',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  isCompletedToday
                                      ? const Color(0xFF059669)
                                      : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 내 달성률
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        '내 달성률',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4A5568),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${achievementRate.round()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // 이미지
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                    challenge['image'] != null
                        ? Image.network(
                          '${dotenv.env['API_URL']?.replaceFirst('/api', '')}${challenge['image']}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF8FAFC),
                              child: Icon(
                                _getCategoryIcon(challenge['category']),
                                size: 40,
                                color: const Color(0xFF94A3B8),
                              ),
                            );
                          },
                        )
                        : Container(
                          color: const Color(0xFFF8FAFC),
                          child: Icon(
                            _getCategoryIcon(challenge['category']),
                            size: 40,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'exercise':
        return Icons.fitness_center;
      case 'health':
        return Icons.favorite;
      case 'study':
        return Icons.book;
      case 'hobby':
        return Icons.palette;
      case 'lifestyle':
        return Icons.local_drink;
      case 'social':
        return Icons.people;
      default:
        return Icons.star;
    }
  }
}
