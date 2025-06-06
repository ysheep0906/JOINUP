import 'package:flutter/material.dart';

class ChallengeContent extends StatelessWidget {
  const ChallengeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildChallengeExplanation(),
        const Divider(height: 1, color: Color(0xFFF2F2F2)),
        _buildChallengeReview(),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '챌린지 설명',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            '하루에 한 번, ‘지금’ 이 순간! 물 한 잔을 마시고 인증해보는 챌린지에요.작은 실천이지만, 수분을 꾸준히 챙기는 건 건강의 시작이죠 :)\n커피 대신 물 한 잔, 습관처럼 매일 해보면 몸도 마음도 훨씬 가벼워질 거예요!',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeReview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '평가 및 리뷰',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '4.3',
                  style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.black),
                        const Icon(Icons.star, color: Colors.black),
                        const Icon(Icons.star, color: Colors.black),
                        const Icon(Icons.star, color: Colors.black),
                        const Icon(Icons.star_half, color: Colors.black),
                      ],
                    ),
                    const Text(
                      '26개의 평가',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Review List
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildReview(),
                const SizedBox(width: 10),
                _buildReview(),
                const SizedBox(width: 10),
                _buildReview(),
                const SizedBox(width: 10),
                _buildReview(),
                const SizedBox(width: 10),
                _buildReview(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReview() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '단순하지만 놀라운 변화, 물...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.black),
              const Icon(Icons.star, color: Colors.black),
              const Icon(Icons.star, color: Colors.black),
              const Icon(Icons.star, color: Colors.black),
              const Icon(Icons.star_half, color: Colors.black),
              const SizedBox(width: 5),
              const Text(
                '3/27',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const Text(
            '아침에 일어나자마자 물 한잔 마시는\n 걸 7일 동안 실천해봤어요. 처음엔\n 별 기대 없었는데, 생각보다 몸이 \n반응하더라고요. 가장 먼저 느낀 건 \n몸이 덜 붓는 느낌이었고, 아침에 \n화장실도 더 ...',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 챌린지 규칙
  Widget _buildChallengeRule() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '챌린지 규칙',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            '1. 하루에 딱 한 잔!\n아침에 일어나자마자 물 한 컵(200~300ml) 마시기\n공복 상태에서 마시는 것이 포인트!\n\n2. 7일 동안 연속으로 실천하기\n하루라도 빠지면 다시 1일차부터 시작!\n일관된 루틴을 만드는 것이 목표야.\n\n3. 커피나 다른 음료는 X\n꼭 순수한 물만 마시기 (온수 or 냉수 모두 가능)\n\n4. 챌린지 인증 남기기\n매일 마신 후 한 줄 후기 or 인증샷 기록하면 더 동기부여\n 됨 (선택사항)예: “3일차 완료! 오늘도 개운하게 시작!”',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // 챌린지 주의사항
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
              color: Color(0xFFFFF2DA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFFFF2DA), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        // 경고는 색깔 w
                        color: Color(0xFFFFA500),
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
                const Text(
                  '• 물을 너무 많이 마시면 오히려 몸에 해로울 수 있어요.\n• 신장 질환이 있으신 분은 의사와 상담 후 참여해주세요.\n• 약물 복용 중이라면 물 섭취 시간을 조절해주세요.',
                  style: TextStyle(
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
}
