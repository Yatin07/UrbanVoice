import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart' as auth;
import '../widgets/comments_modal.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_hasMore && !_loading) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadPosts() async {
    try {
      setState(() => _loading = true);
      
      Query query = FirebaseFirestore.instance
          .collection('complaints')
          .orderBy('createdAt', descending: true)
          .limit(10);

      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _posts = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      }

      setState(() {
        _loading = false;
        _hasMore = snapshot.docs.length == 10;
      });
    } catch (e) {
      debugPrint('Error loading posts: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_lastDocument == null) return;

    try {
      setState(() => _loading = true);
      
      final snapshot = await FirebaseFirestore.instance
          .collection('complaints')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(10)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final newPosts = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        
        setState(() {
          _posts.addAll(newPosts);
          _hasMore = snapshot.docs.length == 10;
        });
      } else {
        setState(() => _hasMore = false);
      }

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Error loading more posts: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshFeed() async {
    _lastDocument = null;
    _posts.clear();
    await _loadPosts();
  }

  Future<void> _voteOnPost(String postId, bool isUpvote) async {
    try {
      final user = context.read<auth.AuthProvider>().user;
      if (user == null) return;

      final postRef = FirebaseFirestore.instance.collection('complaints').doc(postId);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(postRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final currentUpvotes = data['upvotes'] ?? 0;
        final currentDownvotes = data['downvotes'] ?? 0;
        final userVotes = List<String>.from(data['userUpvotes'] ?? []);
        final userDownvotes = List<String>.from(data['userDownvotes'] ?? []);

        // Remove user from both lists first
        userVotes.remove(user.id);
        userDownvotes.remove(user.id);

        int newUpvotes = currentUpvotes;
        int newDownvotes = currentDownvotes;

        if (isUpvote) {
          userVotes.add(user.id);
          newUpvotes = userVotes.length;
          newDownvotes = userDownvotes.length;
        } else {
          userDownvotes.add(user.id);
          newUpvotes = userVotes.length;
          newDownvotes = userDownvotes.length;
        }

        transaction.update(postRef, {
          'upvotes': newUpvotes,
          'downvotes': newDownvotes,
          'userUpvotes': userVotes,
          'userDownvotes': userDownvotes,
        });
      });

      // Update local state optimistically
      final postIndex = _posts.indexWhere((post) => post['id'] == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        final userUpvotes = List<String>.from(post['userUpvotes'] ?? []);
        final userDownvotes = List<String>.from(post['userDownvotes'] ?? []);
        
        // Remove user from both lists first
        userUpvotes.remove(user.id);
        userDownvotes.remove(user.id);
        
        // Add to appropriate list
        if (isUpvote) {
          userUpvotes.add(user.id);
        } else {
          userDownvotes.add(user.id);
        }
        
        setState(() {
          _posts[postIndex] = {
            ..._posts[postIndex],
            'upvotes': userUpvotes.length,
            'downvotes': userDownvotes.length,
            'userUpvotes': userUpvotes,
            'userDownvotes': userDownvotes,
          };
        });
      }
    } catch (e) {
      debugPrint('Error voting on post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to vote. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Community Feed'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFeed,
        child: _loading && _posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _posts.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _posts.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPostCard(_posts[index]),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final user = context.read<auth.AuthProvider>().user;
    final userId = user?.id ?? '';
    
    final title = post['title'] ?? 'Civic Issue';
    final description = post['description'] ?? '';
    final category = post['category'] ?? 'General';
    final status = post['status'] ?? 'open';
    final imageUrl = post['imageUrl'] as String?;
    final createdAt = post['createdAt'];
    final upvotes = post['upvotes'] ?? 0;
    final downvotes = post['downvotes'] ?? 0;
    final userUpvotes = List<String>.from(post['userUpvotes'] ?? []);
    final userDownvotes = List<String>.from(post['userDownvotes'] ?? []);
    final address = post['address'] ?? 'Unknown location';
    
    final hasUserUpvoted = userUpvotes.contains(userId);
    final hasUserDownvoted = userDownvotes.contains(userId);

    // Format timestamp
    String timeAgo = 'Recently';
    try {
      DateTime date;
      if (createdAt is Timestamp) {
        date = createdAt.toDate();
      } else if (createdAt is String) {
        date = DateTime.parse(createdAt);
      } else {
        date = DateTime.now();
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        timeAgo = '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        timeAgo = '${difference.inMinutes}m ago';
      } else {
        timeAgo = 'Just now';
      }
    } catch (e) {
      timeAgo = 'Recently';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getCategoryColor(category),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Citizen Report',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(status)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Image - Debug logging for image URL
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  debugPrint('Post ${post['id']}: imageUrl exists, length: ${imageUrl.length}');
                  debugPrint('Post ${post['id']}: imageUrl preview: ${imageUrl.substring(0, min(100, imageUrl.length))}...');
                  return _buildPostImage(imageUrl);
                }
              ),
            ] else ...[
              Builder(
                builder: (context) {
                  debugPrint('Post ${post['id']}: No imageUrl - imageUrl is ${imageUrl == null ? 'null' : 'empty'}');
                  return const SizedBox.shrink();
                }
              ),
            ],
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildVoteButton(
                    icon: Icons.thumb_up_outlined,
                    activeIcon: Icons.thumb_up,
                    count: upvotes,
                    isActive: hasUserUpvoted,
                    onTap: () => _voteOnPost(post['id'], true),
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 16),
                  _buildVoteButton(
                    icon: Icons.thumb_down_outlined,
                    activeIcon: Icons.thumb_down,
                    count: downvotes,
                    isActive: hasUserDownvoted,
                    onTap: () => _voteOnPost(post['id'], false),
                    color: const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 16),
                  _buildCommentButton(post),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: _getCategoryColor(category),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentButton(Map<String, dynamic> post) {
    final commentCount = (post['comments'] as List?)?.length ?? 0;
    
    return GestureDetector(
      onTap: () => _showCommentsModal(post),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.comment_outlined, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              commentCount.toString(),
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsModal(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsModal(
        postId: post['id'],
        postTitle: post['title'] ?? 'Civic Issue',
      ),
    );
  }

  Widget _buildVoteButton({
    required IconData icon,
    required IconData activeIcon,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 18,
              color: isActive ? color : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: isActive ? color : Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostImage(String imageData) {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildImageFromBase64(imageData),
      ),
    );
  }

  Widget _buildImageFromBase64(String imageData) {
    try {
      debugPrint('Processing image data: ${imageData.substring(0, min(50, imageData.length))}...');
      
      // Check if it's a data URL format
      if (imageData.startsWith('data:image')) {
        // Extract base64 part after comma
        if (!imageData.contains(',')) {
          debugPrint('Invalid data URL format - no comma found');
          return _buildErrorPlaceholder('Invalid data URL format');
        }
        
        final base64String = imageData.split(',')[1];
        if (base64String.isEmpty) {
          debugPrint('Empty base64 string after comma');
          return _buildErrorPlaceholder('Empty image data');
        }
        
        final Uint8List bytes = base64Decode(base64String);
        debugPrint('Successfully decoded ${bytes.length} bytes from data URL');
        
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Image.memory error: $error');
            return _buildErrorPlaceholder('Failed to display image');
          },
        );
      } else if (imageData.isNotEmpty) {
        // Try to decode as plain base64
        debugPrint('Attempting to decode as plain base64');
        final Uint8List bytes = base64Decode(imageData);
        debugPrint('Successfully decoded ${bytes.length} bytes from plain base64');
        
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Image.memory error: $error');
            return _buildErrorPlaceholder('Failed to display image');
          },
        );
      } else {
        debugPrint('Empty image data provided');
        return _buildErrorPlaceholder('No image data');
      }
    } catch (e) {
      debugPrint('Error decoding image: $e');
      return _buildErrorPlaceholder('Invalid image format');
    }
  }

  Widget _buildErrorPlaceholder(String message) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'water_supply_dept':
        return const Color(0xFF3B82F6);
      case 'road_maintenance':
        return const Color(0xFFEF4444);
      case 'waste_management':
        return const Color(0xFF10B981);
      case 'streetlight':
        return const Color(0xFFF59E0B);
      case 'drainage':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'water_supply_dept':
        return Icons.water_drop_outlined;
      case 'road_maintenance':
        return Icons.construction;
      case 'waste_management':
        return Icons.delete_outline;
      case 'streetlight':
        return Icons.lightbulb_outline;
      case 'drainage':
        return Icons.water_outlined;
      default:
        return Icons.report_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFF10B981);
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'open':
      default:
        return const Color(0xFFF59E0B);
    }
  }
}
