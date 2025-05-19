import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/word_trainer_provider.dart';
import '../models/word.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _searchController = TextEditingController();
  String _selectedLesson = 'Всі уроки';
  String? _selectedWordKey;
  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
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

    // Create the list of lesson names, including 'Всі уроки'
    final List<String> lessonNames = ['Всі уроки'];
    // Add unique lesson names from provider
    lessonNames.addAll(provider.lessons.map((lesson) => lesson.name).toSet());
    
    // Ensure _selectedLesson exists in the list, defaulting to 'Всі уроки' if not
    if (!lessonNames.contains(_selectedLesson)) {
      print('Selected lesson "$_selectedLesson" not found in lessons, resetting to default');
      _selectedLesson = 'Всі уроки';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Словник'),
        backgroundColor: const Color(0xFF2ECC71),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Меню редагування',
            onPressed: () => _showEditOptions(context, provider),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green[100]!,
              Colors.green[50]!,
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
                    items: lessonNames.map((name) => DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedLesson = value;
                          _selectedWordKey = null; // Скидаємо вибране слово при зміні уроку
                        });
                        provider.loadWords(lessonName: value);
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
                  final isSelected = entry.key == _selectedWordKey;
                  
                  return Slidable(
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) async {
                            await provider.toggleWordLearned(entry.key);
                          },
                          backgroundColor: entry.value.learned
                              ? Colors.orange
                              : Colors.green,
                          foregroundColor: Colors.white,
                          icon: entry.value.learned
                              ? Icons.refresh
                              : Icons.check,
                          label:
                              entry.value.learned ? 'Повторити' : 'Вивчено',
                        ),
                        SlidableAction(
                          onPressed: (_) {
                            setState(() {
                              _selectedWordKey = entry.key;
                            });
                            _editSelectedWord(context, provider);
                          },
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.edit,
                          label: 'Редагувати',
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () {
                        // Вибираємо/скасовуємо вибір слова при натисканні
                        setState(() {
                          _selectedWordKey = isSelected ? null : entry.key;
                        });
                      },
                      onLongPress: () {
                        // Показуємо контекстне меню при довгому натисканні
                        _showWordContextMenu(context, provider, entry.key);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        color: isSelected ? Colors.green[50] : null,
                        shape: isSelected 
                          ? RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Colors.green, width: 2),
                            )
                          : null,
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (entry.value.learned)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              if (isSelected)
                                const Icon(
                                  Icons.radio_button_checked,
                                  color: Colors.green,
                                ),
                            ],
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

  void _showNoWordSelectedMessage(BuildContext context) {
    if (!mounted) return;
    _scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Спочатку оберіть слово для редагування'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _editSelectedWord(
    BuildContext context,
    WordTrainerProvider provider,
  ) async {
    if (!mounted) return;
    
    if (_selectedWordKey == null) {
      _showNoWordSelectedMessage(context);
      return;
    }

    final selectedWord = provider.words[_selectedWordKey!];
    if (selectedWord == null) {
      if (!mounted) return;
      _scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Обране слово не знайдено'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final englishController = TextEditingController(text: _selectedWordKey);
    final ukrainianController = TextEditingController(text: selectedWord.ukrainian);
    String selectedLesson = selectedWord.lesson;

    // Get unique lesson names
    final List<String> lessonNames = provider.lessons
        .map((lesson) => lesson.name)
        .toSet()
        .toList();
    
    // Ensure the selected lesson exists in the list
    if (!lessonNames.contains(selectedLesson) && lessonNames.isNotEmpty) {
      selectedLesson = lessonNames.first;
    }

    try {
      // Показуємо діалог для редагування
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Редагувати слово'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: englishController,
                    decoration: const InputDecoration(
                      labelText: 'Англійське слово',
                      border: OutlineInputBorder(),
                    ),
                    enableSuggestions: false,
                    autocorrect: false,
                    enableIMEPersonalizedLearning: false,
                    onSubmitted: (_) {
                      // При натисканні Enter переходимо до наступного поля
                      FocusScope.of(context).nextFocus();
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ukrainianController,
                    decoration: const InputDecoration(
                      labelText: 'Український переклад',
                      border: OutlineInputBorder(),
                    ),
                    enableSuggestions: false,
                    autocorrect: false,
                    enableIMEPersonalizedLearning: false,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedLesson,
                    decoration: const InputDecoration(
                      labelText: 'Урок',
                      border: OutlineInputBorder(),
                    ),
                    items: lessonNames.map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedLesson = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Скасувати'),
              ),
              TextButton(
                onPressed: () {
                  if (englishController.text.isEmpty || ukrainianController.text.isEmpty) {
                    return;
                  }
                  Navigator.pop(context, {
                    'english': englishController.text.trim(),
                    'ukrainian': ukrainianController.text.trim(),
                    'lesson': selectedLesson,
                  });
                },
                child: const Text('Зберегти'),
              ),
            ],
          ),
        ),
      );

      // Обробляємо результат - перевіряємо mounted перед продовженням
      if (result != null) {
        if (!mounted) return;
        
        final oldKey = _selectedWordKey!;
        final newEnglish = result['english'] as String;
        final newUkrainian = result['ukrainian'] as String;
        final newLesson = result['lesson'] as String;

        try {
          // Показуємо індикатор завантаження - використовуємо кешований месенджер
          if (!mounted) return;
          _scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Оновлення слова...'),
              duration: Duration(seconds: 1),
            ),
          );

          final success = await provider.updateWord(
            oldKey, 
            newEnglish, 
            newUkrainian, 
            newLesson
          );

          if (!mounted) return;

          if (success) {
            // Оновлюємо вибране слово, якщо змінилося англійське слово
            setState(() {
              _selectedWordKey = newEnglish;
            });

            _scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Слово успішно оновлено'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            _scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Помилка оновлення слова'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          print('Помилка при оновленні слова після діалогу: $e');
          if (!mounted) return;
          _scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Помилка: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Помилка при редагуванні слова: $e');
      // Використовуємо кешований месенджер замість ScaffoldMessenger.of(context)
      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Помилка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Безпечно утилізуємо контролери після повного закриття діалогу
      if (mounted) {
        // Використовуємо post-frame callback для безпечної утилізації
        WidgetsBinding.instance.addPostFrameCallback((_) {
          englishController.dispose();
          ukrainianController.dispose();
        });
      } else {
        englishController.dispose();
        ukrainianController.dispose();
      }
    }
  }
  
  Future<void> _renameLesson(
    BuildContext context,
    WordTrainerProvider provider,
  ) async {
    if (!mounted) return;
    
    if (_selectedLesson == 'Всі уроки') {
      if (!mounted) return;
      _scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Виберіть урок для перейменування'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final textController = TextEditingController(text: _selectedLesson);
    
    try {
      final newName = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Перейменувати урок'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Поточна назва: $_selectedLesson',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Нова назва',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                enableSuggestions: false,
                autocorrect: false,
                enableIMEPersonalizedLearning: false,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    Navigator.of(context).pop(value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Скасувати'),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  Navigator.pop(context, textController.text);
                }
              },
              child: const Text('Зберегти'),
            ),
          ],
        ),
      );

      if (newName != null && newName.isNotEmpty) {
        if (!mounted) return;
        
        // Показуємо індикатор завантаження
        _scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Перейменування уроку...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        final success = await provider.renameLesson(_selectedLesson, newName);
        if (!mounted) return;

        if (success) {
          setState(() {
            _selectedLesson = newName;
          });
          
          _scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Урок успішно перейменовано на "$newName"'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Урок з такою назвою вже існує'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Помилка при перейменуванні уроку: $e');
      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Помилка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Безпечно утилізуємо контролер після діалогу
      if (mounted) {
        // Використовуємо post-frame callback для безпечної утилізації
        WidgetsBinding.instance.addPostFrameCallback((_) {
          textController.dispose();
        });
      } else {
        textController.dispose();
      }
    }
  }

  void _showWordContextMenu(
    BuildContext context,
    WordTrainerProvider provider,
    String wordKey,
  ) {
    final word = provider.words[wordKey];
    if (word == null || !mounted) return;
    
    // Встановлюємо вибране слово
    setState(() {
      _selectedWordKey = wordKey;
    });
    
    // Показуємо спливаюче меню з опціями
    showModalBottomSheet(
      context: context,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          // Перехоплюємо подію закриття, щоб забезпечити стабільність
          return true;
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Редагувати слово'),
              onTap: () {
                // Закриваємо меню
                Navigator.pop(context);
                // Невелика затримка перед викликом редагування
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    _editSelectedWord(context, provider);
                  }
                });
              },
            ),
            ListTile(
              leading: Icon(
                word.learned ? Icons.refresh : Icons.check_circle,
                color: word.learned ? Colors.orange : Colors.green,
              ),
              title: Text(word.learned ? 'Позначити як невивчене' : 'Позначити як вивчене'),
              onTap: () async {
                // Закриваємо меню
                Navigator.pop(context);
                // Невелика затримка перед зміною статусу
                await Future.delayed(const Duration(milliseconds: 100));
                if (mounted) {
                  // Змінюємо статус слова
                  await provider.toggleWordLearned(wordKey);
                  
                  if (mounted) {
                    _scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          word.learned 
                              ? 'Слово позначено як невивчене' 
                              : 'Слово позначено як вивчене'
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Видалити слово'),
              onTap: () {
                // Закриваємо меню
                Navigator.pop(context);
                // Невелика затримка перед викликом діалогу
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    _showDeleteConfirmation(context, provider, wordKey);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation(
    BuildContext context,
    WordTrainerProvider provider,
    String wordKey,
  ) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false, // Вимикаємо закриття при натисканні поза діалогом
      builder: (context) => AlertDialog(
        title: const Text('Видалити слово?'),
        content: Text('Ви дійсно хочете видалити слово "$wordKey"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Невелика затримка перед показом повідомлення
              await Future.delayed(const Duration(milliseconds: 100));
              
              if (mounted) {
                // У майбутньому можна додати метод видалення слова
                _scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Функція видалення слів поки недоступна'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Видалити', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditOptions(BuildContext context, WordTrainerProvider provider) {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          // Перехоплюємо подію закриття, щоб забезпечити стабільність
          return true;
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedWordKey != null) 
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Редагувати вибране слово'),
                subtitle: Text('Слово: $_selectedWordKey'),
                onTap: () {
                  Navigator.pop(context);
                  // Невелика затримка перед викликом редагування
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      _editSelectedWord(context, provider);
                    }
                  });
                },
              ),
            if (_selectedLesson != 'Всі уроки')
              ListTile(
                leading: const Icon(Icons.book, color: Colors.green),
                title: const Text('Перейменувати урок'),
                subtitle: Text('Урок: $_selectedLesson'),
                onTap: () {
                  Navigator.pop(context);
                  // Невелика затримка перед викликом перейменування
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      _renameLesson(context, provider);
                    }
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.manage_search, color: Colors.orange),
              title: const Text('Вибрати інше слово'),
              subtitle: const Text('Натисніть на слово в списку, щоб вибрати його'),
              onTap: () {
                Navigator.pop(context);
                // Невелика затримка перед показом повідомлення
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted && _selectedWordKey == null) {
                    _scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Оберіть слово зі списку для редагування'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
} 