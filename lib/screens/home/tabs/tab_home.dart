import 'package:flutter/material.dart';
import 'package:joinup/widgets/home/home_main_button.dart';
import 'package:joinup/widgets/home/home_popular_challenge.dart';
import 'package:joinup/widgets/home/home_participating_challenges.dart';
import 'package:joinup/widgets/home/home_category_grid.dart';
import 'package:joinup/widgets/home/home_new_challenges.dart';
import 'package:joinup/widgets/home/home_achievement_badges.dart';
import '../../challenge/challenge_list_screen.dart'; // 챌린지 목록 화면 import

class TabHome extends StatelessWidget {
  final Map<String, dynamic>? userInfo;
  final Function(int)? onTabChange;

  const TabHome({super.key, this.userInfo, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      physics: const BouncingScrollPhysics(),
      children: [
        // 메인 버튼
        const HomeMainButton(),
        const SizedBox(height: 50),

        // 내가 참여 중인 챌린지
        _buildSectionTitle('내가 참여 중인 챌린지'),
        const SizedBox(height: 15),
        HomeParticipatingChallenges(
          onTap: () {
            // 커뮤니티 탭(인덱스 1)으로 이동
            onTabChange?.call(1);
          },
        ),
        const SizedBox(height: 50),

        // 인기 챌린지
        _buildSectionTitle('🔥 인기 챌린지'),
        const SizedBox(height: 15),
        const HomePopularChallenge(),
        const SizedBox(height: 50),

        // 카테고리별 챌린지
        _buildSectionTitle('📂 카테고리'),
        const SizedBox(height: 15),
        const HomeCategoryGrid(),
        const SizedBox(height: 30),

        // 전체 챌린지 보기 버튼
        _buildAllChallengesButton(context),
        const SizedBox(height: 50),

        // 새로운 챌린지
        _buildSectionTitle('🆕 새로운 챌린지'),
        const SizedBox(height: 15),
        const HomeNewChallenges(),
        const SizedBox(height: 50),

        // 성취 뱃지
        _buildSectionTitle('🏆 내 성취'),
        const SizedBox(height: 15),
        HomeAchievementBadges(userInfo: userInfo),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAllChallengesButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChallengeListScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '챌린지 더보기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
