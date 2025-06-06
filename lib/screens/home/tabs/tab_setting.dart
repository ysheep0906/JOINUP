import 'package:flutter/material.dart';

class TabSetting extends StatelessWidget {
  final Map<String, dynamic>? userInfo;
  const TabSetting({super.key, this.userInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () async {
              // 로그아웃 처리 (예: 토큰 삭제 등)
              // 이동 전에 SnackBar 보여주고, 잠시 후 이동
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('로그아웃 되었습니다.')));
              await Future.delayed(const Duration(milliseconds: 500));
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          const Divider(height: 1, color: Colors.grey),
        ],
      ),
    );
  }
}
