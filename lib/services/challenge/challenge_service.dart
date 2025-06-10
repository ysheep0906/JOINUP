import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../badge/badge_service.dart'; // BadgeService import 추가

class ChallengeService {
  static final ChallengeService _instance = ChallengeService._internal();
  factory ChallengeService() => _instance;

  late final Dio dio;
  final BadgeService _badgeService = BadgeService(); // BadgeService 인스턴스 추가

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  ChallengeService._internal() {
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

  // 챌린지 생성 (이미지 없이)
  Future<Map<String, dynamic>> createChallenge({
    required String title,
    required String description,
    required String category,
    required String rules,
    required String cautions,
    required int maxParticipants,
    required String frequencyType,
    required int frequencyInterval,
  }) async {
    try {
      final data = {
        'title': title,
        'description': description,
        'category': category,
        'rules': rules,
        'cautions': cautions,
        'maxParticipants': maxParticipants,
        'frequency': {'type': frequencyType, 'interval': frequencyInterval},
      };

      final response = await dio.post('/challenge', data: data);

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {'success': false, 'message': '알 수 없는 오류가 발생했습니다: $e'};
    }
  }

  // 챌린지 목록 조회
  Future<Map<String, dynamic>> getChallenges({
    int page = 1,
    int limit = 10,
    String? search,
    String sortBy = 'createdAt',
  }) async {
    try {
      final response = await dio.get(
        '/challenge',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null) 'search': search,
          'sortBy': sortBy,
        },
      );

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 챌린지 상세 조회
  Future<Map<String, dynamic>> getChallengeById(String id) async {
    try {
      final response = await dio.get('/challenge/$id');

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 챌린지 참여
  Future<Map<String, dynamic>> joinChallenge(String challengeId) async {
    try {
      final response = await dio.post('/challenge/$challengeId/join');

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 챌린지 탈퇴
  Future<Map<String, dynamic>> leaveChallenge(String challengeId) async {
    try {
      final response = await dio.delete('/challenge/$challengeId/leave');

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 챌린지 완료
  Future<Map<String, dynamic>> completeChallenge(
    String challengeId,
    File photo,
  ) async {
    try {
      // 파일을 바이트로 읽기
      final photoBytes = await photo.readAsBytes();
      final fileName =
          'completion_${challengeId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          photoBytes,
          filename: fileName,
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      final response = await dio.post(
        '/challenge/$challengeId/complete',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      // 챌린지 완료 성공 시 배지 체크
      if (response.data['success'] == true) {
        print('챌린지 완료 성공, 배지 체크 시작...');

        // 배지 체크를 백그라운드에서 실행 (에러가 발생해도 완료 결과에 영향 없음)
        _badgeService
            .checkAndAwardBadges()
            .then((badgeResult) {
              if (badgeResult['success'] == true) {
                print('배지 체크 완료: ${badgeResult['message']}');
                if (badgeResult['data'] != null) {
                  print('새로 획득한 배지: ${badgeResult['data']}');
                }
              } else {
                print('배지 체크 실패: ${badgeResult['message']}');
              }
            })
            .catchError((error) {
              print('배지 체크 중 예외 발생: $error');
            });
      }

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 챌린지 수정
  Future<Map<String, dynamic>> updateChallenge(
    String challengeId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put('/challenge/$challengeId', data: data);

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 챌린지 삭제
  Future<Map<String, dynamic>> deleteChallenge(String challengeId) async {
    try {
      final response = await dio.delete('/challenge/$challengeId');

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 조회수 증가
  Future<Map<String, dynamic>> increaseViewCount(String challengeId) async {
    try {
      final response = await dio.patch('/challenge/$challengeId/view');

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 챌린지 이미지 업로드
  Future<Map<String, dynamic>> updateChallengeImage(
    String challengeId,
    File image,
  ) async {
    try {
      // 파일을 바이트로 읽기
      final imageBytes = await image.readAsBytes();
      final fileName =
          'challenge_${challengeId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      final response = await dio.put(
        '/challenge/$challengeId/image',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 챌린지 이미지 삭제
  Future<Map<String, dynamic>> deleteChallengeImage(String challengeId) async {
    try {
      final response = await dio.delete('/challenge/$challengeId/image');

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 챌린지 랭킹 조회 (새로 추가된 메소드)
  Future<Map<String, dynamic>> getChallengeRanking(String challengeId) async {
    try {
      final response = await dio.get(
        '/userchallenge/challenge/$challengeId/ranking',
      );

      return {'success': true, 'data': response.data};
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
      // 네트워크 연결 오류
      return {'success': false, 'message': '네트워크 연결을 확인해주세요.'};
    }
  }

  // 참여 중인 챌린지 조회 (UserChallenge 기반)
  Future<Map<String, dynamic>> getParticipatingChallenges() async {
    try {
      final response = await dio.get('/userchallenge/participating');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 오늘 완료 가능한 챌린지 조회
  Future<Map<String, dynamic>> getTodayCompletableChallenges() async {
    try {
      final response = await dio.get('/userchallenge/completable-today');

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // 사용자의 챌린지 통계 조회
  Future<Map<String, dynamic>> getUserChallengeStats() async {
    try {
      final response = await dio.get('/userchallenge/my-stats');

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }
}
