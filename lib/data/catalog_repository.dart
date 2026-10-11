import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../domain/models.dart';

class CatalogRepository {
  static Future<Catalog> load() async {
    final raw = await rootBundle.loadString('assets/catalog.json');
    return Catalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
