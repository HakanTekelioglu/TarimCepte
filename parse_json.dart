import 'dart:io';
import 'dart:convert';
void main() {
  final content = File('users.json').readAsStringSync();
  final List j = jsonDecode(content);
  for (var tag in j.where((u) => u['city'] == 'Mersin')) {
     print(tag);
  }
}
