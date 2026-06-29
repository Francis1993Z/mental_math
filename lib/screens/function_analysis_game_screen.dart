import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/function_analysis.dart';
import '../models/game_config.dart';
import '../services/function_analysis_loader.dart';
import '../widgets/math_keypad.dart';
import '../widgets/math_text.dart';
import 'function_analysis_result_screen.dart';
import 'function_graph_screen.dart';

/// Which token field the keypad is currently editing.
enum _FieldKind { interval, extremum }

class _Active {
  final _FieldKind kind;
  final int index;
  const _Active(this.kind, this.index);
}

/// Student input for one analysis-table row.
class _IntervalInput {
  final List<String> tokens = [];
  Sign? fPrime;
  Sign? fSecond;
}

/// Student input for one extremum row.
class _ExtremumInput {
  final List<String> tokens = [];
  ExtremumType? type;
}

/// Per-interval grading feedback.
class _IntervalFeedback {
  final AnalysisInterval expected;
  final bool matched;
  final Sign? studentFPrime;
  final Sign? studentFSecond;

  _IntervalFeedback({
    required this.expected,
    required this.matched,
    this.studentFPrime,
    this.studentFSecond,
  });

  bool get fPrimeOk => matched && studentFPrime == expected.fPrime;
  bool get fSecondOk => matched && studentFSecond == expected.fSecond;
  bool get allOk => matched && fPrimeOk && fSecondOk;
}

class _ExtremumFeedback {
  final Extremum expected;
  final bool matched;
  final ExtremumType? studentType;

  _ExtremumFeedback({
    required this.expected,
    required this.matched,
    this.studentType,
  });

  bool get typeOk => matched && studentType == expected.type;
  bool get allOk => matched && typeOk;
}

/// Gameplay screen for the Function-analysis mode.
class FunctionAnalysisGameScreen extends StatefulWidget {
  final FunctionAnalysisConfig config;

  const FunctionAnalysisGameScreen({super.key, required this.config});

  @override
  State<FunctionAnalysisGameScreen> createState() =>
      _FunctionAnalysisGameScreenState();
}

