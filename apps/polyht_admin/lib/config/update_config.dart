class UpdateConfig {
  static const manifestUrl = String.fromEnvironment(
    'UPDATE_MANIFEST_URL',
    defaultValue: 'https://example.com/releases/polyht_admin_latest.json',
  );
}
