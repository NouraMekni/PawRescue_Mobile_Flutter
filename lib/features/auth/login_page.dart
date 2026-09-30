import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import 'auth_api.dart';
import 'paw_logo.dart';
import 'register_page.dart';
import 'session_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authApi});

  final AuthApi authApi;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => homeForSession(session: session, authApi: widget.authApi),
        ),
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
    final topHeight = MediaQuery.sizeOf(context).height * 0.42;
    return Scaffold(
      backgroundColor: Colors.white,
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
                const Positioned(
                  left: 24,
                  top: 48,
                  child: Row(
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
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
                const Text(
                  'Connexion',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF243028),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Heureux de vous revoir.',
                  style: TextStyle(color: Color(0xFF8D98A0), fontSize: 15),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fieldDecoration('E-mail', Icons.mail_outline),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  decoration: _fieldDecoration('Mot de passe', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF8D98A0),
                      ),
                    ),
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
                    child: Text(_loading ? 'Connexion...' : 'Se connecter'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Pas encore de compte ? ',
                      style: TextStyle(color: Color(0xFF8D98A0)),
                    ),
                    GestureDetector(
                      onTap: _loading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RegisterPage(authApi: widget.authApi),
                                ),
                              );
                            },
                      child: const Text(
                        'Créer un compte',
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
      prefixIcon: Icon(icon, color: const Color(0xFF8D98A0)),
      filled: true,
      fillColor: const Color(0xFFF7F8F8),
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
