// lib/screens/comments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../models/comment.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/medicine_card.dart';

class CommentsScreen extends StatefulWidget {
  final Medicine medicine;

  const CommentsScreen({super.key, required this.medicine});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _selectedFilter;
  int _currentPage = 1;
  int _totalComments = 0;
  bool _hasMore = true;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, dynamic>? _statistics;

  // Comment types for filtering
  final List<String> _filterTypes = [
    'All',
    'Positive',
    'Negative',
    'Neutral',
    'General',
  ];
  final Map<String, String> _filterMap = {
    'All': '',
    'Positive': 'POSITIVE',
    'Negative': 'NEGATIVE',
    'Neutral': 'NEUTRAL',
    'General': 'general',
  };

  @override
  void initState() {
    super.initState();
    _loadComments();
    _loadStatistics();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await ApiService.getCommentStatistics(widget.medicine.id);
      if (mounted) {
        setState(() {
          _statistics = stats['statistics'];
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      // Set default statistics if API call fails
      if (mounted) {
        setState(() {
          _statistics = {
            'total_comments': _comments.length,
            'positive': _comments
                .where((c) => c.type.toUpperCase() == 'POSITIVE')
                .length,
            'negative': _comments
                .where((c) => c.type.toUpperCase() == 'NEGATIVE')
                .length,
            'neutral': _comments
                .where((c) => c.type.toUpperCase() == 'NEUTRAL')
                .length,
            'general': _comments
                .where((c) => c.type.toLowerCase() == 'general')
                .length,
          };
        });
      }
    }
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _comments = [];
        _hasMore = true;
        _isLoading = true;
      });
    } else if (_isLoadingMore || !_hasMore) {
      return;
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final filterValue = _filterMap[_selectedFilter ?? 'All'] ?? '';

      final response = await ApiService.getMedicineComments(
        widget.medicine.id,
        type: filterValue.isNotEmpty ? filterValue : null,
        page: _currentPage,
        pageSize: 20,
      );

      if (mounted) {
        final newComments = (response['results'] as List)
            .map((json) => Comment.fromJson(json))
            .toList();

        setState(() {
          if (refresh) {
            _comments = newComments;
          } else {
            _comments.addAll(newComments);
          }
          _totalComments = response['count'];
          _hasMore = newComments.length == 20;
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a comment')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiService.createComment(widget.medicine.id, text);

      // Clear input
      _commentController.clear();

      // Refresh comments and statistics
      await _loadComments(refresh: true);
      await _loadStatistics();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add comment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteComment(commentId);
        await _loadComments(refresh: true);
        await _loadStatistics();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete comment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reviews - ${widget.medicine.name}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade800,
                Colors.green.shade600,
                Colors.teal.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Statistics Section
          if (_statistics != null) _buildStatisticsSection(),

          // Comment Input Section
          _buildCommentInput(currentUser),

          // Filter Section
          _buildFilterSection(),

          // Comments List
          Expanded(child: _buildCommentsList()),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final stats = _statistics!;
    final total = stats['total_comments'] ?? 0;
    final positive = stats['positive'] ?? 0;
    final negative = stats['negative'] ?? 0;
    final neutral = stats['neutral'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Reviews',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Text(
                '$total',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip('Positive', positive, Colors.green),
              const SizedBox(width: 8),
              _buildStatChip('Negative', negative, Colors.red),
              const SizedBox(width: 8),
              _buildStatChip('Neutral', neutral, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(Map<String, dynamic>? currentUser) {
    if (currentUser == null) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Please login to leave a review',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: currentUser['photo'] != null
                ? NetworkImage(currentUser['photo'])
                : null,
            child: currentUser['photo'] == null
                ? Icon(Icons.person, color: Colors.green.shade700)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Write your review...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isSubmitting
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  onPressed: _submitComment,
                  icon: Icon(Icons.send, color: Colors.green.shade700),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterTypes.length,
        itemBuilder: (context, index) {
          final filter = _filterTypes[index];
          final isSelected =
              _selectedFilter == filter ||
              (filter == 'All' && _selectedFilter == null);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? filter : 'All';
                  if (_selectedFilter == 'All') {
                    _selectedFilter = null;
                  }
                });
                _loadComments(refresh: true);
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.green.shade100,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.green.shade700
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadComments(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review this medicine',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isLoadingMore &&
            _hasMore &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 100) {
          setState(() {
            _currentPage++;
          });
          _loadComments();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _comments.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _comments.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildCommentCard(_comments[index]);
        },
      ),
    );
  }

  Widget _buildCommentCard(Comment comment) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Check if the current user is the comment owner
    final isOwner = authProvider.user?['id'] == comment.commentCustomer;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: comment.customerPhoto != null
                      ? NetworkImage(comment.customerPhoto!)
                      : null,
                  child: comment.customerPhoto == null
                      ? Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.green.shade700,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        comment.getFormattedDate(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sentiment Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: comment.getSentimentColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        comment.getSentimentIcon(),
                        size: 14,
                        color: comment.getSentimentColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        comment.type,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: comment.getSentimentColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () => _deleteComment(comment.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comment.text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
