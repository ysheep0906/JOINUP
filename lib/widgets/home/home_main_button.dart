import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:joinup/services/challenge/challenge_service.dart';
import 'package:joinup/services/auth/auth_service.dart';
import 'package:joinup/widgets/common/challenge_placeholder.dart';
import 'package:joinup/widgets/challenge/challenge_camera_widget.dart';

class HomeMainButton extends StatefulWidget {
  const HomeMainButton({super.key});

  @override
  State<HomeMainButton> createState() => _HomeMainButtonState();
}

class _HomeMainButtonState extends State<HomeMainButton> {
  final PageController _controller = PageController();
  final ChallengeService _challengeService = ChallengeService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> completableChallenges = [];
  String? currentUserId;
  bool isLoading = false;
  int currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();

    // PageView 변경 감지 (완료 가능한 챌린지가 있을 때만)
    _controller.addListener(() {
      if (completableChallenges.isNotEmpty) {
        final page = _controller.page?.round() ?? 0;
        if (page != currentImageIndex) {
          setState(() {
            currentImageIndex = page;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _getCurrentUser();
    await _loadCompletableChallenges();
  }

  Future<void> _getCurrentUser() async {
    try {
      final userInfo = await _authService.getCurrentUser().then(
        (response) => {
          setState(() {
            currentUserId = response['_id'];
          }),
        },
      );
    } catch (e) {
      print('Error getting current user: $e');
    }
  }

  Future<void> _loadCompletableChallenges() async {
    if (currentUserId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await _challengeService.getTodayCompletableChallenges();

      if (response['success']) {
        setState(() {
          completableChallenges = List<Map<String, dynamic>>.from(
            response['data']['data']['challenges'] ?? [],
          );
        });
      }
    } catch (e) {
      print('Error loading completable challenges: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showChallengeCompleteDialog() async {
    if (completableChallenges.isEmpty) {
      // 완료할 챌린지가 없으면 "오늘 모든 챌린지를 완료했습니다" 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 오늘 모든 챌린지를 완료했습니다!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '오늘의 챌린지 완료',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: completableChallenges.length,
              itemBuilder: (context, index) {
                final item = completableChallenges[index];
                final challenge = item['challenge'];
                final userChallenge = item['userChallenge'];

                // 이미지 URL 구성
                final String imageUrl =
                    challenge['image'] != null
                        ? '${dotenv.env['API_URL']?.replaceFirst('/api', '')}${challenge['image']}'
                        : '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading:
                        imageUrl.isNotEmpty
                            ? CircleAvatar(
                              backgroundImage: NetworkImage(imageUrl),
                              onBackgroundImageError: (error, stackTrace) {},
                            )
                            : ChallengePlaceholder(
                              category: null,
                              width: 40,
                              height: 40,
                              iconSize: 20,
                              isCircular: true,
                            ),
                    title: Text(
                      challenge['title'] ?? '챌린지',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFrequencyText(challenge['frequency']),
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '연속 ${userChallenge['currentStreakCount'] ?? 0}일',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _completeChallenge(
                        challenge['_id'],
                        challenge['title'],
                        userChallenge,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeChallenge(
    String challengeId,
    String? challengeTitle,
    Map<String, dynamic> userChallenge,
  ) async {
    // 카메라 화면으로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ChallengeCameraWidget(
              onPhotoTaken: (File photo) async {
                await _submitChallengeCompletion(
                  challengeId,
                  challengeTitle,
                  photo,
                );
              },
            ),
      ),
    );
  }

  Future<void> _submitChallengeCompletion(
    String challengeId,
    String? challengeTitle,
    File photo,
  ) async {
    setState(() {
      isLoading = true;
    });

    try {
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('챌린지 완료 처리 중...'),
              ],
            ),
          );
        },
      );

      final response = await _challengeService.completeChallenge(
        challengeId,
        photo,
      );

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      if (response['success']) {
        final completionData = response['data']['data'];

        // 성공 다이얼로그 표시
        _showCompletionSuccessDialog(challengeTitle, completionData);

        // 완료 가능한 챌린지 목록 새로고침
        await _loadCompletableChallenges();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? '챌린지 완료에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('네트워크 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showCompletionSuccessDialog(
    String? challengeTitle,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '챌린지 완료!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${challengeTitle ?? '챌린지'}를 성공적으로 완료했습니다! 🎉',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('획득 점수:'),
                        Text(
                          '+10점',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('연속 달성:'),
                        Text(
                          '${data['currentStreakCount'] ?? 0}일',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('신뢰도 증가:'),
                        Text(
                          '+${data['trustScoreIncrease'] ?? 0}점',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  String _getFrequencyText(Map<String, dynamic>? frequency) {
    if (frequency == null) return '매일';

    final type = frequency['type'];
    final interval = frequency['interval'] ?? 1;

    switch (type) {
      case 'daily':
        return interval == 1 ? '매일' : '매일 ${interval}회';
      case 'weekly':
        return '주 ${interval}회';
      case 'monthly':
        return '월 ${interval}회';
      default:
        return '매일';
    }
  }

  Widget _getDisplayWidget() {
    // 완료 가능한 챌린지가 있으면 PageView, 없으면 단일 플레이스홀더
    if (completableChallenges.isNotEmpty) {
      return _buildPageView();
    } else {
      return ChallengePlaceholder(
        index: 0,
        width: double.infinity,
        height: double.infinity,
      );
    }
  }

  String _getCurrentChallengeTitle() {
    if (completableChallenges.isNotEmpty &&
        currentImageIndex < completableChallenges.length) {
      return completableChallenges[currentImageIndex]['challenge']['title'] ??
          '새로운 챌린지';
    }

    // 완료할 챌린지가 없으면 "완료했습니다" 표시
    return '오늘 완료했습니다';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 300,
      child: Stack(children: [_buildBackgroundLayers(), _buildMainContent()]),
    );
  }

  Widget _buildBackgroundLayers() {
    return Stack(
      children: [
        // 첫 번째 배경 레이어
        Transform.rotate(
          angle: -0.05,
          child: Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: const Color(0xFFF6E9C5),
            ),
          ),
        ),
        // 두 번째 배경 레이어
        Transform.rotate(
          angle: 0.05,
          child: Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: const Color(0xFFDAF3DF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.grey[200],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          _getDisplayWidget(),
          if (completableChallenges.isNotEmpty) _buildPageIndicator(),
          _buildChallengeButton(),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _controller,
      itemCount: completableChallenges.length,
      itemBuilder: (context, index) {
        final challenge = completableChallenges[index]['challenge'];
        final String imageUrl =
            challenge['image'] != null
                ? '${dotenv.env['API_URL']?.replaceFirst('/api', '')}${challenge['image']}'
                : '';

        // 네트워크 이미지인지 로컬 이미지인지 확인
        if (imageUrl.isNotEmpty) {
          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return ChallengePlaceholder(
                category: challenge['category'],
                index: index,
                width: double.infinity,
                height: double.infinity,
              );
            },
          );
        } else {
          return ChallengePlaceholder(
            category: challenge['category'],
            index: index,
            width: double.infinity,
            height: double.infinity,
          );
        }
      },
    );
  }

  Widget _buildPageIndicator() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            completableChallenges.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: currentImageIndex == index ? 12 : 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    currentImageIndex == index ? Colors.white : Colors.white54,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeButton() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: isLoading ? null : _showChallengeCompleteDialog,
          child: Container(
            width: 200,
            height: 50,
            decoration: BoxDecoration(
              color:
                  completableChallenges.isEmpty
                      ? Colors.green.withOpacity(0.8) // 완료했을 때는 초록색
                      : Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child:
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            completableChallenges.isEmpty
                                ? Icons.check_circle
                                : Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            completableChallenges.isEmpty
                                ? '오늘 완료했습니다'
                                : '사진 찍고 완료하기',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
}
