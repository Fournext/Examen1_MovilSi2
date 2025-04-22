import 'package:flutter/material.dart';
import 'package:login/Core/Animation/Fade_Animation.dart';
import 'package:login/Core/Colors/Hex_Color.dart';
import 'package:login/Core/services/register_service%20.dart';
import 'LoginScreen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.1, 0.4, 0.7, 0.9],
            colors: [
              HexColor("#4b4293").withOpacity(0.8),
              HexColor("#4b4293"),
              HexColor("#08418e"),
              HexColor("#08418e")
            ],
          ),
          image: DecorationImage(
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              HexColor("#fff").withOpacity(0.2),
              BlendMode.dstATop,
            ),
            image: const NetworkImage(
              'https://mir-s3-cdn-cf.behance.net/project_modules/fs/01b4bd84253993.5d56acc35e143.jpg',
            ),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 5,
              color: const Color.fromARGB(255, 171, 211, 250).withOpacity(0.4),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeAnimation(
                        delay: 0.8,
                        child: Image.network(
                          "https://cdn-icons-png.flaticon.com/512/5087/5087579.png",
                          width: 80,
                          height: 80,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Registro de nuevo cliente",
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(_nombreController, 'Nombre completo'),
                      _buildInputField(_direccionController, 'Dirección'),
                      _buildInputField(_telefonoController, 'Teléfono', keyboardType: TextInputType.phone),
                      _buildInputField(_emailController, 'Email', keyboardType: TextInputType.emailAddress, isEmail: true),
                      _buildInputField(_usernameController, 'Username'),
                      _buildInputField(_passwordController, 'Contraseña', isPassword: true),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _registrarUsuario,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2697FF),
                                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                              ),
                              child: const Text("Registrarse", style: TextStyle(color: Colors.white)),
                            ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        ),
                        child: const Text("¿Ya tienes una cuenta? Inicia sesión", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Campo obligatorio';
          if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Correo no válido';
          if (isPassword && value.length < 6) return 'Mínimo 6 caracteres';
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          fillColor: Colors.white.withOpacity(0.8),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final service = RegistroService();
    final exito = await service.registrarClienteCompleto(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      nombreCompleto: _nombreController.text.trim(),
      direccion: _direccionController.text.trim(),
      telefono: _telefonoController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario registrado correctamente ✅")),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al registrar el usuario ❌")),
      );
    }
  }
}
