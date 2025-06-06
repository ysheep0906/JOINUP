import 'package:flutter/material.dart';
import 'package:joinup/services/challenge/challenge_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'challenge_card.dart';

class HomeNewChallenges extends StatefulWidget {
  const HomeNewChallenges({super.key});

  @override
  State<HomeNewChallenges> createState() => _HomeNewChallengesState();
}

class _HomeNewChallengesState extends State<HomeNewChallenges> {
  final ChallengeService _challengeService = ChallengeService();
  List<Map<String, dynamic>> challenges = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNewChallenges();
  }

  Future<void> _loadNewChallenges() async {
    try {
      final response = await _challengeService.getChallenges(
        page: 1,
        limit: 5,
        sortBy: 'createdAt', // 최신 순으로 정렬
      );

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
              final createdAt = challenge['createdAt'];

              // 새로운 챌린지인지 확인 (7일 이내)
              bool isNew = false;
              if (createdAt != null) {
                try {
                  final createdDate = DateTime.parse(createdAt);
                  final daysDifference =
                      DateTime.now().difference(createdDate).inDays;
                  isNew = daysDifference <= 7;
                } catch (e) {
                  // 날짜 파싱 에러 시 무시
                }
              }

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
                'badge': isNew ? 'NEW' : null, // 7일 이내면 NEW 뱃지
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
        print('새로운 챌린지 로드 실패: ${response['message']}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('새로운 챌린지 로드 에러: $e');
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
              Icon(
                Icons.new_releases_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                '새로운 챌린지가 없습니다',
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
                              'challenge/${challenge['id']}',
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
