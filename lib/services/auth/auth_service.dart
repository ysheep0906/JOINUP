import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  late final Dio dio;
  String? _cachedKakaoToken;
  String? _cachedGoogleToken;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  AuthService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_URL'] ?? '',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );

    // 인터셉터 추가 (토큰 자동 추가)
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          print('API Error: ${error.response?.data}');
          handler.next(error);
        },
      ),
    );
  }

  Future<Response> login(String provider, String token) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'socialId': token, 'provider': provider},
      );

      // 회원가입 성공 시 토큰 저장
      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        if (token != null) {
          await saveToken(token);
          print('토큰 저장 완료 (Secure Storage)');
        }
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> register(
    String provider,
    String accessToken,
    String nickname,
  ) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'provider': provider,
          'socialId': accessToken,
          'nickname': nickname,
        },
      );

      // 회원가입 성공 시 토큰 저장
      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        if (token != null) {
          await saveToken(token);
          print('토큰 저장 완료 (Secure Storage)');
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> kakaoLogin() async {
    try {
      OAuthToken oauthToken;
      try {
        // 카카오톡 로그인 시도
        oauthToken = await UserApi.instance.loginWithKakaoTalk();
      } catch (error) {
        // 카카오톡 로그인 실패 시 웹 로그인 시도
        oauthToken = await UserApi.instance.loginWithKakaoAccount();
      }

      // 토큰이 정상적으로 받아졌는지 확인
      if (oauthToken == null) {
        throw Exception('카카오 토큰을 받지 못했습니다.');
      }

      _cachedKakaoToken = oauthToken.accessToken;

      print(oauthToken.accessToken);
      return await login('kakao', oauthToken.accessToken!);
    } catch (error) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getKakaoUserInfo() async {
    try {
      User user = await UserApi.instance.me();
      return {'accessToken': _cachedKakaoToken};
    } catch (error) {
      rethrow;
    }
  }

  Future<void> kakaoLogout() async {
    try {
      // 카카오 로그아웃
      await UserApi.instance.logout();
      _cachedKakaoToken = null;
      print('카카오 로그아웃 성공');
    } catch (error) {
      print('카카오 로그아웃 실패: $error');
      rethrow;
    }
  }

  Future<Response> googleLogin() async {
    try {
      // 구글 로그인 시도
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('구글 로그인이 취소되었습니다.');
      }

      // 구글 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null) {
        throw Exception('구글 토큰을 받지 못했습니다.');
      }

      _cachedGoogleToken = googleAuth.accessToken;

      print('구글 토큰: ${googleAuth.accessToken}');
      return await login('google', googleAuth.accessToken!);
    } catch (error) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGoogleUserInfo() async {
    try {
      final GoogleSignInAccount? googleUser =
          _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();

      if (googleUser == null) {
        throw Exception('구글 사용자 정보를 가져올 수 없습니다.');
      }

      return {'accessToken': _cachedGoogleToken};
    } catch (error) {
      rethrow;
    }
  }

  Future<void> googleLogout() async {
    await _googleSignIn.signOut();
    _cachedGoogleToken = null;
  }

  // 토큰 저장
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // 토큰 불러오기
  Future<String?> getStoredToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // 토큰 유효성 확인
  Future<bool> isLoggedIn() async {
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }

  // 토큰 삭제
  Future<void> removeToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // 모든 저장된 데이터 삭제 (앱 초기화 시 사용)
  Future<void> clearAllData() async {
    await _storage.deleteAll();
  }

  // 현재 사용자 정보 조회
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await getStoredToken();
      if (token == null) throw Exception('토큰이 없습니다.');

      final response = await dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true) {
        return response.data['data']['user'];
      } else {
        throw Exception(response.data['message'] ?? '사용자 정보를 가져올 수 없습니다.');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 전체 로그아웃 (모든 소셜 로그인)
  Future<void> logout() async {
    try {
      // 카카오 로그아웃
      await kakaoLogout();
      // 구글 로그아웃
      await googleLogout();

      await removeToken(); // 저장된 토큰 삭제
    } catch (error) {}
  }

  String? getCachedKakaoToken() => _cachedKakaoToken;

  // 프로필 업데이트 (대표 배지 순서 포함)
  Future<Map<String, dynamic>> updateProfile({
    String? nickname,
    List<String>? representativeBadges, // 배지 ID 순서대로
    String? profileImagePath,
    Uint8List? profileImageBytes,
  }) async {
    try {
      final token = await getStoredToken();
      if (token == null) throw Exception('토큰이 없습니다.');

      final data = <String, dynamic>{};
      if (nickname != null) data['nickname'] = nickname;

      // 대표 배지를 order와 함께 전송
      if (representativeBadges != null) {
        final badgesWithOrder =
            representativeBadges
                .asMap()
                .entries
                .map(
                  (entry) => {
                    'badgeId': entry.value,
                    'order': entry.key + 1, // 1부터 시작
                  },
                )
                .toList();
        data['representativeBadges'] = badgesWithOrder;
      }

      // 이미지 업로드 처리 (실제 구현 시 FormData 사용)
      if (profileImagePath != null || profileImageBytes != null) {
        // TODO: 이미지 업로드 로직 구현
        data['profileImage'] = 'updated_image_url';
      }

      final response = await dio.put(
        '/auth/profile',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true) {
        return response.data['data']['user'];
      } else {
        throw Exception(response.data['message'] ?? '프로필 업데이트에 실패했습니다.');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 프로필 이미지 업로드 전용 메서드
  Future<String> uploadProfileImage(
    Uint8List imageBytes, [
    String? nickname,
  ]) async {
    try {
      final token = await getStoredToken();
      if (token == null) throw Exception('토큰이 없습니다.');

      // 닉네임이 제공되지 않으면 현재 사용자 정보에서 가져오기
      String fileName;
      if (nickname != null && nickname.isNotEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        fileName = '${nickname}_profile_$timestamp.jpg';
      } else {
        fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      final formData = FormData.fromMap({
        'profileImage': MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      final response = await dio.post(
        '/auth/profile/image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.data['success'] == true) {
        return response.data['data']['profileImage'];
      } else {
        throw Exception(response.data['message'] ?? '프로필 이미지 업로드에 실패했습니다.');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 대표 배지 순서 업데이트 전용 메서드
  Future<Map<String, dynamic>> updateRepresentativeBadges(
    List<String> badgeIds,
  ) async {
    try {
      final token = await getStoredToken();
      if (token == null) throw Exception('토큰이 없습니다.');

      final badgesWithOrder =
          badgeIds
              .asMap()
              .entries
              .map(
                (entry) => {
                  'badgeId': entry.value,
                  'order': entry.key + 1, // 1부터 시작
                },
              )
              .toList();

      final response = await dio.put(
        '/badge/representative',
        data: {'badges': badgesWithOrder},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? '대표 배지 업데이트에 실패했습니다.');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 프로필 이미지 삭제
  Future<void> deleteProfileImage() async {
    try {
      final token = await getStoredToken();
      if (token == null) throw Exception('토큰이 없습니다.');

      final response = await dio.delete(
        '/auth/profile/image',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true) {
        print('프로필 이미지 삭제 성공');
      } else {
        throw Exception(response.data['message'] ?? '프로필 이미지 삭제에 실패했습니다.');
      }
    } catch (e) {
      rethrow;
    }
  }

  //특정 사용자 정보 조회
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final token = await getStoredToken();
      if (token == null) throw Exception('토큰이 없습니다.');

      final response = await dio.get(
        '/auth/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? '사용자 정보를 가져올 수 없습니다.');
      }
    } catch (e) {
      rethrow;
    }
  }
}
