import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RegistroService {
  final String baseUrl = dotenv.env['API_URL'] ?? '';

  Future<bool> registrarClienteCompleto({
    required String email,
    required String password,
    required String username,
    required String nombreCompleto,
    required String direccion,
    required String telefono,
  }) async {
    try {
      // Paso 1: Registrar usuario
      final usuarioResponse = await http.post(
        Uri.parse('$baseUrl/usuario/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": username,
          "email": email,
          "tipo_usuario": "cliente",
          "estado": "activo",
          "password": password
        }),
      );
      
      if (usuarioResponse.statusCode != 200 && usuarioResponse.statusCode != 201) {
        print("Error al registrar usuario: ${usuarioResponse.body}");
        return false;
      }

      // Paso 2: Registrar cliente con el mismo username
      final clienteResponse = await http.post(
        Uri.parse('$baseUrl/cliente/registrar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "nombre_completo": nombreCompleto,
          "direccion": direccion,
          "telefono": telefono,
          "estado": "activo",
          "username": username
        }),
      );

      if (clienteResponse.statusCode != 200 && clienteResponse.statusCode != 201) {
        print("Error al registrar cliente: ${clienteResponse.body}");
        return false;
      }

      return true;
    } catch (e) {
      print("Excepción al registrar cliente: $e");
      return false;
    }
  }
}
