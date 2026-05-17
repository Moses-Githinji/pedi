class EnvironmentConfig {
  /// Google Cloud API Key (Firebase/General)
  static const String gcpApiKey = String.fromEnvironment('GCP_API_KEY');

  /// Google Cloud Key for Maps/Places/Directions
  static const String googleCloudKey = String.fromEnvironment('GOOGLE_CLOUD_KEY');

  /// OAuth 2.0 Client ID
  static const String oauthClientId = String.fromEnvironment('OAUTH_CLIENT_ID');
}
