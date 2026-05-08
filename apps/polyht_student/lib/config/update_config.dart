class UpdateConfig {
  static const manifestUrl = String.fromEnvironment(
    'UPDATE_MANIFEST_URL',
    defaultValue: 'https://example.com/releases/polyht_student_latest.json',
  );
}
