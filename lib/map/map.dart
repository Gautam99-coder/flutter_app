
// screens/map/map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:abc_app/models/location_model.dart';
import 'package:abc_app/services/map_service.dart'; // We will use your MapService
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

  // Default center if no location is found
  final latlong.LatLng _defaultCenter = const latlong.LatLng(28.6139, 77.2090); // Delhi

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
    _getCurrentLocationAndMove();
  }

  void _loadPharmacies() {
    // Assuming mapService.getPharmacyLocations() returns Stream<List<LocationPoint>>
    _mapService.getPharmacyLocations().listen((pharmacies) {
      if (mounted) {
        setState(() {
          _pharmacies = pharmacies;
        });
      }
    });
  }

  Future<void> _getCurrentLocationAndMove() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (mounted) {
          setState(() {
            _currentLocation = latlong.LatLng(position.latitude, position.longitude);
            if (widget.isSelectingLocation && _selectedLocation == null) {
              // If we're selecting, default the selected pin to user's location
              _selectedLocation = _currentLocation;
            }
          });
          _moveCamera(); // Move camera after getting location
        }
      } catch (e) {
        print('Error getting location: $e');
        _moveCamera(); // Move camera even if location fails
      }
    } else {
      print('Location permission denied');
      _moveCamera(); // Move camera even if permission is denied
    }
  }

  void _moveCamera() {
    // 1. Prioritize focusing on a specific location
    if (widget.locationToFocus != null) {
      _mapController.move(widget.locationToFocus!, 15.0);
    }
    // 2. Else, move to user's current location
    else if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 14.0);
    }
    // 3. Else, move to default (e.g., Delhi)
    else {
      _mapController.move(_defaultCenter, 13.0);
    }
  }

  void _centerOnUser() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    } else {
      // If user location is not available, try to get it again
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
      Navigator.pop(context, _selectedLocation); // Return the selected location
    } else if (widget.isSelectingLocation && _selectedLocation != null) {
      // Handle case where onLocationSelected is null but we are in selection mode
      Navigator.pop(context, _selectedLocation);
    }
  }

  void _openInExternalMap(double lat, double lng) async {
    // Using OpenStreetMap URL
    final url = 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=16/$lat/$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectingLocation ? 'Select Location' : 'Find Pharmacies'),
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
          initialCenter: widget.locationToFocus ?? _currentLocation ?? _defaultCenter,
          initialZoom: 13.0,
          onTap: _onMapTap,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.abc_app', // Use your app's package name
          ),

          // Layer for Pharmacy markers
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

          // Layer for User's location and Selected location
          MarkerLayer(
            markers: [
              // User's current location marker
              if (_currentLocation != null && !widget.isSelectingLocation)
                Marker(
                  point: _currentLocation!,
                  width: 40,
                  height: 40,
                  child: const Tooltip(
                    message: 'Your Location',
                    child: Icon(
                      Icons.my_location,
                      color: Colors.blueAccent,
                      size: 30,
                    ),
                  ),
                ),
              // Location being selected by the user
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
          // "Center on me" button
          FloatingActionButton(
            onPressed: _centerOnUser,
            tooltip: 'My Location',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          // "Confirm" button
          if (_selectedLocation != null && widget.isSelectingLocation)
            FloatingActionButton.extended(
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
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800]),
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
              Navigator.pop(context); // Close dialog first
              _openInExternalMap(pharmacy.latitude, pharmacy.longitude);
            },
            child: const Text('Open in Map'),
          ),
        ],
      ),
    );
  }
}
