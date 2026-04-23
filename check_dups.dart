import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase/supabase.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);
  
  final prods = await client.from('products').select('id, name, price_per_kg').eq('name', 'Salatalık');
  print("Salatalık instances in products:");
  for (var p in prods) {
    print(p);
  }
  
  final prices = await client.from('product_prices').select('id, product_id, city, district, price_per_kg').eq('city', 'Mersin').eq('district', 'Bozyazı/Tekeli');
  print("\nPrices for Bozyazı/Tekeli:");
  for (var p in prices.where((p) => prods.any((prod) => prod['id'] == p['product_id']))) {
    print(p);
  }
  exit(0);
}
