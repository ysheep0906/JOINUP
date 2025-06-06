import 'package:flutter/material.dart';
import 'package:joinup/widgets/profile/profile_badge.dart';
import 'package:joinup/widgets/profile/profile_calendar.dart';
import 'package:joinup/widgets/profile/profile_validity.dart';
import 'package:joinup/widgets/profile/profile.dart';

class TabProfile extends StatelessWidget {
  final Map<String, dynamic>? userInfo;
  final VoidCallback? onProfileUpdated;

  const TabProfile({super.key, this.userInfo, this.onProfileUpdated});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 왼쪽 공간 확보용 투명 아이콘
                const SizedBox(width: 48),
                const Text(
                  '프로필',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                // 새로고침 버튼
                IconButton(
                  onPressed: onProfileUpdated,
                  icon: const Icon(Icons.refresh),
                  tooltip: '프로필 새로고침',
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (onProfileUpdated != null) {
                  onProfileUpdated!();
                }
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                children: [
                  Column(
                    spacing: 40,
                    children: [
                      Profile(
                        userInfo: userInfo,
                        onProfileUpdated: onProfileUpdated, // 프로필 수정 후 새로고침
                      ),
                      ProfileCalendar(userInfo: userInfo),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ProfileValidity(userInfo: userInfo),
                  const SizedBox(height: 60),
                  ProfileBadge(
                    userInfo: userInfo,
                    onProfileUpdated: onProfileUpdated, // 배지 새로고침을 위한 콜백 추가
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
