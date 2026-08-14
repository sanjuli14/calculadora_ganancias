import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../notifiers/theme_controller.dart';
import '../theme/app_palettes.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

// Pantalla de personalización: moneda por defecto, modos de visualización y
// paletas de colores. Los cambios se aplican y se guardan al instante.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Personalización')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            const _SectionTitle(
              icon: Icons.payments_outlined,
              title: 'Moneda',
              subtitle:
                  'Define la moneda general de la app (precios, ventas y ganancias). '
                  'Si cambias después de registrar datos, deberás convertir tú los montos.',
            ),
            const SizedBox(height: 12),
            _CurrencySelector(controller: controller),
            const SizedBox(height: 28),

            const _SectionTitle(
              icon: Icons.brightness_6_outlined,
              title: 'Modo de visualización',
              subtitle:
                  'Claro para el día, oscuro para la noche o alto contraste si '
                  'necesitas más legibilidad.',
            ),
            const SizedBox(height: 12),
            _ModeSelector(controller: controller),
            const SizedBox(height: 28),

            const _SectionTitle(
              icon: Icons.palette_outlined,
              title: 'Colores de la app',
              subtitle: 'Elige la paleta que más te guste.',
            ),
            const SizedBox(height: 12),
            _PaletteGrid(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.navySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.navy, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  final ThemeController controller;

  const _CurrencySelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final code in supportedCurrencyCodes) ...[
            _CurrencyTile(code: code, controller: controller),
            if (code != supportedCurrencyCodes.last)
              Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  final String code;
  final ThemeController controller;

  const _CurrencyTile({required this.code, required this.controller});

  @override
  Widget build(BuildContext context) {
    final selected = activeCurrencyCode == code;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: selected ? AppColors.navy : AppColors.navySoft,
        child: Icon(
          _currencyIcon(code),
          size: 18,
          color: selected ? Colors.white : AppColors.navy,
        ),
      ),
      title: Text(
        _currencyName(code),
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        '${currencySymbol(code).trim()} — ${_sampleM(code)}',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: selected
          ? Icon(Icons.check_circle, color: AppColors.emerald)
          : Icon(Icons.radio_button_unchecked, color: AppColors.border),
      onTap: () => controller.setCurrency(code),
    );
  }

  IconData _currencyIcon(String code) {
    switch (code) {
      case 'USD':
        return Icons.attach_money;
      case 'EUR':
        return Icons.euro;
      default:
        return Icons.payments_outlined;
    }
  }

  String _currencyName(String code) {
    switch (code) {
      case 'USD':
        return 'Dólar estadounidense (USD)';
      case 'EUR':
        return 'Euro (EUR)';
      default:
        return 'Peso cubano (CUP)';
    }
  }

  String _sampleM(String code) {
    String formatWith(String symbol) => symbol.isEmpty
        ? formatMoney(1250)
        : NumberFormat.currency(
            locale: 'es',
            symbol: '$symbol ',
            decimalDigits: 2,
          ).format(1250);
    return formatWith(currencySymbol(code).trim());
  }
}

class _ModeSelector extends StatelessWidget {
  final ThemeController controller;

  const _ModeSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    final modes = [
      (AppThemeMode.light, Icons.light_mode_outlined, 'Claro', 'Para el día'),
      (AppThemeMode.dark, Icons.dark_mode_outlined, 'Oscuro', 'Para la noche'),
      (
        AppThemeMode.highContrast,
        Icons.highlight_outlined,
        'Alto contraste',
        'Más legible',
      ),
    ];

    return Column(
      children: [
        for (final (mode, icon, label, hint) in modes)
          _ModeTile(
            mode: mode,
            icon: icon,
            label: label,
            hint: hint,
            selected: controller.mode == mode,
            onSelected: () => controller.setMode(mode),
          ),
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  final AppThemeMode mode;
  final IconData icon;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onSelected;

  const _ModeTile({
    required this.mode,
    required this.icon,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onSelected,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.navy : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.navy : AppColors.navySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : AppColors.navy,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        hint,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.navy : AppColors.border,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteGrid extends StatelessWidget {
  final ThemeController controller;

  const _PaletteGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 340 ? 3 : 2;
        final itemWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final palette in appPalettes)
              _PaletteCard(
                palette: palette,
                width: itemWidth,
                selected: controller.palette.id == palette.id,
                onTap: () => controller.setPalette(palette),
              ),
          ],
        );
      },
    );
  }
}

class _PaletteCard extends StatelessWidget {
  final AppPalette palette;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteCard({
    required this.palette,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.navy : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Swatch(color: palette.primary),
                    const SizedBox(width: 4),
                    _Swatch(color: palette.accent),
                    const SizedBox(width: 4),
                    _Swatch(color: palette.turquoise),
                    const Spacer(),
                    if (selected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.emerald,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  palette.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;

  const _Swatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border, width: 1),
      ),
    );
  }
}
