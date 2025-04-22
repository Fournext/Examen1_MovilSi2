import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login/Core/Animation/Fade_Animation.dart';
import 'package:login/Core/Colors/Hex_Color.dart';
import 'package:login/Core/services/cliente_service.dart';
import 'package:login/Core/services/perfil_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final ClienteService _clienteService = ClienteService();
  final PerfilService _perfilService = PerfilService();

  bool cargando = true;
  bool _modoEdicion = false;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    cargarDatosPerfil();
  }

  Future<void> cargarDatosPerfil() async {
    final datos = await _clienteService.getClienteDatos();
    final url = await _perfilService.obtenerUrlImagenPerfil();

    setState(() {
      _nombreController.text = datos?['nombre_completo'] ?? '';
      _direccionController.text = datos?['direccion'] ?? '';
      _telefonoController.text = datos?['telefono'] ?? '';
      imageUrl = url;
      cargando = false;
    });
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);
    if (imagen == null) return;

    final url = await _perfilService.subirACloudinary(File(imagen.path));
    if (url != null) {
      final ok = await _perfilService.guardarUrlImagenPerfil(url);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto actualizada ✅")),
        );
        cargarDatosPerfil();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al guardar la imagen 😓")),
        );
      }
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await _perfilService.actualizarDatosCliente(
      nombre: _nombreController.text,
      direccion: _direccionController.text,
      telefono: _telefonoController.text,
    );
    

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Información actualizada ✅")),
      );
      setState(() => _modoEdicion = false);
      cargarDatosPerfil();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar 😓")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              HexColor("#4b4293").withOpacity(0.8),
              HexColor("#4b4293"),
              HexColor("#08418e"),
              HexColor("#08418e")
            ],
          ),
        ),
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 5,
                    color: const Color.fromARGB(255, 171, 211, 250).withOpacity(0.4),
                    child: Container(
                      width: 400,
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeAnimation(
                            delay: 0.8,
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage: imageUrl != null
                                  ? NetworkImage(imageUrl!)
                                  : const AssetImage('lib/Core/image/default_image.png')
                                      as ImageProvider,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _seleccionarImagen,
                            icon: const Icon(Icons.photo_library),
                            label: const Text("Cambiar foto"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HexColor("#2697FF"),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nombreController,
                                  enabled: _modoEdicion,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(labelText: "Nombre"),
                                  validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                                ),
                                TextFormField(
                                  controller: _direccionController,
                                  enabled: _modoEdicion,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(labelText: "Dirección"),
                                  validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                                ),
                                TextFormField(
                                  controller: _telefonoController,
                                  enabled: _modoEdicion,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(labelText: "Teléfono"),
                                  validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/products'),
                            child: const Text("Volver a productos"),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text("Editar"),
                            onPressed: () => setState(() => _modoEdicion = !_modoEdicion),
                          ),
                          if (_modoEdicion)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text("Confirmar"),
                              onPressed: _guardarCambios,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
