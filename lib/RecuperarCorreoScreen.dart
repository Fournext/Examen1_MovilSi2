import 'package:flutter/material.dart';
import 'package:login/Core/Colors/Hex_Color.dart';
import 'package:login/Core/services/recuperar_service.dart';
import 'package:login/VerificarCodigoScreen.dart';

class RecuperarCorreoScreen extends StatefulWidget {
  const RecuperarCorreoScreen({super.key});

  @override
  State<RecuperarCorreoScreen> createState() => _RecuperarCorreoScreenState();
}

class _RecuperarCorreoScreenState extends State<RecuperarCorreoScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _enviando = false;

  Future<void> _enviarEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);
    final success = await RecuperarPasswordService().enviarCorreo(_emailController.text.trim());
    setState(() => _enviando = false);

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificarCodigoScreen(email: _emailController.text.trim()),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error al enviar el correo")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recuperar Cuenta"),
        backgroundColor: HexColor("#4b4293"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Introduce tu correo electrónico para recuperar tu cuenta.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Correo electrónico",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty || !value.contains('@')) {
                    return 'Introduce un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _enviando ? null : _enviarEmail,
                  icon: const Icon(Icons.send,color: Colors.white,),
                  label: _enviando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Recuperar cuenta",style: TextStyle(
                                color: Colors.white, letterSpacing: 0.5),
                                ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HexColor("#4b4293"),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
