import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/sale.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  int _inventoryDay = DateTime.friday; // Default to Friday
  DateTime? _customStart;
  DateTime? _customEnd;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStart = picked;
        } else {
          _customEnd = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    final customSales = (_customStart != null && _customEnd != null)
        ? databaseService.getSalesBetween(_customStart!, _customEnd!)
        : <Sale>[];

    final customSummary = databaseService.calculateSummary(customSales);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Ventas'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Resumen Personalizado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(context, true),
                      child: Text(_customStart == null
                          ? 'Seleccionar Fecha Inicio'
                          : 'Inicio: ${_customStart!.day}/${_customStart!.month}/${_customStart!.year}'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(context, false),
                      child: Text(_customEnd == null
                          ? 'Seleccionar Fecha Fin'
                          : 'Fin: ${_customEnd!.day}/${_customEnd!.month}/${_customEnd!.year}'),
                    ),
                  ),
                ],
              ),
              if (_customStart != null && _customEnd != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Aspecto')),
                        DataColumn(label: Text('Valor')),
                      ],
                      rows: [
                        DataRow(cells: [
                          const DataCell(Text('Total Ventas')),
                          DataCell(Text('\$${customSummary['totalSales']!.toStringAsFixed(2)}')),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Total Ganancias')),
                          DataCell(Text('\$${customSummary['totalProfit']!.toStringAsFixed(2)}')),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Número de Ventas')),
                          DataCell(Text('${customSales.length}')),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
