import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/off_product.dart';

// Thin client for the Open Food Facts read API (free, no auth). Used to turn a
// scanned barcode into exact packaged-product nutrition, which the LLM parser
// can only estimate. Returns null on any miss (not found, no nutrition, error)
// so the caller can fall back to manual entry.
class OpenFoodFactsClient {
  static const _fields =
      'product_name,product_name_de,brands,quantity,serving_size,serving_quantity,nutriments';

  Future<OffProduct?> lookupByBarcode(String barcode) async {
    final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json?fields=$_fields');
    try {
      final res = await http.get(url, headers: {
        // OFF asks clients to identify themselves with a descriptive UA.
        'user-agent': 'NourishMe/1.0 (Flutter; nutrition app)',
      }).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null; // 404 = unknown barcode
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (body['status'] != 1) return null; // 0 = product not found
      final product = body['product'];
      if (product is! Map<String, dynamic>) return null;
      return OffProduct.fromOffJson(product);
    } catch (e) {
      debugPrint('OFF lookup failed for $barcode: $e');
      return null;
    }
  }
}
