import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/estacion.dart';

class ApiService {
  // Nota: 10.0.2.2 es el localhost para el emulador Android.
  // Si usa Linux Desktop o Web, use 'localhost'.
  final String baseUrl = "http://127.0.0.1:8000";

  Future<List<Estacion>> fetchEstaciones() async {
    final response = await http.get(Uri.parse('$baseUrl/estaciones/'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Estacion.fromJson(data)).toList();
    } else {
      throw Exception('Falla al conectar con el servidor SMAT');
    }
  }
}
