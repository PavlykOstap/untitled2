class Word {
  final String english;
  final String ukrainian;
  bool learned;
  final String lesson;

  Word({
    required this.english,
    required this.ukrainian,
    this.learned = false,
    this.lesson = 'Головний',
  });

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      english: map['english'] as String,
      ukrainian: map['ukrainian'] as String,
      learned: map['learned'] as bool? ?? false,
      lesson: map['lesson'] as String? ?? 'Головний',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'english': english,
      'ukrainian': ukrainian,
      'learned': learned,
      'lesson': lesson,
    };
  }
} 