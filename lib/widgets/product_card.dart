import 'package:flutter/material.dart';
import 'dart:io';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate potential profit per unit
    final profit = product.sellPrice - product.buyPrice;
    final profitPercent = (profit / product.buyPrice) * 100;
    
    // Stock visual indicator
    Color stockColor;
    String stockLabel;
    if (product.stock == 0) {
      stockColor = Colors.red;
      stockLabel = 'Agotado';
    } else if (product.stock < 5) {
      stockColor = Colors.orange;
      stockLabel = 'Bajo Stock';
    } else {
      stockColor = Colors.green;
      stockLabel = 'En Stock';
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit, // Allow tapping card to edit
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: product.imagePath != null && File(product.imagePath!).existsSync()
                        ? Image.file(
                            File(product.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(Icons.broken_image, 
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  size: 24,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              product.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: stockColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: stockColor),
                              ),
                              child: Text(
                                '$stockLabel (${product.stock})',
                                style: TextStyle(color: stockColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Editar')]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))]),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriceColumn(context, 'Compra', product.buyPrice),
                  _buildPriceColumn(context, 'Venta', product.sellPrice),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Ganancia', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        '\$${profit.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                      ),
                      Text(
                        '${profitPercent.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceColumn(BuildContext context, String label, double price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          '\$${price.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
