import 'package:uuid/uuid.dart';

class Report {
  final String id;
  final String title;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final String imagePath;
  final String status;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final bool isSynced;

  Report({
    String? id,
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.imagePath,
    this.status = 'pending',
    required this.createdAt,
    this.syncedAt,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4();

  // Convertir a Map para la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'imagePath': imagePath,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  // Crear desde Map
  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: map['category'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      imagePath: map['imagePath'],
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
      syncedAt:
          map['syncedAt'] != null ? DateTime.parse(map['syncedAt']) : null,
      isSynced: map['isSynced'] == 1,
    );
  }

  // Convertir a JSON para la API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} '
        '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}
