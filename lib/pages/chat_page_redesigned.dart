import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'dart:async';

class ChatPageRedesigned extends StatefulWidget {
  final String sellerName;
  final String? sellerId;
  final String? sellerAvatar;
  final String? conversationId;

  const ChatPageRedesigned({
    super.key,
    required this.sellerName,
    this.sellerId,
    this.sellerAvatar,
    this.conversationId,
  });

  @override
  State<ChatPageRedesigned> createState() => _ChatPageRedesignedState();
}

class _ChatPageRedesignedState extends State<ChatPageRedesigned> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  Conversation? _conversation;
  bool _loading = true;
  bool _sending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    // Auto-refresh messages every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && _conversation != null) {
        _loadMessages(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => _loading = true);
    
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      Conversation? conversation;
      
      // If conversationId is provided, use it
      if (widget.conversationId != null) {
        conversation = await chatService.getConversation(widget.conversationId!);
      }
      // Otherwise, create new conversation
      else if (widget.sellerId != null) {
        conversation = await chatService.createConversation(widget.sellerId!);
      }
      
      if (conversation != null) {
        setState(() => _conversation = conversation);
        await _loadMessages();
        
        // Mark as read
        await chatService.markMessagesAsRead(conversation.conversationId);
      } else {
        throw Exception('Failed to initialize conversation');
      }
    } catch (e) {
      print('❌ Error initializing chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    if (_conversation == null) return;
    
    if (showLoading) {
      setState(() => _loading = true);
    }
    
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final messages = await chatService.getChatHistory(_conversation!.conversationId);
      
      setState(() {
        _messages = messages.reversed.toList(); // Reverse to show oldest first
      });
      
      // Auto-scroll to bottom
      if (_scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
      print('❌ Error loading messages: $e');
    } finally {
      if (showLoading) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _conversation == null || _sending) return;
    
    final messageText = _controller.text.trim();
    _controller.clear();
    
    setState(() => _sending = true);
    
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.sendMessage(_conversation!.conversationId, messageText);
      
      // Reload messages to get the sent message
      await _loadMessages(showLoading: false);
    } catch (e) {
      print('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Restore message in input
      _controller.text = messageText;
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tin nhắn'),
        content: const Text('Bạn có chắc muốn xóa tin nhắn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final success = await chatService.deleteMessage(messageId);
      
      if (success) {
        await _loadMessages(showLoading: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tin nhắn')),
          );
        }
      }
    } catch (e) {
      print('❌ Error deleting message: $e');
    }
  }

  void _startVideoCall() async {
    if (_conversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy cuộc trò chuyện')),
      );
      return;
    }
    
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      // Initiate video call via API (like frontend)
      print('📞 Initiating video call for conversation: ${_conversation!.conversationId}');
      final callResponse = await chatService.initiateVideoCall(_conversation!.conversationId);
      
      // Close loading
      if (mounted) Navigator.pop(context);
      
      if (callResponse == null || !callResponse.containsKey('callSessionId')) {
        throw Exception('Failed to initiate video call');
      }
      
      final callSessionId = callResponse['callSessionId']?.toString();
      
      if (callSessionId == null) {
        throw Exception('Invalid call session ID');
      }
      
      print('✅ Video call initiated: $callSessionId');
      
      // Navigate to video call page with call session ID
      // NOTE: Full Azure Communication Services integration requires:
      // 1. Install flutter_azure_communication_services package
      // 2. Use getCallJoinInfo() to get fresh token before joining
      // 3. Initialize Azure CallAgent and join the call
      // 4. Handle video streams (local/remote)
      // For now, this navigates to the UI but actual video requires Azure SDK
      if (mounted) {
        Navigator.pushNamed(context, '/video-call', arguments: {
          'conversationId': _conversation!.conversationId,
          'callSessionId': callSessionId,
          'name': widget.sellerName,
          'id': widget.sellerId,
        });
      }
    } catch (e) {
      // Close loading if still open
      if (mounted) Navigator.pop(context);
      
      print('❌ Error starting video call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể bắt đầu cuộc gọi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUserId = authService.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context, true), // Return true to trigger refresh
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _conversation?.isAdminConversation == true
                    ? Colors.blue.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _conversation?.isAdminConversation == true
                    ? Icon(Icons.support_agent, color: Colors.blue, size: 24)
                    : Text(
                        widget.sellerName[0].toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.sellerName,
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _conversation?.isAdminConversation == true 
                        ? 'Hỗ trợ khách hàng'
                        : 'Hoạt động',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_conversation?.videoCallEnabled == true)
            IconButton(
              icon: Icon(Icons.videocam, color: AppColors.primary),
              onPressed: _startVideoCall,
              tooltip: 'Gọi video',
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.foreground),
            onPressed: () => _loadMessages(),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                // Messages
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: AppColors.mutedForeground,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có tin nhắn',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Bắt đầu cuộc trò chuyện!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMe = message.sender?.userId == currentUserId;
                            final showTime = index == 0 || 
                                DateTime.parse(_messages[index].sentAt)
                                    .difference(DateTime.parse(_messages[index - 1].sentAt))
                                    .inMinutes > 5;
                            
                            return _buildMessageBubble(message, isMe, showTime);
                          },
                        ),
                ),
                
                // Input
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe, bool showTime) {
    final messageTime = DateTime.parse(message.sentAt);
    
    // Handle deleted messages
    if (message.isDeleted) {
      return Container(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        margin: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.muted.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 16, color: AppColors.mutedForeground),
              const SizedBox(width: 8),
              Text(
                'Tin nhắn đã bị xóa',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Handle system messages
    if (message.messageType == 'SYSTEM') {
      return Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (showTime)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTime(messageTime),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
        GestureDetector(
          onLongPress: isMe ? () => _showMessageOptions(message) : null,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: EdgeInsets.only(
              bottom: 8,
              left: isMe ? 48 : 0,
              right: isMe ? 0 : 48,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isMe
                  ? LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isMe ? null : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message content
                if (message.messageType == 'IMAGE' && message.mediaUrl != null)
                  _buildImageMessage(message.mediaUrl!)
                else
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.foreground,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                
                // Time and status
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(messageTime),
                      style: TextStyle(
                        color: isMe ? Colors.white.withOpacity(0.7) : AppColors.mutedForeground,
                        fontSize: 11,
                      ),
                    ),
                    if (message.editedAt != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(đã chỉnh sửa)',
                        style: TextStyle(
                          color: isMe ? Colors.white.withOpacity(0.6) : AppColors.mutedForeground,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message.isRead ? Colors.blue.shade200 : Colors.white.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageMessage(String mediaUrl) {
    // Parse mediaUrl - could be single URL or JSON array
    List<String> urls = [];
    try {
      if (mediaUrl.startsWith('[')) {
        // JSON array
        final dynamic parsed = Uri.decodeComponent(mediaUrl);
        // Simple parsing - in production use proper JSON parser
        urls = [mediaUrl]; // Fallback
      } else {
        urls = [mediaUrl];
      }
    } catch (e) {
      urls = [mediaUrl];
    }

    return Column(
      children: urls.map((url) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: AppColors.muted,
                  child: Icon(Icons.broken_image, color: AppColors.mutedForeground),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa tin nhắn'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message.messageId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Image button
            Container(
              decoration: BoxDecoration(
                color: AppColors.muted,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.image, color: AppColors.primary),
                onPressed: () {
                  // TODO: Implement image picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image upload coming soon!')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            
            // Text input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 15,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Send button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _sending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