class _FunctionAnalysisGameScreenState
    extends State<FunctionAnalysisGameScreen> {
  final FunctionAnalysisLoader _loader = FunctionAnalysisLoader();
  final math.Random _rng = math.Random();

  List<FunctionAnalysisQuestion> _pool = [];
  FunctionAnalysisQuestion? _current;

  final List<_IntervalInput> _rows = [];
  final List<_ExtremumInput> _extrema = [];
  _Active? _active;

  bool _isInitialized = false;
  bool _noQuestions = false;

  bool _showingCorrection = false;
  List<_IntervalFeedback> _intervalFeedback = [];
  List<_ExtremumFeedback> _extremaFeedback = [];
  List<String> _extraIntervals = [];
  bool _lastPassed = false;

  int _answeredCount = 0;
  int _correctCount = 0;

  Timer? _timer;
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _pool = await _loader.load(difficulty: widget.config.difficulty);
    if (!mounted) return;
    if (_pool.isEmpty) {
      setState(() {
        _noQuestions = true;
        _isInitialized = true;
      });
      return;
    }
    _loadQuestion();
    if (widget.config.mode == GameMode.timed) {
      _remainingSeconds = widget.config.duration!;
      _startTimer(countdown: true);
    } else {
      _startTimer(countdown: false);
    }
    setState(() => _isInitialized = true);
  }

  void _startTimer({required bool countdown}) {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        if (countdown) {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) _endGame();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  FunctionAnalysisQuestion _pickQuestion() {
    if (_pool.length == 1) return _pool.first;
    FunctionAnalysisQuestion q;
    do {
      q = _pool[_rng.nextInt(_pool.length)];
    } while (q.id == _current?.id);
    return q;
  }

  void _loadQuestion() {
    _current = _pickQuestion();
    _rows
      ..clear()
      ..add(_IntervalInput());
    _extrema.clear();
    _active = null;
    _showingCorrection = false;
    _intervalFeedback = [];
    _extremaFeedback = [];
    _extraIntervals = [];
  }

  // ---- Keypad editing -------------------------------------------------------

  List<String>? _activeTokens() {
    final a = _active;
    if (a == null) return null;
    if (a.kind == _FieldKind.interval) {
      if (a.index < _rows.length) return _rows[a.index].tokens;
    } else {
      if (a.index < _extrema.length) return _extrema[a.index].tokens;
    }
    return null;
  }

  void _insert(String token) {
    final tokens = _activeTokens();
    if (tokens == null) return;
    setState(() => tokens.add(token));
  }

  void _backspace() {
    final tokens = _activeTokens();
    if (tokens == null || tokens.isEmpty) return;
    setState(() => tokens.removeLast());
  }

  void _clearField() {
    final tokens = _activeTokens();
    if (tokens == null) return;
    setState(() => tokens.clear());
  }

  String? get _activeLabel {
    final a = _active;
    if (a == null) return null;
    return a.kind == _FieldKind.interval
        ? 'Intervalle ${a.index + 1}'
        : 'Valeur de x (point ${a.index + 1})';
  }

  // ---- Grading --------------------------------------------------------------

  void _validate() {
    final q = _current!;
    final used = <int>{};
    final intervalFb = <_IntervalFeedback>[];

    for (final exp in q.intervals) {
      final normExp = normalizeMath(exp.intervalLatex);
      int matchIdx = -1;
      for (int i = 0; i < _rows.length; i++) {
        if (used.contains(i)) continue;
        final norm = normalizeMath(_rows[i].tokens.join());
        if (norm.isNotEmpty && norm == normExp) {
          matchIdx = i;
          break;
        }
      }
      if (matchIdx >= 0) {
        used.add(matchIdx);
        final r = _rows[matchIdx];
        intervalFb.add(_IntervalFeedback(
          expected: exp,
          matched: true,
          studentFPrime: r.fPrime,
          studentFSecond: r.fSecond,
        ));
      } else {
        intervalFb.add(_IntervalFeedback(expected: exp, matched: false));
      }
    }

    final extra = <String>[];
    for (int i = 0; i < _rows.length; i++) {
      if (used.contains(i)) continue;
      final s = _rows[i].tokens.join();
      if (normalizeMath(s).isNotEmpty) extra.add(s);
    }

    final usedX = <int>{};
    final extremaFb = <_ExtremumFeedback>[];
    for (final exp in q.extrema) {
      final normExp = normalizeMath(exp.xLatex);
      int matchIdx = -1;
      for (int i = 0; i < _extrema.length; i++) {
        if (usedX.contains(i)) continue;
        final norm = normalizeMath(_extrema[i].tokens.join());
        if (norm.isNotEmpty && norm == normExp) {
          matchIdx = i;
          break;
        }
      }
      if (matchIdx >= 0) {
        usedX.add(matchIdx);
        extremaFb.add(_ExtremumFeedback(
          expected: exp,
          matched: true,
          studentType: _extrema[matchIdx].type,
        ));
      } else {
        extremaFb.add(_ExtremumFeedback(expected: exp, matched: false));
      }
    }

    final allIntervalsOk =
        intervalFb.every((f) => f.allOk) && extra.isEmpty;
    final allExtremaOk = extremaFb.every((f) => f.allOk);
    final passed = allIntervalsOk && allExtremaOk;

    setState(() {
      _active = null;
      _showingCorrection = true;
      _intervalFeedback = intervalFb;
      _extremaFeedback = extremaFb;
      _extraIntervals = extra;
      _lastPassed = passed;
      _answeredCount++;
      if (passed) _correctCount++;
    });
  }

  void _next() {
    if (widget.config.mode == GameMode.fixedQuestions &&
        _answeredCount >= widget.config.questionCount!) {
      _endGame();
      return;
    }
    setState(_loadQuestion);
  }

  void _endGame() {
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => FunctionAnalysisResultScreen(
          correct: _correctCount,
          total: _answeredCount == 0 ? 1 : _answeredCount,
          totalTimeSeconds: _elapsedSeconds,
        ),
      ),
    );
  }

  void _openGraph() {
    setState(() => _active = null);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FunctionGraphScreen(question: _current!),
      ),
    );
  }

  // ---- Build ----------------------------------------------------------------

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
          title: const Text('Analyse de fonction'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aucune fonction disponible pour ce niveau.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }

    final showKeypad = _active != null && !_showingCorrection;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: _buildAppBarTitle(),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: _confirmExit),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: _showingCorrection
                    ? _buildCorrection()
                    : _buildEditor(),
              ),
            ),
            if (showKeypad)
              MathKeypad(
                activeLabel: _activeLabel,
                onInsert: _insert,
                onBackspace: _backspace,
                onClear: _clearField,
              ),
            _buildBottomBar(showKeypad),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    if (widget.config.mode == GameMode.timed) {
      final m = _remainingSeconds ~/ 60;
      final s = _remainingSeconds % 60;
      return Text(
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: _remainingSeconds <= 10 ? Colors.red : null,
        ),
      );
    }
    return Text('Fonction ${_answeredCount + 1}/${widget.config.questionCount}');
  }

  Widget _buildFunctionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Center(child: MathText(_current!.functionLatex, fontSize: 26)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openGraph,
                icon: const Icon(Icons.show_chart),
                label: const Text('Voir la courbe'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFunctionCard(),
        const SizedBox(height: 16),
        _sectionTitle('Tableau de variation', Icons.table_chart),
        const SizedBox(height: 4),
        Text(
          'Pour chaque intervalle : signe de f′, signe de f″. L\'allure (↗/↘ et ∪/∩) est déduite automatiquement.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < _rows.length; i++) _intervalCard(i),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _rows.add(_IntervalInput());
            _active = _Active(_FieldKind.interval, _rows.length - 1);
          }),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un intervalle'),
        ),
        const SizedBox(height: 20),
        _sectionTitle('Extrema et points particuliers', Icons.place_outlined),
        const SizedBox(height: 4),
        Text(
          'Indiquez la valeur de x puis classez : maximum, minimum ou point d\'inflexion.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < _extrema.length; i++) _extremumCard(i),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _extrema.add(_ExtremumInput());
            _active = _Active(_FieldKind.extremum, _extrema.length - 1);
          }),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un point'),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _intervalCard(int i) {
    final r = _rows[i];
    final isActive =
        _active?.kind == _FieldKind.interval && _active?.index == i;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _fieldBox(
                    tokens: r.tokens,
                    isActive: isActive,
                    hint: 'Intervalle, ex. (-∞, -3)',
                    onTap: () => setState(
                        () => _active = _Active(_FieldKind.interval, i)),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: _rows.length <= 1
                      ? null
                      : () => setState(() {
                            _rows.removeAt(i);
                            _active = null;
                          }),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _signToggle('f′', r.fPrime,
                    (s) => setState(() => r.fPrime = s)),
                const SizedBox(width: 12),
                _signToggle('f″', r.fSecond,
                    (s) => setState(() => r.fSecond = s)),
                const Spacer(),
                _allurePreview(r.fPrime, r.fSecond),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _extremumCard(int i) {
    final e = _extrema[i];
    final isActive =
        _active?.kind == _FieldKind.extremum && _active?.index == i;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        child: Column(
          children: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Text('x =',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: _fieldBox(
                    tokens: e.tokens,
                    isActive: isActive,
                    hint: 'Valeur, ex. -3',
                    onTap: () => setState(
                        () => _active = _Active(_FieldKind.extremum, i)),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed: () => setState(() {
                    _extrema.removeAt(i);
                    _active = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: ExtremumType.values.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t.label),
                    selected: e.type == t,
                    onSelected: (sel) =>
                        setState(() => e.type = sel ? t : null),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldBox({
    required List<String> tokens,
    required bool isActive,
    required String hint,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.06),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        child: tokens.isEmpty
            ? Text(hint,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14))
            : Align(
                alignment: Alignment.centerLeft,
                child: MathText(tokens.join(), fontSize: 22),
              ),
      ),
    );
  }

  Widget _signToggle(String label, Sign? value, ValueChanged<Sign> onChanged) {
    Widget btn(Sign s, String text) {
      final selected = value == s;
      final color = s == Sign.positive ? Colors.green : Colors.red;
      return InkWell(
        onTap: () => onChanged(s),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.18) : Colors.transparent,
            border: Border.all(
              color: selected ? color : Colors.grey.shade400,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(text,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: selected ? color : Colors.grey.shade700,
              )),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label :', style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 6),
        btn(Sign.positive, '+'),
        const SizedBox(width: 4),
        btn(Sign.negative, '\u2212'),
      ],
    );
  }

  Widget _allurePreview(Sign? fPrime, Sign? fSecond) {
    if (fPrime == null || fSecond == null) {
      return Text('allure : —',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('allure : ', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        MathText(AnalysisInterval.allureFor(fPrime, fSecond), fontSize: 20),
      ],
    );
  }

  // ---- Correction view ------------------------------------------------------

  Widget _buildCorrection() {
    final q = _current!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (_lastPassed ? Colors.green : Colors.red)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(_lastPassed ? Icons.check_circle : Icons.cancel,
                  color: _lastPassed ? Colors.green : Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _lastPassed
                      ? 'Analyse correcte !'
                      : 'Quelques erreurs — voici la correction.',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: Center(child: MathText(q.functionLatex, fontSize: 24)),
        ),
        const SizedBox(height: 12),
        _sectionTitle('Tableau corrigé', Icons.table_chart),
        const SizedBox(height: 8),
        _correctionTable(),
        const SizedBox(height: 16),
        if (_intervalFeedback.isNotEmpty && _extremaFeedback.isNotEmpty) ...[
          _sectionTitle('Extrema corrigés', Icons.place_outlined),
          const SizedBox(height: 8),
          ..._extremaFeedback.map(_extremumFeedbackTile),
        ],
        if (_extraIntervals.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Intervalles en trop (non attendus) :',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 13)),
          const SizedBox(height: 4),
          ..._extraIntervals.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: MathText(s, fontSize: 18, color: Colors.orange.shade800),
                ),
              )),
        ],
      ],
    );
  }

  Widget _correctionTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1.4),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: const [
            _HeaderCell('Intervalle'),
            _HeaderCell('f′'),
            _HeaderCell('f″'),
            _HeaderCell('Allure'),
          ],
        ),
        ..._intervalFeedback.map((f) {
          return TableRow(
            children: [
              _cell(MathText(f.expected.intervalLatex, fontSize: 16)),
              _signCell(f.expected.fPrime, f.matched ? f.fPrimeOk : null),
              _signCell(f.expected.fSecond, f.matched ? f.fSecondOk : null),
              _cell(MathText(f.expected.allureLatex, fontSize: 16)),
            ],
          );
        }),
      ],
    );
  }

  Widget _cell(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Center(child: child),
      );

  Widget _signCell(Sign expected, bool? ok) {
    Color color;
    IconData? icon;
    if (ok == null) {
      color = Colors.grey.shade700;
    } else if (ok) {
      color = Colors.green;
      icon = Icons.check;
    } else {
      color = Colors.red;
      icon = Icons.close;
    }
    return _cell(Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(expected.symbol,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        if (icon != null) ...[
          const SizedBox(width: 2),
          Icon(icon, size: 14, color: color),
        ],
      ],
    ));
  }

  Widget _extremumFeedbackTile(_ExtremumFeedback f) {
    final ok = f.allOk;
    final color = ok ? Colors.green : Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel, size: 18, color: color),
          const SizedBox(width: 8),
          MathText('x = ${f.expected.xLatex}', fontSize: 18),
          const SizedBox(width: 10),
          Text(f.expected.type.label,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: color)),
          if (!f.matched) ...[
            const SizedBox(width: 8),
            Text('(manquant)',
                style: TextStyle(fontSize: 13, color: Colors.red.shade400)),
          ],
        ],
      ),
    );
  }

  // ---- Bottom action bar ----------------------------------------------------

  Widget _buildBottomBar(bool keypadShown) {
    final isLast = widget.config.mode == GameMode.fixedQuestions &&
        _answeredCount >= widget.config.questionCount!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: keypadShown
            ? null
            : const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1)),
              ],
      ),
      child: _showingCorrection
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _next,
                icon: Icon(isLast ? Icons.flag : Icons.arrow_forward),
                label: Text(isLast ? 'Terminer' : 'Fonction suivante',
                    style: const TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : Row(
              children: [
                if (_active != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _active = null),
                      icon: const Icon(Icons.keyboard_hide),
                      label: const Text('Fermer'),
                    ),
                  ),
                if (_active != null) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _validate,
                    icon: const Icon(Icons.check),
                    label: const Text('Valider', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
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

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Center(
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}
