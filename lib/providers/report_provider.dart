import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/report.dart';
import '../models/user.dart';

class ReportProvider extends ChangeNotifier {
  final List<ReportModel> _reports = [];
  final _uuid = const Uuid();

  List<ReportModel> get reports => List.unmodifiable(_reports);

  ReportProvider() {
    _seedSample();
  }

  void _seedSample() {
    _reports.addAll([
      ReportModel(
        id: '1',
        title: 'Large pothole on Main Street',
        description: 'Deep pothole causing vehicle damage near the traffic light',
        category: ReportCategory.pothole,
        status: ReportStatus.inProgress,
        location: const GeoLocation(
          lat: 19.0760,
          lng: 72.8777,
          address: 'Main Street, Andheri West, Mumbai',
        ),
        images: const ['https://images.pexels.com/photos/1051747/pexels-photo-1051747.jpeg'],
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 16),
        userId: 'user1',
      ),
      ReportModel(
        id: '2',
        title: 'Garbage accumulation',
        description: 'Overflowing garbage bin attracting stray animals',
        category: ReportCategory.garbage,
        status: ReportStatus.acknowledged,
        location: const GeoLocation(
          lat: 19.0896,
          lng: 72.8656,
          address: 'Linking Road, Bandra West, Mumbai',
        ),
        images: const ['https://images.pexels.com/photos/2827754/pexels-photo-2827754.jpeg'],
        createdAt: DateTime(2024, 1, 14),
        updatedAt: DateTime(2024, 1, 15),
        userId: 'user2',
      ),
    ]);
  }

  void addReport({
    required String title,
    required String description,
    required ReportCategory category,
    required GeoLocation location,
    required List<String> images,
    required String userId,
  }) {
    final now = DateTime.now();
    final model = ReportModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      category: category,
      status: ReportStatus.pending,
      location: location,
      images: images,
      createdAt: now,
      updatedAt: now,
      userId: userId,
    );
    _reports.insert(0, model);
    notifyListeners();
  }

  void updateStatus(String id, ReportStatus status) {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _reports[index] = _reports[index].copyWith(status: status, updatedAt: DateTime.now());
    notifyListeners();
  }

  List<ReportModel> myReportsFor(CivicUser? user) {
    if (user == null) return const [];
    return _reports.where((r) => r.userId == user.id).toList(growable: false);
  }
}
