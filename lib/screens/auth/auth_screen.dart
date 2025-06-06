import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:joinup/screens/auth/profile_setup_screen.dart';
import 'package:joinup/services/auth/auth_service.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              // 상단 로고 영역
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/app_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'JoinUP',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A202C),
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '함께 성장하는 챌린지 플랫폼',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 하단 로그인 버튼 영역
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildKakaoLoginButton(context),
                    const SizedBox(height: 16),
                    _buildGoogleLoginButton(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKakaoLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () async {
          AuthService()
              .kakaoLogin()
              .then((response) {
                // 로그인 성공 시 다음 화면 이동 등 처리
                Navigator.pushNamed(context, '/home');
              })
              .catchError((error) {
                // 만약 회원정보가 없는 경우 회원가입 화면으로 이동
                if (error is DioException) {
                  final response = error.response;
                  if (response?.statusCode == 400 &&
                      response?.data['message'] == 'Invalid credentials') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProfileSetupScreen(
                              socialId: error.response?.data['socialId'] ?? '',
                              provider: 'kakao',
                            ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('카카오 로그인 실패: ${error.message}')),
                    );
                  }
                }
              });
        },
        icon: Container(
          width: 24,
          height: 24,
          padding: const EdgeInsets.all(2),
          child: Image.asset(
            'assets/kakao_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.chat, size: 20, color: Colors.black);
            },
          ),
        ),
        label: const Text(
          '카카오 로그인',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500),
          foregroundColor: Colors.black,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () async {
          AuthService()
              .googleLogin()
              .then((response) {
                // 로그인 성공 시 다음 화면 이동 등 처리
                // print(response.data.token);
                Navigator.pushNamed(context, '/home');
                print(response);
              })
              .catchError((error) {
                // 만약 회원정보가 없는 경우 회원가입 화면으로 이동
                if (error is DioException) {
                  final response = error.response;
                  if (response?.statusCode == 400 &&
                      response?.data['message'] == 'Invalid credentials') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProfileSetupScreen(
                              socialId: error.response?.data['socialId'] ?? '',
                              provider: 'google',
                            ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('구글 로그인 실패: ${error.message}')),
                    );
                  }
                }
              });
        },
        icon: Container(
          width: 24,
          height: 24,
          padding: const EdgeInsets.all(2),
          child: Image.asset(
            'assets/google_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.g_mobiledata,
                size: 20,
                color: Colors.grey,
              );
            },
          ),
        ),
        label: const Text(
          'Google 로그인',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          side: BorderSide(color: Colors.grey[300]!, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    // Navigator.pushReplacementNamed(context, '/home');
    Navigator.pushNamed(context, '/home');
  }
}
