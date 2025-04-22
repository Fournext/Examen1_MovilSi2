import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class PerfilService {
  final String baseUrl = dotenv.env['API_URL'] ?? '';

  Future<int?> _getIdUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) return null;
    final payload = JwtDecoder.decode(token);
    return payload['id'];
  }

  Future<String?> obtenerUrlImagenPerfil() async {
    final idUsuario = await _getIdUsuario();
    if (idUsuario == null) return null;

    final response = await http.get(Uri.parse('$baseUrl/usuario/getURL/$idUsuario'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['url'];
    }
    return null;
  }

  Future<bool> guardarUrlImagenPerfil(String urlImagen) async {
    final idUsuario = await _getIdUsuario();
    if (idUsuario == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/usuario/insertarURL'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_usuario': idUsuario,
        'url': urlImagen,
      }),
    );
    return response.statusCode == 200;
  }

  Future<String?> subirACloudinary(File imagen) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dmfl4ahiy/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'Examen1_S12'
      ..files.add(await http.MultipartFile.fromPath('file', imagen.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      return data['secure_url'];
    }
    return null;
  }

  Future<bool> actualizarDatosCliente({
    required String nombre,
    required String direccion,
    required String telefono,
  }) async {
    final idUsuario = await _getIdUsuario();
    if (idUsuario == null) return false;

    final url = Uri.parse('$baseUrl/cliente/actualizar');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre_completo': nombre,
          'direccion': direccion,
          'telefono': telefono,
          'estado': 'activo',
          'id_usuario': idUsuario
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

}
