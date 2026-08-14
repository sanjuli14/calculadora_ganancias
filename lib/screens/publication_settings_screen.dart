import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/database_service.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';

class PublicationSettingsScreen extends StatefulWidget {
  const PublicationSettingsScreen({super.key});

  @override
  State<PublicationSettingsScreen> createState() =>
      _PublicationSettingsScreenState();
}

class _PublicationSettingsScreenState
    extends State<PublicationSettingsScreen> {
  late TextEditingController _businessCtrl;
  late TextEditingController _headerCtrl;
  late TextEditingController _footerCtrl;
  late TextEditingController _phonesCtrl;
  late TextEditingController _priceTagCtrl;

  @override
  void initState() {
    super.initState();
    final db = context.read<DatabaseService>();
    _businessCtrl = TextEditingController(text: db.publicationBusinessName);
    _headerCtrl = TextEditingController(text: db.publicationHeader);
    _footerCtrl = TextEditingController(text: db.publicationFooter);
    _phonesCtrl = TextEditingController(text: db.publicationPhones);
    _priceTagCtrl = TextEditingController(text: db.publicationPriceTag);
  }

  @override
  void dispose() {
    _businessCtrl.dispose();
    _headerCtrl.dispose();
    _footerCtrl.dispose();
    _phonesCtrl.dispose();
    _priceTagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicación'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Guardar',
              style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            const _InfoBanner(),
            const SizedBox(height: 20),
            _Field(
              label: 'Nombre del negocio',
              hint: 'Ej: Bodega La Esquina',
              controller: _businessCtrl,
              maxLines: 1,
            ),
            const SizedBox(height: 14),
            _Field(
              label: 'Encabezado',
              hint: 'Se muestra arriba de la lista',
              controller: _headerCtrl,
              maxLines: 6,
            ),
            const SizedBox(height: 14),
            _Field(
              label: 'Etiqueta de precio',
              hint: 'Ej:  *EFECTIVO*',
              controller: _priceTagCtrl,
              maxLines: 1,
            ),
            const SizedBox(height: 14),
            _Field(
              label: 'Pie',
              hint: 'Se muestra debajo de la lista',
              controller: _footerCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: 14),
            _Field(
              label: 'Teléfonos de contacto',
              hint: 'Uno por línea o separados por coma',
              controller: _phonesCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const _Legend(),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final db = context.read<DatabaseService>();
    await db.setPublicationConfig(
      businessName: _businessCtrl.text,
      header: _headerCtrl.text,
      footer: _footerCtrl.text,
      phones: _phonesCtrl.text,
      priceTag: _priceTagCtrl.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plantilla guardada')),
    );
    Navigator.of(context).pop();
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, color: AppColors.navy, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Configura el texto de la publicación que se compartirá por WhatsApp, '
              'Telegram u otra app. Las fotos de los productos se adjuntan '
              'automáticamente junto al mensaje.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    final products = db.productsBox.values.toList();
    if (products.isEmpty) return const SizedBox.shrink();

    final service = ShareService(db);
    final preview = service.buildPublicationText(products.take(3).toList());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vista previa',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            preview,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
