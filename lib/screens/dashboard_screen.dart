import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../notifiers/nav_notifier.dart';
import '../models/sale.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/stat_card.dart';
import '../widgets/section_header.dart';
import 'fiados_screen.dart';
import 'summary_screen.dart';
import 'help_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: db.metaListenable,
          builder: (context, metaBox, _) {
            return ValueListenableBuilder(
              valueListenable: db.salesListenable,
              builder: (context, salesBox, _) {
                return ValueListenableBuilder(
                  valueListenable: db.productsListenable,
                  builder: (context, productsBox, _) {
                    return ValueListenableBuilder(
                      valueListenable: db.debtsListenable,
                      builder: (context, debtsBox, _) {
                        final allSales = salesBox.values.toList().cast<Sale>();
                        final totalRevenue = allSales.fold(
                          0.0,
                          (s, x) => s + x.total,
                        );
                        final totalProfit = allSales.fold(
                          0.0,
                          (s, x) => s + x.profit,
                        );
                        final invested = db.getInvestedCapital();
                        final inventoryValue = db.getInventoryValue();
                        final outstanding = db.getTotalOutstanding();
                        final lowStock = db.getLowStockProducts();

                        final now = DateTime.now();
                        final greeting = _greeting(now.hour);
                        final dateStr = DateFormat(
                          'EEEE, d MMMM yyyy',
                          'es',
                        ).format(now);

                        return RefreshIndicator(
                          onRefresh: () async {},
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    8,
                                    20,
                                    8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    '$greeting 👋',
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  dateStr[0].toUpperCase() +
                                                      dateStr.substring(1),
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'Resumen por fechas',
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const SummaryScreen(),
                                                ),
                                              );
                                            },
                                            style: IconButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.surface,
                                              side: const BorderSide(
                                                color: AppColors.border,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.calendar_month,
                                              color: AppColors.navy,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'Ayuda',
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const HelpScreen(),
                                                ),
                                              );
                                            },
                                            style: IconButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.surface,
                                              side: const BorderSide(
                                                color: AppColors.border,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.help_outline,
                                              color: AppColors.navy,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _HeroCard(
                                        totalProfit: totalProfit,
                                        totalRevenue: totalRevenue,
                                        salesCount: allSales.length,
                                      ),
                                      const SizedBox(height: 20),
                                      _InvestmentCard(
                                        totalInvestment: db.totalInvestment,
                                        onEdit: () =>
                                            _editInvestment(context, db),
                                      ),
                                      const SizedBox(height: 20),
                                      const SectionHeader(
                                        title: 'Resumen financiero',
                                        subtitle: 'Tu dinero de un vistazo',
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: StatCard(
                                              label: 'Dinero invertido',
                                              value: invested,
                                              icon: Icons
                                                  .account_balance_wallet_outlined,
                                              color: AppColors.navy,
                                              softColor: AppColors.navySoft,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: StatCard(
                                              label: 'Por cobrar (fiados)',
                                              value: outstanding,
                                              icon: Icons.handshake_outlined,
                                              color: AppColors.warning,
                                              softColor: AppColors.warningSoft,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: StatCard(
                                              label: 'Valor inventario',
                                              value: inventoryValue,
                                              icon: Icons.inventory_2_outlined,
                                              color: AppColors.turquoise,
                                              softColor:
                                                  AppColors.turquoiseSoft,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: StatCard(
                                              label: 'Ganancias totales',
                                              value: totalProfit,
                                              icon: Icons.savings_outlined,
                                              color: AppColors.emerald,
                                              softColor: AppColors.emeraldSoft,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      const SectionHeader(
                                        title: 'Acciones rápidas',
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _QuickAction(
                                              icon: Icons.add_shopping_cart,
                                              label: 'Nueva Venta',
                                              color: AppColors.emerald,
                                              onTap: () {
                                                Provider.of<MainNavNotifier>(
                                                  context,
                                                  listen: false,
                                                ).goTo(2);
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _QuickAction(
                                              icon: Icons.inventory_2_outlined,
                                              label: 'Nuevo Producto',
                                              color: AppColors.navy,
                                              onTap: () {
                                                Provider.of<MainNavNotifier>(
                                                  context,
                                                  listen: false,
                                                ).goTo(1);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _QuickAction(
                                              icon: Icons.payments_outlined,
                                              label: 'Caja Contable',
                                              color: AppColors.turquoise,
                                              onTap: () {
                                                Provider.of<MainNavNotifier>(
                                                  context,
                                                  listen: false,
                                                ).goTo(4);
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _QuickAction(
                                              icon: Icons.handshake_outlined,
                                              label: 'Cuentas por Cobrar',
                                              color: AppColors.warning,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const FiadosScreen(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (lowStock.isNotEmpty) ...[
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                                    child: SectionHeader(
                                      title: 'Alerta de stock bajo',
                                    ),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      12,
                                      20,
                                      8,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.warningSoft,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.warning.withOpacity(
                                            0.4,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            color: AppColors.warning,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              '${lowStock.length} producto${lowStock.length == 1 ? '' : 's'} con stock bajo o agotado.',
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Provider.of<MainNavNotifier>(
                                                context,
                                                listen: false,
                                              ).goTo(1);
                                            },
                                            child: const Text('Ver'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (allSales.isNotEmpty) ...[
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      20,
                                      20,
                                      12,
                                    ),
                                    child: SectionHeader(
                                      title: 'Ventas recientes',
                                      trailing: TextButton(
                                        onPressed: () {
                                          Provider.of<MainNavNotifier>(
                                            context,
                                            listen: false,
                                          ).goTo(3);
                                        },
                                        child: const Text('Ver todas'),
                                      ),
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    24,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final sale =
                                            allSales[allSales.length -
                                                1 -
                                                index];
                                        return _RecentSaleTile(sale: sale);
                                      },
                                      childCount: allSales.length > 4
                                          ? 4
                                          : allSales.length,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  Future<void> _editInvestment(BuildContext context, DatabaseService db) async {
    final controller = TextEditingController(
      text: db.totalInvestment == 0 ? '' : db.totalInvestment.toString(),
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Inversión total'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa el total de dinero que has invertido en tu negocio.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Inversión',
                prefixText: 'CUP ',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );
              if (value != null && value >= 0) {
                db.setTotalInvestment(value);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final double totalProfit;
  final double totalRevenue;
  final int salesCount;

  const _HeroCard({
    required this.totalProfit,
    required this.totalRevenue,
    required this.salesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.turquoise],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.savings_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Ganancia total',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatMoney(totalProfit),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStat(label: 'Ventas', value: '$salesCount'),
              Container(width: 1, height: 32, color: Colors.white24),
              _HeroStat(
                label: 'Ingresos',
                value: formatMoneyCompact(totalRevenue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InvestmentCard extends StatelessWidget {
  final double totalInvestment;
  final VoidCallback onEdit;

  const _InvestmentCard({required this.totalInvestment, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.turquoise, AppColors.emerald],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inversión total',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMoney(totalInvestment),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Editar inversión',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
            icon: const Icon(
              Icons.edit_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSaleTile extends StatelessWidget {
  final Sale sale;

  const _RecentSaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM • HH:mm').format(sale.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.emeraldSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.emerald,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.productName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$dateStr • ${sale.quantity} u',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${formatMoney(sale.total)}',
                style: const TextStyle(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                'ganancia ${formatMoney(sale.profit)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
