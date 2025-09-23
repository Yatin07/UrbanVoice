import 'package:flutter/material.dart';

enum ReportCategory { pothole, garbage, streetlight, other }

enum ReportStatus { pending, acknowledged, inProgress, resolved }

@immutable
class GeoLocation {
  final double lat;
  final double lng;
  final String address;

  const GeoLocation({required this.lat, required this.lng, required this.address});
}

@immutable
class ReportModel {
  final String id;
  final String title;
  final String description;
  final ReportCategory category;
  final ReportStatus status;
  final GeoLocation location;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  const ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.location,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  ReportModel copyWith({
    String? id,
    String? title,
    String? description,
    ReportCategory? category,
    ReportStatus? status,
    GeoLocation? location,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return ReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      location: location ?? this.location,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }
}
