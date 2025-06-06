import 'package:flutter/material.dart';
import 'package:joinup/services/socket/socket_service.dart';
import 'package:joinup/services/auth/auth_service.dart';

class TabChallengeChat extends StatefulWidget {
  final String? challengeId;

  const TabChallengeChat({super.key, this.challengeId});

  @override
  State<TabChallengeChat> createState() => _TabChallengeChatState();
}

class _TabChallengeChatState extends State<TabChallengeChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SocketService _socketService = SocketService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> messages = [];
  Map<String, dynamic>? currentUser;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    if (widget.challengeId != null) {
      _socketService.leaveChallenge(widget.challengeId!);
    }
    _socketService.removeAllListeners();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (widget.challengeId == null) return;

    // 현재 사용자 정보 가져오기
    await _getCurrentUser();

    // 소켓 연결
    _socketService.connect();

    // 챌린지 방 참가
    _socketService.joinChallenge(widget.challengeId!);

    // 메시지 수신 리스너 등록
    _socketService.onMessageReceived((messageData) {
      setState(() {
        messages.add(messageData);
      });
      _scrollToBottom();
    });

    // 기존 메시지 로드
    await _loadMessages();
  }

  Future<void> _getCurrentUser() async {
    try {
      final response = await _authService.getCurrentUser().then(
        (response) => {
          setState(() {
            currentUser = response;
          }),
        },
      );
    } catch (e) {
      print('Error getting current user: $e');
    }
  }

  Future<void> _loadMessages() async {
    // TODO: 기존 메시지 로드 API 호출
    // 여기서는 임시로 빈 리스트로 시작
    setState(() {
      messages = [];
    });
  }

  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty ||
        currentUser == null ||
        widget.challengeId == null) {
      return;
    }

    _socketService.sendMessage(
      challengeId: widget.challengeId!,
      message: messageText,
      userId: currentUser!['_id'],
      userNickname: currentUser!['nickname'] ?? '익명',
      userProfileImage: currentUser!['profileImage'],
    );

    _messageController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 채팅 메시지 목록
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMe = message['userId'] == currentUser?['_id'];

              return _buildMessageBubble(message, isMe);
            },
          ),
        ),

        // 메시지 입력 영역
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  message['userProfileImage'] != null
                      ? NetworkImage(message['userProfileImage'])
                      : null,
              child:
                  message['userProfileImage'] == null
                      ? Text(
                        message['userNickname']
                                ?.substring(0, 1)
                                .toUpperCase() ??
                            '?',
                        style: const TextStyle(fontSize: 12),
                      )
                      : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message['userNickname'] ?? '익명',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message['message'] ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  currentUser?['profileImage'] != null
                      ? NetworkImage(currentUser!['profileImage'])
                      : null,
              child:
                  currentUser?['profileImage'] == null
                      ? Text(
                        currentUser?['nickname']
                                ?.substring(0, 1)
                                .toUpperCase() ??
                            '?',
                        style: const TextStyle(fontSize: 12),
                      )
                      : null,
            ),
          ],
        ],
      ),
    );
  }
}
