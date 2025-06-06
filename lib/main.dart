import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:joinup/screens/auth/auth_screen.dart';
import 'package:joinup/screens/challenge/challenge_screen.dart';
import 'package:joinup/screens/home/home_screen.dart';
import 'package:joinup/screens/home/tabs/tab_home.dart';
import 'package:joinup/screens/notifications/notifications_screen.dart';
import 'package:joinup/screens/profile/calendar_screen.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  KakaoSdk.init(nativeAppKey: '80106bc8e079ee4c0da6ef44feb63bd1');
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JOINUP',
      locale: const Locale('ko', 'KR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFFAF9F6),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAF9F6),
          scrolledUnderElevation: 0,
          elevation: 0,
        ),
      ),
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: NoScrollbarBehavior(),
          child: child!,
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthScreen(),
        '/home': (context) => HomeScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');

        // /challenge/:id 형태의 라우트 처리
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments[0] == 'challenge') {
          final challengeId = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (context) => ChallengeScreen(challengeId: challengeId),
            settings: settings,
          );
        }

        // 알 수 없는 라우트인 경우 홈으로 리다이렉트
        return MaterialPageRoute(builder: (context) => HomeScreen());
      },
    );
  }
}

class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
