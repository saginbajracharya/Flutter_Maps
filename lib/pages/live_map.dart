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

  LatLng? _startPoint; // New variable for starting point
  LatLng? _endPoint;   // New variable for destination point
  bool _showInputFields = false; // Control visibility of input fields
  bool _isSettingStartPoint = false; // New variable to track if setting start point
  bool _isSettingEndPoint = false;   // New variable to track if setting end point
  final List<LatLng> _pathPoints = [];
  final TextEditingController _startPointController = TextEditingController(); // Controller for start point
  final TextEditingController _endPointController = TextEditingController();   // Controller for end point

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
          padding: const EdgeInsets.all(0.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showInputFields = !_showInputFields; // Toggle input fields
                    });
                    if (!_showInputFields) {
                      // Reset points and markers when hiding input fields
                      _startPoint = null;
                      _endPoint = null;
                      _pathPoints.clear(); // Clear path points
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.only(left: 5, right: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Less rounded
                      side: const BorderSide(
                        color: Colors.black, // Border color
                        width: 2, // Border width
                      ),
                    ),
                  ),
                  child: Text(_showInputFields?'Cancle':'Set Start and Destination',style: const TextStyle(color: Colors.white))
                ),
                if (_showInputFields) ...[
                  TextField(
                    controller: _startPointController,
                    decoration: const InputDecoration(labelText: 'Start Point (Lat, Lng)'),
                    onSubmitted: (value) {
                      // Parse and set the start point
                      final coords = value.split(',');
                      if (coords.length == 2) {
                        _startPoint = LatLng(double.parse(coords[0]), double.parse(coords[1]));
                      }
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isSettingStartPoint = true; // Start setting the start point
                        _isSettingEndPoint = false; // Ensure end point is not being set
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.only(left: 5, right: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Less rounded
                        side: const BorderSide(
                          color: Colors.black, // Border color
                          width: 2, // Border width
                        ),
                      ),
                    ),
                    child: const Text('Set Start Point',style: TextStyle(color: Colors.white)),
                  ),
                  TextField(
                    controller: _endPointController,
                    decoration: const InputDecoration(labelText: 'End Point (Lat, Lng)'),
                    onSubmitted: (value) {
                      // Parse and set the end point
                      final coords = value.split(',');
                      if (coords.length == 2) {
                        _endPoint = LatLng(double.parse(coords[0]), double.parse(coords[1]));
                      }
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isSettingEndPoint = true; // Start setting the end point
                        _isSettingStartPoint = false; // Ensure start point is not being set
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.only(left: 5, right: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Less rounded
                        side: const BorderSide(
                          color: Colors.black, // Border color
                          width: 2, // Border width
                        ),
                      ),
                    ),
                    child: const Text('Set End Point',style: TextStyle(color: Colors.white))
                  ),
                ],
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
                        if (_isSettingStartPoint) {
                          setState(() {
                            _startPoint = point; // Set the start point
                            _pathPoints.add(point); // Add start point to path
                            _isSettingStartPoint = false; // Reset the setting state
                            // Set the coordinates in the input field
                            _startPointController.text = '${point.latitude}, ${point.longitude}'; // Update start point field
                          });
                        } else if (_isSettingEndPoint) {
                          setState(() {
                            _endPoint = point; // Set the end point
                            _pathPoints.add(point); // Add end point to path
                            _isSettingEndPoint = false; // Reset the setting state
                            // Set the coordinates in the input field
                            _endPointController.text = '${point.latitude}, ${point.longitude}'; // Update end point field
                          });
                        }
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
                          if (_startPoint != null) // Add marker for start point
                            Marker(
                              point: _startPoint!,
                              child: const Icon(Icons.location_on, color: Colors.green),
                            ),
                          if (_endPoint != null) // Add marker for end point
                            Marker(
                              point: _endPoint!,
                              child: const Icon(Icons.location_on, color: Colors.red),
                            ),
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
                      if (_pathPoints.length == 2) // Draw path if both points are set
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _pathPoints,
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