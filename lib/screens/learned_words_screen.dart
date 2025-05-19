import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/word_trainer_provider.dart';

class LearnedWordsScreen extends StatefulWidget {
  const LearnedWordsScreen({super.key});

  @override
  State<LearnedWordsScreen> createState() => _LearnedWordsScreenState();
}

class _LearnedWordsScreenState extends State<LearnedWordsScreen> {
  final _searchController = TextEditingController();
  String _selectedLesson = 'Всі уроки';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WordTrainerProvider>(context, listen: false);
      provider.loadWords(showLearned: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WordTrainerProvider>(context);
    final words = provider.words.entries.toList();
    final filteredWords = words.where((entry) {
      final searchTerm = _searchController.text.toLowerCase();
      return (_selectedLesson == 'Всі уроки' ||
              entry.value.lesson == _selectedLesson) &&
          (entry.key.toLowerCase().contains(searchTerm) ||
              entry.value.ukrainian.toLowerCase().contains(searchTerm));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Вивчені слова'),
        backgroundColor: const Color(0xFFF1C40F),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.yellow[100]!,
              Colors.yellow[50]!,
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Пошук',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    enableSuggestions: false,
                    autocorrect: false,
                    enableIMEPersonalizedLearning: false,
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedLesson,
                    decoration: InputDecoration(
                      labelText: 'Урок',
                      prefixIcon: const Icon(Icons.book),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'Всі уроки',
                        child: Text('Всі уроки'),
                      ),
                      ...provider.lessons.map(
                        (lesson) => DropdownMenuItem(
                          value: lesson.name,
                          child: Text(lesson.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedLesson = value;
                        });
                        provider.loadWords(
                          lessonName: value,
                          showLearned: true,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredWords.length,
                itemBuilder: (context, index) {
                  final entry = filteredWords[index];
                  return Slidable(
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) async {
                            await provider.toggleWordLearned(entry.key);
                          },
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          icon: Icons.refresh,
                          label: 'Повторити',
                        ),
                      ],
                    ),
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.value.ukrainian),
                            Text(
                              'Урок: ${entry.value.lesson}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 