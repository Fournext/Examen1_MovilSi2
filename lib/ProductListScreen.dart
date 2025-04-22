import 'package:flutter/material.dart';
import 'package:login/CartScreen.dart';
import 'package:login/Core/model/product.dart';
import 'package:login/Core/services/productos_service.dart';
import 'package:login/Core/services/sugerencias_service.dart';
import 'package:login/PerfilScreen.dart';
import 'package:login/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:login/Core/Colors/Hex_Color.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:login/Core/services/voice_filter_service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductosService _productosService = ProductosService();
  final SugerenciasService _sugerenciasService = SugerenciasService();
  final VoiceFilterService _voiceFilterService = VoiceFilterService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  List<Product> _todosLosProductos = [];
  List<Product> _productosFiltrados = [];
  List<Product> _sugerencias = [];
  Product? _productoSeleccionado;

  bool _isListening = false;
  String _filtroTexto = '';
  String _tipoFiltro = 'Nombre';
  final List<String> _tiposFiltro = ['Nombre', 'Categoría'];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final productos = await _productosService.getProductos();
      if (!mounted) return;
      setState(() {
        _todosLosProductos = productos;
        _productosFiltrados = productos;
      });
    } catch (e) {
      debugPrint("Error cargando productos: $e");
    }
  }

  void _mostrarTodosLosProductos() {
    setState(() {
      _productoSeleccionado = null;
      _productosFiltrados = _todosLosProductos;
      _sugerencias = [];
    });
  }

  void _filtrarProductosPorTexto(String texto) {
    setState(() {
      _filtroTexto = texto;
    });

    final productosFiltrados = _tipoFiltro == 'Nombre'
        ? _todosLosProductos
            .where((p) => p.nombre.toLowerCase().contains(texto.toLowerCase()))
            .toList()
        : _todosLosProductos
            .where((p) => p.categoria.toLowerCase().contains(texto.toLowerCase()))
            .toList();

    setState(() {
      _productosFiltrados = productosFiltrados;
      _productoSeleccionado = null;
      _sugerencias = [];
    });
  }

  void _filtrarProductosPorVoz(String comando) {
    final productosFiltrados = _voiceFilterService
        .filtrarProductosPorComando(_todosLosProductos, comando)
        .where((p) => _tipoFiltro == 'Nombre'
            ? p.nombre.toLowerCase().contains(comando.toLowerCase())
            : p.categoria.toLowerCase().contains(comando.toLowerCase()))
        .toList();

    setState(() {
      _productosFiltrados = productosFiltrados.isNotEmpty ? productosFiltrados : _todosLosProductos;
      _productoSeleccionado = null;
      _sugerencias = [];
    });
  }

  Future<void> _escucharComando() async {
    if (!_isListening) {
      bool disponible = await _speech.initialize();
      if (disponible) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (resultado) {
          if (resultado.finalResult) {
            _filtrarProductosPorVoz(resultado.recognizedWords);
            if (mounted) setState(() => _isListening = false);
          }
        });
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _manejarClickProducto(Product product) async {
    if (_productoSeleccionado?.id == product.id) {
      _showAddToCartDialog(context, product);
    } else {
      setState(() {
        _productoSeleccionado = product;
        _productosFiltrados = [product];
        _sugerencias = [];
      });

      try {
        final ids = await _sugerenciasService.obtenerIdsSugeridos([product.id]);
        if (!mounted) return;

        final sugeridos = _todosLosProductos
            .where((p) => ids.contains(p.id) && p.id != product.id)
            .toList();

        if (mounted) {
          setState(() => _sugerencias = sugeridos);
        }
      } catch (e) {
        debugPrint("Error obteniendo sugerencias: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: HexColor("#4b4293"),
        title: const Text("Productos", style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
            tooltip: "Buscar por voz",
            onPressed: _escucharComando,
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          )
        ],
      ),
      backgroundColor: const Color(0xFFF1F1F1),
      endDrawer: _buildDrawer(context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _filtrarProductosPorTexto,
                    decoration: const InputDecoration(
                      hintText: 'Buscar...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _tipoFiltro,
                  items: _tiposFiltro.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _tipoFiltro = value);
                      _filtrarProductosPorTexto(_filtroTexto);
                    }
                  },
                )
              ],
            ),
          ),
          Expanded(child: _buildMainContent()),
        ],
      ),
      floatingActionButton: _productoSeleccionado != null
          ? FloatingActionButton.extended(
              backgroundColor: HexColor("#4b4293"),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.arrow_back),
              label: const Text("Ver todos", style: TextStyle(color: Colors.white)),
              onPressed: _mostrarTodosLosProductos,
            )
          : null,
    );
  }

  Widget _buildMainContent() {
    if (_todosLosProductos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        if (_productoSeleccionado != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🟢 Producto Seleccionado:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildProductItem(_productoSeleccionado!),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        if (_sugerencias.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: const Text("🔁 Sugerencias:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        if (_sugerencias.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(10),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.60,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProductItem(_sugerencias[index]),
                childCount: _sugerencias.length,
              ),
            ),
          ),
        if (_productoSeleccionado == null)
          SliverPadding(
            padding: const EdgeInsets.all(10),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.60,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProductItem(_productosFiltrados[index]),
                childCount: _productosFiltrados.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductItem(Product product) {
    return GestureDetector(
      onTap: () => _manejarClickProducto(product),
      child: _buildProductCard(product),
    );
  }

  Widget _buildProductCard(Product product) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 4,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Añade un Container con altura fija para la imagen
        Container(
          height: 150, // Altura fija para la sección de imagen
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: product.imagenUrl.isEmpty
                ? Image.asset('lib/Core/image/default_image.png', fit: BoxFit.cover)
                : Image.network(
                    product.imagenUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset('lib/Core/image/default_image.png', fit: BoxFit.cover);
                    },
                  ),
          ),
        ),
        // Elimina los Expanded y usa un Padding normal
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.nombre, 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis, 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text("Stock: ${product.inventario}", 
                  style: TextStyle(fontSize: 12, color: Colors.green)),
              SizedBox(height: 4),
              Text("Bs.${product.precio.toStringAsFixed(2)}", 
                  style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    ),
  );
}

  void _showAddToCartDialog(BuildContext context, Product product) {
    final cantidadController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Añadir al carrito", style: TextStyle(color: HexColor("#4b4293"))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("¿Cuántas unidades de '${product.nombre}' desea añadir? (Máximo: ${product.inventario})"),
            const SizedBox(height: 10),
            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Cantidad", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              final cantidad = int.tryParse(cantidadController.text) ?? 1;
              if (cantidad > product.inventario || cantidad <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cantidad inválida. Stock disponible: ${product.inventario}")));
                return;
              }
              Provider.of<CartProvider>(context, listen: false).addProduct(product, cantidad);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${product.nombre} añadido al carrito.")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: HexColor("#4b4293")),
            child: const Text("Añadir"),
          )
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: HexColor("#4b4293")),
            child: const Text('Menú de Opciones', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Carrito de Compras'),
            onTap: () async {
              final cartProvider = Provider.of<CartProvider>(context, listen: false);
              cartProvider.setProductosCompletos(_todosLosProductos);
              await cartProvider.cargarDesdeBackend();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
    );
  }
}
