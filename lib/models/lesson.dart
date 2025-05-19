class Lesson {
  final String name;
  final String description;
  final DateTime createdAt;

  Lesson({
    required this.name,
    this.description = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Lesson.fromMap(Map<String, dynamic> map) {
    final name = map['name']?.toString();
    if (name == null) {
      throw FormatException('Name is required for Lesson');
    }
    
    return Lesson(
      name: name,
      description: map['description']?.toString() ?? '',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 