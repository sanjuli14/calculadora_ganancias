import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const SectionHeader(title: 'Lo nuevo en esta versión'),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.menu,
              color: AppColors.navy,
              title: 'Menú lateral (sidebar)',
              description:
                  'Arriba a la izquierda hay un botón de menú (☰). Al pulsarlo se abre el '
                  'menú lateral con las opciones: Cuentas de Transferencia, Hacer Backup, '
                  'Exportar Copia e Importar Copia. Ya no hay menú (⋮) arriba a la derecha.',
            ),
            SizedBox(height: 12),
            _InfoCard(
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.emerald,
              title: 'Cuentas para cobrar por transferencia',
              description:
                  'Ahora puedes guardar una o varias cuentas para recibir pagos por '
                  'transferencia. Cada cuenta guarda una foto del QR, el nombre del banco y '
                  'el número de tarjeta. Así, al vender, eliges cuál mostrarle al cliente.',
            ),
            SizedBox(height: 12),
            _InfoCard(
              icon: Icons.add_to_photos_outlined,
              color: AppColors.turquoise,
              title: 'Cómo guardar una cuenta',
              description:
                  'Abre el menú lateral (☰), entra en "Cuentas de Transferencia" y pulsa el '
                  'botón "+". Agrega un alias, el banco, el número de tarjeta y la foto del QR. '
                  'Puedes marcar una cuenta como "principal" para que se muestre primero.',
            ),
            SizedBox(height: 12),
            _InfoCard(
              icon: Icons.payments_outlined,
              color: AppColors.navy,
              title: 'Cómo cobrar mostrando el QR',
              description:
                  'En "Vender", selecciona "Transferencia" como forma de pago. Aparecerá la '
                  'cuenta principal con su QR y el número de tarjeta. Toca "Cambiar" para '
                  'elegir otra cuenta o "Ver QR" para mostrarlo en grande.',
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Tus datos y tu responsabilidad'),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.phone_android,
              color: AppColors.navy,
              title: '¿Dónde viven tus datos?',
              description:
                  'Todos tus productos, ventas, fiados y cajas se guardan SOLO en este teléfono, '
                  'dentro de la app. No se suben a ninguna nube ni servidor. Si pierdes o '
                  'dañas el teléfono, tus datos NO se pueden recuperar de ningún lado.',
            ),
            SizedBox(height: 12),
            _InfoCard(
              icon: Icons.warning_amber,
              color: AppColors.warning,
              title: 'Las actualizaciones normalmente no borran nada',
              description:
                  'Cuando se instala una versión nueva de la app sobre la anterior, tus datos '
                  'se conservan. PERO no hay garantía total: si algo falla durante la '
                  'actualización, o si la app se desinstala (por error o porque Android lo pide), '
                  'todos los datos se pierden para siempre.',
            ),
            SizedBox(height: 12),
            _InfoCard(
              icon: Icons.rule,
              color: AppColors.danger,
              title: 'Lo más importante: nunca desinstales la app',
              description:
                  'Desinstalar "para volver a instalar" BORRA todo. Si te piden actualizar, '
                  'actualiza encima. Si algo sale mal, primero guarda tu copia de seguridad '
                  '(ver más abajo) ANTES de tocar nada.',
            ),
            SizedBox(height: 24),
            const SectionHeader(title: 'Cómo protegerte'),
            SizedBox(height: 12),
            _InfoCard(
              icon: Icons.autorenew,
              color: AppColors.emerald,
              title: 'Copias automáticas en Descargas',
              description:
                  'La app guarda automáticamente una copia de tus datos (archivo .json) en la '
                  'carpeta Descargas/CuentasClaras de tu teléfono cada vez que haces un cambio. '
                  'El archivo lleva la fecha, por ejemplo: cuentas_claras_2026-08-08_14-30.json',
            ),
            SizedBox(height: 12),
            _InfoCard(
              icon: Icons.verified_user,
              color: AppColors.turquoise,
              title: 'Tu regla de oro: respalda en otro lugar',
              description:
                  'Las copias automáticas viven en el mismo teléfono, así que no te protegen si '
                  'el teléfono se daña o se pierde. Cada cierto tiempo envía la copia a otro '
                  'lugar: WhatsApp, correo, tu cuenta de Google, una memoria USB o tu PC.',
            ),
            SizedBox(height: 12),
            _InfoCard(
              icon: Icons.upload_file,
              color: AppColors.navy,
              title: 'Cómo hacer una copia manual',
              description:
                  'Abre el menú lateral (☰) arriba a la izquierda y toca "Exportar Copia". '
                  'La app genera el archivo .json y te deja compartirlo donde quieras. '
                  'Guarda ese archivo en otro lugar para tener tu respaldo.',
            ),
            SizedBox(height: 12),
            _InfoCard(
              icon: Icons.download,
              color: AppColors.emerald,
              title: 'Cómo recuperar tus datos',
              description:
                  'Si reinstalas la app y quieres volver a tener tus datos, abre el menú '
                  'lateral (☰) y elige "Importar Copia". Selecciona el archivo .json que '
                  'guardaste. IMPORTANTE: importa solo después de tener la app instalada y '
                  'funcionando.',
            ),
            SizedBox(height: 24),
            const SectionHeader(title: 'Antes de cada actualización'),
            SizedBox(height: 12),
            const _ChecklistCard(),
            SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.gavel, color: AppColors.warning, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Aviso importante',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'El usuario es responsable de mantener una copia de seguridad de su '
                    'información. El desarrollador de esta app no se hace responsable por '
                    'la pérdida de datos que pueda ocurrir por actualizaciones fallidas, '
                    'desinstalaciones, daño o pérdida del dispositivo, o por no seguir '
                    'estas recomendaciones.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Haz una copia manual (Exportar Copia) y envíala a otro lugar.',
      'Asegúrate de que la batería del teléfono esté cargada.',
      'No desinstales la app para "limpiarla".',
      'Si algo falla al actualizar, no borres nada: contacta a soporte.',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.navy,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i],
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
