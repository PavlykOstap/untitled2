import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_trainer_provider.dart';

class AddWordScreen extends StatefulWidget {
  const AddWordScreen({super.key});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> with WidgetsBindingObserver {
  final _englishController = TextEditingController();
  final _ukrainianController = TextEditingController();
  final _englishFocusNode = FocusNode();
  final _ukrainianFocusNode = FocusNode();
  String _selectedLesson = 'Головний';
  bool _isProcessing = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Use a simple post-frame callback instead of adding it to the binding
    Future.microtask(() {
      if (!_disposed && mounted) {
        FocusScope.of(context).requestFocus(_englishFocusNode);
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    
    // Make sure to unfocus before disposing to prevent rendering errors
    _englishFocusNode.unfocus();
    _ukrainianFocusNode.unfocus();
    
    _englishFocusNode.dispose();
    _ukrainianFocusNode.dispose();
    _englishController.dispose();
    _ukrainianController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Clear focus when app goes to background
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_disposed) return;
    
    // Check if the lessons are loaded and ensure selected lesson is valid
    final provider = Provider.of<WordTrainerProvider>(context, listen: false);
    final uniqueLessons = provider.lessons.map((e) => e.name).toSet().toList();
    
    if (uniqueLessons.isNotEmpty && !uniqueLessons.contains(_selectedLesson)) {
      setState(() {
        _selectedLesson = uniqueLessons.first;
      });
    }
  }
  
  // Helper method to show a single SnackBar
  void _showSnackBar(String message, {bool isError = false, int durationSeconds = 3}) {
    if (_disposed || !mounted) return;
    
    // Clear any existing SnackBars first
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // Використовуємо безпечніший підхід з мікротаском
    Future.microtask(() {
      if (mounted && !_disposed) {
        try {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isError ? Colors.red : Colors.green,
              duration: Duration(seconds: durationSeconds),
            ),
          );
        } catch (e) {
          print('Помилка при показі повідомлення: $e');
        }
      }
    });
  }

