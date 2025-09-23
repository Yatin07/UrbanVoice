import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as auth;

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<auth.AuthProvider>().user;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
          ),
        ],
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Please login to view your reports'))
          : StreamBuilder<QuerySnapshot>(
                  stream: _getMyReports(user?.uid),
                  builder: (context, snapshot) {
                    debugPrint('StreamBuilder state: ${snapshot.connectionState}');
                    debugPrint('Has data: ${snapshot.hasData}');
                    debugPrint('Has error: ${snapshot.hasError}');
                    if (snapshot.hasData) {
                      debugPrint('Documents count: ${snapshot.data!.docs.length}');
                    }
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      debugPrint('Error in stream: ${snapshot.error}');
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final reports = snapshot.data?.docs ?? [];
                    debugPrint('User reports count: ${reports.length}');
                    debugPrint('Current user ID: ${user?.uid}');

                    if (reports.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No reports found',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Summary Cards Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  reports.length.toString(),
                                  'Total Reports',
                                  const Color(0xFF3B82F6),
                                  Icons.assignment,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryCard(
                                  reports.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'resolved').length.toString(),
                                  'Resolved',
                                  const Color(0xFF10B981),
                                  Icons.check_circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryCard(
                                  reports.where((doc) => (doc.data() as Map<String, dynamic>)['status'] != 'resolved').length.toString(),
                                  'Pending',
                                  const Color(0xFFF59E0B),
                                  Icons.pending,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Reports List
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reports.length,
                            itemBuilder: (context, index) {
                              final report = reports[index];
                              final data = report.data() as Map<String, dynamic>;
                              
                              return GestureDetector(
                                onTap: () {
                                  context.go('/report-status/${report.id}');
                                },
                                child: _buildReportCard(data, report.id, context),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Stream<QuerySnapshot> _getMyReports(String? userId) {
    if (userId == null) {
      return const Stream.empty();
    }
    
    debugPrint('Fetching reports for userId: $userId');
    
    return FirebaseFirestore.instance
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Widget _buildSummaryCard(String count, String title, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, String reportId, BuildContext context) {
    final status = report['status'] ?? 'open';
    final title = report['title'] ?? 'Civic Issue Report';
    final description = report['description'] ?? 'No description';
    final address = report['address'] ?? 'Unknown location';
    final createdAt = report['createdAt'];
    DateTime? date;
    try {
      if (createdAt is Timestamp) {
        date = createdAt.toDate();
      } else if (createdAt is String) {
        date = DateTime.tryParse(createdAt);
      }
    } catch (e) {
      date = null;
    }
    final category = report['category'] ?? 'General';
    final priority = report['priority'] ?? 'medium';

    Color statusColor = _getStatusColor(status);
    IconData statusIcon = _getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.go('/report-status/$reportId');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Location and date
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (date != null)
                      Text(
                        _formatDate(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Category and Priority chips
                Row(
                  children: [
                    _buildInfoChip(category, Icons.category, const Color(0xFF8E44AD)),
                    const SizedBox(width: 8),
                    _buildInfoChip(priority, Icons.priority_high, _getPriorityColor(priority)),
                    const Spacer(),
                    Text(
                      'ID: ${reportId.substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
      case 'open':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.hourglass_empty;
      case 'pending':
      case 'open':
        return Icons.radio_button_unchecked;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
