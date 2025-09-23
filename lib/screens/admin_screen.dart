import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../models/user.dart';
import '../models/report.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    // Check if user is admin
    if (!(auth.user?.isAdmin ?? false)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You need administrator privileges to access this page.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Reports', icon: Icon(Icons.report_problem)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DashboardTab(),
          _UsersTab(),
          _ReportsTab(),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('reports').snapshots(),
          builder: (context, reportSnapshot) {
            final userCount = userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;
            final reportCount = reportSnapshot.hasData ? reportSnapshot.data!.docs.length : 0;
            final adminCount = userSnapshot.hasData 
                ? userSnapshot.data!.docs.where((doc) => 
                    (doc.data() as Map<String, dynamic>)['role'] == 'admin').length 
                : 0;
            final citizenCount = userCount - adminCount;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Users',
                        value: userCount.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Total Reports',
                        value: reportCount.toString(),
                        icon: Icons.report_problem,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Administrators',
                        value: adminCount.toString(),
                        icon: Icons.admin_panel_settings,
                        color: Colors.red.withValues(alpha: 0.1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Citizens',
                        value: citizenCount.toString(),
                        icon: Icons.person,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Activity
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (reportSnapshot.hasData) ...[
                          ...reportSnapshot.data!.docs.take(5).map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              leading: const Icon(Icons.report, color: Colors.orange),
                              title: Text(data['title'] ?? 'Unknown Report'),
                              subtitle: Text('Status: ${data['status'] ?? 'Unknown'}'),
                              trailing: Text(
                                _formatDate(data['createdAt']),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            );
                          }),
                        ] else
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No users found'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final userData = doc.data() as Map<String, dynamic>;
            final user = CivicUser.fromMap({...userData, 'id': doc.id});

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: user.isAdmin ? Colors.red.shade100 : Colors.blue.shade100,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: user.isAdmin ? Colors.red.shade700 : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(user.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.email),
                    if (user.phone?.isNotEmpty ?? false)
                      Text(user.phone!),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isAdmin ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: user.isAdmin ? Colors.red.shade200 : Colors.green.shade200,
                    ),
                  ),
                  child: Text(
                    user.isAdmin ? 'ADMIN' : 'CITIZEN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: user.isAdmin ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
                onTap: () => _showUserDetails(context, user),
              ),
            );
          },
        );
      },
    );
  }

  void _showUserDetails(BuildContext context, CivicUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('Email', user.email),
            if (user.phone?.isNotEmpty ?? false)
              _DetailRow('Phone', user.phone!),
            _DetailRow('Role', user.isAdmin ? 'Administrator' : 'Citizen'),
            _DetailRow('User ID', user.id),
            _DetailRow('Member Since', '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
            if (user.lastLoginAt != null)
              _DetailRow('Last Login', '${user.lastLoginAt!.day}/${user.lastLoginAt!.month}/${user.lastLoginAt!.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final reports = reportProvider.reports;

    if (reports.isEmpty) {
      return const Center(
        child: Text('No reports found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              _getCategoryIcon(report.category),
              color: _getStatusColor(report.status),
            ),
            title: Text(
              report.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '${_getCategoryLabel(report.category)} • ${report.location.address}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(report.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(report.status).withValues(alpha: 0.3)),
              ),
              child: Text(
                _getStatusLabel(report.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(report.status),
                ),
              ),
            ),
            onTap: () => _showReportActions(context, report, reportProvider),
          ),
        );
      },
    );
  }

  void _showReportActions(BuildContext context, ReportModel report, ReportProvider reportProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report.description),
            const SizedBox(height: 12),
            _DetailRow('Category', _getCategoryLabel(report.category)),
            _DetailRow('Status', _getStatusLabel(report.status)),
            _DetailRow('Location', report.location.address),
            _DetailRow('Reported', '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}'),
          ],
        ),
        actions: [
          if (report.status != ReportStatus.resolved) ...[
            TextButton(
              onPressed: () {
                reportProvider.updateStatus(report.id, ReportStatus.acknowledged);
                Navigator.pop(context);
              },
              child: const Text('Acknowledge'),
            ),
            TextButton(
              onPressed: () {
                reportProvider.updateStatus(report.id, ReportStatus.inProgress);
                Navigator.pop(context);
              },
              child: const Text('In Progress'),
            ),
            TextButton(
              onPressed: () {
                reportProvider.updateStatus(report.id, ReportStatus.resolved);
                Navigator.pop(context);
              },
              child: const Text('Resolve'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ReportCategory category) {
    switch (category) {
      case ReportCategory.pothole:
        return Icons.construction;
      case ReportCategory.garbage:
        return Icons.delete;
      case ReportCategory.streetlight:
        return Icons.lightbulb;
      case ReportCategory.other:
        return Icons.report_problem;
    }
  }

  String _getCategoryLabel(ReportCategory category) {
    switch (category) {
      case ReportCategory.pothole:
        return 'Pothole';
      case ReportCategory.garbage:
        return 'Garbage';
      case ReportCategory.streetlight:
        return 'Streetlight';
      case ReportCategory.other:
        return 'Other';
    }
  }

  String _getStatusLabel(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.acknowledged:
        return 'Acknowledged';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.resolved:
        return 'Resolved';
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.acknowledged:
        return Colors.blue;
      case ReportStatus.inProgress:
        return Colors.purple;
      case ReportStatus.resolved:
        return Colors.green;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}