import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/api_models.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];

  PostFeedScope _activeScope = PostFeedScope.community;
  String _visibility = 'PUBLIC';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostService>().initialize(scope: _activeScope);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _hashtagsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final service = context.read<PostService>();
    if (!service.hasMore || service.loading) return;
    final threshold = 200.0;
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels <= threshold) {
      service.loadMore();
    }
  }

  Future<void> _pickImages() async {
    final files = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() {
      _selectedImages.addAll(files);
    });
  }

  void _removeSelectedImage(int index) {
    if (index < 0 || index >= _selectedImages.length) return;
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  List<String> _parseHashtags(String value) {
    return value
        .split(RegExp(r'[\s,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => e.startsWith('#') ? e.substring(1) : e)
        .toList();
  }

  Future<void> _submitPost(PostService service, AuthService auth) async {
    if (!auth.isLoggedIn) {
      _showSnackBar('Bạn cần đăng nhập để tạo bài viết.');
      return;
    }
    if (_submitting) return;

    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) {
      _showSnackBar('Vui lòng nhập nội dung hoặc thêm hình ảnh.');
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final List<String> uploadedUrls = [];
      for (final image in _selectedImages) {
        final file = File(image.path);
        final url = await service.uploadImage(file);
        uploadedUrls.add(url);
      }

      final request = PostCreateRequest(
        content: content.isEmpty ? null : content,
        images: uploadedUrls,
        hashtags: _parseHashtags(_hashtagsController.text),
        visibility: _visibility,
      );

      await service.createPost(request);
      _contentController.clear();
      _hashtagsController.clear();
      _selectedImages.clear();
      _visibility = 'PUBLIC';
      _showSnackBar('Đăng bài viết thành công!');
    } catch (e) {
      _showSnackBar('Không thể đăng bài viết: $e');
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final postService = context.watch<PostService>();
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bài viết',
          style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () => postService.refresh(),
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            _buildComposer(postService, authService),
            const SizedBox(height: 16),
            _buildFeedTabs(postService, authService),
            const SizedBox(height: 16),
            if (postService.error != null && postService.posts.isEmpty)
              _buildErrorMessage(postService.error!),
            if (postService.loading && postService.posts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!postService.loading && postService.posts.isEmpty && postService.error == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'Chưa có bài viết nào ở mục này. Hãy là người đầu tiên chia sẻ! 😊',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              ),
            ...postService.posts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPostCard(postService, authService, post),
              ),
            ),
            if (postService.loading && postService.posts.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(PostService service, AuthService auth) {
    if (!auth.isLoggedIn) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Text(
          'Đăng nhập để chia sẻ câu chuyện bền vững của bạn cùng cộng đồng.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chia sẻ điều bạn đang suy nghĩ...',
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Viết cảm hứng thời trang bền vững của bạn',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hashtagsController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.tag, size: 18),
                hintText: '#GreenLoop #SustainableFashion',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _submitting ? null : _pickImages,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Thêm ảnh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDCFCE7),
                    foregroundColor: const Color(0xFF166534),
                  ),
                ),
                DropdownButton<String>(
                  value: _visibility,
                  items: const [
                    DropdownMenuItem(value: 'PUBLIC', child: Text('Công khai')),
                    DropdownMenuItem(value: 'FOLLOWERS_ONLY', child: Text('Người theo dõi')),
                    DropdownMenuItem(value: 'PRIVATE', child: Text('Riêng tư')),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _visibility = value;
                          });
                        },
                ),
              ],
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_selectedImages.length, (index) {
                  final image = _selectedImages[index];
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(image.path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeSelectedImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  );
                }),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (_submitting || service.uploading)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : () => _submitPost(service, auth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Chia sẻ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTabs(PostService service, AuthService auth) {
    final tabs = <({String label, PostFeedScope scope})>[
      (label: 'Khám phá', scope: PostFeedScope.community),
      if (auth.isLoggedIn) (label: 'Đang theo dõi', scope: PostFeedScope.following),
      if (auth.isLoggedIn) (label: 'Của tôi', scope: PostFeedScope.mine),
    ];

    return Wrap(
      spacing: 8,
      children: tabs.map((tab) {
        final selected = _activeScope == tab.scope;
        return ChoiceChip(
          label: Text(tab.label),
          selected: selected,
          onSelected: (value) {
            if (!value) return;
            setState(() {
              _activeScope = tab.scope;
            });
            service.switchScope(tab.scope);
          },
          selectedColor: const Color(0xFFDCFCE7),
          labelStyle: TextStyle(
            color: selected ? const Color(0xFF166534) : const Color(0xFF6B7280),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
          backgroundColor: const Color(0xFFF9FAFB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
      }).toList(),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Color(0xFFB91C1C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostService service, AuthService auth, PostResponse post) {
    final authorLabel = post.authorDisplayName ?? post.authorUsername ?? 'Người dùng';
    final isOwner = auth.currentUser?.id != null && auth.currentUser!.id == post.authorId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE0F2FE),
              backgroundImage:
                  post.authorAvatarUrl != null && post.authorAvatarUrl!.isNotEmpty
                      ? NetworkImage(post.authorAvatarUrl!)
                      : null,
              child: (post.authorAvatarUrl == null || post.authorAvatarUrl!.isEmpty)
                  ? Text(
                      authorLabel.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Color(0xFF0369A1)),
                    )
                  : null,
            ),
            title: Text(authorLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              _formatTimestamp(post.createdAt),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            trailing: isOwner
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openEditPost(service, post);
                      } else if (value == 'delete') {
                        _confirmDelete(service, post.postId);
                      } else if (value == 'restore') {
                        service.restorePost(post.postId).catchError((e) {
                          _showSnackBar('Không thể khôi phục bài viết: $e');
                        });
                      }
                    },
                    itemBuilder: (context) {
                      final items = <PopupMenuEntry<String>>[
                        const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                        const PopupMenuItem(value: 'delete', child: Text('Xoá bài viết')),
                      ];
                      if (post.hidden) {
                        items.add(const PopupMenuItem(value: 'restore', child: Text('Khôi phục')));
                      }
                      return items;
                    },
                  )
                : null,
          ),
          if (post.hidden)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Bài viết đã ẩn',
                  style: TextStyle(color: Color(0xFF92400E), fontSize: 12),
                ),
              ),
            ),
          if (post.content != null && post.content!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                post.content!,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
              ),
            ),
          if (post.images.isNotEmpty)
            SizedBox(
              height: 240,
              child: PageView.builder(
                itemCount: post.images.length,
                controller: PageController(viewportFraction: 0.95),
                itemBuilder: (context, index) {
                  final url = post.images[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF3F4F6),
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFF3F4F6),
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined, size: 48, color: Color(0xFF9CA3AF)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (post.hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: post.hashtags
                    .map(
                      (tag) => Chip(
                        label: Text('#$tag'),
                        backgroundColor: const Color(0xFFE0F2FE),
                        labelStyle: const TextStyle(color: Color(0xFF0369A1)),
                      ),
                    )
                    .toList(),
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildIconButton(
                  icon: post.likedByViewer ? Icons.favorite : Icons.favorite_border,
                  label: '${post.likesCount} thích',
                  active: post.likedByViewer,
                  onTap: () async {
                    try {
                      await service.toggleLike(post.postId);
                    } catch (e) {
                      _showSnackBar('Không thể cập nhật lượt thích: $e');
                    }
                  },
                ),
                _buildIconButton(
                  icon: Icons.mode_comment_outlined,
                  label: '${post.commentsCount} bình luận',
                  onTap: () => _openComments(service, auth, post),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    _showSnackBar('Chia sẻ sắp ra mắt!');
                  },
                  icon: const Icon(Icons.share_outlined, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 18,
        color: active ? const Color(0xFFDC2626) : const Color(0xFF6B7280),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFFDC2626) : const Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(PostService service, String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá bài viết'),
        content: const Text('Bạn có chắc chắn muốn xoá bài viết này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await service.deletePost(postId);
      _showSnackBar('Đã xoá bài viết.');
    } catch (e) {
      _showSnackBar('Không thể xoá bài viết: $e');
    }
  }

  Future<void> _openEditPost(PostService service, PostResponse post) async {
    final contentController = TextEditingController(text: post.content ?? '');
    final hashtagsController = TextEditingController(
      text: post.hashtags.map((tag) => '#$tag').join(' '),
    );
    String visibility = post.visibility;
    List<String> imageUrls = List<String>.from(post.images);
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickAdditionalImages() async {
              final files = await _imagePicker.pickMultiImage(imageQuality: 85);
              if (files.isEmpty) return;
              setModalState(() => saving = true);
              try {
                for (final file in files) {
                  final url = await service.uploadImage(File(file.path));
                  imageUrls.add(url);
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Không thể tải ảnh lên: $e');
                }
              } finally {
                setModalState(() => saving = false);
              }
            }

            Future<void> saveChanges() async {
              if (saving) return;
              setModalState(() => saving = true);
              try {
                await service.updatePost(
                  post.postId,
                  PostUpdateRequest(
                    content: contentController.text.trim(),
                    hashtags: _parseHashtags(hashtagsController.text),
                    visibility: visibility,
                    images: imageUrls,
                  ),
                );
                if (mounted) Navigator.pop(context);
                _showSnackBar('Đã cập nhật bài viết.');
              } catch (e) {
                _showSnackBar('Không thể cập nhật bài viết: $e');
              } finally {
                setModalState(() => saving = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                  const Text(
                    'Chỉnh sửa bài viết',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hashtagsController,
                    decoration: const InputDecoration(
                      labelText: 'Hashtag',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: visibility,
                    decoration: const InputDecoration(
                      labelText: 'Chế độ hiển thị',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'PUBLIC', child: Text('Công khai')),
                      DropdownMenuItem(value: 'FOLLOWERS_ONLY', child: Text('Người theo dõi')),
                      DropdownMenuItem(value: 'PRIVATE', child: Text('Riêng tư')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() {
                        visibility = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: saving ? null : pickAdditionalImages,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Thêm ảnh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (imageUrls.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final url = imageUrls[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: saving
                                      ? null
                                      : () {
                                          setModalState(() {
                                            imageUrls.removeAt(index);
                                          });
                                        },
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Lưu thay đổi'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openComments(PostService service, AuthService auth, PostResponse post) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CommentsSheet(service: service, auth: auth, post: post),
    );
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
      if (diff.inDays < 1) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return timestamp;
    }
  }
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.service, required this.auth, required this.post});

  final PostService service;
  final AuthService auth;
  final PostResponse post;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();

  List<CommentResponse> _comments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final comments = await widget.service.fetchComments(widget.post.postId);
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    if (!widget.auth.isLoggedIn) {
      _showMessage('Bạn cần đăng nhập để bình luận.');
      return;
    }

    try {
      final comment = await widget.service.addComment(widget.post.postId, content);
      if (comment != null) {
        setState(() {
          _comments.insert(0, comment);
        });
      }
      _commentController.clear();
    } catch (e) {
      _showMessage('Không thể gửi bình luận: $e');
    }
  }

  Future<void> _deleteComment(CommentResponse comment) async {
    if (!widget.auth.isLoggedIn) {
      _showMessage('Bạn cần đăng nhập để xoá bình luận.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá bình luận'),
        content: const Text('Bạn có chắc chắn muốn xoá bình luận này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')), 
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.service.deleteComment(widget.post.postId, comment.commentId);
      setState(() {
        _comments.removeWhere((c) => c.commentId == comment.commentId);
      });
    } catch (e) {
      _showMessage('Không thể xoá bình luận: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final currentUserId = widget.auth.currentUser?.id;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomPadding + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bình luận',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFB91C1C)),
              ),
            )
          else if (_comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Chưa có bình luận nào. Hãy bắt đầu cuộc trò chuyện!'),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                separatorBuilder: (_, __) => const Divider(),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  final canDelete = currentUserId != null && currentUserId == comment.authorId;
                  final authorLabel = comment.authorDisplayName ?? comment.authorUsername ?? 'Người dùng';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE0F2FE),
                      child: Text(
                        authorLabel.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Color(0xFF0369A1)),
                      ),
                    ),
                    title: Text(authorLabel),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment.content),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(comment.createdAt),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                    trailing: canDelete
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                            onPressed: () => _deleteComment(comment),
                          )
                        : null,
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Viết bình luận...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submitComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Icon(Icons.send, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
      if (diff.inDays < 1) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return timestamp;
    }
  }
}


