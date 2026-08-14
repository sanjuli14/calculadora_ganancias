import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CalcOp { none, add, sub, mul, div }

class _CalcEntry {
  final String expression;
  final String result;

  const _CalcEntry(this.expression, this.result);
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _current = '';
  double? _accumulator;
  CalcOp _pending = CalcOp.none;
  bool _justEvaluated = false;
  final List<_CalcEntry> _history = [];
  bool _showHistory = false;

  String get _upperLine {
    if (_justEvaluated) {
      return _expression.replaceAll(RegExp(r'\s*$'), '');
    }
    final text = '$_expression$_current';
    if (text.isNotEmpty) return text;
    return _pending == CalcOp.none ? '' : '0';
  }

  String get _mainLine {
    final preview = _livePreview;
    if (preview != null) return '= $preview';
    if (_current.isNotEmpty) return _current;
    return '0';
  }

  String? get _livePreview {
    if (_pending == CalcOp.none) return null;
    if (_current.isEmpty) return null;
    final right = double.tryParse(_current);
    if (right == null) return null;
    final result = _compute(_accumulator ?? 0, right, _pending);
    if (result.isNaN || result.isInfinite) return 'Error';
    return _formatNumber(result);
  }

  void _inputDigit(String d) {
    setState(() {
      if (_justEvaluated) {
        _startFresh(d);
        return;
      }
      if (_current == '0' && d != '.') {
        _current = d;
      } else if (_current.replaceAll('-', '').length >= 14) {
        return;
      } else {
        _current = '$_current$d';
      }
    });
  }

  void _startFresh(String d) {
    _expression = '';
    _current = d;
    _accumulator = null;
    _pending = CalcOp.none;
    _justEvaluated = false;
  }

  void _inputDot() {
    setState(() {
      if (_justEvaluated) {
        _expression = '';
        _current = '0.';
        _accumulator = null;
        _pending = CalcOp.none;
        _justEvaluated = false;
        return;
      }
      if (!_current.contains('.')) {
        _current = _current.isEmpty ? '0.' : '$_current.';
      }
    });
  }

  void _clearAll() {
    setState(() {
      _expression = '';
      _current = '';
      _accumulator = null;
      _pending = CalcOp.none;
      _justEvaluated = false;
    });
  }

  void _backspace() {
    setState(() {
      if (_justEvaluated) {
        _clearAll();
        return;
      }
      if (_current.isEmpty) {
        if (_pending != CalcOp.none) {
          _current = _formatNumber(_accumulator!);
          _expression = '';
          _accumulator = null;
          _pending = CalcOp.none;
        }
        return;
      }
      _current = _current.length <= 1
          ? ''
          : _current.substring(0, _current.length - 1);
    });
  }

  void _toggleSign() {
    setState(() {
      if (_justEvaluated) {
        _expression = '';
        _accumulator = null;
        _pending = CalcOp.none;
        _justEvaluated = false;
      }
      if (_current.isEmpty || _current == '0') return;
      _current = _current.startsWith('-')
          ? _current.substring(1)
          : '-$_current';
    });
  }

  void _applyPercent() {
    final current = double.tryParse(_current);
    if (current == null) return;
    setState(() {
      if (_accumulator != null) {
        _current = _formatNumber(_accumulator! * current / 100.0);
      } else {
        _current = _formatNumber(current / 100.0);
      }
    });
  }

  void _setOp(CalcOp op) {
    setState(() {
      if (_pending != CalcOp.none) {
        if (_current.isNotEmpty) {
          final right = double.tryParse(_current) ?? 0;
          final result = _compute(_accumulator!, right, _pending);
          _accumulator = result;
          _expression = '${_formatNumber(result)} ${_opSymbol(op)} ';
        } else {
          _expression = '${_formatNumber(_accumulator!)} ${_opSymbol(op)} ';
        }
        _current = '';
        _pending = op;
        _justEvaluated = false;
        return;
      }
      if (_justEvaluated) {
        _accumulator = double.tryParse(_current) ?? 0;
        _expression = '${_formatNumber(_accumulator!)} ${_opSymbol(op)} ';
        _current = '';
        _pending = op;
        _justEvaluated = false;
        return;
      }
      if (_current.isEmpty) return;
      _accumulator = double.tryParse(_current) ?? 0;
      _expression = '${_formatNumber(_accumulator!)} ${_opSymbol(op)} ';
      _current = '';
      _pending = op;
      _justEvaluated = false;
    });
  }

  void _equals() {
    if (_pending == CalcOp.none) return;
    final right = double.tryParse(_current) ?? 0;
    final result = _compute(_accumulator!, right, _pending);
    final resultStr = _formatNumber(result);
    final expressionText =
        '${_formatNumber(_accumulator!)} ${_opSymbol(_pending)} ${_formatNumber(right)}';
    setState(() {
      _history.insert(0, _CalcEntry(expressionText, resultStr));
      if (_history.length > 30) _history.removeLast();
      _expression = '$expressionText =';
      _current = resultStr;
      _accumulator = null;
      _pending = CalcOp.none;
      _justEvaluated = true;
    });
  }

  double _compute(double a, double b, CalcOp op) {
    switch (op) {
      case CalcOp.add:
        return a + b;
      case CalcOp.sub:
        return a - b;
      case CalcOp.mul:
        return a * b;
      case CalcOp.div:
        if (b == 0) return double.nan;
        return a / b;
      case CalcOp.none:
        return b;
    }
  }

