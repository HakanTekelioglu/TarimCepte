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
     final users = await client.from('users').select('id, full_name, city, district');
     for (var u in users) {
       if (u['city'] == 'Mersin') {
         print("User: ${u['full_name']} - ${u['district']}");
       }
     }
  } catch (e) {
     print("Error: $e");
  }
  exit(0);
}
