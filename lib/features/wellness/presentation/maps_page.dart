import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as maplat;
// import 'dart:io'; // import/export removed
// import 'dart:convert'; // import/export removed
// import 'package:path_provider/path_provider.dart'; // import/export removed
import 'package:geolocator/geolocator.dart';
import '../domain/geofence_mission.dart';
import '../data/geofence_repository.dart';
import '../services/geofence_service.dart';

class WellnessMapsPage extends StatefulWidget {
  const WellnessMapsPage({super.key});

  @override
  State<WellnessMapsPage> createState() => _WellnessMapsPageState();
}

class _WellnessMapsPageState extends State<WellnessMapsPage> {
  fm.MapController? _mapController;
  maplat.LatLng? _initialCenter;
  maplat.LatLng? _lastCenter;
  StreamSubscription<GeofenceEvent>? _eventsSub;
  bool _missionsVisible = true;

  GeofenceRepository _getRepo() {
    try {
      return context.read<GeofenceRepository>();
    } catch (_) {
      return InMemoryGeofenceRepository();
    }
  }

  GeofenceService _getService() {
    try {
      return context.read<GeofenceService>();
    } catch (_) {
      return GeofenceService(repository: _getRepo());
    }
  }

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _initialCenter = maplat.LatLng(pos.latitude, pos.longitude);
      });
      // Move map if controller already exists (no-op if controller == null)
      _mapController?.move(_initialCenter!, 16.0);

      GeofenceService service;
      try {
        service = context.read<GeofenceService>();
      } catch (_) {
        // If a provider is not present, fallback to a local in-memory service.
        final fallbackRepo = InMemoryGeofenceRepository();
        service = GeofenceService(repository: fallbackRepo);
      }
      await service.startMonitoring();
      _eventsSub = service.events.listen((event) {
        final repo = _getRepo();
        final m = repo.getById(event.missionId);
        if (m == null) return;
        final message = _buildEventMessage(m, event);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _eventsSub?.cancel();
    super.dispose();
  }

  String _buildEventMessage(GeofenceMission m, GeofenceEvent event) {
    switch (event.type) {
      case GeofenceEventType.entered:
        return '${m.title} - entered';
      case GeofenceEventType.exited:
        return '${m.title} - exited';
      case GeofenceEventType.targetReached:
        return '${m.title} - progress ${(event.value ?? 0).toStringAsFixed(1)} m';
      case GeofenceEventType.outsideAlert:
        return '${m.title} - outside ${(event.value ?? 0).toStringAsFixed(1)} m';
    }
  }

  Future<void> _addGeofenceAtLatLng(maplat.LatLng latLng) async {
    final mission = await showDialog<GeofenceMission>(
      context: context,
      builder: (ctx) {
        return _AddMissionDialog(latLng: latLng);
      },
    );
    if (mission != null) {
      final repo = _getRepo();
      await repo.add(mission);
    }
  }

  @override
  Widget build(BuildContext context) {
    late final GeofenceRepository repo;
    late final GeofenceService service;
    try {
      repo = context.watch<GeofenceRepository>();
      service = context.watch<GeofenceService>();
    } catch (_) {
      // Fallback for direct use of WellnessMapsPage without wrapping provider
      repo = InMemoryGeofenceRepository();
      service = GeofenceService(repository: repo);
    }

    final markers = <fm.Marker>[];
    final circles = <fm.CircleMarker>[];

    for (final m in repo.current) {
  final marker = fm.Marker(
        width: 36,
        height: 36,
        point: maplat.LatLng(m.center.latitude, m.center.longitude),
        child: GestureDetector(
          onTap: () {
            _mapController?.move(
              maplat.LatLng(m.center.latitude, m.center.longitude),
              16.0,
            );
            _showMissionActions(m);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: m.isActive ? Colors.greenAccent : Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4.0)],
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
      markers.add(marker);

      final circle = fm.CircleMarker(
        point: maplat.LatLng(m.center.latitude, m.center.longitude),
        color: (m.isActive
            ? Colors.greenAccent.withOpacity(0.2)
            : Colors.redAccent.withOpacity(0.1)),
        borderStrokeWidth: 1.0,
        borderColor: m.isActive ? Colors.green : Colors.red,
        radius: m.radiusMeters.toDouble(),
        useRadiusInMeter: true,
      );
      circles.add(circle);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Full-screen map
          Positioned.fill(
            child: _initialCenter == null
                ? const Center(child: CircularProgressIndicator())
                : fm.FlutterMap(
                    mapController: _mapController ??= fm.MapController(),
                    options: fm.MapOptions(
                      onLongPress: (tapPosition, latlng) =>
                          _addGeofenceAtLatLng(
                            maplat.LatLng(latlng.latitude, latlng.longitude),
                          ),
                      onPositionChanged: (pos, _) {
                        setState(() => _lastCenter = pos.center);
                      },
                    ),
                    children: [
                      fm.TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      const CurrentLocationLayer(
                        alignPositionOnUpdate: AlignOnUpdate.always,
                        alignDirectionOnUpdate: AlignOnUpdate.never,
                      ),
                      fm.CircleLayer(circles: circles),
                      fm.MarkerLayer(markers: markers),
                    ],
                  ),
          ),

          // top overlay controls (back, import/export)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                          Row(
                            children: [
                              _TopActionButton(
                                icon: _missionsVisible ? Icons.close : Icons.list,
                                onTap: () async => setState(() => _missionsVisible = !_missionsVisible),
                                label: _missionsVisible ? 'Hide' : 'Show',
                              ),
                            ],
                          ),
                ],
              ),
            ),
          ),

          // floating center button & add mission
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 70.0, right: 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'center_location',
                      onPressed: () async {
                        final pos = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high,
                        );
                        _mapController?.move(
                          maplat.LatLng(pos.latitude, pos.longitude),
                          16.0,
                        );
                      },
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'add_mission',
                      onPressed: () async {
                        // Add mission at center
                        final center = _lastCenter;
                        if (center != null) {
                          await _addGeofenceAtLatLng(maplat.LatLng(center.latitude, center.longitude));
                        }
                      },
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom sheet with missions (draggable)
          if (_missionsVisible)
            DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.12,
            maxChildSize: 0.85,
            builder: (BuildContext context, ScrollController controller) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18.0),
                    topRight: Radius.circular(18.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8.0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12.0),
                    Container(
                      width: 48.0,
                      height: 6.0,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Missions', style: Theme.of(context).textTheme.titleLarge),
                              Text('${repo.current.length} missions', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  // TODO: Implement filters in future iterations
                                },
                                icon: const Icon(Icons.filter_list),
                                label: const Text('Filter'),
                              ),
                              const SizedBox(width: 8.0),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  // Add mission at center as quick action
                                  final center = _lastCenter;
                                  if (center != null) {
                                    await _addGeofenceAtLatLng(maplat.LatLng(center.latitude, center.longitude));
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildMissionList(repo, service, controller),
                    ),
                  ],
                ),
              );
            },
            ),
        ],
      ),
    );
  }

  // Import and export functionality removed — no longer exposed in the UI.

  Widget _buildMissionList(GeofenceRepository repo, GeofenceService service, ScrollController controller) {
    if (repo.current.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Text(
            'No missions yet. Long-press on the map or tap Add to create a mission.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      itemCount: repo.current.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8.0),
      itemBuilder: (context, index) {
        final m = repo.current[index];
        return Card(
          elevation: 2.2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            title: Text(m.title, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4.0),
                Text('${describeEnum(m.type)} • ${m.radiusMeters.toStringAsFixed(0)} m'),
                if (m.type == MissionType.target)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: LinearProgressIndicator(
                      value: (m.targetDistanceMeters == null || m.targetDistanceMeters == 0)
                          ? 0.0
                          : (service.getProgress(m.id) /(m.targetDistanceMeters ?? 1.0)).clamp(0.0, 1.0),
                    ),
                  ),
              ],
            ),
            trailing: SizedBox(
              height: 56,
              width: 56,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: m.isActive,
                      onChanged: (v) => v ? service.activateMission(m.id) : service.deactivateMission(m.id),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    iconSize: 18,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async => await repo.delete(m.id),
                  ),
                ],
              ),
            ),
            onTap: () async {
              _mapController?.move(maplat.LatLng(m.center.latitude, m.center.longitude), 16.0);
              _showMissionActions(m);
            },
          ),
        );
      },
    );
  }

  void _showMissionActions(GeofenceMission mission) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            ListTile(
              title: Text(mission.title),
              subtitle: Text(mission.description ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Activate'),
              onTap: () async {
                final service = _getService();
                await service.activateMission(mission.id);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.stop),
              title: const Text('Deactivate'),
              onTap: () async {
                final service = _getService();
                await service.deactivateMission(mission.id);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () async {
                final edited = await showDialog<GeofenceMission>(
                  context: context,
                  builder: (_) => _EditMissionDialog(mission: mission),
                );
                if (edited != null) {
                  await _getRepo().update(edited);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
            ),
          ),
        );
      },
    );
  }
}

