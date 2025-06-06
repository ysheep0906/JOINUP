import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;

  late final Dio dio;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  BadgeService._internal() {
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

  // 토큰 가져오기
  Future<String?> getStoredToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // 토큰 자동 설정 (add interceptor)

  // 모든 배지 조회
  Future<List<Map<String, dynamic>>> getAllBadges() async {
    try {
      final response = await dio.get('/badge');

      if (response.data['success'] == true) {
        final badges = response.data['data']['badges'] as List;
        return List<Map<String, dynamic>>.from(badges);
      } else {
        throw Exception(response.data['message'] ?? '배지를 가져올 수 없습니다.');
      }
    } catch (e) {
      throw Exception('배지 목록 조회 실패: $e');
    }
  }

  // 여러 배지 ID로 배지 정보 조회 (POST /api/badge/batch)
  Future<List<Map<String, dynamic>>> getBadgesByIds(
    List<String> badgeIds,
  ) async {
    try {
      if (badgeIds.isEmpty) {
        return [];
      }

      final response = await dio.post('/badge/batch', data: {'ids': badgeIds});

      if (response.data['success'] == true) {
        final badges = response.data['data']['badges'] as List;
        final foundCount = response.data['data']['found'] ?? 0;
        final totalCount = response.data['data']['total'] ?? 0;
        final notFoundIds = response.data['data']['notFound'] as List?;

        return List<Map<String, dynamic>>.from(badges);
      } else {
        throw Exception(response.data['message'] ?? '배지를 가져올 수 없습니다.');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          throw Exception('잘못된 배지 ID 형식입니다.');
        }
      }
      throw Exception('배지 목록 조회 실패: $e');
    }
  }

  // 배지 획득 조건 체크 및 자동 수여
  Future<Map<String, dynamic>> checkAndAwardBadges() async {
    try {
      final response = await dio.post(
        '/badge/check',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await getStoredToken()}',
            'Content-Type': 'application/json',
          },
        ),
      );

      return {
        'success': response.data['success'] ?? false,
        'data': response.data['data'],
        'message': response.data['message'] ?? '배지 체크 완료',
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {'success': false, 'message': '배지 체크 중 오류가 발생했습니다: $e'};
    }
  }

  // 사용자 배지 조회
  Future<Map<String, dynamic>> getUserBadges(String userId) async {
    try {
      final response = await dio.get('/badge/user/$userId');

      return {
        'success': response.data['success'] ?? false,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 대표 배지 업데이트
  Future<Map<String, dynamic>> updateRepresentativeBadges(
    List<Map<String, dynamic>> badges,
  ) async {
    try {
      final response = await dio.put(
        '/badge/representative',
        data: {'badges': badges},
      );

      return {
        'success': response.data['success'] ?? false,
        'data': response.data['data'],
        'message': response.data['message'] ?? '대표 배지가 업데이트되었습니다.',
      };
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // Dio 에러 처리
  Map<String, dynamic> _handleDioError(DioException e) {
    String message = '네트워크 오류가 발생했습니다.';

    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final responseData = e.response!.data;

      switch (statusCode) {
        case 400:
          message = responseData['message'] ?? '잘못된 요청입니다.';
          break;
        case 401:
          message = '인증이 필요합니다. 다시 로그인해주세요.';
          break;
        case 403:
          message = '권한이 없습니다.';
          break;
        case 404:
          message = '요청한 데이터를 찾을 수 없습니다.';
          break;
        case 500:
          message = '서버 오류가 발생했습니다.';
          break;
        default:
          message = responseData['message'] ?? '알 수 없는 오류가 발생했습니다.';
      }

      return {
        'success': false,
        'message': message,
        'errors': responseData['errors'],
        'statusCode': statusCode,
      };
    } else {
      return {'success': false, 'message': '네트워크 연결을 확인해주세요.'};
    }
  }
}
