abstract interface class AuthSessionStore {
  Future<String?> readLocalUserJson();
  Future<void> writeLocalUserJson(String value);

  Future<String?> readSupabaseUserId();
  Future<void> writeSupabaseUserId(String value);

  Future<bool> isRememberMeEnabled();
  Future<String?> readLastActivity();
  Future<void> configureRememberMe(bool enabled);
  Future<void> markActive();

  Future<void> clear();
}
