import 'package:login/Core/model/product.dart';

class VoiceFilterService {
  final Map<String, String> _numerosTexto = {
    'uno': '1',
    'una': '1',
    'dos': '2',
    'tres': '3',
    'cuatro': '4',
    'cinco': '5',
    'seis': '6',
    'siete': '7',
    'ocho': '8',
    'nueve': '9',
    'diez': '10',
    'once': '11',
    'doce': '12',
    'trece': '13',
    'catorce': '14',
    'quince': '15',
    'veinte': '20',
    'treinta': '30',
    'cien': '100',
    'mil': '1000',
  };

  String limpiarTexto(String input) {
    String limpio = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // elimina signos
        .replaceAll(RegExp(r'\s+'), ' ') // normaliza espacios
        .trim();

    // Reemplazar texto numérico por dígitos
    _numerosTexto.forEach((palabra, numero) {
      limpio = limpio.replaceAll(RegExp('\\b$palabra\\b'), numero);
    });

    return limpio;
  }

  List<Product> filtrarProductosPorComando(List<Product> productos, String comando, {bool porCategoria = false}) {
    final palabrasClave = limpiarTexto(comando).split(' ');

    if (palabrasClave.contains('todos') || palabrasClave.contains('todo') || palabrasClave.contains('productos')) {
      return productos;
    }

    final productosConSimilitud = productos.map((producto) {
      final campo = porCategoria ? limpiarTexto(producto.categoria) : limpiarTexto(producto.nombre);
      final partesCampo = campo.split(' ');
      double puntuacion = palabrasClave.fold(0, (acc, palabra) {
        return acc + _similaridadMaxima(palabra, partesCampo);
      });
      return {'producto': producto, 'puntuacion': puntuacion};
    }).toList();

    productosConSimilitud.sort((a, b) =>
        (b['puntuacion'] as double).compareTo(a['puntuacion'] as double));

    if (productosConSimilitud.isEmpty) return [];

    final mejorPuntaje = productosConSimilitud.first['puntuacion'] as double;

    return productosConSimilitud
        .where((p) {
          final puntaje = p['puntuacion'] as double;
          return porCategoria
              ? puntaje >= 0.4  // más tolerante para categorías
              : puntaje >= mejorPuntaje * 0.7;
        })
        .map((p) => p['producto'] as Product)
        .toList();
  }

  double _similaridadMaxima(String palabra, List<String> opciones) {
    return opciones
        .map((op) => _similaridad(palabra, op))
        .reduce((a, b) => a > b ? a : b);
  }

  double _similaridad(String a, String b) {
    int distancia = _levenshtein(a, b);
    int largo = a.length > b.length ? a.length : b.length;
    return 1 - (distancia / largo);
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<List<int>> matrix = List.generate(
      s.length + 1,
      (_) => List.filled(t.length + 1, 0),
    );

    for (int i = 0; i <= s.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= t.length; j++) matrix[0][j] = j;

    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        int costo = s[i - 1] == t[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + costo
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s.length][t.length];
  }
}
