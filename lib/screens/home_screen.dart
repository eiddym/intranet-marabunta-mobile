import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import '../services/auth_service.dart';
import '../services/intranet_api.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSignedOut;

  const HomeScreen({
    super.key,
    required this.authService,
    required this.onSignedOut,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final IntranetApi _api = IntranetApi(widget.authService);
  bool _loading = true;
  String? _error;
  IntranetUser? _user;
  List<IntranetCard> _cards = const [];
  List<IntranetNotice> _notices = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.fetchMe(),
        _api.fetchCards(),
        _api.fetchNotices(),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as IntranetUser;
        _cards = results[1] as List<IntranetCard>;
        _notices = results[2] as List<IntranetNotice>;
      });
    } on UnauthorizedException {
      await widget.authService.logout();
      if (!mounted) return;
      widget.onSignedOut();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo cargar la intranet: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openModule(IntranetCard card) async {
    final url = Uri.parse(card.resolvedUrl);
    await launchUrl(
      url,
      customTabsOptions: CustomTabsOptions(
        colorSchemes: CustomTabsColorSchemes.defaults(
          toolbarColor: const Color(0xFF0F172A),
        ),
        shareState: CustomTabsShareState.off,
        urlBarHidingEnabled: true,
        showTitle: true,
      ),
      safariVCOptions: const SafariViewControllerOptions(
        preferredBarTintColor: Color(0xFF0F172A),
        preferredControlTintColor: Colors.white,
        barCollapsingEnabled: true,
      ),
    );
  }

  Future<void> _logout() async {
    await widget.authService.logout();
    if (!mounted) return;
    widget.onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<IntranetCard>>{};
    for (final card in _cards) {
      grouped.putIfAbsent(card.section, () => []).add(card);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('Intranet Marabunta R.L.'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFFCA5A5)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_user != null)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131C31),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFF59E0B).withOpacity(0.2),
                                child: Text(
                                  _user!.name.isNotEmpty
                                      ? _user!.name[0].toUpperCase()
                                      : 'M',
                                  style: const TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _user!.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _user!.title,
                                      style: const TextStyle(
                                        color: Color(0xFFFBBF24),
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (_user!.email.isNotEmpty)
                                      Text(
                                        _user!.email,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_notices.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Comunicados Oficiales',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._notices.map(
                          (n) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF17223B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withOpacity(0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: const TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      for (final entry in grouped.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, top: 6),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ...entry.value.map(
                          (card) => Card(
                            color: const Color(0xFF131C31),
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.apps_rounded,
                                  color: Color(0xFFFBBF24),
                                ),
                              ),
                              title: Text(
                                card.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: card.description.isEmpty
                                  ? null
                                  : Text(
                                      card.description,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.65),
                                        fontSize: 13,
                                      ),
                                    ),
                              trailing: const Icon(
                                Icons.open_in_new_rounded,
                                color: Colors.white54,
                              ),
                              onTap: () => _openModule(card),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

