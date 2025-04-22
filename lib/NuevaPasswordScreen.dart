import 'package:flutter/material.dart';
import 'package:login/Core/Colors/Hex_Color.dart';
import 'package:login/Core/services/recuperar_service.dart';
import 'package:login/LoginScreen.dart';

class NuevaPasswordScreen extends StatefulWidget {
  final String email;
  const NuevaPasswordScreen({super.key, required this.email});

  @override
  State<NuevaPasswordScreen> createState() => _NuevaPasswordScreenState();
}

class _NuevaPasswordScreenState extends State<NuevaPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nuevaPasswordController = TextEditingController();
  final TextEditingController _confirmarPasswordController = TextEditingController();
  bool _guardando = false;

  Future<void> _guardarNuevaPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final recuperarService = RecuperarPasswordService();
    final username = await recuperarService.obtenerUsernameDesdeEmail(widget.email);

    if (username == null) {
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ No se pudo obtener el nombre de usuario")),
      );
      return;
    }

    final success = await recuperarService.cambiarPassword(
      username,
      _nuevaPasswordController.text,
    );

    setState(() => _guardando = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Contraseña actualizada correctamente")),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error al actualizar la contraseña")),
      );
    }
  }


  @override
  void dispose() {
    _nuevaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Contraseña"), backgroundColor: HexColor("#4b4293")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Escribe tu nueva contraseña"),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nuevaPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Nueva contraseña"),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmarPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirmar contraseña"),
                validator: (value) {
                  if (value != _nuevaPasswordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _guardando ? null : _guardarNuevaPassword,
                icon: const Icon(Icons.save),
                label: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Guardar y continuar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HexColor("#4b4293"),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
