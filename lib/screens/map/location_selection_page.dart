import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
// Make sure these imports are correct for your project structure
import 'package:abc_app/models/location_model.dart';
import 'package:abc_app/services/map_service.dart';
import 'map_page.dart';

class LocationSelectionPage extends StatefulWidget {
  final bool forPharmacy;

  const LocationSelectionPage({super.key, this.forPharmacy = false});

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  final MapService _mapService = MapService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  LatLng? _selectedLocation;
  bool _isLoading = false;

  void _selectLocation() async {
    // Navigate to MapPage to select a location
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => const MapPage(isSelectingLocation: true),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
      // You can reverse geocode here to get address from coordinates
      // For now, just filling with lat/lng
      _addressController.text =
      '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation == null ||
        _titleController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and select a location')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final location = LocationPoint(
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        address: _addressController.text,
        title: _titleController.text,
        createdAt: DateTime.now(),
      );

      if (widget.forPharmacy) {
        await _mapService.savePharmacyLocation(location);
      } else {
        await _mapService.saveUserLocation(location);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.forPharmacy ? 'Set Pharmacy Location' : 'Set My Location'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Location Title',
                hintText: 'e.g., My Home, Main Pharmacy',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Enter address or it will be filled automatically',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectLocation,
              icon: const Icon(Icons.map),
              label: const Text('Select on Map'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedLocation != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selected Location:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(4)}'),
                      Text(
                          'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(4)}'),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Location',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}