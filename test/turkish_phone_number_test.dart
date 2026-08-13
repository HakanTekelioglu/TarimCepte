import 'package:flutter_test/flutter_test.dart';
import 'package:tarimcepte/domain/auth/turkish_phone_number.dart';

void main() {
  group('TurkishPhoneNumber', () {
    test('normalizes supported Turkish phone formats', () {
      expect(TurkishPhoneNumber.normalize('0555 111 22 33'), '+905551112233');
      expect(TurkishPhoneNumber.normalize('5551112233'), '+905551112233');
      expect(TurkishPhoneNumber.normalize('905551112233'), '+905551112233');
      expect(TurkishPhoneNumber.normalize('00905551112233'), '+905551112233');
    });

    test('keeps legacy lookup variants for existing profiles', () {
      final candidates = TurkishPhoneNumber.lookupCandidates('05551112233');

      expect(candidates, contains('+905551112233'));
      expect(candidates, contains('+95551112233'));
    });

    test('does not invent a value for an unsupported format', () {
      expect(TurkishPhoneNumber.normalize('123'), '123');
    });
  });
}
