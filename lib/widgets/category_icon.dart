import 'package:flutter/material.dart';
import '../models/report.dart';

class CategoryIcon extends StatelessWidget {
  final ReportCategory category;
  final Color? color;
  final double size;
  const CategoryIcon({super.key, required this.category, this.color, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.primary;
    IconData icon;
    switch (category) {
      case ReportCategory.pothole:
        icon = Icons.directions_car;
        break;
      case ReportCategory.garbage:
        icon = Icons.delete_outline;
        break;
      case ReportCategory.streetlight:
        icon = Icons.lightbulb_outline;
        break;
      case ReportCategory.other:
        icon = Icons.warning_amber_outlined;
        break;
    }
    return Icon(icon, color: iconColor, size: size);
  }
}
