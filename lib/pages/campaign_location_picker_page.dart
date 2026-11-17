import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/campaign_location.dart';
import '../services/campaign_location_service.dart';

class CampaignLocationPickerPage extends StatefulWidget {
  final CampaignLocation? initialLocation;
  final CampaignLocationService? locationService;
  final TileProvider? tileProvider;
  const CampaignLocationPickerPage(
      {super.key,
      this.initialLocation,
      this.locationService,
      this.tileProvider});

  @override
  State<CampaignLocationPickerPage> createState() =>
      _CampaignLocationPickerPageState();
}

class _CampaignLocationPickerPageState
    extends State<CampaignLocationPickerPage> {
  final _controller = MapController();
  final _searchController = TextEditingController();
  late final CampaignLocationService _service;
  CampaignLocation? _candidate;
  LatLng? _point;
  List<CampaignLocation> _results = [];
  Timer? _reverseTimer;
  int _version = 0;
  int _searchVersion = 0;
  bool _searching = false;
  bool _locating = false;
  bool _resolving = false;
  bool _tileError = false;
  String? _error;
  int _tileRevision = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.locationService ?? CampaignLocationService();
    _candidate = widget.initialLocation;
    if (_candidate != null) {
      _point = LatLng(_candidate!.latitude, _candidate!.longitude);
    }
  }

  @override
  void dispose() {
    _reverseTimer?.cancel();
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  Future<void> _search() async {
    if (_searching) return;
    final query = _searchController.text.trim();
    if (query.length < 3) {
      setState(() =>
          _error = 'Masukkan minimal 3 karakter alamat atau nama tempat.');
      return;
    }
    FocusScope.of(context).unfocus();
    final version = ++_searchVersion;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await _service.search(query);
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _error =
              'Lokasi tidak ditemukan. Coba nama tempat atau alamat yang lebih lengkap.';
        }
      });
    } catch (error) {
      if (mounted && version == _searchVersion) {
        setState(() => _error = _message(error));
      }
    } finally {
      if (mounted && version == _searchVersion) {
        setState(() => _searching = false);
      }
    }
  }

  void _chooseResult(CampaignLocation result) {
    _reverseTimer?.cancel();
    _version++;
    setState(() {
      _candidate = result;
      _point = LatLng(result.latitude, result.longitude);
      _resolving = false;
      _results = [];
      _error = null;
    });
    _controller.move(_point!, 16);
  }

  void _choosePoint(LatLng raw) {
    final point = LatLng(double.parse(raw.latitude.toStringAsFixed(7)),
        double.parse((((raw.longitude + 180) % 360) - 180).toStringAsFixed(7)));
    if (_point?.latitude == point.latitude &&
        _point?.longitude == point.longitude &&
        (_candidate != null || _resolving)) {
      return;
    }
    _reverseTimer?.cancel();
    final version = ++_version;
    setState(() {
      _point = point;
      _candidate = null;
      _resolving = true;
      _error = null;
      _results = [];
    });
    // Resolve only after movement stops; never send geocoding per animation frame.
    _reverseTimer = Timer(
        const Duration(milliseconds: 1100), () => _resolve(point, version));
  }

  Future<void> _resolve(LatLng point, int version) async {
    try {
      final location = await _service.reverse(point);
      if (!mounted || version != _version) return;
      setState(() => _candidate = location);
    } catch (error) {
      if (mounted && version == _version) {
        setState(() => _error = _message(error));
      }
    } finally {
      if (mounted && version == _version) setState(() => _resolving = false);
    }
  }

  Future<void> _useMyLocation() async {
    if (_locating) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _locating = true;
      _error = null;
    });
    final selectionVersion = _version;
    try {
      final point = await _service.currentPosition();
      if (!mounted || selectionVersion != _version) return;
      _choosePoint(point);
      _controller.move(point, 16);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pilih Lokasi Bantuan')),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
            child: LayoutBuilder(
                builder: (context, constraints) => Stack(children: [
                      FlutterMap(
                        mapController: _controller,
                        options: MapOptions(
                          // Indonesia is only an initial viewport, never a selected/submitted point.
                          initialCenter: _point ?? const LatLng(-2.5, 118),
                          initialZoom: _point == null ? 4 : 16,
                          minZoom: 3, maxZoom: 19,
                          onTap: (_, point) {
                            FocusScope.of(context).unfocus();
                            _choosePoint(point);
                          },
                          onPositionChanged: (camera, hasGesture) {
                            if (hasGesture) _choosePoint(camera.center);
                          },
                        ),
                        children: [
                          TileLayer(
                            key: ValueKey(_tileRevision),
                            urlTemplate: const String.fromEnvironment(
                                'MAP_TILE_URL',
                                defaultValue:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                            userAgentPackageName: 'DonGivMobile',
                            tileProvider: widget.tileProvider,
                            maxNativeZoom: 19,
                            errorTileCallback: (_, __, ___) {
                              if (!_tileError && mounted) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() => _tileError = true);
                                  }
                                });
                              }
                            },
                          ),
                          if (_point != null)
                            MarkerLayer(markers: [
                              Marker(
                                point: _point!,
                                width: 48,
                                height: 48,
                                alignment: Alignment.topCenter,
                                child: const Icon(Icons.location_pin,
                                    size: 48, color: Color(0xFF2972FF)),
                              )
                            ]),
                        ],
                      ),
                      Positioned(
                          top: 10,
                          left: 12,
                          right: 12,
                          child: Material(
                            elevation: 3,
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white,
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                          controller: _searchController,
                                          textInputAction:
                                              TextInputAction.search,
                                          onSubmitted: (_) => _search(),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Cari alamat atau nama tempat',
                                            isDense: true,
                                            prefixIcon:
                                                const Icon(Icons.search),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            suffixIcon: IconButton(
                                                tooltip: 'Cari lokasi',
                                                onPressed:
                                                    _searching ? null : _search,
                                                icon: const Icon(
                                                    Icons.arrow_forward)),
                                          )),
                                      if (_searching)
                                        const Padding(
                                            padding: EdgeInsets.only(top: 8),
                                            child: LinearProgressIndicator()),
                                      Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed: _locating
                                                ? null
                                                : _useMyLocation,
                                            icon: _locating
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2))
                                                : const Icon(Icons.my_location),
                                            label: const Text(
                                                'Gunakan Lokasi Saya'),
                                          )),
                                      if (_results.isNotEmpty)
                                        ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxHeight: 160),
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: _results.length,
                                              itemBuilder: (_, index) =>
                                                  ListTile(
                                                dense: true,
                                                contentPadding: EdgeInsets.zero,
                                                leading: const Icon(
                                                    Icons.place_outlined),
                                                title: Text(
                                                    _results[index].address,
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                                onTap: () => _chooseResult(
                                                    _results[index]),
                                              ),
                                            )),
                                    ])),
                          )),
                      Positioned(
                          bottom: 10,
                          left: 12,
                          right: 12,
                          child: Material(
                            elevation: 4,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxHeight: constraints.maxHeight * .45),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Lokasi terpilih',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16)),
                                        const SizedBox(height: 6),
                                        if (_resolving)
                                          const Text(
                                              'Memperbarui alamat titik yang dipilih...')
                                        else
                                          Text(
                                              _candidate?.address ??
                                                  'Ketuk atau geser peta untuk memilih titik. Lokasi belum dipilih.',
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis),
                                        if (_candidate != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                              [
                                                _candidate!.district,
                                                _candidate!.city,
                                                _candidate!.province
                                              ]
                                                  .where((s) => s.isNotEmpty)
                                                  .join(', '),
                                              style: const TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontSize: 12)),
                                        ],
                                        if (_point != null)
                                          Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Text(
                                                '${_point!.latitude.toStringAsFixed(7)}, ${_point!.longitude.toStringAsFixed(7)}',
                                                key: const Key(
                                                    'selected-coordinates'),
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              )),
                                        if (_error != null)
                                          Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Text(_error!,
                                                  style: const TextStyle(
                                                      color: Colors.red))),
                                        if (_point != null &&
                                            !_resolving &&
                                            _candidate == null)
                                          TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _resolving = true;
                                                  _error = null;
                                                });
                                                _resolve(_point!, ++_version);
                                              },
                                              child: const Text(
                                                  'Coba muat alamat lagi')),
                                        if (_tileError)
                                          TextButton(
                                              onPressed: () => setState(() {
                                                    _tileError = false;
                                                    _tileRevision++;
                                                  }),
                                              child: const Text(
                                                  'Peta gagal dimuat. Coba lagi')),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                            width: double.infinity,
                                            child: FilledButton(
                                              onPressed: _candidate == null ||
                                                      _resolving ||
                                                      _locating
                                                  ? null
                                                  : () => Navigator.pop(
                                                      context, _candidate),
                                              child: const Text(
                                                  'Pilih Lokasi Ini'),
                                            )),
                                        TextButton(
                                            onPressed: () => launchUrl(Uri.parse(
                                                'https://www.openstreetmap.org/copyright')),
                                            child: const Text(
                                                'Peta © OpenStreetMap contributors',
                                                style:
                                                    TextStyle(fontSize: 10))),
                                      ]),
                                )),
                          )),
                    ]))),
      );
}
