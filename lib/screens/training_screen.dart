import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_trainer_provider.dart';

class TrainingScreen extends StatefulWidget {
  final String mode;

  const TrainingScreen({
    super.key,
    required this.mode,
  });

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final _answerController = TextEditingController();
  bool _showError = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WordTrainerProvider>(context);
    
    if (provider.isTrainingComplete) {
      return _buildResultScreen(context, provider);
    }

    final currentWord = provider.trainingWords[provider.trainingIndex];
    final questionWord = widget.mode == 'EN-UA'
        ? currentWord.english
        : currentWord.ukrainian;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренування'),
        backgroundColor: const Color(0xFFE67E22),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          'Переклад слова:',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          questionWord,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    labelText: 'Ваша відповідь',
                    errorText: _showError ? _errorMessage : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  enableSuggestions: false,
                  autocorrect: false,
                  enableIMEPersonalizedLearning: false,
                  onSubmitted: (_) => _checkAnswer(context, provider),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _checkAnswer(context, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Перевірити',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Слово ${provider.trainingIndex + 1} з ${provider.trainingWords.length}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen(BuildContext context, WordTrainerProvider provider) {
    final accuracy = provider.trainingAccuracy;
    
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
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.celebration,
                    size: 80,
                    color: Color(0xFF2ECC71),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Тренування завершено!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Точність: ${accuracy.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFF34495E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Помилок: ${provider.mistakeCount}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFF34495E),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3498DB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Завершити',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _checkAnswer(BuildContext context, WordTrainerProvider provider) {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      setState(() {
        _showError = true;
        _errorMessage = 'Введіть відповідь';
      });
      return;
    }

    final isCorrect = provider.checkAnswer(answer);
    setState(() {
      _showError = !isCorrect;
      _errorMessage = isCorrect ? '' : 'Неправильна відповідь';
    });

    if (isCorrect) {
      _answerController.clear();
    }
  }
} 