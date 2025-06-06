import 'package:flutter/material.dart';
import 'package:joinup/services/badge/badge_service.dart';

class BadgesScreen extends StatefulWidget {
  final Map<String, dynamic>? userInfo;

  const BadgesScreen({super.key, this.userInfo});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final BadgeService _badgeService = BadgeService();
  List<Map<String, dynamic>> allBadges = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllBadges();
    print(widget.userInfo);
  }

  Future<void> _loadAllBadges() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final badges = await BadgeService().getAllBadges();
      setState(() {
        allBadges = badges;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '내 배지',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadAllBadges,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
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
              '배지를 불러올 수 없습니다',
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
              onPressed: _loadAllBadges,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // userInfo의 earnedBadges에서 획득한 배지 ID 추출
    final earnedBadges = widget.userInfo?['earnedBadges'] ?? [];
    final earnedBadgeIds = <String>{};

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

    // 카테고리별로 배지 분류
    final healthBadges = _getBadgesByCategory('health', earnedBadgeIds);
    final exerciseBadges = _getBadgesByCategory('exercise', earnedBadgeIds);
    final studyBadges = _getBadgesByCategory('study', earnedBadgeIds);
    final hobbyBadges = _getBadgesByCategory('hobby', earnedBadgeIds);
    final lifestyleBadges = _getBadgesByCategory('lifestyle', earnedBadgeIds);
    final socialBadges = _getBadgesByCategory('social', earnedBadgeIds);
    final achievementBadges = _getBadgesByCategory(
      'achievement',
      earnedBadgeIds,
    );
    final otherBadges = _getBadgesByCategory('other', earnedBadgeIds);

    final earnedCount = earnedBadgeIds.length;
    final totalCount = allBadges.length;

    return RefreshIndicator(
      onRefresh: _loadAllBadges,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCard(earnedCount, totalCount),
            const SizedBox(height: 24),
            if (healthBadges.isNotEmpty) ...[
              _buildBadgeSection('🩺 건강 배지', healthBadges),
              const SizedBox(height: 20),
            ],
            if (exerciseBadges.isNotEmpty) ...[
              _buildBadgeSection('🏋️ 운동 배지', exerciseBadges),
              const SizedBox(height: 20),
            ],
            if (studyBadges.isNotEmpty) ...[
              _buildBadgeSection('📚 학습 배지', studyBadges),
              const SizedBox(height: 20),
            ],
            if (hobbyBadges.isNotEmpty) ...[
              _buildBadgeSection('🎨 취미 배지', hobbyBadges),
              const SizedBox(height: 20),
            ],
            if (lifestyleBadges.isNotEmpty) ...[
              _buildBadgeSection('🌱 라이프스타일 배지', lifestyleBadges),
              const SizedBox(height: 20),
            ],
            if (socialBadges.isNotEmpty) ...[
              _buildBadgeSection('👥 소셜 배지', socialBadges),
              const SizedBox(height: 20),
            ],
            if (achievementBadges.isNotEmpty) ...[
              _buildBadgeSection('🏆 성취 배지', achievementBadges),
              const SizedBox(height: 20),
            ],
            if (otherBadges.isNotEmpty) ...[
              _buildBadgeSection('✨ 기타 배지', otherBadges),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  // 카테고리별 배지 필터링 (획득 여부 포함)
  List<BadgeItem> _getBadgesByCategory(
    String category,
    Set<String> earnedBadgeIds,
  ) {
    final categoryBadges =
        allBadges.where((badge) => badge['category'] == category).toList();

    final badgeItems =
        categoryBadges.map<BadgeItem>((badge) {
          final badgeId =
              badge['_id']?.toString() ?? badge['id']?.toString() ?? '';
          final isEarned = earnedBadgeIds.contains(badgeId);

          return BadgeItem(
            id: badgeId,
            emoji: badge['iconUrl'] ?? '🏅',
            name: badge['name'] ?? '',
            description: badge['description'] ?? '',
            isEarned: isEarned,
            rarity: badge['rarity'] ?? 'common',
            condition: badge['condition'] ?? {},
            category: badge['category'] ?? 'other',
            earnedDate: isEarned ? _getEarnedDate(badgeId) : null,
          );
        }).toList();

    // 희귀도 순서로 정렬 (common → rare → epic → legendary)
    badgeItems.sort((a, b) {
      final rarityOrder = {'common': 0, 'rare': 1, 'epic': 2, 'legendary': 3};

      final aOrder = rarityOrder[a.rarity] ?? 0;
      final bOrder = rarityOrder[b.rarity] ?? 0;

      return aOrder.compareTo(bOrder);
    });

    return badgeItems;
  }

  String? _getEarnedDate(String badgeId) {
    try {
      final earnedBadges = widget.userInfo?['earnedBadges'] ?? [];

      for (final badge in earnedBadges) {
        if (badge is Map<String, dynamic>) {
          final id = badge['_id'] ?? badge['id'] ?? badge['badgeId'];
          if (id?.toString() == badgeId) {
            return badge['earnedAt'] ?? badge['createdAt'] ?? '최근';
          }
        }
      }
      return '최근';
    } catch (e) {
      return '최근';
    }
  }

  Widget _buildStatsCard(int earnedCount, int totalCount) {
    final percentage =
        totalCount > 0 ? (earnedCount / totalCount * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3C4)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '총 획득 배지',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$earnedCount개',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A202C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '전체 $totalCount개 중 ($percentage%)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF8F9FA)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  blurRadius: 15,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFFFD54F).withOpacity(0.6),
                width: 3,
              ),
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 36)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeSection(String title, List<BadgeItem> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A202C),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            return _buildBadgeItem(context, badges[index]);
          },
        ),
      ],
    );
  }

  Widget _buildBadgeItem(BuildContext context, BadgeItem badge) {
    Color rarityColor = _getRarityColor(badge.rarity);

    return GestureDetector(
      onTap: () => _showBadgeDetail(context, badge),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient:
                  badge.isEarned
                      ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFF8F9FA)],
                      )
                      : const LinearGradient(
                        colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)],
                      ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(badge.isEarned ? 0.15 : 0.08),
                  blurRadius: badge.isEarned ? 12 : 6,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
              border: Border.all(
                color: badge.isEarned ? rarityColor : const Color(0xFFE5E7EB),
                width: badge.isEarned ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                badge.emoji,
                style: TextStyle(
                  fontSize: 28,
                  color: badge.isEarned ? null : Colors.grey[400],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              badge.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    badge.isEarned
                        ? const Color(0xFF1A202C)
                        : const Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'legendary':
        return Colors.purple;
      case 'epic':
        return Colors.deepPurple;
      case 'rare':
        return Colors.blue;
      case 'common':
      default:
        return const Color(0xFFFFD54F);
    }
  }

  void _showBadgeDetail(BuildContext context, BadgeItem badge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들바
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // 배지 이미지
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient:
                      badge.isEarned
                          ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Color(0xFFF8F9FA)],
                          )
                          : const LinearGradient(
                            colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)],
                          ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        badge.isEarned ? 0.15 : 0.08,
                      ),
                      blurRadius: badge.isEarned ? 20 : 10,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.9),
                      blurRadius: 15,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  border: Border.all(
                    color:
                        badge.isEarned
                            ? _getRarityColor(badge.rarity)
                            : const Color(0xFFE5E7EB),
                    width: badge.isEarned ? 3 : 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    badge.emoji,
                    style: TextStyle(
                      fontSize: 48,
                      color: badge.isEarned ? null : Colors.grey[400],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 배지 이름과 희귀도
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      badge.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color:
                            badge.isEarned
                                ? const Color(0xFF1A202C)
                                : const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getRarityColor(badge.rarity).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getRarityColor(badge.rarity).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      badge.rarity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getRarityColor(badge.rarity),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 배지 설명
              Text(
                badge.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 획득 조건
              if (badge.condition.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '획득 조건',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        badge.condition['description'] ?? '조건 없음',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 상태 표시
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      badge.isEarned
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        badge.isEarned
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFD1D5DB),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      badge.isEarned ? Icons.check_circle : Icons.lock,
                      size: 18,
                      color:
                          badge.isEarned
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      badge.isEarned ? '획득 완료' : '미획득',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            badge.isEarned
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if (badge.isEarned && badge.earnedDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  '획득일: ${badge.earnedDate}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class BadgeItem {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final bool isEarned;
  final String rarity;
  final Map<String, dynamic> condition;
  final String category;
  final String? earnedDate;

  BadgeItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.isEarned,
    required this.rarity,
    required this.condition,
    required this.category,
    this.earnedDate,
  });
}
