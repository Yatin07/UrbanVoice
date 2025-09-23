import 'package:cloud_firestore/cloud_firestore.dart';

enum IssueStatus { pending, inProgress, resolved }

class Issue {
  final String? id;
  final String imageUrl;
  final String? thumbUrl;
  final double latitude;
  final double longitude;
  final String address;
  final String pincode;
  final Timestamp timestamp;
  final IssueStatus status;
  final String? assignedTo;
  final String userId;
  final String? originalImageName;
  final String? storagePath;
  final String? remarks;

  Issue({
    this.id,
    required this.imageUrl,
    this.thumbUrl,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.pincode,
    required this.timestamp,
    this.status = IssueStatus.pending,
    this.assignedTo,
    required this.userId,
    this.originalImageName,
    this.storagePath,
    this.remarks,
  });

  factory Issue.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Issue(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      thumbUrl: data['thumbUrl'],
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      pincode: data['pincode'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      status: _statusFromString(data['status'] ?? 'Pending'),
      assignedTo: data['assignedTo'],
      userId: data['userId'] ?? '',
      originalImageName: data['originalImageName'],
      storagePath: data['storagePath'],
      remarks: data['remarks'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      if (thumbUrl != null) 'thumbUrl': thumbUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'pincode': pincode,
      'timestamp': timestamp,
      'status': _statusToString(status),
      if (assignedTo != null) 'assignedTo': assignedTo,
      'userId': userId,
      if (originalImageName != null) 'originalImageName': originalImageName,
      if (storagePath != null) 'storagePath': storagePath,
      if (remarks != null) 'remarks': remarks,
    };
  }

  Issue copyWith({
    String? id,
    String? imageUrl,
    String? thumbUrl,
    double? latitude,
    double? longitude,
    String? address,
    String? pincode,
    Timestamp? timestamp,
    IssueStatus? status,
    String? assignedTo,
    String? userId,
    String? originalImageName,
    String? storagePath,
    String? remarks,
  }) {
    return Issue(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      userId: userId ?? this.userId,
      originalImageName: originalImageName ?? this.originalImageName,
      storagePath: storagePath ?? this.storagePath,
      remarks: remarks ?? this.remarks,
    );
  }

  static IssueStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'inprogress':
      case 'in_progress':
        return IssueStatus.inProgress;
      case 'resolved':
        return IssueStatus.resolved;
      default:
        return IssueStatus.pending;
    }
  }

  static String _statusToString(IssueStatus status) {
    switch (status) {
      case IssueStatus.inProgress:
        return 'InProgress';
      case IssueStatus.resolved:
        return 'Resolved';
      default:
        return 'Pending';
    }
  }
}
