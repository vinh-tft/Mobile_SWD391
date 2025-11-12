import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'add_sale_item_page.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final List<Map<String, String>> _posts = [
    {
      'title': 'Cool recycled outfit ideas',
      'image': 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?q=80&w=1200&auto=format&fit=crop',
      'seller': 'Green Studio',
    },
    {
      'title': 'The story behind a vintage denim jacket',
      'image': 'https://images.unsplash.com/photo-1548883354-94bcfe321c35?q=80&w=1200&auto=format&fit=crop',
      'seller': 'Eco Wardrobe',
    },
    {
      'title': 'Why choose sustainable fashion?',
      'image': 'https://images.unsplash.com/photo-1521335629791-ce4aec67dd53?q=80&w=1200&auto=format&fit=crop',
      'seller': 'ReWear',
    },
  ];

  final Set<int> _liked = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Posts',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = _posts[index];
          final isLiked = _liked.contains(index);
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    post['image']!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 200,
                        color: const Color(0xFFF3F4F6),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Color(0xFF22C55E)),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: const Color(0xFFF3F4F6),
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image, color: Color(0xFF6B7280), size: 48),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['title']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildIconAction(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            isLiked ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
                            isLiked ? 'Liked' : 'Like',
                            () {
                              setState(() {
                                if (isLiked) {
                                  _liked.remove(index);
                                } else {
                                  _liked.add(index);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 12),
                          _buildIconAction(
                            Icons.mode_comment_outlined,
                            const Color(0xFF6B7280),
                            'Comment',
                            () => _openComments(post['title']!),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChatPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF22C55E)),
                            label: const Text(
                              'Chat seller',
                              style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E).withOpacity(0.08),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconAction(IconData icon, Color color, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _openComments(String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Comments • $title',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: const [
                    ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Great idea!'),
                      subtitle: Text('2h ago'),
                    ),
                    ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Love sustainable fashion ❤️'),
                      subtitle: Text('1h ago'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
                    child: const Text('Send'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}


