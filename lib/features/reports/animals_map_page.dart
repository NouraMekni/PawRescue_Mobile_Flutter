import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/api_config.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_api.dart';
import '../auth/paw_logo.dart';
import 'citoyen_home_page.dart';
import 'reports_api.dart';

class AnimalsMapPage extends StatefulWidget {
  const AnimalsMapPage({
    super.key,
    required this.session,
    required this.reports,
    this.active = true,
  });

  final AuthSession session;
  final ReportsApi reports;
  final bool active;

  @override
  State<AnimalsMapPage> createState() => _AnimalsMapPageState();
}

class _AnimalsMapPageState extends State<AnimalsMapPage> {
  final MapController _mapController = MapController();
  final LatLng _tunisia = const LatLng(34.0, 9.0);

  List<Map<String, dynamic>> _items = [];
  String? _type;
  String? _status;
  String? _error;
  bool _loading = true;
  bool _located = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _load();
    }
  }

  @override
  void didUpdateWidget(AnimalsMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.reports.mapMarkers(
        token: widget.session.accessToken,
        type: _type,
        status: _status,
      );
      if (!mounted) {
        return;
      }
      setState(() => _items = items);
      if (!_located) {
        await _locateUser();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = context.tr('Impossible de joindre le serveur.'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _locateUser() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          !await Geolocator.isLocationServiceEnabled()) {
        _located = true;
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted) {
        return;
      }
      _located = true;
      _mapController.move(LatLng(position.latitude, position.longitude), 12);
    } catch (_) {
      _located = true;
    }
  }

  double? _doubleValue(dynamic value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value.toString());
  }

  List<Marker> _markers() {
    final markers = <Marker>[];
    for (final report in _items) {
      final latitude = _doubleValue(report['latitude']);
      final longitude = _doubleValue(report['longitude']);
      if (latitude == null || longitude == null) {
        continue;
      }
      final injured = report['type'] == 'injured';
      final critical = report['severity'] == 'critical';
      final color = critical
          ? Colors.red.shade700
          : injured
          ? Colors.orange.shade700
          : PawLogo.green;
      markers.add(
        Marker(
          point: LatLng(latitude, longitude),
          width: 44,
          height: 44,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _openReport(report),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                injured ? Icons.pets : Icons.location_on,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  void _openReport(Map<String, dynamic> report) {
    final photo =
        report['photos'] is List && (report['photos'] as List).isNotEmpty
        ? (report['photos'] as List).first
        : null;
    final photoUrl = photo is Map ? photo['image']?.toString() : null;
    final description = (report['description'] ?? '').toString().trim();
    final species = (report['species'] ?? '').toString().trim();
    final address = (report['address_text'] ?? '').toString().trim();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (photoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      _photoUrl(photoUrl),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 180,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                if (photoUrl != null) const SizedBox(height: 14),
                Text(
                  context.tr(reportTypeLabel(report['type']?.toString())),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(reportStatusLabel(report['status']?.toString())),
                  style: const TextStyle(
                    color: PawLogo.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (species.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('${context.tr('Espèce')}: $species'),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(address),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(description),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _photoUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '$apiBaseUrl${url.startsWith('/') ? url : '/$url'}';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return const SizedBox.shrink();
    }
    final markers = _markers();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          context.tr('Carte'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Actualiser'),
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _tunisia,
              initialZoom: 6,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'tn.pawrescue.mobile',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: _FilterBar(
              type: _type,
              status: _status,
              onTypeChanged: (value) {
                setState(() => _type = value);
                _load();
              },
              onStatusChanged: (value) {
                setState(() => _status = value);
                _load();
              },
              onMyLocation: () async {
                await _locateUser();
              },
            ),
          ),
          if (_loading)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(color: PawLogo.green),
                  ),
                ),
              ),
            ),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.type,
    required this.status,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onMyLocation,
  });

  final String? type;
  final String? status;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onMyLocation;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: context.tr('Tous'),
                      selected: type == null,
                      onTap: () => onTypeChanged(null),
                    ),
                    _FilterChip(
                      label: context.tr('Errants'),
                      selected: type == 'stray',
                      onTap: () => onTypeChanged('stray'),
                    ),
                    _FilterChip(
                      label: context.tr('Blessés'),
                      selected: type == 'injured',
                      onTap: () => onTypeChanged('injured'),
                    ),
                    const SizedBox(width: 4),
                    _FilterChip(
                      label: context.tr('Tous les statuts'),
                      selected: status == null,
                      onTap: () => onStatusChanged(null),
                    ),
                    _FilterChip(
                      label: context.tr('En attente'),
                      selected: status == 'pending',
                      onTap: () => onStatusChanged('pending'),
                    ),
                    _FilterChip(
                      label: context.tr('Assignés'),
                      selected: status == 'assigned',
                      onTap: () => onStatusChanged('assigned'),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: context.tr('Ma position'),
              onPressed: onMyLocation,
              icon: const Icon(Icons.my_location, color: PawLogo.green),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: PawLogo.green.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          color: selected ? PawLogo.green : null,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
