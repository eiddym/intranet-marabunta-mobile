class AuthConfig {
  static const String clientId = 'marabunta-intranet-mobile';
  static const String redirectUri = 'com.marabuntarl.intranet://callback';
  static const String postLogoutRedirectUri = 'com.marabuntarl.intranet://logout';
  static const String issuer = 'https://auth.marabuntarl.com/application/o/intranet-mobile/';
  static const String discoveryUrl =
      'https://auth.marabuntarl.com/application/o/intranet-mobile/.well-known/openid-configuration';
  static const List<String> scopes = <String>[
    'openid',
    'profile',
    'email',
    'offline_access',
  ];

  static const String apiBaseUrl = 'https://homepage.marabuntarl.com';
}

