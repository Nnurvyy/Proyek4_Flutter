class LogModel {
  final String title;
  final String description;
  DateTime timestamp;
  final String category;

  LogModel({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.category,
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'],
      description: map['description'],
      timestamp: DateTime.parse(map['timestamp']),
      category: map['category'] ?? 'Pribadi',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title, 
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
    };
  }
}