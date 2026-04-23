class AppConstants {
  static const List<String> cities = ['Antalya', 'Mersin'];
  
  static const Map<String, List<String>> cityDistricts = {
    'Mersin': [
      'Merkez',
      'Tarsus',
      'Erdemli',
      'Aydıncık',
      'Bozyazı/Tekeli',
      'Anamur'
    ],
    'Antalya': [
      'Alanya',
      'Gazipaşa',
      'Manavgat',
      'Serik',
      'Kepez'
    ],
  };

  static String? normalizeDistrict(String city, String? district) {
    if (district == null || district.isEmpty) {
      final distList = cityDistricts[city] ?? [];
      return distList.isNotEmpty ? distList.first : null;
    }

    final distList = cityDistricts[city] ?? [];
    final normalized = district.trim().toLowerCase();

    final caseInsensitiveMatch = distList.where(
      (d) => d.toLowerCase() == normalized,
    );

    if (caseInsensitiveMatch.isNotEmpty) {
      return caseInsensitiveMatch.first;
    } 
    
    // Eski/eslesmeyen kayitlar icin ozel durumlar (Mersin)
    if (city == 'Mersin' && 
        (normalized == 'bozyazı' || normalized == 'bozyazi' || normalized == 'tekeli') && 
        distList.contains('Bozyazı/Tekeli')) {
      return 'Bozyazı/Tekeli';
    }

    return distList.isNotEmpty ? distList.first : null;
  }
}
