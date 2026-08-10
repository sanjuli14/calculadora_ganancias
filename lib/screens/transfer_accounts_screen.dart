import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/transfer_account.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class TransferAccountsScreen extends StatelessWidget {
  const TransferAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas de Transferencia'),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<TransferAccount>>(
          valueListenable: db.transferAccountsListenable,
          builder: (context, box, _) {
            final accounts = db.getTransferAccounts();

            if (accounts.isEmpty) {
              return const _EmptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: accounts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final acc = accounts[index];
                return _AccountCard(
                  account: acc,
                  keyValue: box.keyAt(index),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAccountForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva cuenta'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.navySoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                size: 44,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes cuentas guardadas',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Agrega una cuenta con su QR para mostrarla al cobrar por transferencia.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final TransferAccount account;
  final dynamic keyValue;

  const _AccountCard({required this.account, required this.keyValue});

  @override
  Widget build(BuildContext context) {
    final hasQr = account.qrImagePath.isNotEmpty &&
        File(account.qrImagePath).existsSync();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openAccountForm(context, account: account, key: keyValue),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: account.isDefault ? AppColors.navy : AppColors.border,
              width: account.isDefault ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.navySoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasQr
                    ? Image.file(File(account.qrImagePath), fit: BoxFit.cover)
                    : const Icon(Icons.qr_code_2, color: AppColors.navy, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            account.alias,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (account.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Principal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.bankName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.cardNumber,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showAccountMenu(context),
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountMenu(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!account.isDefault)
                ListTile(
                  leading: const Icon(Icons.star_outline, color: AppColors.navy),
                  title: const Text('Marcar como principal'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    account.isDefault = true;
                    await db.updateTransferAccount(
                      db.transferAccountsBox.values.toList().indexOf(account),
                      account,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cuenta marcada como principal')),
                      );
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.navy),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openAccountForm(context, account: account, key: keyValue);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text(
                  'Eliminar',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar cuenta'),
                      content: const Text('¿Seguro que deseas eliminar esta cuenta?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await db.deleteTransferAccount(keyValue);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cuenta eliminada')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _openAccountForm(
  BuildContext context, {
  TransferAccount? account,
  dynamic key,
}) async {
  final db = Provider.of<DatabaseService>(context, listen: false);
  final aliasController = TextEditingController(text: account?.alias ?? '');
  final bankController = TextEditingController(text: account?.bankName ?? '');
  final cardController = TextEditingController(text: account?.cardNumber ?? '');
  String qrPath = account?.qrImagePath ?? '';
  bool isDefault = account?.isDefault ?? false;
  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final hasQr = qrPath.isNotEmpty && File(qrPath).existsSync();
          return AlertDialog(
            title: Text(account == null ? 'Nueva cuenta' : 'Editar cuenta'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          setState(() => qrPath = image.path);
                        }
                      },
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.navySoft,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: hasQr ? AppColors.navy : AppColors.border,
                            width: hasQr ? 1.6 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasQr
                            ? Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.file(File(qrPath), fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    right: 4,
                                    bottom: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.55),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 32,
                                    color: AppColors.navy,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Foto del QR',
                                    style: TextStyle(
                                      color: AppColors.navy,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (hasQr)
                      TextButton.icon(
                        onPressed: () => setState(() => qrPath = ''),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Quitar QR'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: aliasController,
                      decoration: const InputDecoration(
                        labelText: 'Alias / Nombre',
                        hintText: 'Ej: Mi cuenta principal',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Ingresa un alias';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bankController,
                      decoration: const InputDecoration(
                        labelText: 'Banco',
                        hintText: 'Ej: BPA, BANDEC',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Ingresa el banco';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cardController,
                      decoration: const InputDecoration(
                        labelText: 'Número de tarjeta',
                        hintText: 'Ej: 9205 1234 5678 9012',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      keyboardType: TextInputType.text,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa el número de tarjeta';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isDefault,
                      onChanged: (v) => setState(() => isDefault = v),
                      activeThumbColor: AppColors.navy,
                      title: const Text(
                        'Marcar como cuenta principal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Se mostrará primero al cobrar',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (qrPath.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Agrega la foto del QR')),
                    );
                    return;
                  }
                  final newAccount = TransferAccount(
                    alias: aliasController.text.trim(),
                    bankName: bankController.text.trim(),
                    cardNumber: cardController.text.trim(),
                    qrImagePath: qrPath,
                    isDefault: isDefault,
                  );
                  if (account == null) {
                    await db.addTransferAccount(newAccount);
                  } else {
                    final index = db.transferAccountsBox.values.toList().indexOf(account);
                    await db.updateTransferAccount(index, newAccount);
                  }
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          account == null ? 'Cuenta agregada' : 'Cuenta actualizada',
                        ),
                      ),
                    );
                  }
                },
                child: Text(account == null ? 'Guardar' : 'Actualizar'),
              ),
            ],
          );
        },
      );
    },
  );
}