  String _opSymbol(CalcOp op) {
    switch (op) {
      case CalcOp.add:
        return '+';
      case CalcOp.sub:
        return '−';
      case CalcOp.mul:
        return '×';
      case CalcOp.div:
        return '÷';
      case CalcOp.none:
        return '';
    }
  }

  String _formatNumber(double v) {
    if (v.isNaN || v.isInfinite) return 'Error';
    final isNeg = v < 0;
    final abs = v.abs();
    if (abs == abs.roundToDouble() && abs < 1e15) {
      final s = abs.toStringAsFixed(0);
      return isNeg ? '-$s' : s;
    }
    final s = abs.toStringAsFixed(6);
    final trimmed = s
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return isNeg ? '-$trimmed' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back, color: AppColors.navy),
        ),
        title: Text(
          'Calculadora',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _showHistory ? 'Ocultar historial' : 'Ver historial',
            onPressed: () => setState(() => _showHistory = !_showHistory),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  _showHistory ? Icons.calculate_outlined : Icons.history,
                  color: _showHistory
                      ? AppColors.navy
                      : AppColors.textSecondary,
                ),
                if (_history.isNotEmpty && !_showHistory)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_history.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _showHistory
                  ? _HistoryView(
                      history: _history,
                      onTap: (entry) {
                        setState(() {
                          _current = entry.result;
                          _expression = '';
                          _accumulator = null;
                          _pending = CalcOp.none;
                          _justEvaluated = true;
                          _showHistory = false;
                        });
                      },
                      onClear: () => setState(() => _history.clear()),
                    )
                  : _Keypad(
                      upper: _upperLine,
                      main: _mainLine,
                      onDigit: _inputDigit,
                      onDot: _inputDot,
                      onClear: _clearAll,
                      onBackspace: _backspace,
                      onOp: _setOp,
                      onEquals: _equals,
                      onPercent: _applyPercent,
                      onToggleSign: _toggleSign,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final String upper;
  final String main;
  final ValueChanged<String> onDigit;
  final VoidCallback onDot;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final ValueChanged<CalcOp> onOp;
  final VoidCallback onEquals;
  final VoidCallback onPercent;
  final VoidCallback onToggleSign;

  const _Keypad({
    required this.upper,
    required this.main,
    required this.onDigit,
    required this.onDot,
    required this.onClear,
    required this.onBackspace,
    required this.onOp,
    required this.onEquals,
    required this.onPercent,
    required this.onToggleSign,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            alignment: Alignment.centerRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 120),
                  child: Text(
                    upper,
                    key: ValueKey(upper),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    main,
                    maxLines: 1,
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _Row(
                  children: [
                    _Key(
                      label: 'C',
                      onTap: onClear,
                      color: AppColors.surface,
                      fg: AppColors.danger,
                    ),
                    _Key(
                      label: '⌫',
                      onTap: onBackspace,
                      color: AppColors.surface,
                      fg: AppColors.textSecondary,
                    ),
                    _Key(
                      label: '%',
                      onTap: onPercent,
                      color: AppColors.surface,
                      fg: AppColors.textPrimary,
                    ),
                    _Key(
                      label: '÷',
                      onTap: () => onOp(CalcOp.div),
                      color: AppColors.navy,
                      fg: Colors.white,
                      big: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _Row(
                  children: [
                    _Key(label: '7', onTap: () => onDigit('7')),
                    _Key(label: '8', onTap: () => onDigit('8')),
                    _Key(label: '9', onTap: () => onDigit('9')),
                    _Key(
                      label: '×',
                      onTap: () => onOp(CalcOp.mul),
                      color: AppColors.navy,
                      fg: Colors.white,
                      big: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _Row(
                  children: [
                    _Key(label: '4', onTap: () => onDigit('4')),
                    _Key(label: '5', onTap: () => onDigit('5')),
                    _Key(label: '6', onTap: () => onDigit('6')),
                    _Key(
                      label: '−',
                      onTap: () => onOp(CalcOp.sub),
                      color: AppColors.navy,
                      fg: Colors.white,
                      big: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _Row(
                  children: [
                    _Key(label: '1', onTap: () => onDigit('1')),
                    _Key(label: '2', onTap: () => onDigit('2')),
                    _Key(label: '3', onTap: () => onDigit('3')),
                    _Key(
                      label: '+',
                      onTap: () => onOp(CalcOp.add),
                      color: AppColors.navy,
                      fg: Colors.white,
                      big: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _Row(
                  children: [
                    _Key(label: '±', onTap: onToggleSign),
                    _Key(label: '0', onTap: () => onDigit('0')),
                    _Key(label: '.', onTap: onDot),
                    _Key(
                      label: '=',
                      onTap: onEquals,
                      color: AppColors.emerald,
                      fg: Colors.white,
                      big: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final List<Widget> children;
  const _Row({required this.children});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? fg;
  final bool big;

  const _Key({
    required this.label,
    required this.onTap,
    this.color,
    this.fg,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg ?? AppColors.textPrimary,
              fontSize: big ? 26 : 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryView extends StatelessWidget {
  final List<_CalcEntry> history;
  final ValueChanged<_CalcEntry> onTap;
  final VoidCallback onClear;

  const _HistoryView({
    required this.history,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 56, color: AppColors.border),
              SizedBox(height: 12),
              Text(
                'Sin operaciones en esta sesión',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Text(
                'Historial de la sesión',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onClear,
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  size: 16,
                  color: AppColors.danger,
                ),
                label: Text(
                  'Limpiar',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            itemCount: history.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, i) {
              final e = history[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                onTap: () => onTap(e),
                title: Text(
                  e.expression,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  e.result,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Icon(
                  Icons.content_paste_outlined,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
