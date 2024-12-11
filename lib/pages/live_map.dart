import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:travelrecords/widgets/direction_marker.dart';
import 'package:travelrecords/widgets/map_style_button.dart';

class LiveMap extends StatefulWidget {
  const LiveMap({super.key});

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  final  _formKey                     = GlobalKey<FormState>();
  final  MapController _mapController = MapController();
  LatLng _currentLocation             = const LatLng(0, 0);
  double _currentDirection            = 0.0; 
  String _currentMapStyle             = 'default';
  bool _isLocationInitialized         = false;

  // Map of available styles
  final Map<String, String> _mapStyles = {
    'default'     : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'topo'        : 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    'cycle'       : 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
    'humanitarian': 'https://tile-{s}.openstreetmap.fr/hot/{z}/{x}/{y}.png',
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startListeningToSensors();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _isLocationInitialized = true; // Mark location as initialized
      _mapController.move(_currentLocation, 13.0); // Center the map on the current location
    });

    // Start listening for location updates with LocationSettings
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update location if the device moves 10 meters
      // timeLimit: Duration(seconds: 5), // Optional: limit the time for location updates
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    });
  }

  void _startListeningToSensors() {
    // Listen to the device's magnetometer using the updated method
    magnetometerEventStream().listen((MagnetometerEvent event) {
      // Calculate the heading based on magnetometer data
      double heading = atan2(event.y, event.x) * (180 / pi); // Convert radians to degrees
      heading = (heading + 360) % 360; // Normalize to 0-360 degrees

      // Adjust the heading to account for the device's orientation
      heading = (heading + 90) % 360; // Adjust for the device's coordinate system

      setState(() {
        _currentDirection = heading; // Update the current direction
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Live Map'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Current Location: ${_currentLocation.latitude}, ${_currentLocation.longitude}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                // Map Type Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      MapStyleButton(
                        title: 'Default',
                        isSelected: _currentMapStyle == 'default',
                        onPressed: () =>
                            setState(() => _currentMapStyle = 'default'),
                      ),
                      const SizedBox(width: 8),
                      MapStyleButton(
                        title: 'Topographic',
                        isSelected: _currentMapStyle == 'topo',
                        onPressed: () =>
                            setState(() => _currentMapStyle = 'topo'),
                      ),
                      const SizedBox(width: 8),
                      MapStyleButton(
                        title: 'Cycle',
                        isSelected: _currentMapStyle == 'cycle',
                        onPressed: () =>
                            setState(() => _currentMapStyle = 'cycle'),
                      ),
                      const SizedBox(width: 8),
                      MapStyleButton(
                        title: 'Humanitarian',
                        isSelected: _currentMapStyle == 'humanitarian',
                        onPressed: () =>
                            setState(() => _currentMapStyle = 'humanitarian'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Add Map
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      crs: const Epsg3857(),
                      initialCenter: _isLocationInitialized ? _currentLocation : const LatLng(0, 0),
                      initialZoom: 13.0,
                      initialRotation: 0.0,
                      onTap: (tapPosition, point) {
                      },
                    ), 
                    children: [
                      TileLayer(
                        urlTemplate: _mapStyles[_currentMapStyle],
                        subdomains: _currentMapStyle == 'default'
                        ? const []
                        : const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation,
                            child: DirectionalMarker(direction: _currentDirection),
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            rotate: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}