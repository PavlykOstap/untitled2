import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  void initState() {
    super.initState();
    // Завантажуємо слова при ініціалізації, вказуючи showLearned: false
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WordTrainerProvider>(context, listen: false);
      provider.loadWords(showLearned: false);
    });
  }

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
                        provider.loadWords(lessonName: value, showLearned: false);
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
                            if (entry.value.learned) {
                              // Якщо слово вже вивчене, переключаємо його статус
                              await provider.toggleWordLearned(entry.key);
                            } else {
                              // Якщо слово не вивчене, позначаємо його як вивчене
                              await provider.markWordAsLearned(entry.key);
                            }
                            
                            // Оновлюємо список слів після зміни статусу
                            await provider.loadWords(
                              lessonName: _selectedLesson != 'Всі уроки' ? _selectedLesson : null,
                              showLearned: false
                            );
                            
                            if (mounted) {
                              _scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(entry.value.learned ? 
                                    'Слово перенесено в режим повторення' : 
                                    'Слово позначено як вивчене'),
                                  backgroundColor: entry.value.learned ? 
                                    Colors.orange : Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
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
                              // Кнопка для позначення слова як вивчене
                              IconButton(
                                icon: Icon(
                                  entry.value.learned ? 
                                    Icons.check_circle : 
                                    Icons.check_circle_outline,
                                  color: entry.value.learned ? 
                                    Colors.green : 
                                    Colors.grey,
                                ),
                                tooltip: entry.value.learned ? 
                                  'Позначено як вивчене' : 
                                  'Позначити як вивчене',
                                onPressed: () async {
                                  if (entry.value.learned) {
                                    // Якщо слово вже вивчене, переключаємо його статус
                                    await provider.toggleWordLearned(entry.key);
                                  } else {
                                    // Якщо слово не вивчене, позначаємо його як вивчене
                                    await provider.markWordAsLearned(entry.key);
                                  }
                                  
                                  // Оновлюємо список слів після зміни статусу
                                  await provider.loadWords(
                                    lessonName: _selectedLesson != 'Всі уроки' ? _selectedLesson : null,
                                    showLearned: false
                                  );
                                  
                                  if (mounted) {
                                    _scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(entry.value.learned ? 
                                          'Слово перенесено в режим повторення' : 
                                          'Слово позначено як вивчене'),
                                        backgroundColor: entry.value.learned ? 
                                          Colors.orange : Colors.green,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.grey[50],
            title: Row(
              children: [
                const Icon(Icons.edit, color: Color(0xFF2ECC71), size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Редагувати слово',
                  style: TextStyle(
                    color: Color(0xFF2C3E50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Закрити',
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: englishController,
                    decoration: InputDecoration(
                      labelText: 'Англійське слово',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.language, color: Color(0xFF3498DB)),
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF3498DB), width: 2),
                      ),
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
                    decoration: InputDecoration(
                      labelText: 'Український переклад',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.translate, color: Color(0xFF9B59B6)),
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF9B59B6), width: 2),
                      ),
                    ),
                    enableSuggestions: false,
                    autocorrect: false,
                    enableIMEPersonalizedLearning: false,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedLesson,
                    decoration: InputDecoration(
                      labelText: 'Урок',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.book, color: Color(0xFF2ECC71)),
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
                      ),
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
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2ECC71)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              // Перший ряд кнопок - Cancel і Delete на одному рівні
              Row(
                children: [
                  // Кнопка Cancel
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        side: BorderSide(color: Colors.blue[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Скасувати'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Кнопка Delete
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, {'action': 'delete'});
                      },
                      icon: const Icon(Icons.delete_forever, size: 20),
                      label: const Text('Видалити'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Кнопка збереження на всю ширину
              ElevatedButton.icon(
                onPressed: () {
                  if (englishController.text.isEmpty || ukrainianController.text.isEmpty) {
                    return;
                  }
                  Navigator.pop(context, {
                    'action': 'save',
                    'english': englishController.text.trim(),
                    'ukrainian': ukrainianController.text.trim(),
                    'lesson': selectedLesson,
                  });
                },
                icon: const Icon(Icons.save, size: 20),
                label: const Text('Зберегти'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );

      // Обробляємо результат - перевіряємо mounted перед продовженням
      if (result != null) {
        if (!mounted) return;
        
        // Перевіряємо дію
        if (result['action'] == 'delete') {
          // Невелика затримка, щоб попередній діалог повністю закрився
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              // Показуємо діалог підтвердження видалення
              _showDeleteConfirmation(context, provider, _selectedWordKey!);
            }
          });
          return;
        }
        
        // Обробляємо збереження
        if (result['action'] == 'save') {
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
                  if (word.learned) {
                    // Якщо слово вже вивчене, позначаємо як невивчене
                    await provider.markWordAsUnlearned(wordKey);
                  } else {
                    // Якщо слово не вивчене, позначаємо його як вивчене
                    await provider.markWordAsLearned(wordKey);
                  }
                  
                  // Оновлюємо список слів
                  await provider.loadWords(
                    lessonName: _selectedLesson != 'Всі уроки' ? _selectedLesson : null,
                    showLearned: false
                  );
                  
                  if (mounted) {
                    _scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          word.learned 
                              ? 'Слово позначено як невивчене' 
                              : 'Слово позначено як вивчене'
                        ),
                        backgroundColor: word.learned ? Colors.orange : Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
            // Додаємо два окремі пункти меню, як в LearnedWordsScreen
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.orange),
              title: const Text('Видалити з підтвердженням'),
              subtitle: const Text('Показати діалог підтвердження перед видаленням'),
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
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Видалити відразу'),
              subtitle: const Text('Видалити слово без додаткових питань'),
              onTap: () async {
                // Закриваємо меню
                Navigator.pop(context);
                // Видаляємо слово відразу
                await _deleteWord(context, provider, wordKey);
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
    
    // Використовуємо простіший діалог, як в LearnedWordsScreen
    showDialog(
      context: context,
      barrierDismissible: false, // Запобігаємо випадковому закриттю діалогу
      builder: (dialogContext) => AlertDialog(
        title: const Text('Видалення слова'),
        content: Text('Ви впевнені, що хочете повністю видалити слово "$wordKey"?\n\nЦю дію неможливо скасувати.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () {
              // Закриваємо діалог спочатку
              Navigator.of(dialogContext).pop();
              
              // Використовуємо малу затримку перед видаленням
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  // Викликаємо метод видалення
                  _deleteWord(context, provider, wordKey);
                }
              });
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

  // Добавляємо окремий метод для видалення слова, щоб можна було викликати його з будь-якого місця
  Future<void> _deleteWord(BuildContext context, WordTrainerProvider provider, String wordKey) async {
    print("Trying to delete word: $wordKey");
    
    // Зберігаємо стан слова перед видаленням для перевірки
    final wordExists = provider.words.containsKey(wordKey);
    print("Word exists before deletion: $wordExists");
    
    try {
      // Показуємо індикатор завантаження - використовуємо кешований месенджер
      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Видалення слова...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // Викликаємо метод бази даних напряму через провайдер
      final success = await provider.deleteWord(wordKey);
      print("Delete result: $success");
      
      // Перевіряємо чи слово справді видалено
      final wordExistsAfter = provider.words.containsKey(wordKey);
      print("Word exists after deletion: $wordExistsAfter");
      
      // Примусово видаляємо з локального стану і оновлюємо інтерфейс
      if (success) {
        // Очищаємо виділення, якщо видалене слово було виділено
        if (mounted) {
          setState(() {
            if (_selectedWordKey == wordKey) {
              _selectedWordKey = null;
            }
          });
        }
        
        // Перезавантажуємо список слів після видалення
        await provider.loadWords(
          lessonName: _selectedLesson != 'Всі уроки' ? _selectedLesson : null,
          showLearned: false
        );
      }
      
      if (mounted) {
        // Показуємо повідомлення
        _scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Слово "$wordKey" видалено повністю' 
              : 'Помилка при видаленні слова'
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error deleting word: $e");
      if (mounted) {
        _scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Помилка при видаленні: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
} 