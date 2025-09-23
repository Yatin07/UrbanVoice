import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/issue.dart';
import '../models/authority.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? _authorityId;
  Authority? _authority;
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAuthorityInfo();
  }

  Future<void> _loadAuthorityInfo() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get admin's authority ID from custom claims or admins collection
      final IdTokenResult tokenResult = await user.getIdTokenResult();
      _authorityId = tokenResult.claims?['authorityId'] as String?;

      // Fallback: check admins collection
      if (_authorityId == null) {
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .get();
        
        if (adminDoc.exists) {
          _authorityId = adminDoc.data()?['authorityId'];
        }
      }

      if (_authorityId != null) {
        final authorityDoc = await FirebaseFirestore.instance
            .collection('authorities')
            .doc(_authorityId!)
            .get();
        
        if (authorityDoc.exists) {
          _authority = Authority.fromFirestore(authorityDoc);
        }
      }
    } catch (e) {
      debugPrint('Error loading authority info: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_authorityId == null || _authority == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: const Center(
          child: Text(
            'Access denied. You are not assigned to any authority.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_authority!.name} Dashboard'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            initialValue: _selectedFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Issues')),
              const PopupMenuItem(value: 'Pending', child: Text('Pending')),
              const PopupMenuItem(value: 'InProgress', child: Text('In Progress')),
              const PopupMenuItem(value: 'Resolved', child: Text('Resolved')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedFilter),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          Expanded(child: _buildIssuesList()),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _authority!.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('District: ${_authority!.district}'),
            Text('State: ${_authority!.state}'),
            Text('Pincodes: ${_authority!.pincodes.join(', ')}'),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('issues')
                  .where('assignedTo', isEqualTo: _authorityId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                
                final issues = snapshot.data!.docs;
                final pending = issues.where((doc) => 
                    (doc.data() as Map<String, dynamic>)['status'] == 'Pending').length;
                final inProgress = issues.where((doc) => 
                    (doc.data() as Map<String, dynamic>)['status'] == 'InProgress').length;
                final resolved = issues.where((doc) => 
                    (doc.data() as Map<String, dynamic>)['status'] == 'Resolved').length;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total', issues.length, Colors.blue),
                    _buildStatItem('Pending', pending, Colors.orange),
                    _buildStatItem('In Progress', inProgress, Colors.purple),
                    _buildStatItem('Resolved', resolved, Colors.green),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildIssuesList() {
    Query query = FirebaseFirestore.instance
        .collection('issues')
        .where('assignedTo', isEqualTo: _authorityId)
        .orderBy('timestamp', descending: true);

    if (_selectedFilter != 'All') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final issues = snapshot.data!.docs
            .map((doc) => Issue.fromFirestore(doc))
            .toList();

        if (issues.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _selectedFilter == 'All' 
                      ? 'No issues assigned yet'
                      : 'No $_selectedFilter issues',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: issues.length,
          itemBuilder: (context, index) => _buildIssueCard(issues[index]),
        );
      },
    );
  }

  Widget _buildIssueCard(Issue issue) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showIssueDetails(issue),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.address,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${issue.latitude.toStringAsFixed(6)}, '
                          'Lng: ${issue.longitude.toStringAsFixed(6)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy hh:mm a')
                              .format(issue.timestamp.toDate()),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      issue.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(issue.status),
                  Row(
                    children: [
                      if (issue.status != IssueStatus.resolved)
                        ElevatedButton.icon(
                          onPressed: () => _updateIssueStatus(issue),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Update'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showIssueDetails(issue),
                        icon: const Icon(Icons.visibility),
                        tooltip: 'View Details',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(IssueStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case IssueStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case IssueStatus.inProgress:
        color = Colors.purple;
        label = 'In Progress';
        break;
      case IssueStatus.resolved:
        color = Colors.green;
        label = 'Resolved';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  void _showIssueDetails(Issue issue) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Issue Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          issue.imageUrl,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('Address', issue.address),
                      _buildDetailRow('Pincode', issue.pincode),
                      _buildDetailRow('Coordinates', 
                          'Lat: ${issue.latitude.toStringAsFixed(6)}, '
                          'Lng: ${issue.longitude.toStringAsFixed(6)}'),
                      _buildDetailRow('Reported', 
                          DateFormat('dd/MM/yyyy hh:mm a')
                              .format(issue.timestamp.toDate())),
                      _buildDetailRow('Status', issue.status.toString().split('.').last),
                      if (issue.remarks?.isNotEmpty == true)
                        _buildDetailRow('Remarks', issue.remarks!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (issue.status != IssueStatus.resolved)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateIssueStatus(issue);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Update Status'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  void _updateIssueStatus(Issue issue) {
    showDialog(
      context: context,
      builder: (context) => _UpdateStatusDialog(issue: issue),
    );
  }
}

class _UpdateStatusDialog extends StatefulWidget {
  final Issue issue;

  const _UpdateStatusDialog({required this.issue});

  @override
  State<_UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<_UpdateStatusDialog> {
  late IssueStatus _selectedStatus;
  final TextEditingController _remarksController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.issue.status;
    _remarksController.text = widget.issue.remarks ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Issue Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<IssueStatus>(
            value: _selectedStatus,
            decoration: const InputDecoration(labelText: 'Status'),
            items: IssueStatus.values.map((status) {
              String label;
              switch (status) {
                case IssueStatus.pending:
                  label = 'Pending';
                  break;
                case IssueStatus.inProgress:
                  label = 'In Progress';
                  break;
                case IssueStatus.resolved:
                  label = 'Resolved';
                  break;
              }
              return DropdownMenuItem(
                value: status,
                child: Text(label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedStatus = value!);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _remarksController,
            decoration: const InputDecoration(
              labelText: 'Remarks (Optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _updateStatus,
          child: _isUpdating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateStatus() async {
    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(widget.issue.id!)
          .update({
        'status': _selectedStatus.toString().split('.').last,
        'remarks': _remarksController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }
}
