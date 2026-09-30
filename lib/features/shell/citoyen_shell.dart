import 'package:flutter/material.dart';

import '../auth/auth_api.dart';
import '../auth/paw_logo.dart';
import '../messages/directory_page.dart';
import '../messages/messages_page.dart';
import '../notifications/notifications_page.dart';
import '../reports/citoyen_home_page.dart';
import 'placeholder_tab.dart';
import 'profile_tab.dart';

class PawShell extends StatefulWidget {
  const PawShell({super.key, required this.session, required this.authApi});

  final AuthSession session;
  final AuthApi authApi;

  @override
  State<PawShell> createState() => _PawShellState();
}

class _PawShellState extends State<PawShell> {
  int _index = 0;
  int _unreadNotifications = 0;

  static const _tabs = [
    _Tab('Accueil', Icons.home_outlined, Icons.home),
    _Tab('Urgences', Icons.emergency_outlined, Icons.emergency),
    _Tab('Animaux', Icons.pets_outlined, Icons.pets),
    _Tab('Carte', Icons.map_outlined, Icons.map),
    _Tab('Messages', Icons.chat_bubble_outline, Icons.chat_bubble),
    _Tab('Notifs', Icons.notifications_outlined, Icons.notifications),
    _Tab('Profil', Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F4),
      body: IndexedStack(
        index: _index,
        children: [
          _home(),
          const PlaceholderTab(
            title: 'Urgences',
            icon: Icons.emergency,
            message: 'Les animaux blessés à traiter en priorité apparaîtront ici.',
          ),
          const PlaceholderTab(
            title: 'Animaux',
            icon: Icons.pets,
            message: 'Les animaux pris en charge par les refuges apparaîtront ici.',
          ),
          const PlaceholderTab(
            title: 'Carte',
            icon: Icons.map,
            message: 'La carte montrera l’emplacement de tous les animaux signalés.',
          ),
          MessagesPage(session: widget.session, authApi: widget.authApi),
          NotificationsPage(
            session: widget.session,
            authApi: widget.authApi,
            onUnreadChanged: (count) {
              if (count == _unreadNotifications) {
                return;
              }
              setState(() => _unreadNotifications = count);
            },
          ),
          ProfileTab(
            session: widget.session,
            authApi: widget.authApi,
            onUserUpdated: () => setState(() {}),
          ),
        ],
      ),
      bottomNavigationBar: _PawBar(
        index: _index,
        unreadNotifications: _unreadNotifications,
        onSelected: (value) => setState(() => _index = value),
      ),
    );
  }

  Widget _home() {
    if (widget.session.user['role'] == 'citoyen') {
      return CitoyenHomePage(session: widget.session, authApi: widget.authApi);
    }
    return RoleHomePage(session: widget.session, authApi: widget.authApi);
  }
}

class RoleHomePage extends StatelessWidget {
  const RoleHomePage({super.key, required this.session, required this.authApi});

  final AuthSession session;
  final AuthApi authApi;

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    final firstName = (user['first_name'] ?? '').toString().trim();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('PawRescue', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            firstName.isEmpty ? 'Bonjour' : 'Bonjour $firstName',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            roleLabel(user['role']?.toString()),
            style: const TextStyle(color: PawLogo.green, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Text(
            'Complétez votre profil depuis l’onglet Profil.',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          if (user['role'] == 'benevole') ...[
            const SizedBox(height: 20),
            DirectoryButtons(session: session, authApi: authApi),
          ],
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _PawBar extends StatelessWidget {
  const _PawBar({
    required this.index,
    required this.unreadNotifications,
    required this.onSelected,
  });

  final int index;
  final int unreadNotifications;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A1E3A4C),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                for (var i = 0; i < _PawShellState._tabs.length; i++)
                  Expanded(
                    child: _PawBarItem(
                      tab: _PawShellState._tabs[i],
                      selected: index == i,
                      showBadge: i == 5 && unreadNotifications > 0,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PawBarItem extends StatelessWidget {
  const _PawBarItem({
    required this.tab,
    required this.selected,
    required this.onTap,
    this.showBadge = false,
  });

  final _Tab tab;
  final bool selected;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? PawLogo.green : const Color(0xFF1E3A4C);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? tab.selectedIcon : tab.icon, color: color, size: 22),
                if (showBadge)
                  const Positioned(
                    right: -2,
                    top: -2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: PawLogo.green, shape: BoxShape.circle),
                      child: SizedBox(width: 8, height: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
