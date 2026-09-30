import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../auth/auth_api.dart';
import '../auth/paw_logo.dart';
import 'compose_page.dart';
import 'messages_api.dart';

class DirectoryButtons extends StatelessWidget {
  const DirectoryButtons({super.key, required this.session, required this.authApi});

  final AuthSession session;
  final AuthApi authApi;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionCard(
          background: Colors.white,
          foreground: const Color(0xFF1E3A4C),
          iconColor: PawLogo.green,
          icon: Icons.home_outlined,
          title: 'Les refuges',
          subtitle: 'Nom, téléphone, adresse, et un message.',
          border: const Color(0xFFE3E8E4),
          onTap: () => _open(context, DirectoryKind.refuge),
        ),
        const SizedBox(height: 12),
        _ActionCard(
          background: const Color(0xFFE7F5EC),
          foreground: const Color(0xFF1E3A4C),
          iconColor: PawLogo.green,
          icon: Icons.medical_services_outlined,
          title: 'Les vétérinaires',
          subtitle: 'Écrivez à un vétérinaire près de vous.',
          onTap: () => _open(context, DirectoryKind.veterinaire),
        ),
      ],
    );
  }

  void _open(BuildContext context, DirectoryKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DirectoryPage(session: session, authApi: authApi, kind: kind),
      ),
    );
  }
}

enum DirectoryKind { refuge, veterinaire }

class DirectoryPage extends StatefulWidget {
  const DirectoryPage({
    super.key,
    required this.session,
    required this.authApi,
    required this.kind,
  });

  final AuthSession session;
  final AuthApi authApi;
  final DirectoryKind kind;

  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  late final MessagesApi _api = MessagesApi(widget.authApi.client);
  List<Map<String, dynamic>> _items = [];
  String? _error;
  bool _loading = true;

  bool get _isRefuge => widget.kind == DirectoryKind.refuge;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = _isRefuge
          ? await _api.refuges(widget.session.accessToken)
          : await _api.veterinaires(widget.session.accessToken);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Impossible de joindre le serveur.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isRefuge ? 'Les refuges' : 'Les vétérinaires';
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PawLogo.green))
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : _items.isEmpty
          ? Center(child: Text(_isRefuge ? 'Aucun refuge pour le moment.' : 'Aucun vétérinaire pour le moment.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ContactCard(
                person: _items[index],
                onContact: () {
                  final person = _items[index];
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ComposePage(
                        session: widget.session,
                        api: _api,
                        refugeId: _isRefuge ? person['id'] as int : null,
                        veterinaireId: _isRefuge ? null : person['id'] as int,
                        contactName: (person['name'] ?? '').toString(),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.person, required this.onContact});

  final Map<String, dynamic> person;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final name = (person['name'] ?? '').toString();
    final phone = (person['phone'] ?? '').toString();
    final location = (person['location'] ?? '').toString();
    final photo = (person['photo'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFE7F5EC),
                backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
                child: photo.isEmpty ? const Icon(Icons.person, color: PawLogo.green) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    _line(Icons.phone_outlined, phone.isEmpty ? 'Téléphone non renseigné' : phone),
                    const SizedBox(height: 4),
                    _line(
                      Icons.place_outlined,
                      location.isEmpty ? 'Adresse non renseignée' : location,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: PawLogo.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onContact,
              child: const Text('Contacter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: PawLogo.green),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.black54))),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.background,
    required this.foreground,
    required this.iconColor,
    required this.icon,
    this.border,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color background;
  final Color foreground;
  final Color iconColor;
  final IconData icon;
  final Color? border;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: border == null ? BorderSide.none : BorderSide(color: border!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: foreground, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: foreground.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}
