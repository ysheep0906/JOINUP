import 'package:flutter/material.dart';
import 'package:joinup/services/challenge/challenge_service.dart';

class HomeParticipatingChallenges extends StatefulWidget {
  final VoidCallback? onTap;

  const HomeParticipatingChallenges({super.key, this.onTap});

  @override
  State<HomeParticipatingChallenges> createState() =>
      _HomeParticipatingChallengesState();
}

class _HomeParticipatingChallengesState
    extends State<HomeParticipatingChallenges> {
  final ChallengeService _challengeService = ChallengeService();
  int participatingCount = 0;
  double averageAchievement = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParticipatingData();
  }

  Future<void> _loadParticipatingData() async {
    try {
      final response = await _challengeService.getParticipatingChallenges();

      if (response['success']) {
        final challenges = List<Map<String, dynamic>>.from(
          response['data']['data']['challenges'] ?? [],
        );

        // 참여 중인 챌린지 개수
        final count = challenges.length;

        // 평균 달성률 계산 (completedDates 기반으로)
        double totalAchievement = 0.0;
        if (challenges.isNotEmpty) {
          for (final challenge in challenges) {
            final userChallenge = challenge['userChallenge']; // 올바른 구조로 수정
            final challengeData = challenge['challenge']; // 올바른 구조로 수정

            // 완료한 날짜들
            final completedDates = List<String>.from(
              userChallenge['completedDates'] ?? [],
            );
            final totalCompletions = completedDates.length;

            // 챌린지 시작일
            final startDateStr =
                userChallenge['startDate'] ?? challengeData['startDate'];

            if (startDateStr != null) {
              final startDate = DateTime.parse(startDateStr);
              final now = DateTime.now();

              // 시작일부터 현재까지 경과된 일수 계산
              final daysPassed =
                  now.difference(startDate).inDays + 1; // +1은 시작일 포함 (20 제거)
              // 달성률 = (완료한 날짜 수 / 경과된 일수) * 100
              final achievement = (totalCompletions / daysPassed * 100).clamp(
                0.0,
                100.0,
              );
              totalAchievement += achievement;
            } else {
              // 시작일이 없으면 점수 기반으로 계산 (fallback)
              final score = userChallenge['score'] ?? 0;
              final maxScore = 100; // 기본값
              final achievement = (score / maxScore * 100).clamp(0.0, 100.0);
              totalAchievement += achievement;
            }
          }

          totalAchievement = totalAchievement / challenges.length;
        }

        setState(() {
          participatingCount = count;
          averageAchievement = totalAchievement;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print('참여 중인 챌린지 로드 실패: ${response['message']}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('참여 중인 챌린지 로드 에러: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0xFFE8E8E8), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
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
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          isLoading ? '로딩중...' : '${participatingCount}개 진행중',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '참여 중인 챌린지',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A202C),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            '평균 달성률',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4A5568),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF48BB78),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF48BB78).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              isLoading
                                  ? '-%'
                                  : '${averageAchievement.round()}%',
                              style: const TextStyle(
                                fontSize: 11,
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
                const SizedBox(width: 12),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Color(0xFFE2E8F0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child:
                        isLoading
                            ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4A5568),
                                ),
                              ),
                            )
                            : Icon(
                              Icons.trending_up_rounded,
                              color: Color(0xFF4A5568),
                              size: 40,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
