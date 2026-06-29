import 'package:flutter/material.dart';

/// A compact on-screen keypad for typing math intervals / values.
///
/// Each visible key inserts a LaTeX *token* (e.g. tapping "−∞" inserts the
/// token "-\\infty"). The parent stores the field as a list of tokens so that
/// backspace removes whole tokens cleanly. Special keys trigger [onBackspace]
/// and [onClear].
class MathKeypad extends StatelessWidget {
  /// Called with the LaTeX token to append to the active field.
  final void Function(String token) onInsert;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  /// Optional label describing the field currently being edited.
  final String? activeLabel;

  const MathKeypad({
    super.key,
    required this.onInsert,
    required this.onBackspace,
    required this.onClear,
    this.activeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (activeLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.edit, size: 14, color: Colors.grey.shade700),
                  const SizedBox(width: 6),
                  Text(
                    activeLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          _row([
            _Key.token('7', '7'),
            _Key.token('8', '8'),
            _Key.token('9', '9'),
            _Key.action(Icons.backspace_outlined, _Act.backspace,
                color: Colors.orange.shade700),
          ]),
          _row([
            _Key.token('4', '4'),
            _Key.token('5', '5'),
            _Key.token('6', '6'),
            _Key.token('(', '('),
          ]),
          _row([
            _Key.token('1', '1'),
            _Key.token('2', '2'),
            _Key.token('3', '3'),
            _Key.token(')', ')'),
          ]),
          _row([
            _Key.token('0', '0'),
            _Key.token('.', '.'),
            _Key.token(',', ','),
            _Key.token('\u2212', '-'), // − inserts '-'
          ]),
          _row([
            _Key.token('\u2212\u221E', '-\\infty'),
            _Key.token('+\u221E', '+\\infty'),
            _Key.token('\u222A', '\\cup'),
            _Key.action(Icons.clear, _Act.clear, color: Colors.red.shade600),
          ]),
        ],
      ),
    );
  }

  Widget _row(List<_Key> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: keys
            .map((k) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _buildKey(k),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildKey(_Key key) {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Material(
          color: key.color ?? scheme.surface,
          borderRadius: BorderRadius.circular(10),
          elevation: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              switch (key.action) {
                case _Act.insert:
                  onInsert(key.token!);
                  break;
                case _Act.backspace:
                  onBackspace();
                  break;
                case _Act.clear:
                  onClear();
                  break;
              }
            },
            child: Container(
              height: 46,
              alignment: Alignment.center,
              child: key.icon != null
                  ? Icon(key.icon,
                      size: 22,
                      color: key.color != null ? Colors.white : null)
                  : Text(
                      key.label!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

enum _Act { insert, backspace, clear }

class _Key {
  final String? label;
  final String? token;
  final IconData? icon;
  final _Act action;
  final Color? color;

  _Key.token(this.label, this.token)
      : icon = null,
        action = _Act.insert,
        color = null;

  _Key.action(this.icon, this.action, {this.color})
      : label = null,
        token = null;
}
