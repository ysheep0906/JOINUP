import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Map<String, dynamic>? userInfo;
  final VoidCallback onProfileTap;

  const HomeAppBar({super.key, this.userInfo, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final profileImage = userInfo?['profileImage'];
    final grade = userInfo?['grade'] ?? 'BRONZE'; // 등급 정보 추가

    return AppBar(
      toolbarHeight: 100,
      centerTitle: true,
      leadingWidth: 100,
      leading: Padding(
        padding: const EdgeInsets.only(top: 15.0, left: 40),
        child: Center(
          child: InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(30.0),
            child: Container(
              width: 50.0,
              height: 50.0,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getGradeColor(grade),
                  width: 3.0,
                ), // 등급별 색상과 두께 4.0
              ),
              child: ClipOval(child: _buildProfileImage(profileImage)),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: 15.0, right: 40.0),
          child: Container(
            width: 50.0,
            height: 50.0,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.chat, color: Colors.black),
              onPressed: () {
                Navigator.pushNamed(context, '/chat-list');
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage(String? profileImage) {
    if (profileImage != null && profileImage.isNotEmpty) {
      String imageUrl = profileImage;
      // .env에서 서버 URL을 불러와서 사용
      final serverUrl = (dotenv.env['API_URL']?.replaceFirst('/api', '')) ?? '';
      if (profileImage.startsWith('/uploads/')) {
        imageUrl = '$serverUrl$profileImage';
      }

      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 50,
        height: 50,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 35, color: Colors.black);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      );
    }

    return const Icon(Icons.person, size: 35, color: Colors.black);
  }

  // Profile 위젯과 동일한 등급별 색상 메서드 추가
  Color _getGradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFBF8B56);
      case 'silver':
        return const Color(0xFFD9D9D9);
      case 'gold':
        return const Color(0xFFF5DB77);
      case 'diamond':
        return const Color(0xFFC1D9E6);
      default:
        return Colors.black;
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
