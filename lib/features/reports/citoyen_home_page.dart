import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../auth/auth_api.dart';
import '../auth/paw_logo.dart';
import 'report_form_page.dart';
import 'reports_api.dart';

class CitoyenHomePage extends StatefulWidget {
  const CitoyenHomePage({
    super.key,
    required this.session,
    required this.authApi,
  });

  final AuthSession session;
  final AuthApi authApi;

  @override
  State<CitoyenHomePage> createState() => _CitoyenHomePageState();
}

class _CitoyenHomePageState extends State<CitoyenHomePage> {
  late final ReportsApi _reports = ReportsApi(widget.authApi.client);
  List<Map<String, dynamic>> _items = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _reports.list(widget.session.accessToken);
      if (!mounted) {
        return;
      }
      setState(() => _items = items);
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

  Future<void> _openForm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReportFormPage(session: widget.session, reports: _reports),
      ),
    );
    if (created == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (widget.session.user['first_name'] ?? '').toString().trim();
    final email = (widget.session.user['email'] ?? '').toString();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('PawRescue', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: PawLogo.green,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              firstName.isEmpty ? 'Bonjour' : 'Bonjour $firstName',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),
            Material(
              color: PawLogo.green,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _openForm,
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.pets, color: Colors.white, size: 32),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Signaler un animal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Errant ou blessé, avec une photo et votre position.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Mes signalements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(color: PawLogo.green)),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_items.isEmpty)
              const _EmptyReports()
            else
              for (final report in _items) _ReportCard(report: report),
          ],
        ),
      ),
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.pets, color: PawLogo.green, size: 36),
          SizedBox(height: 8),
          Text('Aucun signalement pour le moment.'),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final Map<String, dynamic> report;

  @override
  Widget build(BuildContext context) {
    final created = (report['created_at'] ?? '').toString();
    final date = created.length >= 10 ? created.substring(0, 10) : '';
    final description = (report['description'] ?? '').toString().trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reportTypeLabel(report['type']?.toString()),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(date, style: const TextStyle(color: Colors.black45, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reportStatusLabel(report['status']?.toString()),
            style: const TextStyle(color: PawLogo.green, fontWeight: FontWeight.w600),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

String reportTypeLabel(String? type) {
  switch (type) {
    case 'injured':
      return 'Animal blessé';
    case 'stray':
      return 'Animal errant';
    default:
      return 'Signalement';
  }
}

String reportStatusLabel(String? status) {
  switch (status) {
    case 'pending':
      return 'En attente';
    case 'assigned':
      return 'Assigné';
    case 'in_progress':
      return 'En cours';
    case 'rescued':
      return 'Secouru';
    case 'closed':
      return 'Clôturé';
    case 'rejected':
      return 'Rejeté';
    default:
      return status ?? '';
  }
}
