import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  List<_Step> _steps(String current) {
    const all = ['Pending', 'Acknowledged', 'In Progress', 'Resolved'];
    final idx = all.indexOf(current);
    return [
      for (var i = 0; i < all.length; i++) _Step(name: all[i], completed: i <= idx, current: i == idx),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    String label(String status) {
      switch (status) {
        case 'pending':
          return 'Pending';
        case 'acknowledged':
          return 'Acknowledged';
        case 'in_progress':
          return 'In Progress';
        case 'resolved':
          return 'Resolved';
        default:
          return 'Unknown';
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Track Reports')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: _StatCard(number: '0', label: 'My Reports', color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(number: '0', label: 'In Progress', color: Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(number: '0', label: 'Resolved', color: Colors.green)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('My Reports', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              if (true) // Always show empty state for now
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: const [
                        Icon(Icons.access_time, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No reports yet', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 4),
                        Text('Your submitted reports will appear here', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox.shrink(), // Remove the else block for now
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Tracking functionality coming soon',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String number;
  final String label;
  final Color color;
  const _StatCard({required this.number, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(number, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Step {
  final String name;
  final bool completed;
  final bool current;
  _Step({required this.name, required this.completed, required this.current});
}
