import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import 'auth_api.dart';
import 'home_page.dart';
import 'paw_logo.dart';
import 'vet_info_page.dart';

class RoleChoice {
  const RoleChoice({
    required this.value,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String value;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

const roleChoices = <RoleChoice>[
  RoleChoice(
    value: 'citoyen',
    title: 'Citoyen',
    description:
        'Signaler des animaux, suivre les signalements, consulter les animaux à adopter.',
    icon: Icons.groups_outlined,
    color: Color(0xFF1F8A45),
  ),
  RoleChoice(
    value: 'benevole',
    title: 'Bénévole',
    description: 'Participer à des missions de secours et d’interventions.',
    icon: Icons.handshake_outlined,
    color: Color(0xFFE15B64),
  ),
  RoleChoice(
    value: 'veterinaire',
    title: 'Vétérinaire',
    description: 'Aider les animaux blessés et gérer les soins médicaux.',
    icon: Icons.medical_services_outlined,
    color: Color(0xFF1F8A45),
  ),
  RoleChoice(
    value: 'refuge',
    title: 'Refuge',
    description:
        'Accueillir les animaux, suivre les missions, les adoptions et les dons.',
    icon: Icons.home_outlined,
    color: Color(0xFF2F6FED),
  ),
];

class RolePage extends StatefulWidget {
  const RolePage({
    super.key,
    required this.authApi,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  final AuthApi authApi;
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  @override
  State<RolePage> createState() => _RolePageState();
}

class _RolePageState extends State<RolePage> {
  String _role = 'citoyen';
  String? _error;
  bool _loading = false;

  Future<void> _submit() async {
    if (_role == 'veterinaire') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VetInfoPage(
            authApi: widget.authApi,
            firstName: widget.firstName,
            lastName: widget.lastName,
            email: widget.email,
            password: widget.password,
          ),
        ),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await widget.authApi.register(
        firstName: widget.firstName,
        lastName: widget.lastName,
        email: widget.email,
        password: widget.password,
        role: _role,
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomePage(session: session, authApi: widget.authApi),
        ),
        (_) => false,
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Impossible de joindre le serveur.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F8),
        elevation: 0,
        foregroundColor: const Color(0xFF243028),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comment souhaitez-vous\naider ?',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF243028),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: roleChoices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final choice = roleChoices[index];
                    final selected = choice.value == _role;
                    return _RoleCard(
                      choice: choice,
                      selected: selected,
                      onTap: _loading
                          ? null
                          : () => setState(() => _role = choice.value),
                    );
                  },
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: PawLogo.green,
                    disabledBackgroundColor: PawLogo.green.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(_loading ? 'Continuer...' : 'Continuer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final RoleChoice choice;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? PawLogo.green : const Color(0xFFE6EAE8),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: choice.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(choice.icon, color: choice.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choice.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF243028),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      choice.description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        color: Color(0xFF6E7872),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.chevron_right,
                color: selected ? PawLogo.green : const Color(0xFFB7C0BC),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
