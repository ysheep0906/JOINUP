import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '알림',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildNotificationItem(
            '새로운 챌린지가 시작되었습니다!',
            '2023년 10월 1일에 새로운 챌린지가 시작됩니다.',
          ),
          _buildNotificationItem(
            '챌린지 참여 요청이 도착했습니다.',
            '사용자123님이 당신의 챌린지에 참여하고 싶어합니다.',
          ),
          _buildNotificationItem(
            '챌린지 마감일이 다가옵니다.',
            '2023년 10월 15일에 챌린지가 종료됩니다.',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      minLeadingWidth: 70,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD9D9D9).withAlpha(128),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.chat, color: Colors.black, size: 25),
      ),
    );
  }
}
