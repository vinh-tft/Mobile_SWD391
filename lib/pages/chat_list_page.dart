import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'chat_page_redesigned.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<Conversation> _conversations = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _loading = true);
    
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final conversations = await chatService.getUserConversations();
      
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
      
      print('✅ Loaded ${conversations.length} conversations');
    } catch (e) {
      print('❌ Error loading conversations: $e');
      setState(() => _loading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load conversations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createAdminConversation() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      if (authService.currentUser == null) {
        throw Exception('Not logged in');
      }
      
      // Create conversation with admin (use current user's ID as placeholder)
      final conversation = await chatService.createConversation(
        authService.currentUser!.id,
        isAdminConversation: true,
      );
      
      if (conversation != null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPageRedesigned(
                sellerName: 'Admin Support',
                sellerId: conversation.otherUser.userId,
                conversationId: conversation.conversationId,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error creating admin conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to contact admin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Conversation> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    
    return _conversations.where((conv) {
      final searchLower = _searchQuery.toLowerCase();
      return conv.conversationName.toLowerCase().contains(searchLower) ||
             conv.otherUser.username.toLowerCase().contains(searchLower) ||
             conv.otherUser.email.toLowerCase().contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredConvs = _filteredConversations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Text(
          'Tin nhắn',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.support_agent, color: AppColors.primary),
            onPressed: _createAdminConversation,
            tooltip: 'Contact Admin Support',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.foreground),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tin nhắn...',
                prefixIcon: Icon(Icons.search, color: AppColors.mutedForeground),
                filled: true,
                fillColor: AppColors.muted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Conversations List
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filteredConvs.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: ListView.builder(
                          itemCount: filteredConvs.length,
                          itemBuilder: (context, index) {
                            final conv = filteredConvs[index];
                            return _buildChatItem(context, conv);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.muted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'Chưa có tin nhắn' : 'Không tìm thấy',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'Bắt đầu trò chuyện với người bán để biết thêm về sản phẩm'
                  : 'Không tìm thấy kết quả cho "$_searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.mutedForeground,
                height: 1.5,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to marketplace or show user search
                  Navigator.pushNamed(context, '/marketplace');
                },
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Khám phá Marketplace'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, Conversation conv) {
    final hasUnread = conv.unreadCount > 0;
    final lastActivity = conv.lastActivity.isNotEmpty
        ? _formatTime(DateTime.parse(conv.lastActivity))
        : '';

    return InkWell(
      onTap: () async {
        // Navigate to chat page
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPageRedesigned(
              sellerName: conv.isAdminConversation 
                  ? 'Admin Support' 
                  : conv.otherUser.username,
              sellerId: conv.otherUser.userId,
              conversationId: conv.conversationId,
            ),
          ),
        );
        
        // Refresh list after returning
        if (result == true || result == null) {
          _loadConversations();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasUnread ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: conv.isAdminConversation
                          ? [Colors.blue.shade400, Colors.blue.shade600]
                          : [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: conv.isAdminConversation
                        ? const Icon(Icons.support_agent, color: Colors.white, size: 28)
                        : Text(
                            conv.otherUser.username.isNotEmpty
                                ? conv.otherUser.username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                // Online indicator (can be enhanced with real status later)
                if (!conv.isAdminConversation)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            
            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv.isAdminConversation
                              ? 'Admin Support'
                              : conv.otherUser.username,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
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
                            fontSize: 13,
                            color: hasUnread ? AppColors.primary : AppColors.mutedForeground,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage ?? 'No messages yet',
                          style: TextStyle(
                            fontSize: 15,
                            color: hasUnread ? AppColors.foreground : AppColors.mutedForeground,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${conv.unreadCount}',
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
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
