class UpdateConfig {
  static const manifestUrl = String.fromEnvironment(
    'UPDATE_MANIFEST_URL',
    defaultValue:
        'https://raw.githubusercontent.com/AustinKarasu/PolyH.T-App/main/website/releases/polyht_latest.json',
  );
}
