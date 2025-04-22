import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SugerenciasService {
  final String baseUrl = dotenv.env['API_URL'] ?? '';

  Future<List<int>> obtenerIdsSugeridos(List<int> idProductos) async {
    final url = Uri.parse('$baseUrl/producto/recomendar_productos_por_lista');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"productos": idProductos}),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map<int>((e) => e['id_producto'] as int).toList();
    } else {
      return [];
    }
  }
}
