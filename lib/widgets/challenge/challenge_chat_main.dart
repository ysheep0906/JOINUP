import 'package:flutter/material.dart';

class ChallengeChatMain extends StatelessWidget {
  const ChallengeChatMain({super.key});

  @override
  Widget build(BuildContext context) {
    //원 모양 이미지
    return Column(
      spacing: 5,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage('assets/profile.jpg'), // 이미지 경로
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '물 한 잔 마시기',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, size: 20),
            const Text(' 3명 참여중', style: TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: 250,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF15CB9A),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Center(
            child: Text(
              '대화방 참여하기',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}
