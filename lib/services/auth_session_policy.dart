abstract final class AuthSessionPolicy {
  static const Duration inactivityTimeout = Duration(hours: 48);

  static bool isExpired(String? lastActivityValue, {DateTime? now}) {
    if (lastActivityValue == null) return true;

    final lastActivity = DateTime.tryParse(lastActivityValue);
    if (lastActivity == null) return true;

    final currentTime = (now ?? DateTime.now()).toUtc();
    final inactivity = currentTime.difference(lastActivity.toUtc());

    return inactivity >= inactivityTimeout;
  }
}
