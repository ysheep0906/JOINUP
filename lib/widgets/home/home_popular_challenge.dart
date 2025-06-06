import 'package:flutter/material.dart';
import 'package:joinup/services/challenge/challenge_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:joinup/widgets/common/challenge_placeholder.dart';
import 'challenge_card.dart';

class HomePopularChallenge extends StatefulWidget {
  const HomePopularChallenge({super.key});

  @override
  State<HomePopularChallenge> createState() => _HomePopularChallengeState();
}

class _HomePopularChallengeState extends State<HomePopularChallenge> {
  final ChallengeService _challengeService = ChallengeService();
  List<Map<String, dynamic>> challenges = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPopularChallenges();
  }

  Future<void> _loadPopularChallenges() async {
    try {
      final response = await _challengeService.getChallenges(
        page: 1,
        limit: 5,
        sortBy: 'viewCount', // 참여자 수 기준으로 인기 챌린지 정렬
      );
      print('인기 챌린지 응답: $response');
      if (response['success']) {
        final challengeList = List<Map<String, dynamic>>.from(
          response['data']['data']['challenges'] ?? [],
        );

        // API 데이터를 기존 형식에 맞게 변환
        final transformedChallenges =
            challengeList.map((challenge) {
              final participants = challenge['participants'] ?? [];
              final maxParticipants = challenge['maxParticipants'] ?? 0;
              final currentParticipants = participants.length;

              return {
                'id': challenge['_id'],
                'title': challenge['title'] ?? '제목 없음',
                'image':
                    challenge['image'] != null
                        ? '${dotenv.env['API_URL']?.replaceFirst('/api', '')}${challenge['image']}'
                        : null, // null로 설정해서 ChallengeCard에서 placeholder 사용하도록
                'current': currentParticipants,
                'max':
                    maxParticipants > 0
                        ? maxParticipants
                        : currentParticipants + 10,
                'badge': '🔥',
                'category': challenge['category'] ?? '기타',
              };
            }).toList();

        setState(() {
          challenges = transformedChallenges;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print('인기 챌린지 로드 실패: ${response['message']}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('인기 챌린지 로드 에러: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (challenges.isEmpty) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                '인기 챌린지가 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  challenges.map((challenge) {
                    final index = challenges.indexOf(challenge);
                    return Row(
                      children: [
                        ChallengeCard(
                          category: challenge['category'],
                          title: challenge['title'],
                          imageAsset: challenge['image'] ?? '',
                          currentParticipants: challenge['current'],
                          maxParticipants: challenge['max'],
                          badge: challenge['badge'],
                          onTap: () {
                            // 챌린지 상세 화면으로 이동
                            Navigator.pushNamed(
                              context,
                              '/challenge/${challenge['id']}',
                            );
                          },
                        ),
                        if (index < challenges.length - 1)
                          const SizedBox(width: 20),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
