import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fromLatController = TextEditingController(); // Starting point latitude
  final _fromLngController = TextEditingController(); // Starting point longitude
  final _toLatController = TextEditingController(); // Destination latitude
  final _toLngController = TextEditingController(); // Destination longitude

  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(0, 0); // Default location
  Marker? _clickedMarker; // Marker for the current location
  double _currentHeading = 0; // Variable to store the current heading
  Timer? _locationTimer; // Timer for location updates

  @override
  void initState() {
    super.initState();
    _setCurrentLocation();
    _startLocationUpdates(); // Start location updates
  }

  @override
  void dispose() {
    _fromLatController.dispose();
    _fromLngController.dispose();
    _toLatController.dispose();
    _toLngController.dispose();
    _locationTimer?.cancel(); // Cancel the timer
    super.dispose();
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _setCurrentLocation(); // Update location every second
    });
  }

  Future<void> _setCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return; // Location services are not enabled
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return; // Permissions are denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return; // Permissions are permanently denied
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Get the current heading
    _currentHeading = position.heading;

    // Check if the widget is still mounted before calling setState
    if (!mounted) return;

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _clickedMarker = Marker(
        point: _currentLocation,
        width: 80,
        height: 80,
        child: Transform.rotate(
          angle: (_currentHeading * (3.141592653589793 / 180)), // Convert degrees to radians
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
      // Ensure the map is centered on the current location
      // _mapController.move(_currentLocation, 13.0);
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
                // From and To fields row
                Row(
                  children: [
                    Flexible(
                      child: TextFormField(
                        controller: _fromLatController,
                        decoration: const InputDecoration(
                          labelText: 'From Latitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter starting latitude';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: TextFormField(
                        controller: _fromLngController,
                        decoration: const InputDecoration(
                          labelText: 'From Longitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter starting longitude';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      child: TextFormField(
                        controller: _toLatController,
                        decoration: const InputDecoration(
                          labelText: 'To Latitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter destination latitude';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: TextFormField(
                        controller: _toLngController,
                        decoration: const InputDecoration(
                          labelText: 'To Longitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter destination longitude';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Add a button to set the path
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Logic to show the path from starting point to destination
                      // You can use a package like 'flutter_polyline_points' to draw the path
                      // Example: drawPath(_fromLatController.text, _fromLngController.text, _toLatController.text, _toLngController.text);
                    }
                  },
                  child: const Text('Set Path'),
                ),
                const SizedBox(height: 10),
                // Add Map
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      crs: const Epsg3857(),
                      initialCenter: _currentLocation,
                      initialZoom: 13.0,
                      initialRotation: 0.0,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _currentLocation = point;
                          // Update the current location marker
                          _clickedMarker = Marker(
                            point: point,
                            width: 80,
                            height: 80,
                            child: Transform.rotate(
                              angle: (_currentHeading * (3.141592653589793 / 180)), // Convert degrees to radians
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          );
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          if (_clickedMarker != null) _clickedMarker!, // Add clicked marker if it exists
                        ],
                      ),
                      // Add PolylineLayer to show the path
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [LatLng(double.parse(_fromLatController.text), double.parse(_fromLngController.text)), LatLng(double.parse(_toLatController.text), double.parse(_toLngController.text))],
                            color: Colors.blue,
                            strokeWidth: 4.0,
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