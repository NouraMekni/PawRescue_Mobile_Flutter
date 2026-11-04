import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_routes.dart';
import '../../l10n/app_localizations.dart';
import 'auth_api.dart';
import 'paw_logo.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authApi});

  final AuthApi authApi;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await widget.authApi.login(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context)
          .pushReplacementNamed<void, void>(AppRoutes.home, arguments: session);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = context.tr('Impossible de joindre le serveur.'));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topHeight = MediaQuery.sizeOf(context).height * 0.42;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          SizedBox(
            height: topHeight,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(36),
                  ),
                  child: Image.asset(
                    'assets/images/handtoPaw.jpg',
                    width: double.infinity,
                    height: topHeight,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.05),
                  ),
                ),
                Positioned(
                  left: 24,
                  top: 48,
                  child: const Row(
                    children: [
                      Icon(Icons.pets, color: Colors.white, size: 36),
                      SizedBox(width: 10),
                      Text(
                        'PawRescue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              children: [
                Text(
                  context.tr('Connexion'),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('Heureux de vous revoir.'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 22),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _fieldDecoration(
                          context.tr('E-mail'),
                          Icons.mail_outline,
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) {
                            return context.tr(
                              'L’adresse e-mail est obligatoire.',
                            );
                          }
                          if (!_emailPattern.hasMatch(email)) {
                            return context.tr('Email invalide.');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        decoration:
                            _fieldDecoration(
                              context.tr('Mot de passe'),
                              Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                        validator: (value) => value == null || value.isEmpty
                            ? context.tr('Le mot de passe est obligatoire.')
                            : null,
                        onFieldSubmitted: _loading ? null : (_) => _submit(),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: PawLogo.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(
                      _loading
                          ? context.tr('Connexion...')
                          : context.tr('Se connecter'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('Pas encore de compte ? '),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap: _loading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RegisterPage(authApi: widget.authApi),
                                ),
                              );
                            },
                      child: Text(
                        context.tr('Créer un compte'),
                        style: TextStyle(
                          color: PawLogo.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE6EAE8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: PawLogo.green, width: 1.4),
      ),
    );
  }
}
