class AppConstants {
  static const List<String> cities = ['Antalya', 'Mersin'];
  
  static const Map<String, List<String>> cityDistricts = {
    'Mersin': [
      'Akdeniz',
      'Mezitli',
      'Toroslar',
      'Yenişehir',
      'Tarsus',
      'Silifke',
      'Erdemli',
      'Mut',
      'Bozyazı',
      'Anamur',
      'Aydıncık',
      'Gülnar',
      'Çamlıyayla'
    ],
    'Antalya': [], // Antalya için ilçe kırılımı istenmedi
  };
}
