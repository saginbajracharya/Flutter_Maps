import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:travelrecords/widgets/map_style_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey             = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _latController       = TextEditingController();
  final _lngController       = TextEditingController();

  // Add map controller
  final  MapController _mapController = MapController();
  LatLng _currentLocation             = const LatLng(0, 0);  // Default location
  String _currentMapStyle             = 'default';
  // Map of available styles
  final Map<String, String> _mapStyles = {
    'default'     : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'topo'        : 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    'cycle'       : 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
    'humanitarian': 'https://tile-{s}.openstreetmap.fr/hot/{z}/{x}/{y}.png',
  };
  final List<Marker> _markers = []; // List to hold markers
  Marker? _clickedMarker; // Add a marker for the clicked position

  @override
  void initState() {
    super.initState();
    _setCurrentLocation();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _setCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, return early
      return;
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, return early
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, return early
      return;
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition();

    // Check if the widget is still mounted before calling setState
    if (!mounted) return;

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _latController.text = position.latitude.toString();
      _lngController.text = position.longitude.toString();
      _clickedMarker = Marker(
          // Initialize or move the current location marker
          point: _currentLocation,
          width: 80,
          height: 80,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red, // Color for the current location marker
            size: 40,
          ),
        );
      // Ensure the map is centered on the current location
      _mapController.move(_currentLocation, 13.0); // Move the map to the current location
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
          title: const Text('MAP'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Name fields row
                Row(
                  children: [
                    Flexible(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter first name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter last name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Lat & Lon fields row
                Row(
                  children: [
                    // Add Latitude field
                    Flexible(
                      child: TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter latitude';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Add Longitude field
                    Flexible(
                      child: TextFormField(
                        controller: _lngController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter longitude';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Current and Set Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _setCurrentLocation();
                          // After getting current location, animate map to that position
                          _mapController.move(_currentLocation, 13.0);
                        },
                        icon: const Icon(Icons.my_location,color: Colors.white),
                        label: const Text('Current Location',style: TextStyle(color: Colors.white)),
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
                        )
                      ),
                    ),
                    const SizedBox(width: 16), // Add some space between the buttons
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            log('Lat: ${_latController.text}, Lng: ${_lngController.text}');
                            // Add a new marker with the first name
                            setState(() {
                              int markerIndex = _markers.length + 1;
                              _markers.add(
                                Marker(
                                  point: LatLng(
                                    double.parse(_latController.text),
                                    double.parse(_lngController.text),
                                  ),
                                  width: 80,
                                  height: 80,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned(
                                        bottom: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Add padding
                                          color: Colors.white.withOpacity(0.7), // Background color with some transparency
                                          child: Text('$markerIndex : ${_firstNameController.text}'),
                                        ),
                                      ), // Show first name
                                      IconButton(
                                        icon: const Icon(
                                          Icons.person_pin_circle,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          // Show dialog with details
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text('Details'),
                                                content: Text(
                                                  'Name: ${_firstNameController.text} ${_lastNameController.text}\n'
                                                  'Latitude: ${_latController.text}\n'
                                                  'Longitude: ${_lngController.text}',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Get.back();
                                                      FocusScope.of(context).unfocus();
                                                    },
                                                    child: const Text('Close'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black54,
                          padding: const EdgeInsets.only(left: 5, right: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10), // Less rounded
                            side: const BorderSide(
                              color: Colors.black, // Border color
                              width: 2, // Border width
                            ),
                          ),
                        ),
                        child: const Text('Set Location',style: TextStyle(color: Colors.white))
                      ),
                    ),
                  ],
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
                const SizedBox(height: 5),
                // Add Map
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation,
                      initialZoom: 13.0,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _currentLocation = point;
                          _latController.text = point.latitude.toString();
                          _lngController.text = point.longitude.toString();
                          _clickedMarker = Marker(
                            // Set the clicked marker
                            point: point,
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red, // Change color for clicked marker
                              size: 40,
                            ),
                          );
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _mapStyles[_currentMapStyle],
                        // Add subdomains for styles that need them
                        subdomains: _currentMapStyle == 'default'
                            ? const []
                            : const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: [
                          ..._markers,
                          if (_clickedMarker != null)
                            _clickedMarker!, // Add clicked marker if it exists
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
