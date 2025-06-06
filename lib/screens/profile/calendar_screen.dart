import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:joinup/services/challenge/challenge_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  final ChallengeService _challengeService = ChallengeService();

  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallengeData();
  }

  Future<void> _loadChallengeData() async {
    try {
      final response = await _challengeService.getParticipatingChallenges();

      if (response['success']) {
        final challenges = List<Map<String, dynamic>>.from(
          response['data']['data']['challenges'] ?? [],
        );

        Map<DateTime, List<Map<String, dynamic>>> events = {};

        for (final challengeData in challenges) {
          final userChallenge = challengeData['userChallenge'];
          final challenge = challengeData['challenge'];
          final completedDates = List<String>.from(
            userChallenge['completedDates'] ?? [],
          );

          for (final dateStr in completedDates) {
            try {
              final date = DateTime.parse(dateStr);
              final dateKey = DateTime.utc(date.year, date.month, date.day);

              if (events[dateKey] == null) {
                events[dateKey] = [];
              }

              events[dateKey]!.add({
                'title': challenge['title'],
                'completedAt': dateStr,
                'category': challenge['category'],
              });
            } catch (e) {
              print('날짜 파싱 오류: $e');
            }
          }
        }

        setState(() {
          _events = events;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print('챌린지 데이터 로드 실패: ${response['message']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('챌린지 데이터 로드 에러: $e');
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'exercise':
        return Icons.fitness_center;
      case 'health':
        return Icons.favorite;
      case 'study':
        return Icons.book;
      case 'hobby':
        return Icons.palette;
      case 'lifestyle':
        return Icons.local_drink;
      case 'social':
        return Icons.people;
      default:
        return Icons.star;
    }
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '완료';
    }
  }

  Widget _buildDayCell(DateTime day, Color bgColor, Color textColor) {
    final events = _getEventsForDay(day);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          // 날짜 숫자
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              padding: const EdgeInsets.all(6),
              child: Text(
                '${day.day}',
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
          ),
          // 체크 아이콘
          if (events.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children:
                      events.take(3).map((event) {
                        return const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Colors.green,
                        );
                      }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MY 습관 캘린더',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  TableCalendar<Map<String, dynamic>>(
                    locale: 'ko_KR',
                    rowHeight: 80,
                    daysOfWeekHeight: 30,
                    firstDay: DateTime.utc(2025, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: DateTime.now(),
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    daysOfWeekVisible: true,
                    eventLoader: _getEventsForDay,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                      });
                    },
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarBuilders: CalendarBuilders<Map<String, dynamic>>(
                      defaultBuilder: (context, day, focusedDay) {
                        return _buildDayCell(
                          day,
                          Colors.transparent,
                          Colors.black,
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        return _buildDayCell(
                          day,
                          Colors.transparent,
                          Colors.black,
                        );
                      },
                      selectedBuilder: (context, day, focusedDay) {
                        return _buildDayCell(day, Colors.black, Colors.white);
                      },
                      markerBuilder: (context, day, events) {
                        return const SizedBox(); // <- 기본 마커 제거
                      },
                      outsideBuilder: (context, day, focusedDay) {
                        return _buildDayCell(
                          day,
                          Colors.transparent,
                          Colors.grey,
                        );
                      },
                      headerTitleBuilder:
                          (context, day) => Center(
                            child: Text(
                              // 월은 한자리 숫자일 때 0을 붙여서 두자리로 표시
                              '${day.year}.${day.month < 10 ? '0' : ''}${day.month} ',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      dowBuilder: (context, day) {
                        final text =
                            ['월', '화', '수', '목', '금', '토', '일'][day.weekday -
                                1];
                        return Center(
                          child: Text(
                            text,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color:
                                  day.weekday == DateTime.saturday
                                      ? Colors.indigo
                                      : day.weekday == DateTime.sunday
                                      ? Colors.red
                                      : Colors.grey[700],
                            ),
                          ),
                        );
                      },
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                      weekendStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      //패딩 없애기
                      headerPadding: EdgeInsets.zero,
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: Icon(Icons.chevron_left),
                      rightChevronIcon: Icon(Icons.chevron_right),
                    ),
                    calendarStyle: const CalendarStyle(
                      cellMargin: EdgeInsets.all(22),
                      markerSize: 5,
                      tableBorder: TableBorder(
                        horizontalInside: BorderSide(
                          color: Color(0xFFF2F2F2),
                          width: 1,
                        ),
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 20),
                            Text(
                              '${_selectedDay.month}.${_selectedDay.day}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${['(월)', '(화)', '(수)', '(목)', '(금)', '(토)', '(일)'][_selectedDay.weekday - 1]}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ..._getEventsForDay(_selectedDay).map((event) {
                          return Column(
                            spacing: 10,
                            children: [
                              ListTile(
                                leading: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(event['title']),
                                // trailing: Text(
                                //   _formatTime(event['completedAt']),
                                //   style: const TextStyle(
                                //     color: Colors.grey,
                                //     fontSize: 14,
                                //   ),
                                // ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Divider(
                                  height: 1,
                                  color: Color(0xFFF2F2F2),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        if (_getEventsForDay(_selectedDay).isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                '이 날에는 완료한 챌린지가 없습니다.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
