import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RecuperarPasswordService {
  final String baseUrl = dotenv.env['API_URL'] ?? '';

  Future<bool> enviarCorreo(String email) async {
    final url = Uri.parse('$baseUrl/recuperar_password/enviarEMAIL');
    final response = await http.post(url, body: {'email': email});
    return response.statusCode == 200;
  }

  Future<bool> verificarCodigo(String codigo) async {
    final url = Uri.parse('$baseUrl/recuperar_password/verificarCOD');
    final response = await http.post(url, body: {'codigo': codigo});
    return response.statusCode == 200;
  }

  Future<bool> cambiarPassword(String username, String newPassword) async {
    final url = Uri.parse('$baseUrl/usuario/newPassword/$username');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': newPassword}),
    );
    return response.statusCode == 200;
  }

  Future<String?> obtenerUsernameDesdeEmail(String email) async {
    final url = Uri.parse('$baseUrl/usuario/username_email/$email');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['username'];
    }
    return null;
  }

}
