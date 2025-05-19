import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_trainer_provider.dart';
import 'add_word_screen.dart';
import 'dictionary_screen.dart';
import 'training_mode_screen.dart';
import 'learned_words_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[100]!,
              Colors.blue[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '📚 Word Trainer',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildMenuButton(
                      context,
                      '➕ Додати слово',
                      const Color(0xFF3498DB),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddWordScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      context,
                      '📖 Словник',
                      const Color(0xFF2ECC71),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DictionaryScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      context,
                      '🏋️ Тренування',
                      const Color(0xFFE67E22),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TrainingModeScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      context,
                      '📝 Вивчені слова',
                      const Color(0xFFF1C40F),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LearnedWordsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 