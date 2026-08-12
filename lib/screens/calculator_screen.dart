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
  String _display = '0';
  String _previous = '';
  double? _accumulator;
  CalcOp _pending = CalcOp.none;
  bool _justEvaluated = false;
  double? _memory;
  final List<_CalcEntry> _history = [];
  bool _showHistory = false;

  void _inputDigit(String d) {
    setState(() {
      if (_justEvaluated) {
        _display = d;
        _previous = '';
        _accumulator = null;
        _pending = CalcOp.none;
        _justEvaluated = false;
        return;
      }
      if (_display == '0' && d != '.') {
        _display = d;
      } else if (_display.replaceAll('-', '').length >= 14) {
        return;
      } else {
        _display = '$_display$d';
      }
    });
  }

  void _inputDot() {
    setState(() {
      if (_justEvaluated) {
        _display = '0.';
        _previous = '';
        _accumulator = null;
        _pending = CalcOp.none;
        _justEvaluated = false;
        return;
      }
      if (!_display.contains('.')) {
        _display = '$_display.';
      }
    });
  }

  void _clearAll() {
    setState(() {
      _display = '0';
      _previous = '';
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
      if (_display.length <= 1 || (_display.length == 2 && _display.startsWith('-'))) {
        _display = '0';
      } else {
        _display = _display.substring(0, _display.length - 1);
      }
    });
  }

  void _toggleSign() {
    setState(() {
      if (_display == '0') return;
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    });
  }

  void _applyPercent() {
    final current = double.tryParse(_display) ?? 0;
    setState(() {
      if (_accumulator != null) {
        final base = _accumulator!;
        final percentValue = base * current / 100.0;
        _display = _formatNumber(percentValue);
        _justEvaluated = true;
      } else {
        _display = _formatNumber(current / 100.0);
      }
    });
  }

  void _setOp(CalcOp op) {
    final current = double.tryParse(_display) ?? 0;
    setState(() {
      if (_accumulator != null && _pending != CalcOp.none && !_justEvaluated) {
        final result = _compute(_accumulator!, current, _pending);
        _accumulator = result;
        _display = _formatNumber(result);
      } else {
        _accumulator = current;
      }
      _pending = op;
      _previous = '$_display ${_opSymbol(op)}';
      _justEvaluated = false;
      _display = '0';
    });
  }

  void _equals() {
    final current = double.tryParse(_display) ?? 0;
    if (_accumulator == null || _pending == CalcOp.none) return;
    final result = _compute(_accumulator!, current, _pending);
    final expression = '$_previous ${_formatNumber(current)}';
    setState(() {
      _history.insert(
        0,
        _CalcEntry(expression, _formatNumber(result)),
      );
      if (_history.length > 30) _history.removeLast();
      _display = _formatNumber(result);
      _previous = expression;
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
    final trimmed = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return isNeg ? '-$trimmed' : trimmed;
  }

  void _memoryAdd() {
    final current = double.tryParse(_display) ?? 0;
    setState(() {
      _memory = (_memory ?? 0) + current;
      _justEvaluated = true;
    });
  }

  void _memorySub() {
    final current = double.tryParse(_display) ?? 0;
    setState(() {
      _memory = (_memory ?? 0) - current;
      _justEvaluated = true;
    });
  }

  void _memoryRecall() {
    if (_memory == null) return;
    setState(() {
      _display = _formatNumber(_memory!);
      _justEvaluated = true;
    });
  }

  void _memoryClear() {
    setState(() => _memory = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
        ),
        title: const Text(
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
                  color: _showHistory ? AppColors.navy : AppColors.textSecondary,
                ),
                if (_history.isNotEmpty && !_showHistory)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
            _MemoryBadge(memory: _memory),
            Expanded(
              child: _showHistory
                  ? _HistoryView(
                      history: _history,
                      onTap: (entry) {
                        setState(() {
                          _display = entry.result;
                          _justEvaluated = true;
                          _showHistory = false;
                        });
                      },
                      onClear: () => setState(() => _history.clear()),
                    )
                  : _Keypad(
                      display: _display,
                      previous: _previous,
                      onDigit: _inputDigit,
                      onDot: _inputDot,
                      onClear: _clearAll,
                      onBackspace: _backspace,
                      onOp: _setOp,
                      onEquals: _equals,
                      onPercent: _applyPercent,
                      onToggleSign: _toggleSign,
                      onMPlus: _memoryAdd,
                      onMSub: _memorySub,
                      onMR: _memoryRecall,
                      onMC: _memoryClear,
                      memoryActive: _memory != null && _memory != 0,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryBadge extends StatelessWidget {
  final double? memory;
  const _MemoryBadge({required this.memory});

  @override
  Widget build(BuildContext context) {
    if (memory == null) return const SizedBox.shrink();
    final m = memory!;
    final digits = m == m.roundToDouble() ? 0 : 2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      color: AppColors.turquoiseSoft,
      child: Row(
        children: [
          const Icon(Icons.bookmarks_outlined, size: 14, color: AppColors.turquoise),
          const SizedBox(width: 6),
          Text(
            'Memoria: ${m.toStringAsFixed(digits)}',
            style: const TextStyle(
              color: AppColors.turquoise,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final String display;
  final String previous;
  final ValueChanged<String> onDigit;
  final VoidCallback onDot;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final ValueChanged<CalcOp> onOp;
  final VoidCallback onEquals;
  final VoidCallback onPercent;
  final VoidCallback onToggleSign;
  final VoidCallback onMPlus;
  final VoidCallback onMSub;
  final VoidCallback onMR;
  final VoidCallback onMC;
  final bool memoryActive;

  const _Keypad({
    required this.display,
    required this.previous,
    required this.onDigit,
    required this.onDot,
    required this.onClear,
    required this.onBackspace,
    required this.onOp,
    required this.onEquals,
    required this.onPercent,
    required this.onToggleSign,
    required this.onMPlus,
    required this.onMSub,
    required this.onMR,
    required this.onMC,
    required this.memoryActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navy, AppColors.turquoise],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                previous,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  display,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _Row(children: [
                  _MemBtn(label: 'MC', onTap: onMC, active: memoryActive),
                  _MemBtn(label: 'MR', onTap: memoryActive ? onMR : null, active: memoryActive),
                  _MemBtn(label: 'M-', onTap: onMSub, active: memoryActive),
                  _MemBtn(label: 'M+', onTap: onMPlus, active: memoryActive),
                ]),
                const SizedBox(height: 8),
                _Row(children: [
                  _Key(label: 'C', onTap: onClear, color: AppColors.danger, fg: Colors.white),
                  _Key(label: '⌫', onTap: onBackspace, color: AppColors.warningSoft, fg: AppColors.warning),
                  _Key(label: '%', onTap: onPercent, color: AppColors.warningSoft, fg: AppColors.warning),
                  _Key(label: '÷', onTap: () => onOp(CalcOp.div), color: AppColors.navy, fg: Colors.white, big: true),
                ]),
                const SizedBox(height: 8),
                _Row(children: [
                  _Key(label: '7', onTap: () => onDigit('7')),
                  _Key(label: '8', onTap: () => onDigit('8')),
                  _Key(label: '9', onTap: () => onDigit('9')),
                  _Key(label: '×', onTap: () => onOp(CalcOp.mul), color: AppColors.navy, fg: Colors.white, big: true),
                ]),
                const SizedBox(height: 8),
                _Row(children: [
                  _Key(label: '4', onTap: () => onDigit('4')),
                  _Key(label: '5', onTap: () => onDigit('5')),
                  _Key(label: '6', onTap: () => onDigit('6')),
                  _Key(label: '−', onTap: () => onOp(CalcOp.sub), color: AppColors.navy, fg: Colors.white, big: true),
                ]),
                const SizedBox(height: 8),
                _Row(children: [
                  _Key(label: '1', onTap: () => onDigit('1')),
                  _Key(label: '2', onTap: () => onDigit('2')),
                  _Key(label: '3', onTap: () => onDigit('3')),
                  _Key(label: '+', onTap: () => onOp(CalcOp.add), color: AppColors.navy, fg: Colors.white, big: true),
                ]),
                const SizedBox(height: 8),
                _Row(children: [
                  _Key(label: '±', onTap: onToggleSign),
                  _Key(label: '0', onTap: () => onDigit('0')),
                  _Key(label: '.', onTap: onDot),
                  _Key(label: '=', onTap: onEquals, color: AppColors.emerald, fg: Colors.white, big: true),
                ]),
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
            border: color == null ? Border.all(color: AppColors.border) : null,
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

class _MemBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool active;

  const _MemBtn({required this.label, required this.onTap, required this.active});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: active ? AppColors.turquoiseSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.turquoise : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: enabled
                  ? (active ? AppColors.turquoise : AppColors.textPrimary)
                  : AppColors.textSecondary.withOpacity(0.6),
              fontSize: 13,
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
      return const Center(
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
              const Text(
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
                icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppColors.danger),
                label: const Text(
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
            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, i) {
              final e = history[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                onTap: () => onTap(e),
                title: Text(
                  e.expression,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  e.result,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(
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
