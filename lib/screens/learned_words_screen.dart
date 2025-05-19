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
  String? _selectedWordKey;
  
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
              child: filteredWords.isEmpty 
                ? Center(
                    child: Text(
                      'Немає вивчених слів',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                      ),
                    ),
                  )
                : ListView.builder(
                  itemCount: filteredWords.length,
                  itemBuilder: (context, index) {
                    final entry = filteredWords[index];
                    final isSelected = entry.key == _selectedWordKey;
                    
                    return Slidable(
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) async {
                              // Використовуємо спеціальний метод для позначення як невивчене
                              await provider.markWordAsUnlearned(entry.key);
                              
                              // Оновлюємо список вивчених слів після видалення
                              await provider.loadWords(
                                lessonName: _selectedLesson != 'Всі уроки' ? _selectedLesson : null,
                                showLearned: true,
                              );
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Слово "${entry.key}" повернуто до словника'),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            icon: Icons.refresh,
                            label: 'Повернути',
                          ),
                          SlidableAction(
                            onPressed: (_) async {
                              // Показуємо діалог підтвердження
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Видалення з вивчених'),
                                  content: Text('Ви впевнені, що хочете видалити "${entry.key}" зі списку вивчених слів?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Скасувати'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Видалити'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                // Використовуємо спеціальний метод для позначення як невивчене
                                await provider.markWordAsUnlearned(entry.key);
                                
                                // Оновлюємо список вивчених слів після видалення
                                await provider.loadWords(
                                  lessonName: _selectedLesson != 'Всі уроки' ? _selectedLesson : null,
                                  showLearned: true,
                                );
                                
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Слово "${entry.key}" видалено з вивчених'),
                                      backgroundColor: Colors.red[400],
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Видалити',
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
                          trailing: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedWordKey = entry.key;
                              });
                              _showWordOptions(context, provider, entry.key);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.grey[300] : Colors.green,
                              ),
                              child: Icon(
                                Icons.check,
                                color: isSelected ? Colors.grey[600] : Colors.white,
                              ),
                            ),
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
  
  // Показує опції для слова (видалити повністю або повернути до словника)
  void _showWordOptions(BuildContext context, WordTrainerProvider provider, String wordKey) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('Повернути до словника'),
            subtitle: const Text('Слово буде позначено як невивчене і з\'явиться в режимі тренування'),
            onTap: () async {
              Navigator.pop(context);
              await provider.markWordAsUnlearned(wordKey);
              
              // Оновлюємо список вивчених слів
              await provider.loadWords(
                lessonName: _selectedLesson != 'Всі уроки' ? _selectedLesson : null,
                showLearned: true,
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Слово "$wordKey" повернуто до словника'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Видалити повністю'),
            subtitle: const Text('Слово буде видалено з бази даних і зникне зі словника'),
            onTap: () async {
              Navigator.pop(context);
              
              // Показуємо діалог підтвердження
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Видалення слова'),
                  content: Text('Ви впевнені, що хочете повністю видалити слово "$wordKey"?\n\nЦю дію неможливо скасувати.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Скасувати'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Видалити', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                final success = await provider.deleteWord(wordKey);
                
                // Оновлюємо список після видалення
                await provider.loadWords(
                  lessonName: _selectedLesson != 'Всі уроки' ? _selectedLesson : null,
                  showLearned: true,
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                        ? 'Слово "$wordKey" видалено повністю' 
                        : 'Помилка при видаленні слова'
                      ),
                      backgroundColor: success ? Colors.red : Colors.grey,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 