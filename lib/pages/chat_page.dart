import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'chat_page_redesigned.dart';

// This file is kept for backward compatibility
// Use ChatPageRedesigned for new implementations
class ChatPage extends StatelessWidget {
  final String sellerName;
  final String? sellerId;
  final String? sellerAvatar;

  const ChatPage({
    super.key,
    required this.sellerName,
    this.sellerId,
    this.sellerAvatar,
  });

  @override
  Widget build(BuildContext context) {
    // Redirect to redesigned chat page
    return ChatPageRedesigned(
      sellerName: sellerName,
      sellerId: sellerId,
      sellerAvatar: sellerAvatar,
    );
  }
}


