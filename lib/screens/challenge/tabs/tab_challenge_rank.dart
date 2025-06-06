import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:joinup/services/challenge/challenge_service.dart';
import 'package:joinup/widgets/common/challenge_placeholder.dart';

class TabChallengeRank extends StatefulWidget {
  final String? challengeId;

  const TabChallengeRank({super.key, this.challengeId});

  @override
  State<TabChallengeRank> createState() => _TabChallengeRankState();
}

class _TabChallengeRankState extends State<TabChallengeRank> {
  final ChallengeService _challengeService = ChallengeService();
  List<dynamic> participants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRankingData();
  }

  Future<void> _loadRankingData() async {
    if (widget.challengeId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // 새로 추가된 getChallengeRanking 메소드 사용
      final response = await _challengeService.getChallengeRanking(
        widget.challengeId!,
      );

      print('챌린지 랭킹 데이터: $response');
      if (response['success']) {
        setState(() {
          // API 응답 구조에 맞게 수정
          participants = response['data']['data']['rankings'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('랭킹 로드 에러: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // 등급별 테두리 색상 가져오기
  Color _getGradeColor(String? grade) {
    switch (grade?.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'diamond':
        return const Color(0xFFB9F2FF);
      default:
        return const Color(0xFFD9D9D9); // 기본 회색
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadRankingData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // 상위 3명 포디움
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 2등
                  if (participants.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 70),
                      child: _buildProfileImageRank(
                        85,
                        const Color(0xFFBABABA),
                        '2',
                        participants[1],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 70),
                      child: _buildEmptyRank(85, const Color(0xFFBABABA), '2'),
                    ),

                  // 1등
                  if (participants.isNotEmpty)
                    _buildProfileImageRank(
                      100,
                      const Color(0xFFF7D000),
                      '1',
                      participants[0],
                    )
                  else
                    _buildEmptyRank(100, const Color(0xFFF7D000), '1'),

                  // 3등
                  if (participants.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 70),
                      child: _buildProfileImageRank(
                        85,
                        const Color(0xFFC68036),
                        '3',
                        participants[2],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 70),
                      child: _buildEmptyRank(85, const Color(0xFFC68036), '3'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(color: Color(0xFFF2F2F2), thickness: 1, height: 1),

            // 순위 섹션 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              alignment: Alignment.centerLeft,
              child: const Text(
                '순위',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            // 전체 순위 리스트
            ...participants.asMap().entries.map((entry) {
              final index = entry.key;
              final participant = entry.value;

              return _buildRank(
                '${participant['rank'] ?? index + 1}', // API에서 제공하는 rank 사용
                participant,
                isMe: false, // TODO: 현재 사용자 확인 로직 추가
              );
            }).toList(),

            if (participants.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '아직 참여자가 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(double size, {String? imageUrl, String? grade}) {
    final String fullImageUrl =
        imageUrl != null
            ? '${dotenv.env['API_URL']?.replaceFirst('/api', '')}$imageUrl'
            : '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _getGradeColor(grade), width: 4.0),
      ),
      child: ClipOval(
        child:
            fullImageUrl.isNotEmpty
                ? Image.network(
                  fullImageUrl,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  errorBuilder: (context, error, stackTrace) {
                    return ChallengePlaceholder(
                      category: 'person',
                      width: size,
                      height: size,
                      iconSize: size * 0.4,
                      isCircular: true,
                    );
                  },
                )
                : ChallengePlaceholder(
                  category: 'person',
                  width: size,
                  height: size,
                  iconSize: size * 0.4,
                  isCircular: true,
                ),
      ),
    );
  }

  Widget _buildProfileImageRank(
    double size,
    Color color,
    String rank,
    dynamic participant,
  ) {
    // API 응답 구조에 맞게 수정
    final nickname = participant?['user']?['nickname'] ?? '닉네임';
    final score = participant?['userChallenge']?['score'] ?? 0;
    final profileImage = participant?['user']?['profileImage'];
    final grade = participant?['user']?['grade'];

    return Column(
      children: [
        Stack(
          children: [
            _buildProfileImage(size, imageUrl: profileImage, grade: grade),
            Positioned(
              top: 0,
              left: size * 0.7,
              right: 0,
              bottom: size * 0.7,
              child: Center(
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      rank,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          nickname,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${score}점',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildEmptyRank(double size, Color color, String rank) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD9D9D9), width: 4.0),
              ),
              child: ChallengePlaceholder(
                category: 'person',
                width: size,
                height: size,
                iconSize: size * 0.4,
                isCircular: true,
              ),
            ),
            Positioned(
              top: 0,
              left: size * 0.7,
              right: 0,
              bottom: size * 0.7,
              child: Center(
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      rank,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '-',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Text('-점', style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRank(String rank, dynamic participant, {bool isMe = false}) {
    // API 응답 구조에 맞게 수정
    final nickname = participant?['user']?['nickname'] ?? '닉네임';
    final score = participant?['userChallenge']?['score'] ?? 0;
    final profileImage = participant?['user']?['profileImage'];
    final grade = participant?['user']?['grade'];

    return Container(
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFF2F2F2) : Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Center(
                    child: Text(
                      rank,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                _buildProfileImage(60, imageUrl: profileImage, grade: grade),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (grade != null)
                      Text(
                        grade.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getGradeColor(grade),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Text(
              '${score}점',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
