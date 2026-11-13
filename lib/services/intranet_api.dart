import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/auth_config.dart';
import 'auth_service.dart';

class IntranetUser {
  final String sub;
  final String name;
  final String email;
  final String title;
  final bool admin;
  final List<String> groups;

  const IntranetUser({
    required this.sub,
    required this.name,
    required this.email,
    required this.title,
    required this.admin,
    required this.groups,
  });

  factory IntranetUser.fromJson(Map<String, dynamic> json) {
    return IntranetUser(
      sub: (json['sub'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      title: (json['title'] ?? 'Socio Cooperativista').toString(),
      admin: json['admin'] == true,
      groups: (json['groups'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class IntranetCard {
  final int id;
  final String section;
  final String title;
  final String href;
  final String description;
  final String icon;

  const IntranetCard({
    required this.id,
    required this.section,
    required this.title,
    required this.href,
    required this.description,
    required this.icon,
  });

  String get resolvedUrl {
    if (href.startsWith('http://') || href.startsWith('https://')) {
      return href;
    }
    final normalized = href.startsWith('/') ? href : '/$href';
    return '${AuthConfig.apiBaseUrl}$normalized';
  }

  factory IntranetCard.fromJson(Map<String, dynamic> json) {
    return IntranetCard(
      id: (json['id'] as num?)?.toInt() ?? 0,
      section: (json['section'] ?? 'Sistemas').toString(),
      title: (json['title'] ?? '').toString(),
      href: (json['href'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
    );
  }
}

class IntranetNotice {
  final int id;
  final String title;
  final String body;
  final String author;
  final int createdAt;

  const IntranetNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.author,
    required this.createdAt,
  });

  factory IntranetNotice.fromJson(Map<String, dynamic> json) {
    return IntranetNotice(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
    );
  }
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();
}

class IntranetApi {
  final AuthService _auth;

  IntranetApi(this._auth);

  Future<http.Response> _authorizedGet(String path) async {
    var token = await _auth.getValidAccessToken();
    if (token == null) {
      throw const UnauthorizedException();
    }

    final uri = Uri.parse('${AuthConfig.apiBaseUrl}$path');
    var response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      final refreshed = await _auth.refreshAccessToken();
      if (refreshed == null) {
        throw const UnauthorizedException();
      }
      response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $refreshed',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 401) {
        throw const UnauthorizedException();
      }
    }

    return response;
  }

  Future<IntranetUser> fetchMe() async {
    final res = await _authorizedGet('/api/me');
    if (res.statusCode != 200) {
      throw Exception('Error al obtener perfil (${res.statusCode})');
    }
    return IntranetUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<IntranetCard>> fetchCards() async {
    final res = await _authorizedGet('/api/cards');
    if (res.statusCode != 200) {
      throw Exception('Error al obtener módulos (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => IntranetCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<IntranetNotice>> fetchNotices() async {
    final res = await _authorizedGet('/api/notices');
    if (res.statusCode != 200) {
      throw Exception('Error al obtener comunicados (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => IntranetNotice.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

