import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:joinup/screens/challenge/challenge_screen.dart';
import '../../services/challenge/challenge_service.dart';
import 'challenge_create_screen.dart';
import '../../widgets/home/challenge_card.dart';
import '../../widgets/common/challenge_placeholder.dart';

class ChallengeListScreen extends StatefulWidget {
  final String? initialCategory; // 초기 카테고리 매개변수 추가

  const ChallengeListScreen({super.key, this.initialCategory});

  @override
  State<ChallengeListScreen> createState() => _ChallengeListScreenState();
}

class _ChallengeListScreenState extends State<ChallengeListScreen> {
  final ChallengeService _challengeService = ChallengeService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _challenges = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _searchQuery = '';
  String _sortBy = 'createdAt';
  String _selectedCategory = 'all'; // 선택된 카테고리

  // 카테고리 목록
  final List<Map<String, dynamic>> _categories = [
    {'value': 'all', 'name': '전체', 'icon': Icons.apps},
    {'value': 'health', 'name': '건강', 'icon': Icons.favorite},
    {'value': 'exercise', 'name': '운동', 'icon': Icons.fitness_center},
    {'value': 'study', 'name': '학습', 'icon': Icons.school},
    {'value': 'hobby', 'name': '취미', 'icon': Icons.palette},
    {'value': 'lifestyle', 'name': '라이프스타일', 'icon': Icons.home},
    {'value': 'social', 'name': '소셜', 'icon': Icons.people},
  ];

  @override
  void initState() {
    super.initState();
    // 초기 카테고리 설정
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadChallenges();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreChallenges();
    }
  }

  Future<void> _loadChallenges({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _challenges.clear();
        _currentPage = 1;
        _hasMore = true;
      }
    });

    try {
      final result = await _challengeService.getChallenges(
        page: _currentPage,
        limit: 1000,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        sortBy: _sortBy,
      );

      if (result['success']) {
        final data = result['data']['data'];
        List<Map<String, dynamic>> newChallenges =
            List<Map<String, dynamic>>.from(data['challenges']);

        // 카테고리 필터링 (all이 아닌 경우)
        if (_selectedCategory != 'all') {
          newChallenges =
              newChallenges
                  .where(
                    (challenge) => challenge['category'] == _selectedCategory,
                  )
                  .toList();
        }

        setState(() {
          if (refresh) {
            _challenges = newChallenges;
          } else {
            _challenges.addAll(newChallenges);
          }
          _hasMore = newChallenges.length == 10;
          _currentPage++;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('챌린지 로딩 중 오류가 발생했습니다: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreChallenges() async {
    if (_hasMore && !_isLoading) {
      await _loadChallenges();
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadChallenges(refresh: true);
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    _loadChallenges(refresh: true);
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadChallenges(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '전체 챌린지',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '챌린지 검색...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: _onSearch,
            ),
          ),

          // 카테고리 필터
          _buildCategoryFilter(),

          // 챌린지 목록
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadChallenges(refresh: true),
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: _challenges.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _challenges.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final challenge = _challenges[index];
                  return _buildChallengeCard(challenge, index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['value'];

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'],
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              onSelected: (_) => _onCategoryChanged(category['value']),
              backgroundColor: Colors.white,
              selectedColor: Colors.black,
              checkmarkColor: Colors.white,
              elevation: isSelected ? 2 : 0,
              pressElevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.black : Colors.grey[300]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge, int index) {
    // 이미지 URL 처리
    final String imageUrl =
        challenge['image'] != null
            ? '${dotenv.env['API_URL']?.replaceFirst('/api', '')}${challenge['image']}'
            : '';
    print(challenge['category']);
    return ChallengeCard(
      title: challenge['title'] ?? '챌린지',
      imageAsset: imageUrl.isNotEmpty ? imageUrl : '',
      currentParticipants: challenge['participants']?.length ?? 0,
      maxParticipants: challenge['maxParticipants'] ?? 0,
      badge: _getChallengeBadge(challenge),
      category: challenge['category'] ?? '기타',
      onTap: () {
        Navigator.pushNamed(context, '/challenge/${challenge['_id']}');
      },
    );
  }

  // 챌린지 뱃지 결정 로직
  String? _getChallengeBadge(Map<String, dynamic> challenge) {
    final participants = challenge['participants']?.length ?? 0;
    final maxParticipants = challenge['maxParticipants'] ?? 1;
    final completionRate = challenge['completionRate'] ?? 0.0;
    final viewCount = challenge['viewCount'] ?? 0;
    final createdAt = challenge['createdAt'];

    // 참여율 계산 (70% 이상)
    final participationRate = participants / maxParticipants;

    // 생성일 계산 (3일 이내면 NEW)
    bool isNew = false;
    if (createdAt != null) {
      try {
        final createdDate = DateTime.parse(createdAt);
        final daysDifference = DateTime.now().difference(createdDate).inDays;
        isNew = daysDifference <= 3;
      } catch (e) {
        // 날짜 파싱 에러 시 무시
      }
    }

    // 뱃지 우선순위: 🔥 > NEW
    // 🔥 조건: 참여율 70% 이상, 완료율 30% 이상, 조회수 100 이상
    if (participationRate >= 0.7 && completionRate >= 0.3 && viewCount >= 100) {
      return '🔥';
    }

    // NEW 조건: 생성된 지 3일 이내
    if (isNew) {
      return 'NEW';
    }

    return null;
  }
}
