import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static List<_OnboardingPage> _buildPages() => [
    _OnboardingPage(
      icon: Icons.inventory_2_outlined,
      color: AppColors.navy,
      softColor: AppColors.navySoft,
      title: 'Tu inventario al día',
      description:
          'Registra tus productos con precio de compra y venta. '
          'Controla el stock y recibe alertas cuando un producto esté por agotarse.',
    ),
    _OnboardingPage(
      icon: Icons.point_of_sale_outlined,
      color: AppColors.emerald,
      softColor: AppColors.emeraldSoft,
      title: 'Vende y gana en claro',
      description:
          'Registra cada venta y la app calcula automáticamente tu ganancia. '
          'Revisa el historial por día, semana o mes en la pestaña Ganancias.',
    ),
    _OnboardingPage(
      icon: Icons.receipt_long_outlined,
      color: AppColors.turquoise,
      softColor: AppColors.turquoiseSoft,
      title: 'Fiados sin pérdidas',
      description:
          'Lleva el control de lo que vendes fiado: cuánto te deben, quién te debe '
          'y qué pagos van llegando, todo con su fecha.',
    ),
    _OnboardingPage(
      icon: Icons.savings_outlined,
      color: AppColors.navy,
      softColor: AppColors.navySoft,
      title: 'Tu caja y tus respaldos',
      description:
          'Cuadra la caja contando billetes y compara con lo esperado. '
          'Tus datos se respaldan automáticamente en Descargas con fecha.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _buildPages().length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _finish() {
    final db = context.read<DatabaseService>();
    db.markOnboardingSeen();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AppLogo(fontSize: 18),
                  ),
                  TextButton(onPressed: _finish, child: const Text('Omitir')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _buildPages().length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _buildPages()[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: p.softColor,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(p.icon, size: 64, color: p.color),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          p.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_buildPages().length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.navy : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                child: Text(
                  _page == _buildPages().length - 1 ? 'Empezar' : 'Siguiente',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color color;
  final Color softColor;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.softColor,
    required this.title,
    required this.description,
  });
}
