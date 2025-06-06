import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void connect() {
    if (_socket != null && _isConnected) return;

    final serverUrl = dotenv.env['SOCKET_URL'] ?? 'ws://localhost:8080';

    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('소켓 연결됨');
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      print('소켓 연결 해제됨');
      _isConnected = false;
    });

    _socket!.onError((error) {
      print('소켓 에러: $error');
    });
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
    }
  }

  // 챌린지 방 참가
  void joinChallenge(String challengeId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join_challenge', challengeId);
      print('챌린지 방 참가: $challengeId');
    }
  }

  // 챌린지 방 떠나기
  void leaveChallenge(String challengeId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave_challenge', challengeId);
      print('챌린지 방 떠나기: $challengeId');
    }
  }

  // 메시지 전송
  void sendMessage({
    required String challengeId,
    required String message,
    required String userId,
    required String userNickname,
    String? userProfileImage,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('send_message', {
        'challengeId': challengeId,
        'message': message,
        'userId': userId,
        'userNickname': userNickname,
        'userProfileImage': userProfileImage,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  // 메시지 수신 리스너 등록
  void onMessageReceived(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('receive_message', (data) {
        callback(Map<String, dynamic>.from(data));
      });
    }
  }

  // 리스너 제거
  void removeAllListeners() {
    if (_socket != null) {
      _socket!.clearListeners();
    }
  }
}
