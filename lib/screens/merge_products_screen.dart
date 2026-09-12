import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Fusiona productos duplicados: elige el producto principal (keeper) y los
/// que se fundirán en él. Se suman los stocks, se unifica el historial
/// (ventas, compras, mermas y fiados) y los absorbidos salen del catálogo.
class MergeProductsScreen extends StatefulWidget {
  const MergeProductsScreen({super.key});

  @override
  State<MergeProductsScreen> createState() => _MergeProductsScreenState();
}

class _MergeProductsScreenState extends State<MergeProductsScreen> {
  Product? _keeper;
  final List<Product> _absorbed = [];
  bool _showLikelyDuplicates = false;

  List<Product> _listForKeeper(List<Product> products) {
    if (!_showLikelyDuplicates || _keeper == null) return products;
    final keeper = _keeper!;
    return products
        .where((p) => p.sellPrice == keeper.sellPrice)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fusionar Productos',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<Product>>(
          valueListenable: db.productsListenable,
          builder: (context, box, _) {
            final products = box.values.toList()
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

            if (products.length < 2) {
              return const _EmptyState();
            }

            // Descarta absorbidos que dejaron de existir.
            _absorbed.removeWhere((p) => !box.values.contains(p));
            if (_keeper != null && !box.values.contains(_keeper)) {
              _keeper = null;
              _absorbed.clear();
            }

            // Objetos para el dropdown del producto principal.
            final absorbCandidates = products
                .where((p) => p != _keeper)
                .toList();
            absorbCandidates.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
            final visibleCandidates = _listForKeeper(absorbCandidates);

            final int stockAfter = _keeper != null
                ? _keeper!.stock +
                    _absorbed.fold<int>(0, (sum, p) => sum + p.stock)
                : 0;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      _buildInstruction(),
                      const SizedBox(height: 16),
                      _buildKeeperDropdown(products),
                      const SizedBox(height: 10),
                      _buildDuplicatesToggle(),
                      if (_keeper != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Se fundirán con "${_keeper!.name}"',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_showLikelyDuplicates &&
                            visibleCandidates.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'No hay productos con el mismo precio de venta.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        for (final product in visibleCandidates)
                          _MergeCandidateTile(
                            product: product,
                            selected: _absorbed.contains(product),
                            references: db.ledgerReferences(product),
                            onChanged: (checked) {
                              setState(() {
                                if (checked) {
                                  _absorbed.add(product);
                                } else {
                                  _absorbed.remove(product);
                                }
                              });
                            },
                          ),
                        if (visibleCandidates.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'No hay otros productos en el catálogo.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                if (_keeper != null)
                  _buildFooter(stockAfter),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInstruction() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.call_merge, color: AppColors.navy, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unifica artículos duplicados',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Elige el producto que se queda y marca los que son el '
                  'mismo artículo. El stock se suma y todo el historial '
                  'queda bajo el producto principal.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeeperDropdown(List<Product> products) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<Product>(
        key: ValueKey(_keeper?.name),
        initialValue: _keeper,
        isExpanded: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: 'Producto principal (se queda)',
          labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        icon: Icon(Icons.expand_more, color: AppColors.navy),
        items: [
          for (final product in products)
            DropdownMenuItem<Product>(
              value: product,
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (value) {
          setState(() {
            if (_keeper != null && value != null && _absorbed.contains(value)) {
              _absorbed.remove(value);
            }
            _keeper = value;
          });
        },
      ),
    );
  }

  Widget _buildDuplicatesToggle() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: _showLikelyDuplicates,
      onChanged: (v) => setState(() => _showLikelyDuplicates = v),
      activeTrackColor: AppColors.turquoise,
      title: Text(
        'Solo posibles duplicados',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Muestra solo productos con el mismo precio de venta',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }

  Widget _buildFooter(int stockAfter) {
    final absorbedCount = _absorbed.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryCard(stockAfter, absorbedCount),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: absorbedCount > 0 ? _confirmMerge : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  disabledBackgroundColor: AppColors.border,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.call_merge),
                label: Text(
                  absorbedCount > 0
                      ? 'Fusionar ${absorbedCount == 1 ? 'producto' : 'productos'} en ${_keeper!.name}'
                      : 'Selecciona qué productos fusionar',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int stockAfter, int absorbedCount) {
    final keeperName = _keeper!.name;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navyDark, AppColors.navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Resultado de la fusión',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ResultLine(
            label: 'Stock final de $keeperName',
            value: '${_keeper!.stock} → $stockAfter uds.',
            valueColor: AppColors.turquoise,
          ),
          const SizedBox(height: 6),
          _ResultLine(
            label: 'Productos que se fusionan',
            value: _plural(absorbedCount),
          ),
        ],
      ),
    );
  }

  String _plural(int count) => count == 1 ? '1 producto' : '$count productos';

  Future<void> _confirmMerge() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final keeper = _keeper!;
    final absorbed = List<Product>.from(_absorbed);
    final keeperName = keeper.name;

    // Total de registros del libro mayor que se unificarán.
    var refs = 0;
    for (final p in absorbed) {
      refs += db
          .ledgerReferences(p)
          .values
          .fold(0, (sum, v) => sum + v);
    }

    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('¿Fusionar productos?'),
          content: Text(
            'El stock de ${absorbed.length == 1 ? 'este producto' : 'estos productos'} '
            'se sumará a "$keeperName" y se eliminarán del catálogo.\n\n'
            '${refs > 0 ? '$refs registros del historial se unificarán bajo "$keeperName".' : 'Estos productos no tienen historial registrado.'}'
            '\n\nNo se puede deshacer.',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Fusionar'),
            ),
          ],
        );
      },
    );

    if (sure != true || !mounted) return;

    await db.mergeProducts(keeper: keeper, absorbed: absorbed);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${absorbed.length} producto${absorbed.length == 1 ? '' : 's'} '
          'fusionado${absorbed.length == 1 ? '' : 's'} en "$keeperName"',
        ),
      ),
    );
    setState(() {
      _keeper = null;
      _absorbed.clear();
    });
  }
}

class _ResultLine extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _ResultLine({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MergeCandidateTile extends StatelessWidget {
  final Product product;
  final bool selected;
  final Map<String, int> references;
  final ValueChanged<bool> onChanged;

  const _MergeCandidateTile({
    required this.product,
    required this.selected,
    required this.references,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalRefs = references.values.fold(0, (sum, v) => sum + v);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.turquoise : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: (v) => onChanged(v ?? false),
        activeColor: AppColors.turquoise,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'Stock: ${product.stock} • Vent: ${formatMoney(product.sellPrice)}'
            '${totalRefs > 0 ? ' • $totalRefs en historial' : ''}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.navySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.inventory_2_outlined, color: AppColors.navy, size: 20),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.navySoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.call_merge, size: 44, color: AppColors.navy),
            ),
            const SizedBox(height: 20),
            Text(
              'Necesitas al menos 2 productos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega productos duplicados al inventario y luego vuelve '
              'aquí para unificarlos en uno solo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}