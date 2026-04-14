import 'dart:io';

void main() {
  final content = File('lib/screens/register_screen.dart').readAsStringSync();
  var newContent = content.replaceFirst(
    "import '../providers/providers.dart';", 
    "import '../providers/providers.dart';\nimport '../utils/app_constants.dart';"
  );

  newContent = newContent.replaceFirst(
    "bool _obscureConfirmPassword = true;", 
    '''bool _obscureConfirmPassword = true;
  String _selectedCity = AppConstants.cities.first;
  String? _selectedDistrict;'''
  );

  newContent = newContent.replaceFirst(
    "      _nameController.text.trim(),\n    );", 
    '''      _nameController.text.trim(),
      city: _selectedCity,
      district: _selectedDistrict,
    );'''
  );

  newContent = newContent.replaceFirst(
    "const SizedBox(height: 24),",
    '''const SizedBox(height: 16),
                
                // Şehir Seçimi
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(
                    labelText: 'Şehir',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.cities.map((String c) {
                    return DropdownMenuItem<String>(
                      value: c,
                      child: Text(c),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCity = newValue;
                        final dList = AppConstants.cityDistricts[newValue] ?? [];
                        _selectedDistrict = dList.isNotEmpty ? dList.first : null;
                      });
                    }
                  },
                ),
                
                // İlçe seçimi (Mersin ise gösteR)
                if ((AppConstants.cityDistricts[_selectedCity] ?? []).isNotEmpty)
                   Padding(
                     padding: const EdgeInsets.only(top: 16),
                     child: DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: const InputDecoration(
                          labelText: 'İlçe',
                          prefixIcon: Icon(Icons.map),
                          border: OutlineInputBorder(),
                        ),
                        items: (AppConstants.cityDistricts[_selectedCity] ?? []).map((String d) {
                          return DropdownMenuItem<String>(
                            value: d,
                            child: Text(d),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedDistrict = newValue;
                            });
                          }
                        },
                      ),
                   ),

                const SizedBox(height: 24),'''
  );

  final f1 = File('lib/screens/register_screen.dart');
  f1.writeAsStringSync(newContent);
}
