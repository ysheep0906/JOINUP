import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';

import 'package:joinup/services/auth/auth_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String socialId;
  final String provider;

  const ProfileSetupScreen({
    super.key,
    required this.socialId,
    required this.provider,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  File? _profileImage;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('닉네임 설정', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nicknameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: '닉네임을 입력하세요',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    validator:
                        (v) => v == null || v.isEmpty ? '닉네임을 입력하세요' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _loading
                              ? null
                              : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setState(() => _loading = true);

                                // TODO: 서버에 닉네임/이미지 업로드 로직 추가

                                await Future.delayed(
                                  const Duration(seconds: 1),
                                ); // 테스트용

                                setState(() => _loading = false);
                                if (mounted) {
                                  await _registerProfile();
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _loading
                              ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              )
                              : const Text(
                                '완료',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _registerProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      Map<String, dynamic> userInfo;

      // widget.provider로 어떤 소셜 로그인인지 확인
      if (widget.provider == 'kakao') {
        userInfo = await AuthService().getKakaoUserInfo();
      } else if (widget.provider == 'google') {
        userInfo = await AuthService().getGoogleUserInfo();
      } else {
        throw Exception('지원하지 않는 로그인 방식입니다.');
      }

      final response = await AuthService().register(
        widget.provider, // 'kakao' 또는 'google'
        userInfo['accessToken'],
        _nicknameController.text,
      );

      setState(() => _loading = false);

      Navigator.pushNamed(context, '/home');
    } on DioException catch (dioError) {
      setState(() => _loading = false);

      String errorMessage = '회원가입에 실패했습니다.';

      if (dioError.response?.data != null) {
        final responseData = dioError.response!.data;
        final message = responseData['message'] ?? '';

        if (message == 'Nickname already taken') {
          errorMessage = '이미 사용 중인 닉네임입니다.';
        } else {
          errorMessage = '회원가입 실패: $message';
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }
}
