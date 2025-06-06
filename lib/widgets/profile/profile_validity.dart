import 'package:flutter/material.dart';

class ProfileValidity extends StatefulWidget {
  final Map<String, dynamic>? userInfo;

  const ProfileValidity({super.key, this.userInfo});

  @override
  State<ProfileValidity> createState() => _ProfileValidityState();
}

class _ProfileValidityState extends State<ProfileValidity> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;

  void _showTooltip() {
    final renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder:
          (context) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _hideTooltip();
              setState(() {});
            },
            child: Stack(
              children: [
                Positioned(
                  left: offset.dx,
                  top: offset.dy + size.height + 5,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: const Text(
                        '신뢰도는 사용자 활동, 평가 등 다양한 데이터를 기반으로 산출됩니다.',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  bool get _tooltipVisible => _overlayEntry != null;

  void _toggleTooltip() {
    if (_tooltipVisible) {
      _hideTooltip();
    } else {
      _showTooltip();
    }
    setState(() {});
  }

  // 신뢰도 배경 색상 결정 (컨테이너용)
  Color _getTrustBackgroundColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    if (score >= 50) return Colors.yellow[700]!;
    return Colors.red;
  }

  // 신뢰도 등급 텍스트
  String _getTrustGrade(int score) {
    if (score >= 90) return '매우 좋음';
    if (score >= 70) return '좋음';
    if (score >= 50) return '보통';
    return '낮음';
  }

  @override
  Widget build(BuildContext context) {
    // userInfo에서 신뢰도 점수 가져오기
    final trustScore = widget.userInfo?['trustScore'] ?? 0;
    final trustPercentage = trustScore / 100.0;
    final trustBackgroundColor = _getTrustBackgroundColor(trustScore);
    final trustGrade = _getTrustGrade(trustScore);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단: 신뢰도 제목과 등급 컨테이너
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  key: _key,
                  onTap: _toggleTooltip,
                  child: const Text(
                    '신뢰도',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.info_outline_rounded, size: 18),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: trustBackgroundColor.withOpacity(0.1), // 배경색만 등급에 따라
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: trustBackgroundColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                trustGrade,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: trustBackgroundColor, // 등급 텍스트는 배경색과 동일
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 하단: 프로그레스바와 점수
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: trustPercentage.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFE0E0E0),
                  color: Colors.black, // 프로그레스바는 검정색
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$trustScore점',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black, // 점수 텍스트는 검정색
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getLastUpdateText() {
    // userInfo에 lastUpdated가 있다면 사용, 없으면 기본값
    final lastUpdated = widget.userInfo?['lastUpdated'];
    if (lastUpdated != null) {
      // DateTime 파싱 및 포맷팅 로직
      return '오늘'; // 임시
    }
    return '오늘';
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }
}
