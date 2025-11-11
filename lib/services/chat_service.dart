import 'api_client.dart';

/// Chat Message Model
class ChatMessage {
  final String messageId;
  final String conversationId;
  final String content;
  final String messageType; // TEXT, IMAGE, SYSTEM, CALL_STARTED, etc.
  final String sentAt;
  final bool isRead;
  final String? readAt;
  final bool isDeleted;
  final String? editedAt;
  final String? mediaUrl;
  final ChatUser? sender;

  ChatMessage({
    required this.messageId,
    required this.conversationId,
    required this.content,
    required this.messageType,
    required this.sentAt,
    required this.isRead,
    this.readAt,
    required this.isDeleted,
    this.editedAt,
    this.mediaUrl,
    this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      messageType: json['messageType']?.toString() ?? 'TEXT',
      sentAt: json['sentAt']?.toString() ?? DateTime.now().toIso8601String(),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt']?.toString(),
      isDeleted: json['isDeleted'] ?? false,
      editedAt: json['editedAt']?.toString(),
      mediaUrl: json['mediaUrl']?.toString(),
      sender: json['sender'] != null ? ChatUser.fromJson(json['sender']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'conversationId': conversationId,
      'content': content,
      'messageType': messageType,
      'sentAt': sentAt,
      'isRead': isRead,
      'readAt': readAt,
      'isDeleted': isDeleted,
      'editedAt': editedAt,
      'mediaUrl': mediaUrl,
      'sender': sender?.toJson(),
    };
  }
}

/// Chat User Model (simplified user info for chat)
class ChatUser {
  final String userId;
  final String username;
  final String email;

  ChatUser({
    required this.userId,
    required this.username,
    required this.email,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
    };
  }
}

/// Conversation Model
class Conversation {
  final String conversationId;
  final String conversationName;
  final bool isActive;
  final bool isAdminConversation;
  final bool videoCallEnabled;
  final int totalMessageCount;
  final String lastActivity;
  final String createdAt;
  final bool isBlocked;
  final bool isBlockedByMe;
  final int unreadCount;
  final String? lastMessage;
  final ChatUser otherUser;

  Conversation({
    required this.conversationId,
    required this.conversationName,
    required this.isActive,
    required this.isAdminConversation,
    required this.videoCallEnabled,
    required this.totalMessageCount,
    required this.lastActivity,
    required this.createdAt,
    required this.isBlocked,
    required this.isBlockedByMe,
    required this.unreadCount,
    this.lastMessage,
    required this.otherUser,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversationId']?.toString() ?? '',
      conversationName: json['conversationName']?.toString() ?? '',
      isActive: json['isActive'] ?? true,
      isAdminConversation: json['isAdminConversation'] ?? false,
      videoCallEnabled: json['videoCallEnabled'] ?? false,
      totalMessageCount: json['totalMessageCount'] ?? 0,
      lastActivity: json['lastActivity']?.toString() ?? DateTime.now().toIso8601String(),
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      isBlocked: json['isBlocked'] ?? false,
      isBlockedByMe: json['isBlockedByMe'] ?? false,
      unreadCount: json['unreadCount'] ?? 0,
      lastMessage: json['lastMessage']?.toString(),
      otherUser: ChatUser.fromJson(json['otherUser'] ?? {}),
    );
  }
}

/// Chat Service - Handles all chat-related API calls
class ChatService {
  final ApiClient _api;

  ChatService(this._api);

  // ==================== Conversation Management ====================

  /// Get all conversations for the current user
  Future<List<Conversation>> getUserConversations() async {
    try {
      print('📱 ChatService: Getting user conversations...');
      final response = await _api.get('/api/chat/conversations');
      
      print('📱 ChatService: Raw response: $response');
      
      // Extract conversations from response
      final data = response is Map && response['data'] != null 
          ? response['data'] 
          : response;
      
      final conversations = data is Map && data['conversations'] != null
          ? data['conversations']
          : (data is List ? data : []);
      
      print('📱 ChatService: Found ${conversations.length} conversations');
      
      return (conversations as List)
          .map((conv) => Conversation.fromJson(conv))
          .toList();
    } catch (e) {
      print('❌ ChatService: Error getting conversations: $e');
      return [];
    }
  }

