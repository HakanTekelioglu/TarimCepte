import 'dart:io';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase/supabase.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);
  
  try {
     final query = client.from('product_prices').select('product_id, price_per_kg, updated_at').eq('city', 'Mersin').eq('district', 'Bozyazı/Tekeli').order('updated_at', ascending: false);
     final pricesResponse = await query;
     print("Prices query success: len ${pricesResponse.length}");
     for(var r in pricesResponse) {
       print(r);
     }
  } catch (e) {
     print("Error: $e");
  }
  exit(0);
}
