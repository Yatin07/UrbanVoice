import 'package:cloud_firestore/cloud_firestore.dart';

class Authority {
  final String id;
  final String name;
  final String state;
  final String district;
  final List<String> pincodes;
  final GeoPoint center;
  final String adminUserId;
  final List<String> fcmTokens;
  final List<List<double>>? polygon; // Optional polygon as array of [lat, lng] pairs

  Authority({
    required this.id,
    required this.name,
    required this.state,
    required this.district,
    required this.pincodes,
    required this.center,
    required this.adminUserId,
    required this.fcmTokens,
    this.polygon,
  });

  factory Authority.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Authority(
      id: doc.id,
      name: data['name'] ?? '',
      state: data['state'] ?? '',
      district: data['district'] ?? '',
      pincodes: List<String>.from(data['pincodes'] ?? []),
      center: data['center'] ?? const GeoPoint(0, 0),
      adminUserId: data['adminUserId'] ?? '',
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
      polygon: data['polygon'] != null 
          ? List<List<double>>.from(
              (data['polygon'] as List).map((point) => List<double>.from(point))
            )
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'state': state,
      'district': district,
      'pincodes': pincodes,
      'center': center,
      'adminUserId': adminUserId,
      'fcmTokens': fcmTokens,
      if (polygon != null) 'polygon': polygon,
    };
  }
}
