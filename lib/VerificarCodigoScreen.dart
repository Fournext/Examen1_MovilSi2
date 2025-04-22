import 'dart:async';
import 'package:flutter/material.dart';
import 'package:login/Core/Colors/Hex_Color.dart';
import 'package:login/Core/services/recuperar_service.dart';
import 'package:login/NuevaPasswordScreen.dart';

class VerificarCodigoScreen extends StatefulWidget {
  final String email;
  const VerificarCodigoScreen({super.key, required this.email});

  @override
  State<VerificarCodigoScreen> createState() => _VerificarCodigoScreenState();
}

class _VerificarCodigoScreenState extends State<VerificarCodigoScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _verificando = false;
  bool _puedeReenviar = false;
  int _contador = 20;
  Timer? _timer;

  final RecuperarPasswordService _recuperarService = RecuperarPasswordService();

  @override
  void initState() {
    super.initState();
    _iniciarContador();
  }

  void _iniciarContador() {
    setState(() {
      _contador = 20;
      _puedeReenviar = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_contador > 0) {
        setState(() => _contador--);
      } else {
        setState(() => _puedeReenviar = true);
        timer.cancel();
      }
    });
  }

  Future<void> _verificarCodigo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _verificando = true);
    final success = await _recuperarService.verificarCodigo(_codigoController.text.trim());
    setState(() => _verificando = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NuevaPasswordScreen(email: widget.email),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Código incorrecto")),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verificar Código"),
        backgroundColor: HexColor("#4b4293"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("Introduce el código de 5 dígitos enviado a tu correo."),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _codigoController,
                keyboardType: TextInputType.number,
                maxLength: 5,
                decoration: const InputDecoration(
                  labelText: "Código de verificación",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length != 5) {
                    return 'El código debe tener 5 dígitos';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _verificando ? null : _verificarCodigo,
              icon: const Icon(Icons.check),
              label: _verificando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Confirmar código"),
              style: ElevatedButton.styleFrom(
                backgroundColor: HexColor("#4b4293"),
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _puedeReenviar
                  ? "✅ Puedes reenviar el correo"
                  : "⌛ Reintenta en $_contador segundos",
              style: TextStyle(color: HexColor("#4b4293")),
            ),
          ],
        ),
      ),
    );
  }
}
