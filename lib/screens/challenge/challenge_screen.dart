import 'package:flutter/material.dart';
import 'package:joinup/screens/challenge/tabs/tab_challenge_chat.dart';
import 'package:joinup/screens/challenge/tabs/tab_challenge_home.dart';
import 'package:joinup/screens/challenge/tabs/tab_challenge_rank.dart';

class ChallengeScreen extends StatefulWidget {
  final String? challengeId;

  const ChallengeScreen({super.key, this.challengeId});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? challengeId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 라우트에서 challengeId 추출
    final route = ModalRoute.of(context);
    if (route != null && route.settings.name != null) {
      final routeName = route.settings.name!;
      // "/challenge/6841a66942b381961a659bdc" 형태에서 ID 추출
      if (routeName.startsWith('/challenge/')) {
        challengeId = routeName.replaceFirst('/challenge/', '');
      }
    }
    // 위젯 매개변수에서도 받을 수 있도록
    challengeId = widget.challengeId ?? challengeId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 뒤로가기 처리 함수
  void _handleBackPress() {
    // true를 반환하여 이전 화면에서 새로고침 처리하도록 함
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: _handleBackPress,
        ),
        title: Text(
          '챌린지 정보',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFFFAF9F6), // 탭바 배경색
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.black, // 밑줄 색
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black, // 선택된 탭 텍스트 색
              unselectedLabelColor: Colors.grey, // 선택 안 된 탭 텍스트 색
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 16),
              indicatorWeight: 3,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 40),
              tabs: const [
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text('홈'),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text('대화방'),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text('랭크'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TabChallengeHome(challengeId: challengeId),
          TabChallengeChat(challengeId: challengeId),
          TabChallengeRank(challengeId: challengeId),
        ],
      ),
    );
  }
}
