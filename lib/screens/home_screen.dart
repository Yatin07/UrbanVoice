import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart' as auth;
import 'report_screen.dart';
import 'social_feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int totalReports = 0;
  int resolvedReports = 0;
  int inProgressReports = 0;
  int pendingReports = 0;
  Map<String, int> categoryCounts = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final complaintsRef = FirebaseFirestore.instance.collection('complaints');
      
      // Get all complaints
      final allComplaints = await complaintsRef.get();
      final total = allComplaints.docs.length;
      
      // Get resolved complaints
      final resolvedQuery = await complaintsRef.where('status', isEqualTo: 'resolved').get();
      final resolved = resolvedQuery.docs.length;
      
      // Get in progress complaints
      final inProgressQuery = await complaintsRef.where('status', isEqualTo: 'in_progress').get();
      final inProgress = inProgressQuery.docs.length;
      
      // Get pending complaints (open status)
      final pendingQuery = await complaintsRef.where('status', isEqualTo: 'open').get();
      final pending = pendingQuery.docs.length;
      
      // Count by category
      Map<String, int> categoryMap = {};
      for (var doc in allComplaints.docs) {
        final data = doc.data();
        final category = data['category'] ?? 'Other';
        categoryMap[category] = (categoryMap[category] ?? 0) + 1;
      }
      
      if (mounted) {
        setState(() {
          totalReports = total;
          resolvedReports = resolved;
          inProgressReports = inProgress;
          pendingReports = pending;
          categoryCounts = categoryMap;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<auth.AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // Header Section
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_city,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'UrbanVoice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Hello, Citizen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          user?.name ?? 'User',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      onSelected: (value) async {
                        if (value == 'logout') {
                          final authProvider = context.read<auth.AuthProvider>();
                          await authProvider.signOut();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Logout', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard('Total', totalReports, const Color(0xFF1E3A8A)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard('Resolved', resolvedReports, const Color(0xFF10B981)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard('Pending', pendingReports, const Color(0xFFF59E0B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Report Services Section
                  const Text(
                    'Report Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.1,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ReportScreen()),
                        ),
                        child: _buildServiceCard(
                          'Pothole',
                          'File a road hazard',
                          Icons.construction,
                          const Color(0xFF3B82F6),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ReportScreen()),
                        ),
                        child: _buildServiceCard(
                          'Garbage',
                          'Request waste pickup',
                          Icons.delete_outline,
                          const Color(0xFF10B981),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ReportScreen()),
                        ),
                        child: _buildServiceCard(
                          'Streetlight',
                          '0 reports',
                          Icons.lightbulb_outline,
                          const Color(0xFFF59E0B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ReportScreen()),
                        ),
                        child: _buildServiceCard(
                          'Other',
                          '1 reports',
                          Icons.warning_outlined,
                          const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Recent Activity Section
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentActivity(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            loading ? '...' : '$count',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('complaints')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'No recent activity',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: snapshot.data!.docs.take(3).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Complaint';
              final category = data['category'] ?? 'general';
              final status = data['status'] ?? 'open';
              final createdAt = data['createdAt'];
              
              // Parse date for display
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

              return _buildActivityItem(
                title,
                status.toUpperCase(),
                timeAgo,
                _getStatusColor(status),
                _getCategoryIcon(category),
              );
            }).toList(),
          ),
        );
      },
    );
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

  Widget _buildCommunityFeedPreview() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('complaints')
          .orderBy('createdAt', descending: true)
          .limit(2)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'No community posts yet',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.take(2).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] ?? 'Civic Issue';
            final upvotes = data['upvotes'] ?? 0;
            final downvotes = data['downvotes'] ?? 0;
            final category = data['category'] ?? 'general';
            final status = data['status'] ?? 'open';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _getCategoryColor(category),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.thumb_up, size: 12, color: Colors.green[600]),
                            const SizedBox(width: 4),
                            Text(
                              upvotes.toString(),
                              style: TextStyle(fontSize: 12, color: Colors.green[600]),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.thumb_down, size: 12, color: Colors.red[600]),
                            const SizedBox(width: 4),
                            Text(
                              downvotes.toString(),
                              style: TextStyle(fontSize: 12, color: Colors.red[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
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

  Widget _buildActivityItem(String title, String status, String subtitle, Color statusColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: const Color(0xFF6B7280), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title - $status',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockReportItem extends StatelessWidget {
  final String title;
  final String location;
  final String status;
  final IconData icon;
  
  const _MockReportItem({
    required this.title,
    required this.location,
    required this.status,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = status == 'Resolved' ? Colors.green : 
                       status == 'In Progress' ? Colors.orange : Colors.grey;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Icon(icon, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.place, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(location, style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String number;
  final String label;
  final Color color;
  const _Stat({required this.number, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(number, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String categoryName;
  final int count;
  const _CategoryTile({required this.categoryName, required this.count});

  @override
  Widget build(BuildContext context) {
    IconData icon = _getIcon(categoryName);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(categoryName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('$count reports', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'Pothole':
        return Icons.construction;
      case 'Garbage':
        return Icons.delete;
      case 'Streetlight':
        return Icons.lightbulb;
      case 'Other':
        return Icons.report_problem;
      default:
        return Icons.help;
    }
  }
}
