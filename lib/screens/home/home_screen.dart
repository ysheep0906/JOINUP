import 'package:flutter/material.dart';
import 'package:joinup/screens/home/tabs/tab_community.dart';
import 'package:joinup/screens/home/tabs/tab_home.dart';
import 'package:joinup/screens/home/tabs/tab_profile.dart';
import 'package:joinup/screens/home/tabs/tab_setting.dart';
import 'package:joinup/widgets/bottom_nav_bar.dart';
import 'package:joinup/widgets/home/home_app_bar.dart';
import 'package:joinup/services/auth/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? userInfo;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await AuthService().getCurrentUser();
      setState(() {
        userInfo = user;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사용자 정보를 불러올 수 없습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 프로필 새로고침 함수 추가
  Future<void> _refreshUserInfo() async {
    await _loadUserInfo();
  }

  List<Widget> get _tabs => [
    TabHome(userInfo: userInfo, onTabChange: _onTabTapped),
    TabCommunity(userInfo: userInfo),
    TabProfile(userInfo: userInfo, onProfileUpdated: _refreshUserInfo), // 새로고침 콜백 전달
    TabSetting(userInfo: userInfo),
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar:
          (_currentIndex <= 1)
              ? HomeAppBar(
                userInfo: userInfo,
                onProfileTap: () {
                  setState(() {
                    _currentIndex = 2; // 프로필 탭으로 이동
                  });
                },
              )
              : null,
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
