import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../config/app_config.dart';
import '../models/api_models.dart';
import 'api_client.dart';
import 'auth_service.dart';

enum PostFeedScope { community, following, mine }

class PostService extends ChangeNotifier {
  PostService(this._api, this._auth);

  final ApiClient _api;
  final AuthService _auth;

  final int _pageSize = 10;

  List<PostResponse> _posts = [];
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  PostFeedScope _scope = PostFeedScope.community;
  bool _includeHidden = false;
  int _page = 0;
  bool _uploading = false;

  List<PostResponse> get posts => _posts;
  bool get loading => _loading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  PostFeedScope get scope => _scope;
  bool get uploading => _uploading;
  bool get isAuthenticated => _auth.isLoggedIn;

  String? get _viewerId => _auth.currentUser?.id;

  Future<void> initialize({PostFeedScope scope = PostFeedScope.community}) async {
    _scope = scope;
    _includeHidden = scope == PostFeedScope.mine;
    await refresh();
  }

  Future<void> refresh() async {
    _page = 0;
    _posts = [];
    _hasMore = true;
    _error = null;
    notifyListeners();
    await _fetchPosts(reset: true);
  }

  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    await _fetchPosts();
  }

  Future<void> switchScope(PostFeedScope scope) async {
    if (_scope == scope && _posts.isNotEmpty) {
      await refresh();
      return;
    }
    _scope = scope;
    _includeHidden = scope == PostFeedScope.mine;
    await refresh();
  }

  Future<PostResponse?> toggleLike(String postId) async {
    final userId = _viewerId;
    if (userId == null) {
      throw Exception('Bạn cần đăng nhập để tương tác với bài viết.');
    }
    final index = _posts.indexWhere((p) => p.postId == postId);
    if (index == -1) return null;

    final post = _posts[index];
    dynamic response;
    try {
      if (post.likedByViewer) {
        response = await _api.delete(
          ApiConfig.likePost(postId),
          query: {'userId': userId},
        );
      } else {
        response = await _api.post(
          ApiConfig.likePost(postId),
          query: {'userId': userId},
        );
      }

      final updated = _parsePost(response);
      _posts[index] = updated;
      notifyListeners();
      return updated;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<PostResponse?> createPost(PostCreateRequest request) async {
    final userId = _viewerId;
    if (userId == null) {
      throw Exception('Bạn cần đăng nhập để tạo bài viết.');
    }

    try {
      final response = await _api.post(ApiConfig.postsForUser(userId), body: request.toJson());
      final post = _parsePost(response);
      _posts.insert(0, post);
      notifyListeners();
      return post;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<PostResponse?> updatePost(String postId, PostUpdateRequest request) async {
    final actorId = _viewerId;
    if (actorId == null) {
      throw Exception('Bạn cần đăng nhập để chỉnh sửa bài viết.');
    }

    final index = _posts.indexWhere((p) => p.postId == postId);
    if (index == -1) {
      throw Exception('Không tìm thấy bài viết để chỉnh sửa.');
    }

    try {
      final response = await _api.put(
        ApiConfig.postDetail(postId),
        query: {'actorId': actorId},
        body: request.toJson(),
      );
      final updated = _parsePost(response);
      _posts[index] = updated;
      notifyListeners();
      return updated;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    final actorId = _viewerId;
    if (actorId == null) {
      throw Exception('Bạn cần đăng nhập để xoá bài viết.');
    }

    try {
      await _api.delete(
        ApiConfig.postDetail(postId),
        query: {'actorId': actorId},
      );
      _posts.removeWhere((p) => p.postId == postId);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> restorePost(String postId) async {
    final actorId = _viewerId;
    if (actorId == null) {
      throw Exception('Bạn cần đăng nhập để khôi phục bài viết.');
    }

    try {
      final response = await _api.patch(
        ApiConfig.restorePost(postId),
        query: {'actorId': actorId},
      );
      final restored = _parsePost(response);
      final index = _posts.indexWhere((p) => p.postId == postId);
      if (index != -1) {
        _posts[index] = restored;
      } else {
        _posts.insert(0, restored);
      }
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<CommentResponse>> fetchComments(String postId, {int page = 0, int size = 20}) async {
    try {
      final response = await _api.get(
        ApiConfig.commentsForPost(postId),
        query: {
          'page': page,
          'size': size,
        },
      );
      final pageResponse = _parseCommentPage(response);
      return pageResponse.content;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<CommentResponse?> addComment(String postId, String content) async {
    final userId = _viewerId;
    if (userId == null) {
      throw Exception('Bạn cần đăng nhập để bình luận.');
    }

    try {
      final response = await _api.post(
        ApiConfig.commentsForPost(postId),
        query: {'userId': userId},
        body: CommentCreateRequest(content: content).toJson(),
      );
      final comment = _parseComment(response);
      _updatePostCounters(postId, commentsDelta: 1);
      return comment;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<CommentResponse?> updateComment(String postId, int commentId, String content) async {
    final userId = _viewerId;
    if (userId == null) {
      throw Exception('Bạn cần đăng nhập để chỉnh sửa bình luận.');
    }

    try {
      final response = await _api.put(
        '${ApiConfig.commentsForPost(postId)}/$commentId',
        query: {'userId': userId},
        body: CommentUpdateRequest(content: content).toJson(),
      );
      return _parseComment(response);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> deleteComment(String postId, int commentId) async {
    final userId = _viewerId;
    if (userId == null) {
      throw Exception('Bạn cần đăng nhập để xoá bình luận.');
    }

    try {
      await _api.delete(
        '${ApiConfig.commentsForPost(postId)}/$commentId',
        query: {'userId': userId},
      );
      _updatePostCounters(postId, commentsDelta: -1);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<String> uploadImage(File file) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset;

    final fileName = file.path.split('/').last;
    request.files.add(await http.MultipartFile.fromPath('file', file.path, filename: fileName));

    _uploading = true;
    notifyListeners();

    try {
      final response = await request.send().timeout(const Duration(seconds: 20));
      final body = await response.stream.bytesToString();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        final secureUrl = decoded['secure_url']?.toString();
        if (secureUrl == null || secureUrl.isEmpty) {
          throw Exception('Không nhận được URL hình ảnh từ Cloudinary.');
        }
        return secureUrl;
      } else {
        String message = 'Tải ảnh lên Cloudinary thất bại (${response.statusCode}).';
        try {
          final decoded = jsonDecode(body) as Map<String, dynamic>;
          if (decoded['error'] != null && decoded['error']['message'] != null) {
            message = decoded['error']['message'].toString();
          }
        } catch (_) {}
        throw Exception(message);
      }
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchPosts({bool reset = false}) async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final viewerId = _viewerId;
      final query = <String, dynamic>{
        'page': _page,
        'size': _pageSize,
      };

      dynamic response;
      switch (_scope) {
        case PostFeedScope.following:
          if (viewerId == null) {
            response = await _api.get(
              ApiConfig.endpoints['posts']['communityFeed'],
              query: query,
            );
          } else {
            query['viewerId'] = viewerId;
            response = await _api.get(
              ApiConfig.endpoints['posts']['followingFeed'],
              query: query,
            );
          }
          break;
        case PostFeedScope.mine:
          if (viewerId == null) {
            _error = 'Bạn cần đăng nhập để xem bài viết của chính mình.';
            _posts = [];
            _hasMore = false;
            _loading = false;
            notifyListeners();
            return;
          }
          final mineQuery = {
            'page': _page,
            'size': _pageSize,
            'includeHidden': _includeHidden,
            'viewerId': viewerId,
          };
          response = await _api.get(ApiConfig.postsForUser(viewerId), query: mineQuery);
          break;
        case PostFeedScope.community:
        default:
          if (viewerId != null) {
            query['viewerId'] = viewerId;
          }
          response = await _api.get(ApiConfig.endpoints['posts']['communityFeed'], query: query);
          break;
      }

      final pageResponse = _parsePage(response);
      if (reset || _page == 0) {
        _posts = pageResponse.content;
      } else {
        _posts.addAll(pageResponse.content);
      }
      _hasMore = !pageResponse.last;
      _page = pageResponse.number + 1;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  PageResponse<PostResponse> _parsePage(dynamic response) {
    final Map<String, dynamic> data = _unwrapMap(response);
    return PageResponse<PostResponse>.fromJson(
      data,
      (item) => PostResponse.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  PageResponse<CommentResponse> _parseCommentPage(dynamic response) {
    final Map<String, dynamic> data = _unwrapMap(response);
    return PageResponse<CommentResponse>.fromJson(
      data,
      (item) => CommentResponse.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  PostResponse _parsePost(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        return PostResponse.fromJson(Map<String, dynamic>.from(response['data'] as Map));
      }
      return PostResponse.fromJson(response);
    }
    throw Exception('Định dạng phản hồi bài viết không hợp lệ: ${response.runtimeType}');
  }

  CommentResponse _parseComment(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        return CommentResponse.fromJson(Map<String, dynamic>.from(response['data'] as Map));
      }
      return CommentResponse.fromJson(response);
    }
    throw Exception('Định dạng phản hồi bình luận không hợp lệ: ${response.runtimeType}');
  }

  Map<String, dynamic> _unwrapMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response['data'] as Map);
      }
      if (response.containsKey('content')) {
        return Map<String, dynamic>.from(response);
      }
      if (response.containsKey('success') && response['data'] != null) {
        return Map<String, dynamic>.from(response['data'] as Map);
      }
      return Map<String, dynamic>.from(response);
    }
    throw Exception('Định dạng phản hồi không hợp lệ: ${response.runtimeType}');
  }

  void _updatePostCounters(String postId, {int commentsDelta = 0}) {
    final index = _posts.indexWhere((p) => p.postId == postId);
    if (index == -1) return;
    final post = _posts[index];
    _posts[index] = post.copyWith(commentsCount: post.commentsCount + commentsDelta);
    notifyListeners();
  }
}
