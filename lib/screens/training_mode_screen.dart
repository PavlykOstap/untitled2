import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_trainer_provider.dart';
import 'training_screen.dart';

class TrainingModeScreen extends StatefulWidget {
  const TrainingModeScreen({super.key});

  @override
  State<TrainingModeScreen> createState() => _TrainingModeScreenState();
}

class _TrainingModeScreenState extends State<TrainingModeScreen> {
  String _selectedLesson = 'Головний';

  @override
  void initState() {
    super.initState();
    // Завантажуємо уроки та перевіряємо значення за замовчуванням
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<WordTrainerProvider>(context, listen: false);
        final lessons = provider.lessons;
        if (lessons.isNotEmpty) {
          final uniqueLessons = lessons.map((e) => e.name).toSet().toList();
          if (!uniqueLessons.contains(_selectedLesson) && uniqueLessons.isNotEmpty) {
            setState(() {
              _selectedLesson = uniqueLessons.first;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WordTrainerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренування'),
        backgroundColor: const Color(0xFFE67E22),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Оновити список уроків',
            onPressed: () async {
              final provider = Provider.of<WordTrainerProvider>(context, listen: false);
              
              // Показуємо сповіщення про початок оновлення
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Оновлення списку уроків...'),
                  duration: Duration(seconds: 1),
                ),
              );
              
              // Оновлюємо список уроків
              await provider.loadLessons();
              
              if (!mounted) return;
              
              // Перевіряємо, чи обраний урок досі існує
              final uniqueLessons = provider.lessons.map((e) => e.name).toSet().toList();
              if (!uniqueLessons.contains(_selectedLesson) && uniqueLessons.isNotEmpty) {
                setState(() {
                  _selectedLesson = uniqueLessons.first;
                });
                
                // Завантажуємо слова для нового уроку
                await provider.loadWords(lessonName: _selectedLesson);
              }
              
              if (!mounted) return;
              
              // Повідомляємо про успішне оновлення
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Список уроків оновлено'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange[100]!,
              Colors.orange[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '🏋️ Тренування',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Оберіть урок:',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF34495E),
                  ),
                ),
                const SizedBox(height: 10),
                _buildLessonDropdown(provider),
                const SizedBox(height: 40),
                const Text(
                  'Оберіть режим:',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF34495E),
                  ),
                ),
                const SizedBox(height: 20),
                _buildModeButton(
                  context,
                  '🇬🇧 Англійська ➡️ 🇺🇦 Українська',
                  const Color(0xFF3498DB),
                  () => _startTraining(context, provider, 'EN-UA'),
                ),
                const SizedBox(height: 16),
                _buildModeButton(
                  context,
                  '🇺🇦 Українська ➡️ 🇬🇧 Англійська',
                  const Color(0xFF2ECC71),
                  () => _startTraining(context, provider, 'UA-EN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonDropdown(WordTrainerProvider provider) {
    // Створюємо список унікальних уроків
    final uniqueLessons = provider.lessons.map((e) => e.name).toSet().toList();
    
    // Перевіряємо, чи обраний урок є в списку
    final selectedValue = uniqueLessons.contains(_selectedLesson) 
        ? _selectedLesson 
        : uniqueLessons.isNotEmpty 
            ? uniqueLessons.first 
            : null;
            
    if (selectedValue != _selectedLesson && selectedValue != null) {
      // Оновлюємо обраний урок, якщо він не є валідним
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _selectedLesson = selectedValue;
          });
        }
      });
    }
    
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.book),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: uniqueLessons.isEmpty
          ? [const DropdownMenuItem(value: '', child: Text('Немає уроків'))]
          : uniqueLessons
              .map((lessonName) => DropdownMenuItem(
                    value: lessonName,
                    child: Text(lessonName),
                  ))
              .toList(),
      onChanged: uniqueLessons.isEmpty 
          ? null 
          : (value) {
              if (value != null) {
                setState(() {
                  _selectedLesson = value;
                });
                provider.loadWords(lessonName: value);
              }
            },
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _startTraining(
    BuildContext context,
    WordTrainerProvider provider,
    String mode,
  ) {
    // Перевіряємо, чи існує вибраний урок
    final uniqueLessons = provider.lessons.map((e) => e.name).toSet().toList();
    if (!uniqueLessons.contains(_selectedLesson)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Обраний урок недоступний. Виберіть інший урок.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final words = provider.words.values.where((word) => !word.learned).toList();
    
    if (words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Немає слів для тренування в цьому уроці'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    provider.startTraining(mode);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingScreen(mode: mode),
      ),
    );
  }
} 