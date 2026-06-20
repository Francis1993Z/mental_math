import 'dart:async';
import 'package:flutter/material.dart';
import '../models/algebra_config.dart';
import '../models/algebra_question.dart';
import '../models/algebra_result.dart';
import '../models/game_config.dart';
import '../services/formula_weight_service.dart';
import '../services/question_loader.dart';
import '../widgets/math_text.dart';
import 'algebra_result_screen.dart';

/// Gameplay screen for the Algebre & Trigo mode.
///
/// Reuses the same timer/feedback flow as the arithmetic GameScreen, but the
/// prompt and the four answer choices are rendered as LaTeX and the player
/// answers by tapping a choice.
class AlgebraGameScreen extends StatefulWidget {
  final AlgebraConfig config;

  const AlgebraGameScreen({super.key, required this.config});

  @override
  State<AlgebraGameScreen> createState() => _AlgebraGameScreenState();
}

class _AlgebraGameScreenState extends State<AlgebraGameScreen> {
  final QuestionLoader _loader = QuestionLoader();
  final FormulaWeightService _weightService = FormulaWeightService();

  List<AlgebraQuestion> _pool = [];
  AlgebraQuestion? _current;
  List<String> _currentChoices = []; // shuffled choices for display
  final List<AlgebraQuestion> _answered = [];

  bool _isInitialized = false;
  bool _noQuestions = false;

  Timer? _timer;
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0;
  final Stopwatch _questionStopwatch = Stopwatch();

  bool _showingFeedback = false;
  bool _lastAnswerCorrect = false;
  bool _waitingForContinue = false;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    await _weightService.init();

    _pool = await _loader.load(
      categories: widget.config.categories,
      difficulty: widget.config.difficulty,
    );

    if (!mounted) return;

    if (_pool.isEmpty) {
      setState(() {
        _noQuestions = true;
        _isInitialized = true;
      });
      return;
    }

    _nextQuestion();
    _questionStopwatch.start();

    if (widget.config.mode == GameMode.timed) {
      _remainingSeconds = widget.config.duration!;
      _startTimer();
    } else {
      _startElapsedTimer();
    }

    setState(() => _isInitialized = true);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        _elapsedSeconds++;
      });
      if (_remainingSeconds <= 0) _endGame();
    });
  }

  void _startElapsedTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Picks the next question (weighted) avoiding an immediate repeat, and
  /// prepares a shuffled copy of its choices.
  void _nextQuestion() {
    AlgebraQuestion? picked = _weightService.selectWeighted(_pool);
    if (_pool.length > 1 && picked != null && picked.id == _current?.id) {
      // One retry to reduce back-to-back repeats.
      picked = _weightService.selectWeighted(_pool);
    }
    picked ??= _pool.first;

    _current = AlgebraQuestion(
      id: picked.id,
      category: picked.category,
      difficulty: picked.difficulty,
      type: picked.type,
      promptLatex: picked.promptLatex,
      answerLatex: picked.answerLatex,
      choicesLatex: picked.choicesLatex,
    );
    _currentChoices = List<String>.from(picked.choicesLatex)..shuffle();
    _selectedIndex = null;
  }

  void _onChoiceTapped(int displayIndex) {
    if (_showingFeedback) return;

    _questionStopwatch.stop();
    final responseTimeMs = _questionStopwatch.elapsedMilliseconds;

    final chosenLatex = _currentChoices[displayIndex];
    final originalIndex = _current!.choicesLatex.indexOf(chosenLatex);
    _current!.answer(originalIndex, timeMs: responseTimeMs);
    _answered.add(_current!);

    _weightService.recordAnswer(
      id: _current!.id,
      correct: _current!.isCorrect!,
      responseTimeMs: responseTimeMs,
    );

    if (widget.config.showImmediateFeedback) {
      final correct = _current!.isCorrect!;
      final pause = !correct && widget.config.pauseOnError;
      setState(() {
        _showingFeedback = true;
        _lastAnswerCorrect = correct;
        _selectedIndex = displayIndex;
        _waitingForContinue = pause;
      });
      if (!pause) {
        Future.delayed(const Duration(milliseconds: 1100), () {
          if (mounted) _proceedToNext();
        });
      }
    } else {
      _proceedToNext();
    }
  }

  void _proceedToNext() {
    if (widget.config.mode == GameMode.fixedQuestions &&
        _answered.length >= widget.config.questionCount!) {
      _endGame();
      return;
    }

    setState(() {
      _showingFeedback = false;
      _waitingForContinue = false;
      _nextQuestion();
    });
    _questionStopwatch
      ..reset()
      ..start();
  }

  void _endGame() {
    _timer?.cancel();
    final result =
        AlgebraResult(questions: _answered, totalTime: _elapsedSeconds);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AlgebraResultScreen(result: result),
      ),
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

    if (_noQuestions) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Algèbre & Trigo'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aucune question disponible pour cette configuration.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
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
              _buildPromptCard(),
              const SizedBox(height: 16),
              Expanded(child: _buildChoices()),
              if (_waitingForContinue) _buildContinueButton(),
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
    }
    return Text('Question ${_answered.length + 1}/${widget.config.questionCount}');
  }

  Widget _buildProgressIndicator() {
    if (widget.config.mode == GameMode.fixedQuestions) {
      return LinearProgressIndicator(
        value: _answered.length / widget.config.questionCount!,
        minHeight: 8,
        borderRadius: BorderRadius.circular(4),
      );
    }
    return Text(
      'Questions: ${_answered.length}',
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  Widget _buildPromptCard() {
    Color? background;
    if (_showingFeedback) {
      background = _lastAnswerCorrect
          ? Colors.green.withValues(alpha: 0.15)
          : Colors.red.withValues(alpha: 0.15);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background ?? Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Center(
              child: MathText(_current!.promptLatex, fontSize: 30),
            ),
          ),
          if (_showingFeedback && !_lastAnswerCorrect) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Bonne réponse',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            MathText(_current!.answerLatex, fontSize: 24, color: Colors.red),
          ],
        ],
      ),
    );
  }

  Widget _buildChoices() {
    return ListView.separated(
      itemCount: _currentChoices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildChoiceTile(index),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _proceedToNext,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Continuer', style: TextStyle(fontSize: 20)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceTile(int index) {
    final latex = _currentChoices[index];
    final isCorrectChoice = latex == _current!.answerLatex;
    final isSelected = _selectedIndex == index;

    Color borderColor = Colors.grey.shade400;
    Color background = Colors.white;
    if (_showingFeedback) {
      if (isCorrectChoice) {
        borderColor = Colors.green;
        background = Colors.green.withValues(alpha: 0.12);
      } else if (isSelected) {
        borderColor = Colors.red;
        background = Colors.red.withValues(alpha: 0.12);
      }
    }

    return InkWell(
      onTap: _showingFeedback ? null : () => _onChoiceTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: MathText(latex, fontSize: 24, color: Colors.black87),
        ),
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
