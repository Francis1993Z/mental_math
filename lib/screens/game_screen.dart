import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_config.dart';
import '../models/game_result.dart';
import '../models/question.dart';
import '../services/question_generator.dart';
import '../services/weight_service.dart';
import '../widgets/numeric_keypad.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  final GameConfig config;

  const GameScreen({super.key, required this.config});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  QuestionGenerator? _generator;
  Question? _currentQuestion;
  final List<Question> _answeredQuestions = [];
  String _currentInput = '';
  final WeightService _weightService = WeightService();
  bool _isInitialized = false;

  Timer? _timer;
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0;
  bool _showingFeedback = false;
  bool _lastAnswerCorrect = false;
  final Stopwatch _questionStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    await _weightService.init();

    _generator = QuestionGenerator(
      minValue: widget.config.minValue,
      maxValue: widget.config.maxValue,
      operators: widget.config.operators,
      weightService: _weightService,
    );
    _currentQuestion = _generator!.generate();
    _questionStopwatch.start();

    if (widget.config.mode == GameMode.timed) {
      _remainingSeconds = widget.config.duration!;
      _startTimer();
    } else {
      _startElapsedTimer();
    }

    setState(() {
      _isInitialized = true;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        _elapsedSeconds++;
      });
      if (_remainingSeconds <= 0) {
        _endGame();
      }
    });
  }

  void _startElapsedTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _submitAnswer() {
    if (_currentInput.isEmpty) return;

    final userAnswer = int.tryParse(_currentInput);
    if (userAnswer == null) return;

    _questionStopwatch.stop();
    final responseTimeMs = _questionStopwatch.elapsedMilliseconds;

    _currentQuestion!.answer(userAnswer, timeMs: responseTimeMs);
    _answeredQuestions.add(_currentQuestion!);

    _weightService.recordAnswer(
      a: _currentQuestion!.a,
      b: _currentQuestion!.b,
      operator: _currentQuestion!.operator,
      correct: _currentQuestion!.isCorrect!,
      responseTimeMs: responseTimeMs,
    );

    if (widget.config.showImmediateFeedback) {
      setState(() {
        _showingFeedback = true;
        _lastAnswerCorrect = _currentQuestion!.isCorrect!;
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _proceedToNext();
        }
      });
    } else {
      _proceedToNext();
    }
  }

  void _proceedToNext() {
    setState(() {
      _showingFeedback = false;
    });

    if (widget.config.mode == GameMode.fixedQuestions &&
        _answeredQuestions.length >= widget.config.questionCount!) {
      _endGame();
      return;
    }

    setState(() {
      _currentQuestion = _generator!.generate();
      _currentInput = '';
    });
    _questionStopwatch.reset();
    _questionStopwatch.start();
  }

  void _endGame() {
    _timer?.cancel();

    final result = GameResult(
      questions: _answeredQuestions,
      totalTime: _elapsedSeconds,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => ResultScreen(result: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chargement...'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: _confirmExit),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 16),
              _buildQuestionDisplay(),
              const SizedBox(height: 16),
              _buildAnswerDisplay(),
              const Spacer(),
              _buildKeypadWithSubmit(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    if (widget.config.mode == GameMode.timed) {
      final minutes = _remainingSeconds ~/ 60;
      final seconds = _remainingSeconds % 60;
      return Text(
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _remainingSeconds <= 10 ? Colors.red : null,
        ),
      );
    } else {
      return Text(
        'Question ${_answeredQuestions.length + 1}/${widget.config.questionCount}',
      );
    }
  }

  Widget _buildProgressIndicator() {
    if (widget.config.mode == GameMode.fixedQuestions) {
      return LinearProgressIndicator(
        value: _answeredQuestions.length / widget.config.questionCount!,
        minHeight: 8,
        borderRadius: BorderRadius.circular(4),
      );
    }
    return Text(
      'Questions: ${_answeredQuestions.length}',
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  Widget _buildQuestionDisplay() {
    Color? backgroundColor;
    if (_showingFeedback) {
      backgroundColor = _lastAnswerCorrect
          ? Colors.green.withValues(alpha: 0.2)
          : Colors.red.withValues(alpha: 0.2);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            _currentQuestion!.display,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          if (_showingFeedback && !_lastAnswerCorrect)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Réponse: ${_currentQuestion!.correctAnswer}',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerDisplay() {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _currentInput.isEmpty ? '?' : _currentInput,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: _currentInput.isEmpty ? Colors.grey : Colors.black,
        ),
      ),
    );
  }

  Widget _buildKeypadWithSubmit() {
    return Column(
      children: [
        NumericKeypad(
          onKeyPressed: _onKeyPressed,
          onDelete: _onDelete,
          onSubmit: _submitAnswer,
          submitEnabled: !_showingFeedback && _currentInput.isNotEmpty,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_showingFeedback || _currentInput.isEmpty)
                ? null
                : _submitAnswer,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Valider', style: TextStyle(fontSize: 24)),
          ),
        ),
      ],
    );
  }

  void _onKeyPressed(String key) {
    if (_showingFeedback) return;
    setState(() {
      if (key == '-') {
        if (_currentInput.isEmpty) {
          _currentInput = '-';
        } else if (_currentInput == '-') {
          _currentInput = '';
        }
      } else {
        if (_currentInput.length < 10) {
          _currentInput += key;
        }
      }
    });
  }

  void _onDelete() {
    if (_showingFeedback) return;
    setState(() {
      if (_currentInput.isNotEmpty) {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      }
    });
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter?'),
        content: const Text('Voulez-vous vraiment abandonner cet exercice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }
}
