import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/users_service.dart';
import '../theme/app_colors.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<Conversation> _conversations = [];
  Conversation? _selectedConversation;
  List<ChatMessage> _messages = [];
  
  bool _loading = true;
  bool _sending = false;
  bool _loadingOlderMessages = false;
  bool _hasMoreMessages = true;
  int _currentPage = 0;
  
  // UI states
  bool _showSearchModal = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  bool _creatingConversation = false;
  
  // Image states
  List<File> _selectedImages = [];
  bool _showImagePreview = false;
  
  // Edit message states
  String? _editingMessageId;
  String _editContent = '';
  
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    // Auto-refresh conversations every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadConversations(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    
    try {
      final chatService = context.read<ChatService>();
      final conversations = await chatService.getUserConversations();
      
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading conversations: $e');
      if (mounted && showLoading) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_selectedConversation == null) return;
    
    try {
      final chatService = context.read<ChatService>();
      final messages = await chatService.getChatHistory(
        _selectedConversation!.conversationId,
        page: 0,
        size: 50,
      );
      
      setState(() {
        _messages = messages.reversed.toList();
        _currentPage = 0;
        _hasMoreMessages = messages.length == 50;
      });
      
      // Mark as read
      await chatService.markMessagesAsRead(_selectedConversation!.conversationId);
      
      // Update conversation list to clear unread
      setState(() {
        _conversations = _conversations.map((conv) {
          if (conv.conversationId == _selectedConversation!.conversationId) {
            return Conversation(
              conversationId: conv.conversationId,
              conversationName: conv.conversationName,
              isActive: conv.isActive,
              isAdminConversation: conv.isAdminConversation,
              videoCallEnabled: conv.videoCallEnabled,
              totalMessageCount: conv.totalMessageCount,
              lastActivity: conv.lastActivity,
              createdAt: conv.createdAt,
              isBlocked: conv.isBlocked,
              isBlockedByMe: conv.isBlockedByMe,
              unreadCount: 0,
              lastMessage: conv.lastMessage,
              otherUser: conv.otherUser,
            );
          }
          return conv;
        }).toList();
      });
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('❌ Error loading messages: $e');
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_selectedConversation == null || _loadingOlderMessages || !_hasMoreMessages) return;
    
    try {
      setState(() => _loadingOlderMessages = true);
      final nextPage = _currentPage + 1;
      final chatService = context.read<ChatService>();
      
      final olderMessages = await chatService.getChatHistory(
        _selectedConversation!.conversationId,
        page: nextPage,
        size: 50,
      );
      
      if (olderMessages.isEmpty) {
        setState(() => _hasMoreMessages = false);
        return;
      }
      
      final oldScrollHeight = _scrollController.hasClients 
          ? _scrollController.position.maxScrollExtent 
          : 0;
      
      setState(() {
        _messages = [...olderMessages.reversed.toList(), ..._messages];
        _currentPage = nextPage;
        _hasMoreMessages = olderMessages.length == 50;
      });
      
      // Restore scroll position
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final newScrollHeight = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(newScrollHeight - oldScrollHeight);
        }
      });
    } catch (e) {
      print('❌ Error loading older messages: $e');
    } finally {
      setState(() => _loadingOlderMessages = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSendMessage() async {
    if (_selectedConversation == null || _messageController.text.trim().isEmpty || _sending) return;
    
    try {
      setState(() => _sending = true);
      final chatService = context.read<ChatService>();
      
      await chatService.sendMessage(
        _selectedConversation!.conversationId,
        _messageController.text.trim(),
      );
      
      _messageController.clear();
      
      // Reload messages to get the new one
      await _loadMessages();
    } catch (e) {
      print('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _handleImageSelect() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage();
      if (images == null || images.isEmpty) return;
      
      // Limit to 8 images
      final selected = images.take(8).map<File>((xFile) => File(xFile.path)).toList();
      
      setState(() {
        _selectedImages = selected;
        _showImagePreview = true;
      });
    } catch (e) {
      print('❌ Error selecting images: $e');
    }
  }

  Future<void> _handleSendImages() async {
    if (_selectedConversation == null || _selectedImages.isEmpty) return;
    
    try {
      setState(() {
        _sending = true;
        _showImagePreview = false;
      });
      
      final chatService = context.read<ChatService>();
      
      // Send images one by one (or implement batch upload)
      for (final imageFile in _selectedImages) {
        await chatService.sendImageMessage(
          _selectedConversation!.conversationId,
          imageFile.path,
        );
      }
      
      setState(() => _selectedImages = []);
      
      // Reload messages
      await _loadMessages();
    } catch (e) {
      print('❌ Error sending images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send images: $e')),
        );
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _handleDeleteMessage(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructive),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final chatService = context.read<ChatService>();
      await chatService.deleteMessage(messageId);
      
      setState(() {
        _messages = _messages.map((msg) {
          if (msg.messageId == messageId) {
            return ChatMessage(
              messageId: msg.messageId,
              conversationId: msg.conversationId,
              content: msg.content,
              messageType: msg.messageType,
              sentAt: msg.sentAt,
              isRead: msg.isRead,
              readAt: msg.readAt,
              isDeleted: true,
              editedAt: msg.editedAt,
              mediaUrl: msg.mediaUrl,
              sender: msg.sender,
            );
          }
          return msg;
        }).toList();
      });
    } catch (e) {
      print('❌ Error deleting message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete message: $e')),
        );
      }
    }
  }

  Future<void> _handleEditMessage(String messageId) async {
    if (_editContent.trim().isEmpty) return;
    
    try {
      final chatService = context.read<ChatService>();
      await chatService.editMessage(messageId, _editContent.trim());
      
      setState(() {
        _messages = _messages.map((msg) {
          if (msg.messageId == messageId) {
            return ChatMessage(
              messageId: msg.messageId,
              conversationId: msg.conversationId,
              content: _editContent.trim(),
              messageType: msg.messageType,
              sentAt: msg.sentAt,
              isRead: msg.isRead,
              readAt: msg.readAt,
              isDeleted: msg.isDeleted,
              editedAt: DateTime.now().toIso8601String(),
              mediaUrl: msg.mediaUrl,
              sender: msg.sender,
            );
          }
          return msg;
        }).toList();
        _editingMessageId = null;
        _editContent = '';
      });
    } catch (e) {
      print('❌ Error editing message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to edit message: $e')),
        );
      }
    }
  }

  bool _canEditMessage(String sentAt) {
    final diff = DateTime.now().difference(DateTime.parse(sentAt));
    return diff.inMinutes < 2; // 2 minutes
  }

  Future<void> _searchUsers() async {
    if (_searchQuery.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    try {
      setState(() => _searching = true);
      final api = context.read<ApiClient>();
      
      // Search users by email or username
      final response = await api.get('/api/users/search', query: {
        'query': _searchQuery.trim(),
      });
      
      List<dynamic> users = [];
      if (response is Map && response['data'] != null) {
        final data = response['data'];
        if (data is Map && data['content'] != null) {
          users = data['content'] as List;
        } else if (data is List) {
          users = data;
        }
      } else if (response is List) {
        users = response;
      }
      
      final auth = context.read<AuthService>();
      final currentUserId = auth.currentUser?.id;
      
      setState(() {
        _searchResults = users
            .where((u) => u['userId']?.toString() != currentUserId)
            .map<Map<String, dynamic>>((u) {
              final name = u['name']?.toString() ?? '';
              final nameParts = name.split(' ');
              return {
                'userId': u['userId']?.toString() ?? '',
                'username': u['username']?.toString() ?? name,
                'email': u['email']?.toString() ?? '',
                'firstName': u['firstName']?.toString() ?? (nameParts.isNotEmpty ? nameParts.first : ''),
                'lastName': u['lastName']?.toString() ?? (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : ''),
              };
            })
            .toList();
      });
    } catch (e) {
      print('❌ Error searching users: $e');
      setState(() => _searchResults = []);
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _createConversation(String otherUserId) async {
    try {
      setState(() => _creatingConversation = true);
      final chatService = context.read<ChatService>();
      
      final conversation = await chatService.createConversation(otherUserId);
      
      if (conversation != null) {
        setState(() {
          final exists = _conversations.any((c) => c.conversationId == conversation.conversationId);
          if (!exists) {
            _conversations = [conversation, ..._conversations];
          }
          _selectedConversation = conversation;
          _showSearchModal = false;
          _searchQuery = '';
          _searchResults = [];
        });
        
        await _loadMessages();
      }
    } catch (e) {
      print('❌ Error creating conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create conversation: $e')),
        );
      }
    } finally {
      setState(() => _creatingConversation = false);
    }
  }

  Future<void> _createAdminConversation() async {
    try {
      setState(() => _creatingConversation = true);
      final auth = context.read<AuthService>();
      final chatService = context.read<ChatService>();
      
      if (auth.currentUser == null) return;
      
      final conversation = await chatService.createConversation(
        auth.currentUser!.id,
        isAdminConversation: true,
      );
      
      if (conversation != null) {
        setState(() {
          final exists = _conversations.any((c) => c.conversationId == conversation.conversationId);
          if (!exists) {
            _conversations = [conversation, ..._conversations];
          }
          _selectedConversation = conversation;
        });
        
        await _loadMessages();
      }
    } catch (e) {
      print('❌ Error creating admin conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to contact admin: $e')),
        );
      }
    } finally {
      setState(() => _creatingConversation = false);
    }
  }

  List<String> _parseMediaUrls(String? mediaUrl) {
    if (mediaUrl == null) return [];
    try {
      if (mediaUrl.startsWith('[')) {
        return List<String>.from(mediaUrl.replaceAll('[', '').replaceAll(']', '').split(',').map((s) => s.trim().replaceAll('"', '')));
      }
      return [mediaUrl];
    } catch (e) {
      return [mediaUrl];
    }
  }

  String? _formatCallMessage(ChatMessage msg) {
    if (msg.messageType != 'SYSTEM') return null;
    
    final content = msg.content.toLowerCase();
    final username = msg.sender?.username ?? 'User';
    final auth = context.read<AuthService>();
    final isOwnMessage = msg.sender?.userId == auth.currentUser?.id;
    final you = isOwnMessage ? 'You' : username;
    
    if (content.contains('initiated a video call')) {
      return '$you started a call';
    }
    if (content.contains('joined the video call')) {
      return '$you joined';
    }
    if (content.contains('video call ended')) {
      final match = RegExp(r'duration:\s*(\d+:\d+)', caseSensitive: false).firstMatch(content);
      if (match != null) {
        return 'Call ended • ${match.group(1)}';
      }
      return 'Call ended';
    }
    if (content.contains('declined the video call')) {
      return '$you declined';
    }
    
    return msg.content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading sustainable conversations...',
                    style: TextStyle(color: AppColors.mutedForeground),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Hero Section - Match React FE
                _buildHeroSection(),
                // Chat Container - Match React FE
                Expanded(
                  child: _buildChatContainer(),
                ),
              ],
            ),
      // Modals - Show only one at a time
      bottomSheet: _showImagePreview
          ? _buildImagePreviewModal()
          : (_showSearchModal ? _buildUserSearchModal() : null),
    );
  }

  // Hero Section - Match React FE
  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            Colors.transparent,
            AppColors.primary.withOpacity(0.05),
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 768;
            
            if (isWide) {
              // Desktop/Tablet: Side-by-side layout
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title - Match React FE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.message, size: 40, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Green Loop Conversations',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.foreground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect with the sustainable fashion community',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  // Buttons - Match React FE
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _showSearchModal = true),
                        icon: const Icon(Icons.person_add, size: 20),
                        label: const Text('New Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _createAdminConversation,
                        icon: const Icon(Icons.headset_mic, size: 20),
                        label: const Text('Contact Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Mobile: Stacked layout
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.message, size: 32, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Green Loop Conversations',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect with the sustainable fashion community',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _showSearchModal = true),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('New Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _createAdminConversation,
                          icon: const Icon(Icons.headset_mic, size: 18),
                          label: const Text('Staff'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  // Chat Container - Match React FE: Grid layout
  Widget _buildChatContainer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 768;
          
          if (isWide) {
            // Desktop/Tablet: Side-by-side layout - Match React FE: md:grid-cols-3
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Conversation List - Match React FE: md:col-span-1
                SizedBox(
                  width: constraints.maxWidth * 0.33,
                  child: _buildConversationList(),
                ),
                const SizedBox(width: 24),
                // Chat Window - Match React FE: md:col-span-2
                Expanded(
                  child: _buildChatWindow(),
                ),
              ],
            );
          } else {
            // Mobile: Show conversation list or chat window
            if (_selectedConversation == null) {
              return _buildConversationList();
            } else {
              return Stack(
                children: [
                  _buildChatWindow(),
                  // Back button for mobile
                  Positioned(
                    top: 8,
                    left: 8,
                    child: SafeArea(
                      child: Material(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedConversation = null;
                              _messages = [];
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.arrow_back, color: AppColors.foreground),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          }
        },
      ),
    );
  }

  // Conversation List - Match React FE
  Widget _buildConversationList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header - Match React FE: bg-primary text-primary-foreground
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.people, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Conversations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Conversations List - Match React FE
          Expanded(
            child: _conversations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.message_outlined,
                            size: 64,
                            color: AppColors.mutedForeground.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No conversations yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start chatting with community members!',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conv = _conversations[index];
                      return _buildConversationItem(conv);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Conversation Item - Match React FE
  Widget _buildConversationItem(Conversation conv) {
    final unreadCount = conv.unreadCount;
    final lastMessage = conv.lastMessage ?? '';
    final lastActivity = conv.lastActivity.isNotEmpty
        ? _formatTime(DateTime.parse(conv.lastActivity))
        : '';
    final isSelected = _selectedConversation?.conversationId == conv.conversationId;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedConversation = conv;
          _messages = [];
        });
        _loadMessages();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: AppColors.border),
            left: isSelected ? BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            // Avatar - Match React FE
            conv.isAdminConversation
                ? Icon(Icons.headset_mic, size: 32, color: AppColors.primary)
                : Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        conv.otherUser.username.isNotEmpty
                            ? conv.otherUser.username[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(width: 12),
            // Conversation Info - Match React FE: flex-1 min-w-0
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv.isAdminConversation ? 'Admin Support' : conv.otherUser.username,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastActivity.isNotEmpty)
                        Text(
                          lastActivity,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          unreadCount > 0
                              ? '$unreadCount new message${unreadCount > 1 ? 's' : ''}'
                              : (lastMessage.isNotEmpty ? lastMessage : 'No messages yet'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                            color: unreadCount > 0 ? AppColors.foreground : AppColors.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Chat Window - Match React FE
  Widget _buildChatWindow() {
    if (_selectedConversation == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco, size: 96, color: AppColors.mutedForeground.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(
                'Select a conversation to start chatting',
                style: TextStyle(
                  fontSize: 20,
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect with the sustainable fashion community',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Chat Header - Match React FE: bg-primary text-primary-foreground
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedConversation!.isAdminConversation
                            ? 'Admin Support'
                            : _selectedConversation!.otherUser.username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedConversation!.isAdminConversation
                            ? 'Get help with your sustainable fashion journey'
                            : _selectedConversation!.otherUser.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Video Call Button - Match React FE
                if (!_selectedConversation!.isAdminConversation && _selectedConversation!.videoCallEnabled)
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement video call
                    },
                    icon: const Icon(Icons.videocam, size: 20),
                    label: const Text('Video Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          ),
          // Messages Area - Match React FE
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background,
                    AppColors.muted.withOpacity(0.2),
                  ],
                ),
              ),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    if (_scrollController.position.pixels == 0 && _hasMoreMessages) {
                      _loadOlderMessages();
                    }
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  padding: const EdgeInsets.all(16),
                  itemCount: _groupedMessages().length + (_loadingOlderMessages ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0 && _loadingOlderMessages) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    final itemIndex = _loadingOlderMessages ? index - 1 : index;
                    final item = _groupedMessages()[itemIndex];
                    
                    if (item['type'] == 'date') {
                      return _buildDateSeparator(item['date'] as String);
                    }
                    
                    return _buildMessageBubble(item['message'] as ChatMessage);
                  },
                ),
              ),
            ),
          ),
          // Message Input - Match React FE
          _buildMessageInput(),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _groupedMessages() {
    final grouped = <Map<String, dynamic>>[];
    String? currentDate;
    
    for (final msg in _messages) {
      final msgDate = _formatDate(DateTime.parse(msg.sentAt));
      if (msgDate != currentDate) {
        grouped.add({'type': 'date', 'date': msgDate});
        currentDate = msgDate;
      }
      grouped.add({'type': 'message', 'message': msg});
    }
    
    return grouped;
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildDateSeparator(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            date,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final auth = context.read<AuthService>();
    final isOwnMessage = msg.sender?.userId == auth.currentUser?.id;
    final isEditing = _editingMessageId == msg.messageId;
    final canEdit = isOwnMessage && _canEditMessage(msg.sentAt) && msg.messageType == 'TEXT';
    final callFormatted = _formatCallMessage(msg);
    
    // Deleted message
    if (msg.isDeleted) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.muted.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              ),
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 16, color: AppColors.mutedForeground),
                  const SizedBox(width: 8),
                  Text(
                    'Message deleted',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // System/Call message
    if (msg.messageType == 'SYSTEM' && callFormatted != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam, size: 16, color: AppColors.mutedForeground),
                const SizedBox(width: 8),
                Text(
                  callFormatted,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(DateTime.parse(msg.sentAt)),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isOwnMessage) const SizedBox(width: 8),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isOwnMessage) const SizedBox(width: 8),
                // Message Bubble
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOwnMessage ? AppColors.primary : AppColors.muted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isEditing
                      ? _buildEditMessageInput(msg)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Gallery
                            if (msg.messageType == 'IMAGE' && msg.mediaUrl != null)
                              _buildImageGallery(msg.mediaUrl!),
                            // Text Content
                            if (msg.messageType == 'TEXT')
                              Text(
                                msg.content,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isOwnMessage ? Colors.white : AppColors.foreground,
                                ),
                              ),
                            const SizedBox(height: 4),
                            // Timestamp and Status
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(DateTime.parse(msg.sentAt)),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOwnMessage
                                        ? Colors.white.withOpacity(0.7)
                                        : AppColors.mutedForeground,
                                  ),
                                ),
                                if (msg.editedAt != null) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    'Edited',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: isOwnMessage
                                          ? Colors.white.withOpacity(0.6)
                                          : AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                                if (isOwnMessage && msg.messageType != 'SYSTEM') ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    msg.isRead ? Icons.done_all : Icons.done,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                ),
                // Action Buttons - Match React FE
                if (isOwnMessage && !isEditing && msg.messageType != 'SYSTEM')
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canEdit)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () {
                            setState(() {
                              _editingMessageId = msg.messageId;
                              _editContent = msg.content;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
                        onPressed: () => _handleDeleteMessage(msg.messageId),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                if (isOwnMessage) const SizedBox(width: 8),
              ],
            ),
          ),
          if (isOwnMessage) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildEditMessageInput(ChatMessage msg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: TextEditingController(text: _editContent),
          onChanged: (value) => setState(() => _editContent = value),
          style: TextStyle(color: AppColors.foreground),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _handleEditMessage(msg.messageId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text('Save', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _editingMessageId = null;
                  _editContent = '';
                });
              },
              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageGallery(String mediaUrl) {
    final urls = _parseMediaUrls(mediaUrl);
    if (urls.isEmpty) return const SizedBox();
    
    final crossAxisCount = urls.length == 1
        ? 1
        : urls.length == 2
            ? 2
            : urls.length <= 4
                ? 2
                : 3;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: urls.length > 9 ? 9 : urls.length,
      itemBuilder: (context, index) {
        if (index == 8 && urls.length > 9) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.network(urls[index], fit: BoxFit.cover),
              Container(
                color: Colors.black54,
                child: Center(
                  child: Text(
                    '+${urls.length - 9}',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        }
        return GestureDetector(
          onTap: () {
            // TODO: Open image lightbox
          },
          child: Image.network(
            urls[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(Icons.image, color: AppColors.mutedForeground),
          ),
        );
      },
    );
  }

  // Message Input - Match React FE
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Image Upload Button - Match React FE
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleImageSelect,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image, size: 20, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Text Input - Match React FE
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          // Send Button - Match React FE
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _sending || _messageController.text.trim().isEmpty
                  ? null
                  : _handleSendMessage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: _sending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.send, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Image Preview Modal - Match React FE
  Widget? _buildImagePreviewModal() {
    if (!_showImagePreview || _selectedImages.isEmpty) return null;
    
    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Send ${_selectedImages.length} image${_selectedImages.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showImagePreview = false;
                    _selectedImages = [];
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_selectedImages[index], fit: BoxFit.cover),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                            if (_selectedImages.isEmpty) {
                              _showImagePreview = false;
                            }
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showImagePreview = false;
                      _selectedImages = [];
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _sending ? null : _handleSendImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send, size: 16),
                            const SizedBox(width: 4),
                            Text('Send ${_selectedImages.length}'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // User Search Modal - Match React FE
  Widget? _buildUserSearchModal() {
    if (!_showSearchModal) return null;
    
    return Container(
      height: 600,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.person_add, size: 24, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Start New Conversation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showSearchModal = false;
                    _searchQuery = '';
                    _searchResults = [];
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Input - Match React FE
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    if (value.trim().isNotEmpty) {
                      _searchUsers();
                    } else {
                      setState(() => _searchResults = []);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by email or username...',
                    prefixIcon: Icon(Icons.search, color: AppColors.mutedForeground),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Results - Match React FE
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty && _searchQuery.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 64, color: AppColors.mutedForeground.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'Search for users to start chatting',
                              style: TextStyle(color: AppColors.mutedForeground),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter an email or username above',
                              style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people, size: 64, color: AppColors.mutedForeground.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  'No users found matching "$_searchQuery"',
                                  style: TextStyle(color: AppColors.mutedForeground),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    (user['firstName'] as String? ?? user['username'] as String? ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  '${user['firstName']} ${user['lastName']}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('@${user['username'] ?? user['email']}'),
                                    Text(user['email'] ?? ''),
                                  ],
                                ),
                                trailing: Icon(Icons.message, color: AppColors.primary),
                                onTap: _creatingConversation
                                    ? null
                                    : () => _createConversation(user['userId'] as String),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
