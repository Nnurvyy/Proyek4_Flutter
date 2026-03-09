import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:hive/hive.dart';

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String category; 

  @HiveField(5)
  final String authorId;

  @HiveField(6)
  final String teamId;

  @HiveField(7)
  bool isSynced;

  @HiveField(8)
  bool isPublic;

  LogModel({
    this.id, 
    required this.title, 
    required this.description, 
    required this.date,
    required this.category, 
    required this.authorId,
    required this.teamId,
    this.isSynced = true,
    this.isPublic = false,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(), 
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'category': category, 
      'authorId': authorId,
      'teamId': teamId,
      'isPublic': isPublic,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    // [PERBAIKAN] Konversi ObjectId dari MongoDB menjadi String untuk Hive
    String? logId;
    if (map['_id'] != null) {
      if (map['_id'] is ObjectId) {
        logId = (map['_id'] as ObjectId).oid; // Ambil nilai string (oid) nya
      } else {
        logId = map['_id'].toString();
      }
    }

    return LogModel(
      id: logId, // Masukkan variabel logId yang sudah berwujud String
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      category: map['category'] ?? 'Pribadi', 
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
      isSynced: true,
      isPublic: map['isPublic'] ?? false,
    );
  }
}