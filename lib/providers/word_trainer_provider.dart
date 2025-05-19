import 'package:flutter/foundation.dart';
import '../models/word.dart';
import '../models/lesson.dart';
import '../services/database_service.dart';

class WordTrainerProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  Map<String, Word> _words = {};
  List<Lesson> _lessons = [];
  String _currentLesson = 'Головний';
  List<Word> _trainingWords = [];
  int _trainingIndex = 0;
  int _mistakeCount = 0;
  String _trainingMode = 'EN-UA';
  bool _isLoading = false;

  Map<String, Word> get words => _words;
  List<Lesson> get lessons => _lessons;
  String get currentLesson => _currentLesson;
  List<Word> get trainingWords => _trainingWords;
  int get trainingIndex => _trainingIndex;
  int get mistakeCount => _mistakeCount;
  String get trainingMode => _trainingMode;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _setLoading(true);
    await _db.initialize();
    await loadLessons();
    await loadWords();
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadLessons() async {
    final fetchedLessons = await _db.getLessons();
    
    // Create a map to deduplicate lessons by name
    final Map<String, Lesson> uniqueLessons = {};
    
    // Keep only one lesson with each name (the first one encountered)
    for (final lesson in fetchedLessons) {
      if (!uniqueLessons.containsKey(lesson.name)) {
        uniqueLessons[lesson.name] = lesson;
      }
    }
    
    // Convert back to list
    _lessons = uniqueLessons.values.toList();
    
    notifyListeners();
  }

  Future<void> loadWords({String? lessonName, bool showLearned = false}) async {
    _words = await _db.loadWords(
      lessonName: lessonName,
      showLearned: showLearned,
    );
    notifyListeners();
  }

  Future<bool> addWord(String english, String ukrainian, String lesson) async {
    final word = Word(
      english: english,
      ukrainian: ukrainian,
      lesson: lesson,
    );
    
    final success = await _db.saveWord(word);
    if (success) {
      _words[english] = word;
      notifyListeners();
    }
    return success;
  }

  Future<bool> createNewLesson(String? name, {String description = ''}) async {
    if (name == null || name.trim().isEmpty) return false;
    
    try {
      final lesson = Lesson(
        name: name.trim(),
        description: description,
      );
      
      // Add the lesson to the local list first with a loading indicator
      final int insertIndex = _lessons.length;
      _lessons.add(lesson);
      notifyListeners();
      
      final success = await _db.createLesson(lesson);
      
      if (!success) {
        // Remove the lesson if Firebase operation failed
        if (insertIndex < _lessons.length) {
          _lessons.removeAt(insertIndex);
        }
        notifyListeners();
        return false;
      }
      
      // No need to add again since we already added it
      notifyListeners();
      return true;
    } catch (e) {
      print('Error in createNewLesson: $e');
      // Notify listeners to refresh UI if there was an error
      notifyListeners();
      return false;
    }
  }

  Future<bool> renameLesson(String oldName, String newName) async {
    final success = await _db.renameLesson(oldName, newName);
    if (success) {
      await loadLessons();
      await loadWords(lessonName: newName);
    }
    return success;
  }

  Future<void> toggleWordLearned(String english) async {
    final success = await _db.toggleWordLearned(english);
    if (success && _words.containsKey(english)) {
      _words[english]!.learned = !_words[english]!.learned;
      notifyListeners();
    }
  }

  Future<bool> updateWord(String oldEnglish, String newEnglish, String newUkrainian, String newLesson) async {
    try {
      print('Провайдер: починаємо оновлення слова $oldEnglish -> $newEnglish');
      
      // Перевіряємо, чи існує урок
      final lessonExists = _lessons.any((lesson) => lesson.name == newLesson);
      if (!lessonExists) {
        print('Провайдер: урок "$newLesson" не знайдено');
        // Якщо урок не існує, використовуємо перший доступний або 'Головний'
        if (_lessons.isNotEmpty) {
          newLesson = _lessons.first.name;
          print('Провайдер: вибираємо перший доступний урок: $newLesson');
        } else {
          newLesson = 'Головний';
          print('Провайдер: вибираємо урок за замовчуванням: $newLesson');
        }
      }
      
      // Спочатку оновлюємо слово в базі даних
      final success = await _db.updateWord(oldEnglish, newEnglish, newUkrainian, newLesson);
      
      if (success) {
        print('Провайдер: база даних оновлена успішно, оновлюємо локальний стан');
        
        // Якщо англійське слово не змінилося, просто оновлюємо поля
        if (oldEnglish == newEnglish) {
          if (_words.containsKey(oldEnglish)) {
            final isLearned = _words[oldEnglish]!.learned;
            print('Провайдер: оновлюємо існуюче слово, isLearned=$isLearned');
            
            _words[oldEnglish] = Word(
              english: newEnglish,
              ukrainian: newUkrainian,
              lesson: newLesson,
              learned: isLearned,
            );
          }
        } 
        // Якщо англійське слово змінилося, видаляємо старе і додаємо нове
        else {
          final isLearned = _words.containsKey(oldEnglish) ? _words[oldEnglish]!.learned : false;
          print('Провайдер: заміна слова, isLearned=$isLearned');
          
          // Видаляємо старе слово
          _words.remove(oldEnglish);
          
          // Додаємо нове слово
          _words[newEnglish] = Word(
            english: newEnglish,
            ukrainian: newUkrainian,
            lesson: newLesson,
            learned: isLearned,
          );
        }
        
        // Обов'язкове оновлення інтерфейсу
        print('Провайдер: повідомляємо слухачів про зміни');
        notifyListeners();
        
        // Перезавантажуємо слова, щоб оновити повний список
        print('Провайдер: перезавантажуємо список слів');
        String? lessonToLoad = _currentLesson != 'Головний' ? _currentLesson : null;
        await loadWords(lessonName: lessonToLoad);
        
        return true;
      } else {
        print('Провайдер: помилка при оновленні в базі даних');
        return false;
      }
    } catch (e) {
      print('Помилка при оновленні слова в провайдері: $e');
      return false;
    }
  }

  void startTraining(String mode) {
    _trainingMode = mode;
    _trainingWords = _words.values.where((word) => !word.learned).toList();
    _trainingWords.shuffle();
    _trainingIndex = 0;
    _mistakeCount = 0;
    notifyListeners();
  }

  bool checkAnswer(String answer) {
    if (_trainingIndex >= _trainingWords.length) return false;

    final currentWord = _trainingWords[_trainingIndex];
    final correctAnswer = _trainingMode == 'EN-UA' 
        ? currentWord.ukrainian.toLowerCase().trim()
        : currentWord.english.toLowerCase().trim();
    
    final isCorrect = answer.toLowerCase().trim() == correctAnswer;
    
    if (!isCorrect) {
      _mistakeCount++;
    } else {
      _trainingIndex++;
    }
    
    notifyListeners();
    return isCorrect;
  }

  bool get isTrainingComplete => _trainingIndex >= _trainingWords.length;

  double get trainingAccuracy {
    if (_trainingWords.isEmpty) return 0.0;
    return ((_trainingWords.length - _mistakeCount) / _trainingWords.length) * 100;
  }

  void setCurrentLesson(String lessonName) {
    _currentLesson = lessonName;
    notifyListeners();
  }
} 