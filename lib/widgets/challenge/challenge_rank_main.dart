import 'package:flutter/material.dart';

class ChallengeRankMain extends StatelessWidget {
  const ChallengeRankMain({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1등,2등,3등 이미지
              Padding(
                padding: const EdgeInsets.only(top: 70),
                child: _buildProfileImageRank(85, const Color(0xFFBABABA), '2'),
              ),
              _buildProfileImageRank(100, const Color(0xFFF7D000), '1'),
              Padding(
                padding: const EdgeInsets.only(top: 70),
                child: _buildProfileImageRank(85, const Color(0xFFC68036), '3'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFF2F2F2), thickness: 1, height: 1),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          alignment: Alignment.centerLeft,
          child: const Text(
            '순위',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        _buildRank('17', isMe: true),
        _buildRank('1'),
        _buildRank('2'),
        _buildRank('3'),
        _buildRank('4'),
        _buildRank('5'),
      ],
    );
  }

  Widget _buildProfileImage(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD9D9D9), width: 4.0),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/profile.jpg',
          fit: BoxFit.cover,
          width: size,
          height: size,
        ),
      ),
    );
  }

  Widget _buildProfileImageRank(double size, Color color, String rank) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD9D9D9), width: 4.0),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/profile.jpg',
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                ),
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
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const Text(
          '닉네임',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Text('230점', style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRank(String rank, {bool? isMe}) {
    return Container(
      decoration: BoxDecoration(
        color: isMe == true ? const Color(0xFFF2F2F2) : Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 20,
              children: [
                SizedBox(
                  width: 30,
                  child: Center(
                    child: Text(
                      rank,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                _buildProfileImage(60),
                const Text(
                  '닉네임',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Text(
              '230점',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
