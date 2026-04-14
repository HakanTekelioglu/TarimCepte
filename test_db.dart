import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);
  try {
    final response = await client.from('products').select().limit(1);
    print("products: $response");
  } catch(e){ print("Err products: $e"); }
  try {
    final response = await client.from('product_prices').select().limit(1);
    print("product_prices: $response");
  } catch(e){ print("Err prices: $e"); }
  exit(0);
}
