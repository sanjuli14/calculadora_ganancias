import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../models/product.dart';
import 'database_service.dart';

class ShareService {
  final DatabaseService db;

  ShareService(this.db);

  // Genera el texto de la publicación a partir de los productos.
  // El formato coincide con el ejemplo de WhatsApp del usuario:
  //   encabezado + lista + pie + teléfonos.
  String buildPublicationText(List<Product> products) {
    final businessName = db.publicationBusinessName.trim();
    final header = db.publicationHeader;
    final footer = db.publicationFooter;
    final phones = db.publicationPhones.trim();
    final priceTag = db.publicationPriceTag;

    final lines = <String>[];
    if (businessName.isNotEmpty) {
      lines.add('🏪 *$businessName*');
      lines.add('');
    }
    lines.add(header.trim().isEmpty ? '💯 *Disponible*:' : header);
    for (final p in products) {
      if (p.stock <= 0) continue;
      final priceStr = _formatPrice(p.sellPrice);
      lines.add('${p.name} - $priceStr$priceTag');
    }
    if (footer.trim().isNotEmpty) {
      lines.add(footer);
    }
    if (phones.isNotEmpty) {
      lines.add('');
      lines.add('⚠️ *Si no estoy en línea:*');
      lines.add(phones);
    }
    return lines.join('\n');
  }

  String _formatPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  // Comparte la publicación: texto + imágenes de los productos que tengan foto.
  // Las imágenes válidas se envían como adjuntos junto al texto.
  Future<ShareResultStatus> sharePublication(List<Product> products) async {
    final text = buildPublicationText(products);
    final images = <XFile>[];
    for (final p in products) {
      final path = p.imagePath;
      if (path == null) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      images.add(XFile(path, name: '${_slug(p.name)}.jpg'));
    }

    if (images.isEmpty) {
      await Share.share(text, subject: 'Lista de precios');
      return ShareResultStatus.success;
    }

    final result = await Share.shareXFiles(
      images,
      text: text,
      subject: 'Lista de precios',
    );
    return result.status;
  }

  String _slug(String input) {
    final cleaned = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return cleaned.isEmpty ? 'producto' : cleaned;
  }
}