class _AddMissionDialog extends StatefulWidget {
  final maplat.LatLng latLng;
  const _AddMissionDialog({required this.latLng});

  @override
  State<_AddMissionDialog> createState() => _AddMissionDialogState();
}

class _EditMissionDialog extends StatefulWidget {
  final GeofenceMission mission;
  const _EditMissionDialog({required this.mission});

  @override
  State<_EditMissionDialog> createState() => _EditMissionDialogState();
}

class _EditMissionDialogState extends State<_EditMissionDialog> {
  late String _title;
  String? _description;
  late MissionType _type;
  late double _radius;
  double? _targetDistance;

  @override
  void initState() {
    super.initState();
    _title = widget.mission.title;
    _description = widget.mission.description;
    _type = widget.mission.type;
    _radius = widget.mission.radiusMeters;
    _targetDistance = widget.mission.targetDistanceMeters;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Mission'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: _title),
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (v) => setState(() => _title = v),
            ),
            TextField(
              controller: TextEditingController(text: _description),
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (v) => setState(() => _description = v),
            ),
            DropdownButton<MissionType>(
              value: _type,
              items: MissionType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(describeEnum(t)),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _type = v ?? MissionType.sanctuary),
            ),
            Row(
              children: [
                const Text('Radius (m)'),
                Expanded(
                  child: Slider(
                    min: 10,
                    max: 2000,
                    value: _radius,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                ),
                Text('${_radius.toStringAsFixed(0)}'),
              ],
            ),
            if (_type == MissionType.target)
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Target distance (m)',
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: _targetDistance?.toString(),
                ),
                onChanged: (v) =>
                    setState(() => _targetDistance = double.tryParse(v)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final updated = widget.mission.copyWith(
              title: _title,
              description: _description,
              radiusMeters: _radius,
              type: _type,
              targetDistanceMeters: _targetDistance,
            );
            Navigator.of(context).pop(updated);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AddMissionDialogState extends State<_AddMissionDialog> {
  String _title = '';
  String? _description;
  MissionType _type = MissionType.sanctuary;
  double _radius = 50.0;
  double? _targetDistance;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Mission'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (v) => setState(() => _title = v),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (v) => setState(() => _description = v),
            ),
            DropdownButton<MissionType>(
              value: _type,
              items: MissionType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(describeEnum(t)),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _type = v ?? MissionType.sanctuary),
            ),
            Row(
              children: [
                const Text('Radius (m)'),
                Expanded(
                  child: Slider(
                    min: 10,
                    max: 1000,
                    value: _radius,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                ),
                Text('${_radius.toStringAsFixed(0)}'),
              ],
            ),
            if (_type == MissionType.target)
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Target distance (m)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    setState(() => _targetDistance = double.tryParse(v)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final id = DateTime.now().millisecondsSinceEpoch.toString();
            final mission = GeofenceMission(
              id: id,
              title: _title.isEmpty ? 'Mission $id' : _title,
              description: _description,
              center: LatLngSimple(
                widget.latLng.latitude,
                widget.latLng.longitude,
              ),
              radiusMeters: _radius,
              type: _type,
              targetDistanceMeters: _targetDistance,
            );
            Navigator.of(context).pop(mission);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  const _TopActionButton({required this.icon, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onTap,
        tooltip: label,
      ),
    );
  }
}
