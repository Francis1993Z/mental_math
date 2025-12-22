import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_config.dart';
import '../models/game_result.dart';
import '../models/question.dart';
import '../services/question_generator.dart';
import '../services/weight_service.dart';
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
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
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
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    final input = _answerController.text.trim();
    if (input.isEmpty) return;

    final userAnswer = int.tryParse(input);
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
      _answerController.clear();
    });
    _questionStopwatch.reset();
    _questionStopwatch.start();
    _focusNode.requestFocus();
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
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildProgressIndicator(),
              const Spacer(),
              _buildQuestionDisplay(),
              const SizedBox(height: 32),
              _buildAnswerInput(),
              const Spacer(),
              _buildSubmitButton(),
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

  Widget _buildAnswerInput() {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: _answerController,
        focusNode: _focusNode,
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32),
        decoration: const InputDecoration(
          hintText: '?',
          border: OutlineInputBorder(),
        ),
        enabled: !_showingFeedback,
        onSubmitted: (_) => _submitAnswer(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showingFeedback ? null : _submitAnswer,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        child: const Text('Valider', style: TextStyle(fontSize: 24)),
      ),
    );
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
