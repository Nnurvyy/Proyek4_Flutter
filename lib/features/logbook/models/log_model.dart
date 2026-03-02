import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final ObjectId? id; 
  final String title;
  final String description;
  final DateTime date;
  final String category; 

  LogModel({
    this.id, 
    required this.title, 
    required this.description, 
    required this.date,
    required this.category, 
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(), 
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'category': category, 
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId?,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      category: map['category'] ?? 'Pribadi', 
    );
  }
}