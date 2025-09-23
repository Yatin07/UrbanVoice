import 'package:flutter/material.dart';
import '../models/report.dart';

class StatusBadge extends StatelessWidget {
  final ReportStatus status;
  final bool small;
  const StatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = {
      ReportStatus.pending: (Colors.yellow.shade100, Colors.yellow.shade800),
      ReportStatus.acknowledged: (Colors.blue.shade100, Colors.blue.shade800),
      ReportStatus.inProgress: (Colors.orange.shade100, Colors.orange.shade800),
      ReportStatus.resolved: (Colors.green.shade100, Colors.green.shade800),
    };
    final colors = map[status]!;
    final label = {
      ReportStatus.pending: 'Pending',
      ReportStatus.acknowledged: 'Acknowledged',
      ReportStatus.inProgress: 'In Progress',
      ReportStatus.resolved: 'Resolved',
    }[status]!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12, vertical: small ? 4 : 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.$2,
          fontWeight: FontWeight.w600,
          fontSize: small ? 10 : 12,
        ),
      ),
    );
  }
}
