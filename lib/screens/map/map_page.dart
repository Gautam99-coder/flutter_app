import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
// Make sure these imports are correct for your project structure
import 'package:abc_app/models/location_model.dart';
import 'package:abc_app/services/map_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapPage extends StatefulWidget {
  final bool isSelectingLocation;
  final Function(latlong.LatLng)? onLocationSelected;
  final latlong.LatLng? locationToFocus; // To focus on a specific pharmacy

  const MapPage({
    super.key,
    this.isSelectingLocation = false,
    this.onLocationSelected,
    this.locationToFocus,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService();

  latlong.LatLng? _selectedLocation;
  latlong.LatLng? _currentLocation;
  List<LocationPoint> _pharmacies = [];

  // Default center if no location is found (Delhi)
  final latlong.LatLng _defaultCenter = const latlong.LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
    _getCurrentLocationAndMove();
  }

  void _loadPharmacies() {
    _mapService.getPharmacyLocations().listen((pharmacies) {
      if (mounted) {
        setState(() {
          _pharmacies = pharmacies;
        });
      }
    });
  }

  Future<void> _getCurrentLocationAndMove() async {
    bool isGranted = false;
    PermissionStatus status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      isGranted = true;
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
                'This app needs location access to show your position. Please go to app settings to enable it.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(ctx);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }

    if (isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (mounted) {
          setState(() {
            _currentLocation =
                latlong.LatLng(position.latitude, position.longitude);
            if (widget.isSelectingLocation && _selectedLocation == null) {
              _selectedLocation = _currentLocation;
            }
          });
          _moveCamera();
        }
      } catch (e) {
        print('Error getting location: $e');
        _moveCamera();
      }
    } else {
      print('Location permission was not granted.');
      _moveCamera();
    }
  }

  void _moveCamera() {
    try {
      if (widget.locationToFocus != null) {
        _mapController.move(widget.locationToFocus!, 15.0);
      } else if (_currentLocation != null) {
        _mapController.move(_currentLocation!, 14.0);
      } else {
        _mapController.move(_defaultCenter, 13.0);
      }
    } catch (e) {
      print("Map controller not ready yet: $e");
    }
  }

  void _centerOnUser() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    } else {
      _getCurrentLocationAndMove();
    }
  }

  void _onMapTap(TapPosition tapPosition, latlong.LatLng point) {
    if (widget.isSelectingLocation) {
      setState(() {
        _selectedLocation = point;
      });
    }
  }

  void _confirmLocation() {
    if (_selectedLocation != null && widget.onLocationSelected != null) {
      widget.onLocationSelected!(_selectedLocation!);
      Navigator.pop(context, _selectedLocation);
    } else if (widget.isSelectingLocation && _selectedLocation != null) {
      Navigator.pop(context, _selectedLocation);
    }
  }

  void _openInExternalMap(double lat, double lng) async {
    final url =
        'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=16/$lat/$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isSelectingLocation ? 'Select Location' : 'Find Pharmacies'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (widget.isSelectingLocation && _selectedLocation != null)
            TextButton(
              onPressed: _confirmLocation,
              child: const Text('Confirm', style: TextStyle(color: Colors.blue)),
            ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter:
          widget.locationToFocus ?? _currentLocation ?? _defaultCenter,
          initialZoom: 13.0,
          onTap: _onMapTap,
          onMapReady: () {
            _moveCamera();
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.abc_app',
          ),
          MarkerLayer(
            markers: _pharmacies.map((pharmacy) {
              return Marker(
                point: latlong.LatLng(pharmacy.latitude, pharmacy.longitude),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _showPharmacyInfo(pharmacy),
                  child: const Tooltip(
                    message: 'Pharmacy',
                    child: Icon(
                      Icons.local_pharmacy,
                      color: Colors.green,
                      size: 30,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          MarkerLayer(
            markers: [
              if (_currentLocation != null)
                Marker(
                  point: _currentLocation!,
                  width: 40,
                  height: 40,
                  child: Tooltip(
                    message: 'Your Location',
                    child: Icon(
                      Icons.my_location,
                      color: widget.isSelectingLocation
                          ? Colors.blue.withAlpha(150)
                          : Colors.blueAccent,
                      size: 30,
                    ),
                  ),
                ),
              if (_selectedLocation != null && widget.isSelectingLocation)
                Marker(
                  point: _selectedLocation!,
                  width: 40,
                  height: 40,
                  child: const Tooltip(
                    message: 'Selected Location',
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            // --- FIX 1 ---
            heroTag: 'btn_center_user', // Unique tag
            onPressed: _centerOnUser,
            tooltip: 'My Location',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          if (_selectedLocation != null && widget.isSelectingLocation)
            FloatingActionButton.extended(
              // --- FIX 2 ---
              heroTag: 'btn_confirm_location', // Unique tag
              onPressed: _confirmLocation,
              icon: const Icon(Icons.check),
              label: const Text('Confirm Location'),
              backgroundColor: Colors.green,
            ),
        ],
      ),
    );
  }

  void _showPharmacyInfo(LocationPoint pharmacy) {
    String distanceStr = '';
    if (_currentLocation != null) {
      final double km = const latlong.Distance().as(
        latlong.LengthUnit.Kilometer,
        latlong.LatLng(pharmacy.latitude, pharmacy.longitude),
        _currentLocation!,
      );
      distanceStr = '${km.toStringAsFixed(1)} km away';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pharmacy.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pharmacy.address),
            const SizedBox(height: 10),
            if (distanceStr.isNotEmpty)
              Text(
                distanceStr,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blue[800]),
              ),
            const SizedBox(height: 10),
            Text('Lat: ${pharmacy.latitude.toStringAsFixed(4)}'),
            Text('Lng: ${pharmacy.longitude.toStringAsFixed(4)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openInExternalMap(pharmacy.latitude, pharmacy.longitude);
            },
            child: const Text('Open in Map'),
          ),
        ],
      ),
    );
  }
}