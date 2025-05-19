import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/word.dart';
import '../models/lesson.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    try {
      // Check if Firestore is available and accessible
      await _firestore.collection('lessons').limit(1).get();
      print('Firebase Firestore initialized successfully');
    } catch (e) {
      print('Error initializing Firebase Firestore: $e');
      // You might want to implement retry logic here
      // For now, we'll just let the error propagate
      rethrow;
    }
  }

  Future<List<Lesson>> getLessons() async {
    try {
      final snapshot = await _firestore.collection('lessons').get();
      final lessons = snapshot.docs.map((doc) {
        final data = doc.data();
        data['name'] = doc.id; // Використовуємо ID документа як назву уроку
        return Lesson.fromMap(data);
      }).toList();

      lessons.sort((a, b) {
        if (a.name == 'Головний') return -1;
        if (b.name == 'Головний') return 1;
        return a.createdAt.compareTo(b.createdAt);
      });

      return lessons;
    } catch (e) {
      print('Error getting lessons: $e');
      return [];
    }
  }

  Future<Map<String, Word>> loadWords({String? lessonName, bool showLearned = false}) async {
    try {
      final Map<String, Word> words = {};
      Query query = _firestore.collection('words');

      if (lessonName != null && lessonName != "Всі уроки") {
        query = query.where('lesson', isEqualTo: lessonName);
      }
      query = query.where('learned', isEqualTo: showLearned);

      final snapshot = await query.get();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        words[doc.id] = Word.fromMap(data);
      }
      return words;
    } catch (e) {
      print('Error loading words: $e');
      return {};
    }
  }

  Future<bool> saveWord(Word word) async {
    try {
      final docRef = _firestore.collection('words').doc(word.english);
      final doc = await docRef.get();
      
      if (doc.exists) return false;
      
      await docRef.set(word.toMap());
      return true;
    } catch (e) {
      print('Error saving word: $e');
      return false;
    }
  }

  Future<bool> createLesson(Lesson lesson) async {
    try {
      print('Спроба створення уроку: ${lesson.name}');
      final docRef = _firestore.collection('lessons').doc(lesson.name);
      
      // Check if the lesson already exists
      try {
        final doc = await docRef.get();
        if (doc.exists) {
          print('Урок ${lesson.name} вже існує');
          return false;
        }
      } catch (e) {
        print('Помилка при перевірці існування уроку: $e');
        // Continue with creation attempt if checking fails
      }
      
      // Create the lesson document
      final data = lesson.toMap();
      print('Створення уроку з даними: $data');
      
      // Use set with merge option to handle potential concurrent operations
      await docRef.set(data, SetOptions(merge: true));
      
      // Verify creation was successful
      try {
        final verifyDoc = await docRef.get();
        if (verifyDoc.exists) {
          print('Урок ${lesson.name} успішно створено');
          return true;
        } else {
          print('Не вдалося перевірити створення уроку ${lesson.name}');
          return false;
        }
      } catch (e) {
        print('Помилка при перевірці створення уроку: $e');
        // Assume success if verification fails but no error during creation
        return true;
      }
    } catch (e) {
      print('Помилка при створенні уроку: $e');
      return false;
    }
  }

  Future<bool> renameLesson(String oldName, String newName) async {
    try {
      if (oldName == newName) return true;
      
      final newLessonRef = _firestore.collection('lessons').doc(newName);
      final newLessonDoc = await newLessonRef.get();
      
      if (newLessonDoc.exists) return false;

      final oldLessonRef = _firestore.collection('lessons').doc(oldName);
      final oldLessonDoc = await oldLessonRef.get();
      
      if (!oldLessonDoc.exists) return false;

      await _firestore.runTransaction((transaction) async {
        // Копіюємо дані старого уроку в новий
        transaction.set(newLessonRef, oldLessonDoc.data()!);
        
        // Видаляємо старий урок
        transaction.delete(oldLessonRef);

        // Оновлюємо всі слова, що належать до цього уроку
        final wordsSnapshot = await _firestore
            .collection('words')
            .where('lesson', isEqualTo: oldName)
            .get();

        for (var doc in wordsSnapshot.docs) {
          transaction.update(doc.reference, {'lesson': newName});
        }
      });

      return true;
    } catch (e) {
      print('Error renaming lesson: $e');
      return false;
    }
  }

  Future<bool> toggleWordLearned(String english) async {
    try {
      final docRef = _firestore.collection('words').doc(english);
      final doc = await docRef.get();
      
      if (!doc.exists) return false;

      final currentStatus = doc.data()!['learned'] as bool? ?? false;
      await docRef.update({'learned': !currentStatus});

      return true;
    } catch (e) {
      print('Error toggling word learned status: $e');
      return false;
    }
  }

  Future<bool> updateWord(String oldEnglish, String newEnglish, String newUkrainian, String newLesson) async {
    try {
      print('Спроба оновлення слова: $oldEnglish -> $newEnglish');
      
      // Якщо англійське слово не змінилося, просто оновлюємо документ
      if (oldEnglish == newEnglish) {
        final docRef = _firestore.collection('words').doc(oldEnglish);
        final doc = await docRef.get();
        
        if (!doc.exists) {
          print('Слово $oldEnglish не знайдено');
          return false;
        }
        
        // Зберігаємо поточний статус вивчення
        final currentLearned = doc.data()?['learned'] as bool? ?? false;
        
        print('Оновлюємо існуюче слово: $oldEnglish, $newUkrainian, $newLesson, learned=$currentLearned');
        
        // Оновлюємо документ з оновленими полями
        await docRef.update({
          'english': newEnglish,
          'ukrainian': newUkrainian,
          'lesson': newLesson,
          'learned': currentLearned, // Зберігаємо статус вивчення
        });
        
        print('Слово $oldEnglish успішно оновлено');
        return true;
      } 
      // Якщо англійське слово змінилося, потрібно створити новий документ і видалити старий
      else {
        // Перевіряємо, чи існує новий документ
        final newDocRef = _firestore.collection('words').doc(newEnglish);
        final newDoc = await newDocRef.get();
        
        if (newDoc.exists) {
          print('Слово $newEnglish вже існує');
          return false;
        }
        
        // Отримуємо старий документ
        final oldDocRef = _firestore.collection('words').doc(oldEnglish);
        final oldDoc = await oldDocRef.get();
        
        if (!oldDoc.exists) {
          print('Слово $oldEnglish не знайдено');
          return false;
        }
        
        // Зберігаємо поточний статус вивчення
        final currentLearned = oldDoc.data()?['learned'] as bool? ?? false;
        
        print('Створюємо нове слово замість старого: $oldEnglish -> $newEnglish');
        
        // Створюємо новий документ з даними
        final wordData = {
          'english': newEnglish,
          'ukrainian': newUkrainian,
          'lesson': newLesson,
          'learned': currentLearned,
        };
        
        print('Нові дані: $wordData');
        
        // Використовуємо окремі операції для гарантованого результату
        await newDocRef.set(wordData);
        await oldDocRef.delete();
        
        print('Слово $oldEnglish успішно оновлено на $newEnglish');
        return true;
      }
    } catch (e) {
      print('Помилка при оновленні слова: $e');
      return false;
    }
  }
} 