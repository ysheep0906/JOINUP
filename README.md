# JoinUP - 습관 형성 챌린지 커뮤니티 플랫폼

함께 성장하는 챌린지 플랫폼으로, 사용자들이 다양한 습관 형성 챌린지에 참여하고 서로 동기부여하며 성장할 수 있는 모바일 애플리케이션입니다.

## 📱 주요 기능

### 🔐 인증 시스템
- **소셜 로그인**: 카카오, 구글 계정으로 간편 로그인
- **프로필 설정**: 닉네임 설정 및 프로필 사진 업로드
- **프로필 편집**: 언제든지 프로필 정보 수정 가능

### 🏆 챌린지 시스템
- **챌린지 생성**: 카테고리별 맞춤 챌린지 생성 (운동, 독서, 생활습관 등)
- **챌린지 참여**: 다양한 챌린지 검색 및 참여
- **완료 인증**: 사진과 함께 일일 완료 보고
- **진행률 추적**: 개인별 달성률 및 연속 완료일 확인

### 💬 커뮤니티 기능
- **실시간 채팅**: 챌린지별 채팅방에서 참여자들과 소통
- **랭킹 시스템**: 주간/월간 랭킹으로 건전한 경쟁
- **신뢰도 시스템**: 꾸준한 참여로 신뢰도 점수 획득

### 🏅 배지 & 성취 시스템
- **배지 수집**: 다양한 조건 달성으로 배지 획득
- **대표 배지**: 최대 4개의 대표 배지 선택 및 순서 변경
- **프로필 칭호**: 첫 번째 배지가 프로필 칭호로 표시

### 📅 습관 추적
- **습관 캘린더**: 월별 달력으로 완료 현황 한눈에 확인
- **연속 달성**: 연속 완료일 기록 및 통계
- **완료율 분석**: 개인 성취도 분석

### 🔔 알림 시스템
- **실시간 알림**: 새로운 참여자, 메시지, 성취 알림
- **푸시 알림**: 챌린지 참여 독려 및 중요 정보 알림

## 🛠 기술 스택

- **Frontend**: Flutter (Dart)
- **State Management**: Provider Pattern
- **HTTP Client**: Dio
- **Image Handling**: Image Picker
- **Real-time Communication**: Socket.IO
- **Environment Variables**: flutter_dotenv
- **Authentication**: JWT Token

## 📂 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── providers/               # 상태 관리
├── screens/                 # 화면 위젯들
│   ├── auth/               # 인증 관련 화면
│   ├── badge/              # 배지 화면
│   ├── challenge/          # 챌린지 화면
│   ├── home/               # 홈 화면
│   └── profile/            # 프로필 화면
├── services/               # API 서비스
│   ├── auth/              # 인증 서비스
│   ├── badge/             # 배지 서비스
│   ├── challenge/         # 챌린지 서비스
│   └── socket/            # 소켓 통신
└── widgets/                # 재사용 가능한 위젯들
    ├── bottom_nav_bar.dart
    ├── challenge/
    ├── common/
    ├── community/
    ├── home/
    └── profile/
```

## 🚀 설치 및 실행

### 사전 요구사항
- Flutter SDK (3.0 이상)
- Dart SDK
- Android Studio / VS Code
- Android/iOS 개발 환경 설정

### 설치 방법

1. **저장소 클론**
```bash
git clone https://github.com/your-username/joinup.git
cd joinup
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **환경 변수 설정**
```bash
# .env 파일 생성 후 API URL 설정
API_URL=your_api_server_url
```

4. **앱 실행**
```bash
flutter run
```