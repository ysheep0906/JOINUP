import 'package:flutter/material.dart';

class ProfileCalendar extends StatelessWidget {
  final Map<String, dynamic>? userInfo;

  const ProfileCalendar({super.key, this.userInfo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // calendar screen으로 이동
        Navigator.pushNamed(context, '/calendar');
      },

      child: Container(
        // 습관 캘린더
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(128),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            Image.asset('assets/calendar.png'),
            const Text(
              'MY 습관 캘린더',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
