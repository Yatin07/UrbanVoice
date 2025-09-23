import 'package:flutter/foundation.dart';

enum UserRole { citizen, admin }

@immutable
class CivicUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const CivicUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory CivicUser.fromMap(Map<String, dynamic> map) {
    return CivicUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.citizen,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
    };
  }

  CivicUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return CivicUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isCitizen => role == UserRole.citizen;
  
  // Firebase compatibility getters
  String get uid => id;
  String? get displayName => name;
  String? get phoneNumber => phone;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CivicUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CivicUser(id: $id, name: $name, email: $email, phone: $phone, role: $role)';
  }
}