  /// Create or get existing conversation with another user
  Future<Conversation?> createConversation(String otherUserId, {bool isAdminConversation = false}) async {
    try {
      print('📱 ChatService: Creating conversation with user: $otherUserId');
      final response = await _api.post(
        '/api/chat/conversations',
        body: {
          'otherUserId': otherUserId,
          'isAdminConversation': isAdminConversation,
        },
      );
      
      final data = response is Map && response['data'] != null 
          ? response['data'] 
          : response;
      
      final conversationData = data is Map && data['conversation'] != null
          ? data['conversation']
          : data;
      
      print('✅ ChatService: Conversation created: ${conversationData['conversationId']}');
      
      return Conversation.fromJson(conversationData);
    } catch (e) {
      print('❌ ChatService: Error creating conversation: $e');
      return null;
    }
  }

  /// Get conversation by ID
  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final response = await _api.get('/api/chat/conversations/$conversationId');
      
      final data = response is Map && response['data'] != null 
          ? response['data'] 
          : response;
      
      final conversationData = data is Map && data['conversation'] != null
          ? data['conversation']
          : data;
      
      return Conversation.fromJson(conversationData);
    } catch (e) {
      print('❌ ChatService: Error getting conversation: $e');
      return null;
    }
  }

  // ==================== Message Management ====================

  /// Get chat history (messages) for a conversation
  Future<List<ChatMessage>> getChatHistory(String conversationId, {int page = 0, int size = 50}) async {
    try {
      print('📱 ChatService: Getting messages for conversation: $conversationId');
      final response = await _api.get(
        '/api/chat/conversations/$conversationId/messages?page=$page&size=$size',
      );
      
      final data = response is Map && response['data'] != null 
          ? response['data'] 
          : response;
      
      final messages = data is Map && data['messages'] != null
          ? data['messages']
          : (data is List ? data : []);
      
      print('📱 ChatService: Found ${messages.length} messages');
      
      return (messages as List)
          .map((msg) => ChatMessage.fromJson(msg))
          .toList();
    } catch (e) {
      print('❌ ChatService: Error getting messages: $e');
      return [];
    }
  }

  /// Send a text message
  Future<ChatMessage?> sendMessage(String conversationId, String content, {String messageType = 'TEXT'}) async {
    try {
      print('📱 ChatService: Sending message to conversation: $conversationId');
      final response = await _api.post(
        '/api/chat/conversations/$conversationId/messages',
        body: {
          'content': content,
          'messageType': messageType,
        },
      );
      
      final data = response is Map && response['data'] != null 
          ? response['data'] 
          : response;
      
      final messageData = data is Map && data['message'] != null
          ? data['message']
          : data;
      
      print('✅ ChatService: Message sent successfully');
      
      return ChatMessage.fromJson(messageData);
    } catch (e) {
      print('❌ ChatService: Error sending message: $e');
      rethrow;
    }
  }

  /// Send an image message (single image)
  Future<ChatMessage?> sendImageMessage(String conversationId, String imagePath) async {
    try {
      print('📱 ChatService: Sending image to conversation: $conversationId');
      
      // In real implementation, upload to your storage (Cloudinary, S3, etc.)
      // For now, send a placeholder
      final response = await _api.post(
        '/api/chat/conversations/$conversationId/messages/image',
        body: {
          'imagePath': imagePath,
        },
      );
      
      final data = response is Map && response['data'] != null 
          ? response['data'] 
          : response;
      
      final messageData = data is Map && data['message'] != null
          ? data['message']
          : data;
      
      return ChatMessage.fromJson(messageData);
    } catch (e) {
      print('❌ ChatService: Error sending image: $e');
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      await _api.post('/api/chat/conversations/$conversationId/read');
      print('✅ ChatService: Messages marked as read');
    } catch (e) {
      print('❌ ChatService: Error marking messages as read: $e');
    }
  }

  /// Delete a message
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _api.delete('/api/chat/messages/$messageId');
      print('✅ ChatService: Message deleted');
      return true;
    } catch (e) {
      print('❌ ChatService: Error deleting message: $e');
      return false;
    }
  }

  /// Edit a message
  Future<bool> editMessage(String messageId, String newContent) async {
    try {
      await _api.put(
        '/api/chat/messages/$messageId',
        body: {'content': newContent},
      );
      print('✅ ChatService: Message edited');
      return true;
    } catch (e) {
      print('❌ ChatService: Error editing message: $e');
      return false;
    }
  }

  /// Get unread message count for a conversation
  Future<int> getUnreadCount(String conversationId) async {
    try {
      final response = await _api.get('/api/chat/conversations/$conversationId/unread-count');
      
      final data = response is Map && response['data'] != null 
          ? response['data'] 
          : response;
      
      final count = data is Map && data['unreadCount'] != null
          ? data['unreadCount']
          : (data is int ? data : 0);
      
      return count;
    } catch (e) {
      print('❌ ChatService: Error getting unread count: $e');
      return 0;
    }
  }

  // ==================== Block/Unblock ====================

  /// Block a user in a conversation
  Future<bool> blockUser(String conversationId) async {
    try {
      await _api.post('/api/chat/conversations/$conversationId/block');
      print('✅ ChatService: User blocked');
      return true;
    } catch (e) {
      print('❌ ChatService: Error blocking user: $e');
      return false;
    }
  }

  /// Unblock a user in a conversation
  Future<bool> unblockUser(String conversationId) async {
    try {
      await _api.post('/api/chat/conversations/$conversationId/unblock');
      print('✅ ChatService: User unblocked');
      return true;
    } catch (e) {
      print('❌ ChatService: Error unblocking user: $e');
      return false;
    }
  }

  // ==================== Video Call Management ====================

  /// Initiate a video call
  Future<Map<String, dynamic>?> initiateVideoCall(String conversationId) async {
    try {
      print('📱 ChatService: Initiating video call for conversation: $conversationId');
      final response = await _api.post(
        '/api/azure-communication/calls/initiate',
        body: {'conversationId': conversationId},
      );
      
      final data = response is Map && response['data'] != null 
          ? response['data'] 
          : response;
      
      print('✅ ChatService: Video call initiated: ${data['callSessionId']}');
      
      return data;
    } catch (e) {
      print('❌ ChatService: Error initiating video call: $e');
      rethrow;
    }
  }

  /// Accept a video call
  Future<Map<String, dynamic>?> acceptVideoCall(String callId) async {
    try {
      print('📱 ChatService: Accepting video call: $callId');
      final response = await _api.post('/api/azure-communication/calls/$callId/answer');
      
      final data = response is Map && response['data'] != null 
          ? response['data'] 
          : response;
      
      print('✅ ChatService: Video call accepted');
      
      return data;
    } catch (e) {
      print('❌ ChatService: Error accepting video call: $e');
      rethrow;
    }
  }

  /// Decline a video call
  Future<bool> declineVideoCall(String callId, {String reason = 'User declined'}) async {
    try {
      print('📱 ChatService: Declining video call: $callId');
      await _api.post(
        '/api/azure-communication/calls/$callId/decline',
        body: {'reason': reason},
      );
      print('✅ ChatService: Video call declined');
      return true;
    } catch (e) {
      print('❌ ChatService: Error declining video call: $e');
      return false;
    }
  }

  /// End a video call
  Future<bool> endVideoCall(String callId, {String reason = 'User ended call'}) async {
    try {
      print('📱 ChatService: Ending video call: $callId');
      await _api.post(
        '/api/azure-communication/calls/$callId/end',
        body: {'reason': reason},
      );
      print('✅ ChatService: Video call ended');
      return true;
    } catch (e) {
      print('❌ ChatService: Error ending video call: $e');
      return false;
    }
  }

  /// Get call history for a conversation
  Future<List<Map<String, dynamic>>> getCallHistory(String conversationId) async {
    try {
      final response = await _api.get('/api/azure-communication/calls/conversation/$conversationId');
      
      final data = response is Map && response['data'] != null 
          ? response['data'] 
          : response;
      
      final calls = data is Map && data['calls'] != null
          ? data['calls']
          : (data is List ? data : []);
      
      return List<Map<String, dynamic>>.from(calls);
    } catch (e) {
      print('❌ ChatService: Error getting call history: $e');
      return [];
    }
  }

  /// Get call join info (token and session details) - CRITICAL for joining video calls
  /// This method is called before joining a call to get fresh Azure token
  /// Frontend uses this in VideoCallModal.initializeCall()
  Future<Map<String, dynamic>?> getCallJoinInfo(String callSessionId) async {
    try {
      print('📱 ChatService: Getting call join info for session: $callSessionId');
      final response = await _api.get('/api/azure-communication/calls/$callSessionId/join-info');
      
      final data = response is Map && response['data'] != null 
          ? response['data'] 
          : response;
      
      print('✅ ChatService: Got call join info');
      print('📱 ChatService: Token available: ${data is Map && data['token'] != null}');
      print('📱 ChatService: CallSessionId: ${data is Map ? data['callSessionId'] : 'N/A'}');
      
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      print('❌ ChatService: Error getting call join info: $e');
      rethrow;
    }
  }
}

