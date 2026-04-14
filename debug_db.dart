import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase/supabase.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);
  
  try {
     final prods = await client.from('products').select().limit(5);
     print("prods[0]: ${prods.first}");
  } catch (e) {
     print("Error: $e");
  }

  try {
     final q = client.from('product_prices').select().eq('city', 'Mersin');
     final filterQ = q.filter('district', 'is', null);
     final filterRes = await filterQ;
     print("prices is null: ${filterRes.length}");
  } catch (e) {
     print("Error2: $e");
  }
  exit(0);
}
