abstract final class TurkishPhoneNumber {
  static String normalize(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('90') && digits.length == 12) {
      return '+$digits';
    }

    if (digits.startsWith('0') && digits.length == 11) {
      return '+90${digits.substring(1)}';
    }

    if (digits.length == 10) {
      return '+90$digits';
    }

    return value.trim();
  }

  static List<String> lookupCandidates(String value) {
    final candidates = <String>{};
    final trimmed = value.trim();
    final normalized = normalize(trimmed);
    var digits = trimmed.replaceAll(RegExp(r'\D'), '');

    void add(String candidate) {
      final normalizedCandidate = candidate.trim();
      if (normalizedCandidate.isNotEmpty) {
        candidates.add(normalizedCandidate);
      }
    }

    add(normalized);
    add(trimmed);

    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('90') && digits.length == 12) {
      final local = digits.substring(2);
      add('+90$local');
      add('+9$local');
    } else if (digits.startsWith('0') && digits.length == 11) {
      final local = digits.substring(1);
      add('+90$local');
      add('+9$local');
    } else if (digits.length == 10) {
      add('+90$digits');
      add('+9$digits');
    } else if (digits.startsWith('9') && digits.length == 11) {
      final local = digits.substring(1);
      add('+$digits');
      add('+90$local');
      add('+9$local');
    }

    return candidates.toList(growable: false);
  }
}
