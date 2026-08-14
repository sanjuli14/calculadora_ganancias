import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _deviceId = context.read<AuthService>().deviceId;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthService>();
    final code = _controller.text;
    if (code.isEmpty) {
      setState(() => _error = 'Ingresa tu código de licencia');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // Descarga la lista actualizada y valida con la que haya (nueva o cacheada).
    final updated = await auth.refreshClients();
    final valid = auth.validateCode(code);
    if (!valid && !updated) {
      // No hubo internet y la lista local no tiene el código: se permite reintentar
      // ya que quizás el dueño aún no activó este dispositivo.
    }
    if (!valid) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _errorMessage(updated);
      });
      return;
    }
    _goToMain();
  }

  String _errorMessage(bool updated) {
    if (!updated) {
      return 'No se pudo conectar. Revisa tu internet y vuelve a intentar.';
    }
    return 'Código incorrecto o licencia no activada. Envía tu ID de dispositivo al vendedor.';
  }

  void _goToMain() {
    context.read<AuthService>().markLoggedIn();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AppLogo(fontSize: 36),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Bienvenido',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.navySoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.phone_android,
                              color: AppColors.navy,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'ID de tu dispositivo',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _deviceId ?? '',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Copiar ID',
                              onPressed: () async {
                                if (_deviceId == null) return;
                                await Clipboard.setData(
                                  ClipboardData(text: _deviceId!),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('ID copiado')),
                                  );
                                }
                              },
                              icon: Icon(
                                Icons.copy,
                                size: 18,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Envía este ID al vendedor para activar tu licencia.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Código de licencia',
                      prefixIcon: Icon(Icons.key_outlined),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Entrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