  // Safe setState that checks if widget is still mounted
  void _safeSetState(Function setState) {
    if (!_disposed && mounted) {
      setState();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Provider.value to avoid creating new listener when rebuilding
    final provider = Provider.of<WordTrainerProvider>(context, listen: false);
    
    // Ensure the lessons list contains unique values
    final uniqueLessons = provider.lessons.map((e) => e.name).toSet().toList();
    
    // Check if the selected lesson exists in our unique list
    final initialValue = uniqueLessons.contains(_selectedLesson) 
        ? _selectedLesson 
        : uniqueLessons.isNotEmpty 
            ? uniqueLessons.first 
            : null;

    return PopScope(
      canPop: !_isProcessing,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // If we're processing, show a message and prevent pop
          _showSnackBar('Зачекайте, операція виконується...', isError: true, durationSeconds: 1);
        } else {
          // If allowed to pop, clear focus first
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Додати нове слово'),
          backgroundColor: const Color(0xFF3498DB),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Safe navigation back
              if (!_isProcessing && mounted && !_disposed) {
                FocusManager.instance.primaryFocus?.unfocus();
                // Use a microtask to avoid frame scheduling issues
                Future.microtask(() {
                  if (mounted && !_disposed) {
                    Navigator.of(context).pop();
                  }
                });
              }
            },
          ),
        ),
        body: SafeArea(
          child: Builder(
            builder: (context) => Container(
              height: double.infinity,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 120, // Approximate safe area
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Focus(
                          onFocusChange: (hasFocus) {
                            if (hasFocus && !_disposed && mounted) {
                              FocusScope.of(context).requestFocus(_englishFocusNode);
                            }
                          },
                          child: TextField(
                            controller: _englishController,
                            focusNode: _englishFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Англійське слово',
                              prefixIcon: const Icon(Icons.language),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            enableSuggestions: false,
                            autocorrect: false,
                            enableIMEPersonalizedLearning: false,
                            onTap: () {
                              if (!_disposed && mounted) {
                                FocusScope.of(context).requestFocus(_englishFocusNode);
                              }
                            },
                            onSubmitted: (_) {
                              if (!_disposed && mounted) {
                                FocusScope.of(context).requestFocus(_ukrainianFocusNode);
                              }
                            },
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Focus(
                          onFocusChange: (hasFocus) {
                            if (hasFocus && !_disposed && mounted) {
                              FocusScope.of(context).requestFocus(_ukrainianFocusNode);
                            }
                          },
                          child: TextField(
                            controller: _ukrainianController,
                            focusNode: _ukrainianFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Український переклад',
                              prefixIcon: const Icon(Icons.translate),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.done,
                            enableSuggestions: false,
                            autocorrect: false,
                            enableIMEPersonalizedLearning: false,
                            onTap: () {
                              if (!_disposed && mounted) {
                                FocusScope.of(context).requestFocus(_ukrainianFocusNode);
                              }
                            },
                            onSubmitted: (_) {
                              _ukrainianFocusNode.unfocus();
                            },
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: uniqueLessons.isEmpty
                          ? const Text('Немає доступних уроків')
                          : DropdownButtonFormField<String>(
                              value: initialValue,
                              decoration: InputDecoration(
                                labelText: 'Урок',
                                prefixIcon: const Icon(Icons.book),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: uniqueLessons.map((lessonName) => 
                                DropdownMenuItem<String>(
                                  value: lessonName,
                                  child: Text(
                                    lessonName,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                )
                              ).toList(),
                              onChanged: _isProcessing ? null : (value) {
                                if (value != null && !_disposed && mounted) {
                                  setState(() {
                                    _selectedLesson = value;
                                  });
                                }
                              },
                            ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing ? null : () async {
                                if (_englishController.text.isEmpty || _ukrainianController.text.isEmpty) {
                                  _showSnackBar('Будь ласка, заповніть обидва поля', isError: true);
                                  return;
                                }
                                
                                // Змінні для локального відстеження стану
                                bool operationSuccess = false;
                                
                                try {
                                  // Unfocus before saving
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  
                                  // Встановлюємо прапорець завантаження
                                  if (mounted && !_disposed) {
                                    setState(() => _isProcessing = true);
                                  } else {
                                    return; // Виходимо, якщо віджет вже знищено
                                  }
                                  
                                  // Зберігаємо слово
                                  final success = await provider.addWord(
                                    _englishController.text.trim(),
                                    _ukrainianController.text.trim(),
                                    _selectedLesson,
                                  );
                                  
                                  // Зберігаємо результат
                                  operationSuccess = success;
                                  
                                  // Перевіряємо, чи віджет ще активний
                                  if (!mounted || _disposed) {
                                    print("Віджет знищено під час операції");
                                    return;
                                  }
                                  
                                  // Скидаємо прапорець завантаження
                                  setState(() => _isProcessing = false);
                                  
                                  // Обробляємо результат
                                  if (success) {
                                    _showSnackBar('Слово успішно додано');
                                    
                                    // Невелика затримка перед навігацією
                                    await Future.delayed(const Duration(milliseconds: 300));
                                    
                                    if (!mounted || _disposed) return;
                                    Navigator.of(context).pop(true); // Return success value
                                  } else {
                                    _showSnackBar('Таке слово вже існує', isError: true);
                                  }
                                } catch (e) {
                                  print('Помилка при збереженні слова: $e');
                                  operationSuccess = false;
                                } finally {
                                  // Гарантуємо скидання прапорця у будь-якому випадку
                                  if (mounted && !_disposed && _isProcessing) {
                                    print("Скидання прапорця завантаження у finally блоці");
                                    setState(() => _isProcessing = false);
                                    
                                    // Показуємо повідомлення про помилку, якщо операція не завершилась успішно
                                    if (!operationSuccess) {
                                      _showSnackBar('Помилка при збереженні слова', isError: true);
                                    }
                                  }
                                }
                              },
                              icon: _isProcessing 
                                  ? const SizedBox(
                                      width: 20, 
                                      height: 20, 
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      )
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                _isProcessing ? 'Зберігання...' : 'Зберегти',
                                style: const TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2ECC71),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : () async {
                              if (_isProcessing) return;
                              
                              // Локальна змінна для відстеження результату
                              bool operationSuccess = false;
                              
                              try {
                                // Unfocus first to prevent keyboard issues
                                FocusManager.instance.primaryFocus?.unfocus();
                                
                                // Set a small delay before showing dialog
                                await Future.delayed(const Duration(milliseconds: 100));
                                if (!mounted || _disposed) return;
                                
                                // Open dialog to get lesson name
                                final lessonName = await _showNewLessonDialog(context);
                                
                                // If dialog was closed without selection or widget destroyed
                                if (lessonName == null || lessonName.isEmpty || !mounted || _disposed) return;
                                
                                // Set loading flag and show indicator
                                setState(() => _isProcessing = true);
                                
                                // Create the lesson
                                final createResult = await provider.createNewLesson(lessonName);
                                
                                // Запам'ятовуємо результат операції
                                operationSuccess = createResult;
                                
                                // Перевіряємо, чи віджет активний
                                if (!mounted || _disposed) {
                                  print("Віджет знищено під час створення уроку");
                                  return;
                                }
                                
                                // Скидаємо прапорець завантаження
                                setState(() => _isProcessing = false);
                                
                                // Невелика затримка для стабілізації інтерфейсу
                                await Future.delayed(const Duration(milliseconds: 100));
                                
                                // Перевіряємо ще раз активність віджета
                                if (!mounted || _disposed) return;
                                
                                // Process result
                                if (createResult == true) {
                                  // Вибираємо новий урок і показуємо повідомлення
                                  setState(() {
                                    _selectedLesson = lessonName;
                                  });
                                  
                                  // Показуємо повідомлення про успіх
                                  _showSnackBar("Урок '$lessonName' створено успішно");
                                } else {
                                  // Урок не створено (можливо, вже існує)
                                  _showSnackBar("Урок '$lessonName' вже існує", isError: true);
                                }
                              } catch (e) {
                                print("Помилка створення уроку: $e");
                                operationSuccess = false;
                              } finally {
                                // Гарантуємо скидання прапорця у будь-якому випадку
                                if (mounted && !_disposed && _isProcessing) {
                                  print("Скидання прапорця завантаження у finally блоці");
                                  setState(() => _isProcessing = false);
                                  
                                  // Показуємо повідомлення про помилку, якщо операція не завершилась успішно і не відображались інші повідомлення
                                  if (!operationSuccess) {
                                    _showSnackBar("Помилка при створенні уроку", isError: true);
                                  }
                                }
                              }
                            },
                            icon: _isProcessing 
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: Text(
                              _isProcessing ? 'Створення...' : 'Новий урок',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3498DB),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _showNewLessonDialog(BuildContext context) async {
    if (_disposed || !mounted) return null;
    
    // Create controller but don't dispose it immediately - let the state management handle it
    final TextEditingController textController = TextEditingController();
    
    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Новий урок'),
            content: TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Введіть назву уроку',
              ),
              maxLength: 25,
              autofocus: true,
              enableSuggestions: false,
              autocorrect: false,
              enableIMEPersonalizedLearning: false,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Скасувати'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(null);
                },
              ),
              TextButton(
                child: const Text('Створити'),
                onPressed: () {
                  if (textController.text.isNotEmpty) {
                    Navigator.of(dialogContext).pop(textController.text);
                  }
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Помилка при показі діалогу: $e');
      return null;
    } finally {
      // Safely dispose the controller after dialog is completely closed
      if (mounted && !_disposed) {
        // Use post-frame callback to ensure widget tree is stable
        WidgetsBinding.instance.addPostFrameCallback((_) {
          textController.dispose();
        });
      } else {
        textController.dispose();
      }
    }
  }
} 