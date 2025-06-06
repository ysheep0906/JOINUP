import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:joinup/services/auth/auth_service.dart';
import 'package:joinup/services/badge/badge_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'dart:typed_data';

/// 프로필 수정 화면 위젯
/// 사용자가 자신의 프로필 정보(닉네임, 프로필 사진, 대표 배지)를 수정할 수 있는 화면
class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic>? userInfo;

  const ProfileEditScreen({super.key, this.userInfo});
  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nicknameController;

  // ============================================================
  // 상태 변수들 (State Variables)
  // ============================================================

  /// 폼 유효성 검사를 위한 글로벌 키
  final _formKey = GlobalKey<FormState>();

  // 서비스 인스턴스들
  final AuthService _authService = AuthService();
  final BadgeService _badgeService = BadgeService();

  // 이미지 관련 변수들 ========================================

  /// 모바일에서 선택한 프로필 이미지 파일
  File? _profileImage;

  /// 웹에서 선택한 프로필 이미지 바이트 데이터
  Uint8List? _webImage;

  /// 이미지 선택을 위한 ImagePicker 인스턴스
  final ImagePicker _picker = ImagePicker();

  /// 현재 설정된 프로필 이미지 URL (기본 이미지 포함)
  String? _currentProfileImageUrl;

  // 배지 관련 변수들 ==========================================

  /// 사용자가 선택한 대표 배지들의 ID 리스트 (최대 4개, 순서 중요)
  List<String> _selectedBadges = [];

  /// 사용자가 획득한 모든 배지들의 리스트
  List<BadgeItem> _availableBadges = [];

  // 로딩 상태 관리
  bool _isLoading = true;
  String? _error;

  // ============================================================
  // 생명주기 메서드들 (Lifecycle Methods)
  // ============================================================

  @override
  void initState() {
    super.initState();
    // userInfo가 있으면 기존 닉네임으로 초기화
    _nicknameController = TextEditingController(
      text: widget.userInfo?['nickname'] ?? '',
    );
    // 화면 초기화 시 필요한 데이터들을 로드
    _loadInitialData();
  }

  /// 초기 데이터 로드 (프로필 정보 + 배지 정보)
  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 병렬로 데이터 로드
      await Future.wait([_loadCurrentProfile(), _loadAvailableBadges()]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 현재 사용자의 프로필 정보를 로드하는 메서드
  Future<void> _loadCurrentProfile() async {
    try {
      if (widget.userInfo != null) {
        // userInfo에서 기본 정보 설정
        _nicknameController.text = widget.userInfo!['nickname'] ?? '';
        _currentProfileImageUrl = widget.userInfo!['profileImage'];

        // representativeBadges에서 배지 ID 추출 (새로운 형태: {badgeId, order})
        final representativeBadges =
            widget.userInfo!['representativeBadges'] ?? [];
        final badgeIds = <String>[];

        if (representativeBadges is List) {
          // order 순서대로 정렬한 후 배지 ID 추출
          final sortedBadges = List<Map<String, dynamic>>.from(
            representativeBadges,
          );
          sortedBadges.sort((a, b) {
            final aOrder = a['order'] ?? 999;
            final bOrder = b['order'] ?? 999;
            return aOrder.compareTo(bOrder);
          });

          for (final badge in sortedBadges) {
            if (badge is Map<String, dynamic>) {
              final badgeId = badge['badgeId'] ?? badge['_id'] ?? badge['id'];
              if (badgeId != null) {
                badgeIds.add(badgeId.toString());
              }
            }
          }
        }

        _selectedBadges = badgeIds;
      } else {
        // userInfo가 없으면 API에서 현재 사용자 정보 조회
        final userInfo = await _authService.getCurrentUser();
        _nicknameController.text = userInfo['nickname'] ?? '';
        _currentProfileImageUrl = userInfo['profileImage'];

        final representativeBadges = userInfo['representativeBadges'] ?? [];
        final badgeIds = <String>[];

        if (representativeBadges is List) {
          // order 순서대로 정렬한 후 배지 ID 추출
          final sortedBadges = List<Map<String, dynamic>>.from(
            representativeBadges,
          );
          sortedBadges.sort((a, b) {
            final aOrder = a['order'] ?? 999;
            final bOrder = b['order'] ?? 999;
            return aOrder.compareTo(bOrder);
          });

          for (final badge in sortedBadges) {
            if (badge is Map<String, dynamic>) {
              final badgeId = badge['badgeId'] ?? badge['_id'] ?? badge['id'];
              if (badgeId != null) {
                badgeIds.add(badgeId.toString());
              }
            }
          }
        }

        _selectedBadges = badgeIds;
      }
    } catch (e) {
      throw Exception('프로필 정보 로드 실패: $e');
    }
  }

  /// 사용자가 획득한 모든 배지 정보를 로드하는 메서드
  Future<void> _loadAvailableBadges() async {
    try {
      // 모든 배지 조회
      final allBadges = await _badgeService.getAllBadges();

      // 사용자가 획득한 배지 ID들 추출
      Set<String> earnedBadgeIds = {};

      if (widget.userInfo != null) {
        // userInfo에서 획득한 모든 배지 가져오기
        final earnedBadges = widget.userInfo!['earnedBadges'] ?? [];
        final representativeBadges =
            widget.userInfo!['representativeBadges'] ?? [];

        // earnedBadges에서 배지 ID 추출
        for (final badge in earnedBadges) {
          if (badge is Map<String, dynamic>) {
            final badgeId = badge['_id'] ?? badge['id'] ?? badge['badgeId'];
            if (badgeId != null) {
              earnedBadgeIds.add(badgeId.toString());
            }
          } else if (badge is String) {
            earnedBadgeIds.add(badge);
          }
        }

        // representativeBadges도 포함 (새로운 형태: {badgeId, order})
        for (final badge in representativeBadges) {
          if (badge is Map<String, dynamic>) {
            final badgeId = badge['badgeId'] ?? badge['_id'] ?? badge['id'];
            if (badgeId != null) {
              earnedBadgeIds.add(badgeId.toString());
            }
          } else if (badge is String) {
            earnedBadgeIds.add(badge);
          }
        }
      } else {
        // userInfo가 없으면 API에서 현재 사용자의 획득 배지 조회
        final userInfo = await _authService.getCurrentUser();
        final earnedBadges = userInfo['earnedBadges'] ?? [];
        final representativeBadges = userInfo['representativeBadges'] ?? [];

        // 모든 획득 배지 처리
        for (final badge in earnedBadges) {
          if (badge is Map<String, dynamic>) {
            final badgeId = badge['_id'] ?? badge['id'] ?? badge['badgeId'];
            if (badgeId != null) {
              earnedBadgeIds.add(badgeId.toString());
            }
          } else if (badge is String) {
            earnedBadgeIds.add(badge);
          }
        }

        // representativeBadges 처리 (새로운 형태)
        for (final badge in representativeBadges) {
          if (badge is Map<String, dynamic>) {
            final badgeId = badge['badgeId'] ?? badge['_id'] ?? badge['id'];
            if (badgeId != null) {
              earnedBadgeIds.add(badgeId.toString());
            }
          } else if (badge is String) {
            earnedBadgeIds.add(badge);
          }
        }
      }

      // 사용자가 획득한 배지들만 필터링
      final availableBadges = <BadgeItem>[];

      for (final badge in allBadges) {
        final badgeId =
            badge['_id']?.toString() ?? badge['id']?.toString() ?? '';

        // 사용자가 획득한 배지만 선택 가능하도록 필터링
        if (earnedBadgeIds.contains(badgeId)) {
          availableBadges.add(
            BadgeItem(
              id: badgeId,
              name: badge['name'] ?? '배지',
              description: badge['description'] ?? '',
              icon: _getIconFromString(badge['iconUrl'] ?? '🏅'),
              color: _getColorFromRarity(badge['rarity'] ?? 'common'),
              emoji: badge['iconUrl'] ?? '🏅',
            ),
          );
        }
      }

      // 희귀도 순서로 정렬 (legendary → epic → rare → common)
      availableBadges.sort((a, b) {
        final rarityOrder = {'legendary': 0, 'epic': 1, 'rare': 2, 'common': 3};

        final aRarity =
            a.color == Colors.purple
                ? 'legendary'
                : a.color == Colors.deepPurple
                ? 'epic'
                : a.color == Colors.blue
                ? 'rare'
                : 'common';
        final bRarity =
            b.color == Colors.purple
                ? 'legendary'
                : b.color == Colors.deepPurple
                ? 'epic'
                : b.color == Colors.blue
                ? 'rare'
                : 'common';

        final aOrder = rarityOrder[aRarity] ?? 3;
        final bOrder = rarityOrder[bRarity] ?? 3;

        return aOrder.compareTo(bOrder);
      });

      setState(() {
        _availableBadges = availableBadges;
      });

      print('전체 배지 수: ${allBadges.length}');
      print('획득한 배지 수: ${earnedBadgeIds.length}');
      print('선택 가능한 배지 수: ${availableBadges.length}');
    } catch (e) {
      throw Exception('배지 정보 로드 실패: $e');
    }
  }

  // 아이콘 문자열을 IconData로 변환 (이모지는 그대로 사용)
  IconData _getIconFromString(String iconStr) {
    // 실제 이모지나 아이콘 URL인 경우 기본 아이콘 반환
    return Icons.emoji_events;
  }

  // 희귀도에 따른 색상 반환
  Color _getColorFromRarity(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return Colors.purple;
      case 'epic':
        return Colors.deepPurple;
      case 'rare':
        return Colors.blue;
      case 'common':
      default:
        return Colors.amber;
    }
  }

  // ============================================================
  // UI 빌드 메서드들 (UI Build Methods)
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 상단 앱바 구성
      appBar: AppBar(
        title: Text(
          '프로필 수정',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0, // 그림자 제거
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          // 오른쪽 상단 저장 버튼
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              '저장',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      // 메인 콘텐츠 영역
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              '데이터를 불러올 수 없습니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('다시 시도', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey, // 폼 유효성 검사를 위한 키
      child: SingleChildScrollView(
        // 스크롤 가능한 영역
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 이미지 수정 섹션
            Center(child: _buildProfileImageSection()),

            SizedBox(height: 30),

            // 닉네임 입력 섹션
            _buildInputSection(
              label: '닉네임 *', // 필수 입력 필드 표시
              child: TextFormField(
                controller: _nicknameController,
                decoration: _inputDecoration('닉네임을 입력하세요'),
                maxLength: 20, // 최대 20자 제한
                validator: (value) {
                  // 닉네임 유효성 검사
                  if (value?.isEmpty ?? true) {
                    return '닉네임을 입력해주세요';
                  }
                  if (value!.length < 2) {
                    return '닉네임은 2글자 이상이어야 합니다';
                  }
                  return null; // 유효한 경우
                },
              ),
            ),

            SizedBox(height: 10),

            // 대표 배지 선택 섹션
            _buildBadgeSection(),

            SizedBox(height: 30),

            // 하단 저장 버튼
            SizedBox(
              width: double.infinity, // 전체 너비
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                        : Text(
                          '프로필 저장',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 프로필 이미지 수정 섹션 위젯을 구성하는 메서드
  /// 원형 프로필 이미지와 카메라 아이콘 버튼을 포함
  Widget _buildProfileImageSection() {
    return Column(
      children: [
        Stack(
          // 프로필 이미지 위에 카메라 버튼을 겹쳐서 배치
          children: [
            // 원형 프로필 이미지 컨테이너
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle, // 원형 모양
                color: Colors.white,
                boxShadow: [
                  // 그림자 효과
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(child: _getProfileImageWidget()), // 이미지를 원형으로 클리핑
            ),

            // 오른쪽 하단 카메라 편집 버튼
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                // 웹인지 모바일인지에 따라 다른 이미지 선택 방법 사용
                onTap: kIsWeb ? _pickImageForWeb : _showImagePickerDialog,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // 안내 텍스트
        Text(
          '프로필 사진 변경',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  /// 대표 배지 선택 섹션 위젯을 구성하는 메서드
  /// 현재 프로필 칭호, 선택된 배지 목록, 배지 추가 버튼을 포함
  Widget _buildBadgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목과 선택 개수 표시
        Row(
          children: [
            Text(
              '대표 배지',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 8),

            // 현재 선택된 배지 개수 표시 (X/4 형태)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_selectedBadges.length}/4', // 현재/최대 개수
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),

        // 안내 텍스트
        Text(
          '최대 4개의 배지를 선택할 수 있습니다. 맨 위 배지가 프로필 칭호가 됩니다.',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        SizedBox(height: 16),

        // 현재 프로필 칭호 표시 (첫 번째 배지)
        if (_selectedBadges.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏆 현재 프로필 칭호',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    // 첫 번째 배지의 아이콘
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getBadgeById(
                          _selectedBadges.first,
                        )?.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getBadgeById(_selectedBadges.first)?.emoji ?? '🏅',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),

                    // 첫 번째 배지의 이름
                    Text(
                      _getBadgeById(_selectedBadges.first)?.name ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],

        // 선택된 배지들의 순서 변경 가능한 리스트
        if (_selectedBadges.isNotEmpty) ...[
          Row(
            children: [
              Text(
                '선택된 배지',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.drag_indicator, color: Colors.grey[400], size: 16),
              SizedBox(width: 4),
              Text(
                '드래그하여 순서 변경',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          SizedBox(height: 12),

          // 드래그 앤 드롭으로 순서 변경 가능한 배지 리스트
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.transparent, // 드래그 시 배경을 투명하게
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true, // 필요한 만큼만 높이 차지
              buildDefaultDragHandles: false, // 기본 드래그 핸들 숨기기
              physics: NeverScrollableScrollPhysics(), // 스크롤 비활성화 (부모 스크롤 사용)
              itemCount: _selectedBadges.length,

              // 배지 순서가 변경될 때 호출되는 콜백
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  // Flutter의 ReorderableListView 규칙에 따른 인덱스 조정
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  // 배지 순서 변경
                  final String badge = _selectedBadges.removeAt(oldIndex);
                  _selectedBadges.insert(newIndex, badge);
                });
              },

              // 각 배지 아이템을 빌드하는 메서드
              itemBuilder: (context, index) {
                final String badgeId = _selectedBadges[index];
                final badge = _getBadgeById(badgeId); // 배지 정보 가져오기

                return Container(
                  key: Key(badgeId), // 고유한 키 (리스트 순서 변경 시 필요)
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),

                  // 드래그 시작 지점을 전체 컨테이너로 설정
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // 순서 번호 (1번은 금색, 나머지는 회색)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color:
                                  index == 0 ? Colors.amber : Colors.grey[100],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    index == 0
                                        ? Colors.amber
                                        : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color:
                                      index == 0
                                          ? Colors.white
                                          : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),

                          // 배지 아이콘
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: badge?.color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                badge?.emoji ?? '🏅',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),

                          // 배지 정보 (이름 및 프로필 칭호 표시)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  badge?.name ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                // 첫 번째 배지에만 "프로필 칭호" 표시
                                if (index == 0)
                                  Text(
                                    '프로필 칭호',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // 삭제 버튼 (빨간색 X 아이콘)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedBadges.removeAt(index); // 해당 배지 제거
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                          ),

                          SizedBox(width: 8),

                          // 드래그 핸들 아이콘
                          Icon(
                            Icons.drag_handle,
                            color: Colors.black,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
        ],

        // 배지 추가/변경 버튼
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            // 4개 미만일 때만 활성화
            onPressed: _selectedBadges.length < 4 ? _showBadgeSelector : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _selectedBadges.length < 4 ? Colors.black : Colors.grey,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              _selectedBadges.isEmpty
                  ? '대표 배지 선택'
                  : '배지 추가 (${_selectedBadges.length}/4)',
              style: TextStyle(
                color: _selectedBadges.length < 4 ? Colors.black : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 입력 섹션 (라벨 + 입력 위젯)을 구성하는 공통 메서드
  Widget _buildInputSection({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨 텍스트
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        child, // 실제 입력 위젯
      ],
    );
  }

  // ============================================================
  // 유틸리티 메서드들 (Utility Methods)
  // ============================================================

  /// 현재 설정된 프로필 이미지를 반환하는 메서드
  /// 웹/모바일 환경과 이미지 유무에 따라 다른 위젯 반환
  Widget _getProfileImageWidget() {
    if (kIsWeb && _webImage != null) {
      // 웹에서 새로 선택한 이미지가 있는 경우
      return Image.memory(_webImage!, fit: BoxFit.cover);
    } else if (!kIsWeb && _profileImage != null) {
      // 모바일에서 새로 선택한 이미지가 있는 경우
      return Image.file(_profileImage!, fit: BoxFit.cover);
    } else if (_currentProfileImageUrl != null &&
        _currentProfileImageUrl!.isNotEmpty) {
      // 기존에 설정된 이미지가 있는 경우
      if (_currentProfileImageUrl!.startsWith('/uploads/')) {
        final apiUrl = dotenv.env['API_URL'];
        return Image.network(
          '${apiUrl != null ? apiUrl.replaceFirst('/api', '') : ''}$_currentProfileImageUrl',
          fit: BoxFit.cover,
        );
      } else {
        return Image.asset(_currentProfileImageUrl!, fit: BoxFit.cover);
      }
    } else {
      // 이미지가 없는 경우 기본 아이콘 표시
      return Icon(Icons.person, size: 60, color: Colors.grey[400]);
    }
  }

  /// 배지 ID로 배지 정보를 찾아 반환하는 메서드
  BadgeItem? _getBadgeById(String id) {
    try {
      return _availableBadges.firstWhere((badge) => badge.id == id);
    } catch (e) {
      // 해당 ID의 배지를 찾을 수 없는 경우 null 반환
      return null;
    }
  }

  // ============================================================
  // 배지 선택 관련 메서드들 (Badge Selection Methods)
  // ============================================================

  /// 배지 선택 모달을 표시하는 메서드
  /// 사용자가 여러 배지를 선택한 후 한 번에 적용할 수 있음
  void _showBadgeSelector() {
    // 임시 선택 리스트 - 현재 선택된 배지들로 초기화
    // 모달 내에서 변경사항을 추적하고, 최종 적용 시에만 실제 상태에 반영
    List<String> tempSelectedBadges = List.from(_selectedBadges);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 키보드가 올라와도 모달 크기 조정
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            // 모달 내에서 독립적인 상태 관리를 위한 StatefulBuilder
            builder:
                (context, setModalState) => DraggableScrollableSheet(
                  initialChildSize: 0.7, // 초기 높이 (화면의 70%)
                  minChildSize: 0.5, // 최소 높이 (화면의 50%)
                  maxChildSize: 0.9, // 최대 높이 (화면의 90%)
                  expand: false,
                  builder:
                      (context, scrollController) => Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            // 상단 핸들 바 (드래그해서 모달 크기 조정 가능)
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(height: 20),

                            // 모달 헤더 (제목과 선택 개수)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '배지 선택',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                // 현재 선택된 배지 개수 표시
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${tempSelectedBadges.length}/4',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),

                            // 추가 선택 가능한 개수 안내
                            Text(
                              '최대 ${4 - tempSelectedBadges.length}개 더 선택 가능',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 20),

                            // 배지 리스트 (스크롤 가능)
                            Expanded(
                              child:
                                  _availableBadges.isEmpty
                                      ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.emoji_events_outlined,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              '획득한 배지가 없습니다',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '활동을 통해 배지를 획득해보세요!',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[500],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                      : ListView.builder(
                                        controller: scrollController,
                                        itemCount: _availableBadges.length,
                                        itemBuilder: (context, index) {
                                          final badge = _availableBadges[index];
                                          final isSelected = tempSelectedBadges
                                              .contains(badge.id);
                                          final canSelect =
                                              !isSelected &&
                                              tempSelectedBadges.length < 4;

                                          return Container(
                                            margin: EdgeInsets.only(bottom: 12),
                                            child: InkWell(
                                              // 배지 클릭 시 선택/해제 처리
                                              onTap: () {
                                                setModalState(() {
                                                  // 모달 내 상태만 업데이트
                                                  if (isSelected) {
                                                    tempSelectedBadges.remove(
                                                      badge.id,
                                                    ); // 선택 해제
                                                  } else if (canSelect) {
                                                    tempSelectedBadges.add(
                                                      badge.id,
                                                    ); // 선택 추가
                                                  }
                                                });
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: AnimatedContainer(
                                                duration: Duration(
                                                  milliseconds: 200,
                                                ), // 애니메이션 효과
                                                padding: EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  // 선택 상태에 따른 배경색 변경
                                                  color:
                                                      isSelected
                                                          ? Colors.black
                                                              .withOpacity(0.05)
                                                          : canSelect
                                                          ? Colors.white
                                                          : Colors.grey[50],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  // 선택 상태에 따른 테두리 변경
                                                  border: Border.all(
                                                    color:
                                                        isSelected
                                                            ? Colors
                                                                .black // 선택됨: 검은색 굵은 테두리
                                                            : canSelect
                                                            ? Colors
                                                                .grey[300]! // 선택 가능: 연한 회색 테두리
                                                            : Colors
                                                                .grey[200]!, // 선택 불가: 더 연한 회색 테두리
                                                    width:
                                                        isSelected
                                                            ? 3
                                                            : 1, // 선택된 경우 더 굵은 테두리
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // 배지 아이콘
                                                    Container(
                                                      width: 50,
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        color: badge.color
                                                            .withOpacity(
                                                              isSelected
                                                                  ? 0.3
                                                                  : 0.2,
                                                            ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          badge.emoji,
                                                          style: TextStyle(
                                                            fontSize: 24,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 16),

                                                    // 배지 정보 (이름과 설명)
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            badge.name,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              color:
                                                                  canSelect ||
                                                                          isSelected
                                                                      ? Colors
                                                                          .black
                                                                      : Colors
                                                                          .grey, // 선택 불가능한 경우 회색
                                                            ),
                                                          ),
                                                          SizedBox(height: 4),
                                                          Text(
                                                            badge.description,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),

                                                    // 오른쪽 상태 아이콘
                                                    if (isSelected)
                                                      // 선택된 경우: 검은색 체크 아이콘
                                                      Container(
                                                        padding: EdgeInsets.all(
                                                          4,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                              color:
                                                                  Colors.black,
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                            ),
                                                        child: Icon(
                                                          Icons.check,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      )
                                                    else if (!canSelect)
                                                      // 선택 불가능한 경우: 회색 차단 아이콘
                                                      Icon(
                                                        Icons.block,
                                                        color: Colors.grey,
                                                        size: 24,
                                                      )
                                                    else
                                                      // 선택 가능한 경우: 빈 원형 테두리
                                                      Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color:
                                                                Colors
                                                                    .grey[400]!,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                            ),

                            SizedBox(height: 16),

                            // 하단 액션 버튼들
                            Row(
                              children: [
                                // 취소 버튼
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed:
                                        () => Navigator.pop(
                                          context,
                                        ), // 변경사항 무시하고 닫기
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.grey[400]!,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      '취소',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),

                                // 적용 버튼 (2배 넓이)
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // 임시 선택사항을 실제 상태에 반영
                                      setState(() {
                                        _selectedBadges = tempSelectedBadges;
                                      });
                                      Navigator.pop(context); // 모달 닫기
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      '적용 (${tempSelectedBadges.length}개)', // 선택된 개수 표시
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                ),
          ),
    );
  }

  // ============================================================
  // 입력 스타일 메서드들 (Input Style Methods)
  // ============================================================

  /// 텍스트 입력 필드의 공통 스타일을 정의하는 메서드
  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      // 기본 테두리
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.black),
      ),
      // 비활성 상태 테두리
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      // 포커스 상태 테두리
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.black),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // ============================================================
  // 이미지 선택 관련 메서드들 (Image Selection Methods)
  // ============================================================

  /// 웹용 이미지 선택 메서드
  /// 파일 선택 다이얼로그를 통해 이미지를 선택하고 메모리에 로드
  Future<void> _pickImageForWeb() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, // 갤러리에서 선택
        maxWidth: 512, // 최대 너비 제한 (성능 최적화)
        maxHeight: 512, // 최대 높이 제한
        imageQuality: 80, // 이미지 품질 (80% 압축)
      );

      if (image != null) {
        final bytes = await image.readAsBytes(); // 이미지를 바이트로 읽기
        setState(() {
          _webImage = bytes; // 웹용 이미지 데이터 저장
          _currentProfileImageUrl = null; // 기존 이미지 URL 제거
        });
      }
    } catch (e) {
      _showSnackBar('이미지 선택 중 오류가 발생했습니다.');
    }
  }

  /// 모바일용 이미지 선택 다이얼로그를 표시하는 메서드
  /// 갤러리, 카메라, 삭제 옵션을 제공
  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min, // 필요한 만큼만 높이 차지
            children: [
              // 갤러리에서 선택
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('갤러리에서 선택'),
                onTap: () async {
                  Navigator.pop(context); // 다이얼로그 닫기
                  await _pickImage(ImageSource.gallery); // 갤러리에서 이미지 선택
                },
              ),

              // 카메라로 촬영
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('카메라로 촬영'),
                onTap: () async {
                  Navigator.pop(context); // 다이얼로그 닫기
                  await _pickImage(ImageSource.camera); // 카메라로 이미지 촬영
                },
              ),

              // 프로필 사진이 있는 경우에만 삭제 옵션 표시
              if (_hasProfileImage())
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('프로필 사진 삭제', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context); // 다이얼로그 닫기
                    setState(() {
                      // 모든 이미지 데이터 제거
                      _profileImage = null;
                      _webImage = null;
                      _currentProfileImageUrl = null;
                    });
                  },
                ),

              // 취소 버튼
              ListTile(
                leading: Icon(Icons.cancel),
                title: Text('취소'),
                onTap: () => Navigator.pop(context), // 다이얼로그만 닫기
              ),
            ],
          ),
        );
      },
    );
  }

  /// 모바일용 이미지 선택 메서드
  /// 갤러리 또는 카메라에서 이미지를 선택하고 파일로 저장
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source, // 갤러리 또는 카메라
        maxWidth: 512, // 최대 너비 제한
        maxHeight: 512, // 최대 높이 제한
        imageQuality: 80, // 이미지 품질
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path); // 모바일용 이미지 파일 저장
          _currentProfileImageUrl = null; // 기존 이미지 URL 제거
        });
      }
    } catch (e) {
      _showSnackBar('이미지 선택 중 오류가 발생했습니다.');
    }
  }

  /// 현재 프로필 이미지가 설정되어 있는지 확인하는 메서드
  bool _hasProfileImage() {
    return _currentProfileImageUrl != null ||
        _profileImage != null ||
        _webImage != null;
  }

  // ============================================================
  // 저장 및 유틸리티 메서드들 (Save & Utility Methods)
  // ============================================================

  /// 프로필 변경사항을 저장하는 메서드
  /// 폼 유효성 검사 후 API 호출로 서버에 데이터 전송
  void _saveProfile() async {
    // 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return; // 유효하지 않으면 저장 중단
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 어떤 프로필이미지가 있는지 print로 출력
      print('Current Profile Image URL: $_currentProfileImageUrl');
      // 1. 프로필 이미지 업로드 (새 이미지가 있는 경우)
      if (kIsWeb && _webImage != null) {
        // 웹에서 새로 선택한 이미지가 있는 경우
        final nickname = _nicknameController.text.trim();
        await _authService.uploadProfileImage(_webImage!, nickname);
      } else if (!kIsWeb && _profileImage != null) {
        // 모바일에서 새로 선택한 이미지가 있는 경우
        final bytes = await _profileImage!.readAsBytes();
        final nickname = _nicknameController.text.trim();
        await _authService.uploadProfileImage(bytes, nickname);
      } // 기존 이미지가 null로 왔으면 이미지 삭제
      else if (_currentProfileImageUrl == null) {
        // 기존 이미지가 있는 경우, URL을 통해 삭제
        await _authService.deleteProfileImage();
      }

      // 2. 대표 배지 업데이트 (순서 포함)
      if (_selectedBadges.isNotEmpty) {
        await _authService.updateRepresentativeBadges(_selectedBadges);
      }

      // 3. 닉네임 업데이트
      await _authService.updateProfile(nickname: _nicknameController.text);

      setState(() {
        _isLoading = false;
      });

      _showSnackBar('프로필이 성공적으로 저장되었습니다!');
      Navigator.pop(context, true);
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('프로필 저장에 실패했습니다: ${error.toString()}');
    }
  }

  /// 하단에 스낵바 메시지를 표시하는 메서드
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black),
    );
  }

  // ============================================================
  // 생명주기 정리 메서드들 (Lifecycle Cleanup Methods)
  // ============================================================

  @override
  void dispose() {
    // 메모리 누수 방지를 위한 컨트롤러 해제
    _nicknameController.dispose();
    super.dispose();
  }
}

// ============================================================
// 데이터 모델 클래스들 (Data Model Classes)
// ============================================================

/// 배지 정보를 담는 데이터 클래스
/// 각 배지의 고유 정보와 UI 표시를 위한 데이터를 포함
class BadgeItem {
  final String id; // 고유 식별자
  final String name; // 배지 이름
  final String description; // 배지 획득 조건 설명
  final IconData icon; // 배지 아이콘 (실제로는 사용 안함)
  final Color color; // 배지 테마 색상
  final String emoji; // 실제 표시할 이모지

  BadgeItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.emoji,
  });
}
