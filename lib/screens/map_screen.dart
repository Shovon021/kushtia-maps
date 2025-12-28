import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/pois.dart'; // Import POI data

// Map Style Definition
class MapStyle {
  final String name;
  final String urlTemplate;
  final IconData icon;

  const MapStyle({
    required this.name,
    required this.urlTemplate,
    required this.icon,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription; // For live updates
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // New state variables for 2.0 features
  final List<PointOfInterest> _customPOIs = [];
  List<LatLng> _routePoints = [];
  PointOfInterest? _routeDestination;
  bool _showBangla = false;
  bool _isLoadingRoute = false;
  String _selectedCategory = 'All'; // Category Filter State
  String _travelMode = 'driving'; // driving, cycling, walking
  Map<String, dynamic>? _routeStats; // To store distance/duration

  // Define available map styles
  final List<MapStyle> _mapStyles = [
    const MapStyle(
      name: 'Standard',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      icon: Icons.map,
    ),
    const MapStyle(
      name: 'Modern',
      urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
      icon: Icons.light_mode,
    ),
    const MapStyle(
      name: 'Dark',
      urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}@2x.png',
      icon: Icons.dark_mode,
    ),
    const MapStyle(
      name: 'Satellite',
      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      icon: Icons.satellite_alt,
    ),
  ];

  late MapStyle _currentMapStyle;

  // Kushtia Center
  final LatLng kushtiaCenter = const LatLng(23.9088, 89.1220);

  // Use POI data from lib/data/pois.dart
  List<PointOfInterest> get _allPOIs => kushtiaPOIs;

  List<PointOfInterest> get _allPOIsIncludingCustom => [..._allPOIs, ..._customPOIs];

  // Dynamic Category List
  List<String> get _categories {
    final categories = _allPOIsIncludingCustom.map((e) => e.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  List<PointOfInterest> get _filteredPOIs {
    var allPois = _allPOIsIncludingCustom;
    
    // 1. Filter by Category
    if (_selectedCategory != 'All') {
      allPois = allPois.where((poi) => poi.category == _selectedCategory).toList();
    }

    // 2. Filter by Search Query
    if (_searchQuery.isEmpty) {
      return allPois;
    }
    return allPois
        .where((poi) =>
            poi.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            poi.nameBn.contains(_searchQuery) ||
            poi.category.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _currentMapStyle = _mapStyles[0];
    _loadCustomPOIs(); // Load saved custom places
    _checkLocationPermission();
  }

  // ========== FEATURE: Persist Custom Places ==========
  Future<void> _loadCustomPOIs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('customPOIs') ?? [];
    setState(() {
      _customPOIs.clear();
      for (final jsonStr in saved) {
        final data = jsonDecode(jsonStr);
        _customPOIs.add(PointOfInterest(
          name: data['name'],
          nameBn: data['nameBn'] ?? '',
          location: LatLng(data['lat'], data['lng']),
          icon: Icons.place,
          color: Colors.purple,
          category: 'Custom',
          isCustom: true,
        ));
      }
    });
  }

  Future<void> _saveCustomPOIs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded = _customPOIs.map((poi) {
      return jsonEncode({
        'name': poi.name,
        'nameBn': poi.nameBn,
        'lat': poi.location.latitude,
        'lng': poi.location.longitude,
      });
    }).toList();
    await prefs.setStringList('customPOIs', encoded);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========== FEATURE: Real-time Location ==========
  void _startLiveLocationUpdates() {
    if (_positionStreamSubscription != null) return; // Already listening

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // Optimized for navigation
      distanceFilter: 5, // Update every 5 meters for smoother movement
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) {
        if (position != null) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
        }
      },
    );
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services disabled')));
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // 1. Get initial fix
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );
      
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      
      // 2. Move camera
      _mapController.move(_currentPosition!, 16.0);

      // 3. Start Live Stream
      _startLiveLocationUpdates();

    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _goToPOI(PointOfInterest poi) {
    _mapController.move(poi.location, 16.0);
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  // ========== FEATURE 1: Place Details Bottom Sheet ==========
  void _showPlaceDetails(PointOfInterest poi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                  color: poi.color.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                  child: Icon(poi.icon, size: 32, color: poi.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _showBangla && poi.nameBn.isNotEmpty ? poi.nameBn : poi.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(poi.category, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                if (poi.isCustom)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                    setState(() => _customPOIs.remove(poi));
                    _saveCustomPOIs(); // Persist deletion
                    Navigator.pop(context);
                  },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(poi.description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            
            // Coordinates
            Text(
              'Coordinates: ${poi.location.latitude.toStringAsFixed(4)}, ${poi.location.longitude.toStringAsFixed(4)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Navigate Button
                _buildActionButton(
                  icon: Icons.directions,
                  label: 'Navigate',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _getRouteToDestination(poi);
                  },
                ),
                // Call Button
                if (poi.phone != null)
                  _buildActionButton(
                    icon: Icons.phone,
                    label: 'Call',
                    color: Colors.green,
                    onTap: () => _makePhoneCall(poi.phone!),
                  ),
                // Share Button
              _buildActionButton(
                icon: Icons.share,
                label: 'Share',
                color: Colors.orange,
                onTap: () async {
                  final url = 'https://www.google.com/maps/search/?api=1&query=${poi.location.latitude},${poi.location.longitude}';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  }
                },
              ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // ========== FEATURE 2: Add Missing Place (Long Press) ==========
  void _onMapLongPress(TapPosition tapPosition, LatLng location) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Place'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Place Name',
                hintText: 'e.g., My Home',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _customPOIs.add(PointOfInterest(
                    name: nameController.text,
                    location: location,
                    icon: Icons.place,
                    color: Colors.pink,
                    category: 'Custom',
                    description: descController.text.isEmpty 
                        ? 'User-added place' 
                        : descController.text,
                    isCustom: true,
                  ));
                });  // end setState
              _saveCustomPOIs(); // Persist new place
              Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added: ${nameController.text}')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ========== FEATURE 3: Navigation/Routing ==========
  Future<void> _getRouteToDestination(PointOfInterest destination) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location first!')),
      );
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _routeDestination = destination;
    });

    try {
      final start = _currentPosition!;
      final end = destination.location;
      
      // Using OSRM (Open Source Routing Machine) - FREE API
      // Profiles: driving, cycling, walking
      final url = 'https://router.project-osrm.org/route/v1/$_travelMode/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
          '?geometries=geojson&overview=full';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final routePoints = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          
          final distance = data['routes'][0]['distance'] / 1000; // km
          
          // Calculate duration based on travel mode speeds (km/h)
          // driving: ~40 km/h avg in city, cycling: ~15 km/h, walking: ~5 km/h
          double speedKmH;
          switch (_travelMode) {
            case 'walking':
              speedKmH = 5.0;
              break;
            case 'cycling':
              speedKmH = 15.0;
              break;
            default: // driving
              speedKmH = 40.0;
          }
          final duration = (distance / speedKmH) * 60; // minutes
          
          setState(() {
            _routePoints = routePoints;
            _isLoadingRoute = false;
            _routeStats = {
              'distance': distance.toStringAsFixed(1),
              'duration': duration.toStringAsFixed(0),
            };
          });
          
          // Fit map to show entire route
          if (routePoints.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(routePoints);
            _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
          }
        }
      } else {
        throw Exception('Failed to get route');
      }
    } catch (e) {
      setState(() => _isLoadingRoute = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Route error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
      _routeDestination = null;
      _routeStats = null;
    });
  }

  void _changeTravelMode(String mode) {
    if (_routeDestination != null) {
      setState(() => _travelMode = mode);
      _getRouteToDestination(_routeDestination!);
    }
  }

  // ========== FEATURE 4: Bangla Toggle ==========
  void _toggleLanguage() {
    setState(() => _showBangla = !_showBangla);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_showBangla ? 'বাংলা সক্রিয়' : 'English enabled'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showStylePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Map Style', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _mapStyles.map((style) {
                final isSelected = _currentMapStyle == style;
                return InkWell(
                  onTap: () {
                    setState(() => _currentMapStyle = style);
                    Navigator.pop(context);
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.teal.withAlpha(51) : Colors.grey[200],
                          border: isSelected ? Border.all(color: Colors.teal, width: 2) : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(style.icon, size: 28, color: Colors.teal),
                      ),
                      const SizedBox(height: 6),
                      Text(style.name, style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.teal : Colors.black,
                        fontSize: 12,
                      )),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(IconData icon, String mode) {
    bool isSelected = _travelMode == mode;
    return GestureDetector(
      onTap: () => _changeTravelMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.teal.shade700) : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.black54,
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showBangla ? 'কুষ্টিয়া ম্যাপস' : 'Kushtia Maps'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // Bangla Toggle
          IconButton(
            icon: Text(_showBangla ? 'EN' : 'বাং', style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _toggleLanguage,
            tooltip: 'Toggle Language',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.tealAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.map, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    _showBangla ? 'কুষ্টিয়া ম্যাপস' : 'Kushtia Maps',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text('v1.0.0', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.teal),
              title: const Text('Developer'),
              subtitle: const Text('Sarfaraz Ahamed Shovon'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('About Developer'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sarfaraz Ahamed Shovon',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Flutter Developer', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 16),
                        const Text('Built with ❤️ for Kushtia'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers, color: Colors.teal),
              title: const Text('Map Style'),
              onTap: () {
                Navigator.pop(context);
                _showStylePicker();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.teal),
              title: const Text('About App'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'Kushtia Maps',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2024 Sarfaraz Ahamed Shovon',
                  children: [
                    const SizedBox(height: 16),
                    const Text('A free, open-source map application for Kushtia District.'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: kushtiaCenter,
              initialZoom: 11.0,
              minZoom: 9.0,
              maxZoom: 18.0,
              onLongPress: _onMapLongPress, // Feature 2: Long press to add
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(23.50, 88.70),
                  const LatLng(24.30, 89.60),
                ),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _currentMapStyle.urlTemplate,
                userAgentPackageName: 'com.kushtiamaps.app',
                maxZoom: 19,
                tileProvider: CancellableNetworkTileProvider(),
              ),
              
              // Feature 3: Route Polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              
              MarkerLayer(
                markers: [
                  // POI Markers
                  ..._filteredPOIs.map((poi) => Marker(
                    point: poi.location,
                    width: 100, // Increase width to accommodate text
                    height: 90, // Increase height for text
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _showPlaceDetails(poi),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Positioned(
                                bottom: 2,
                                child: Container(
                                  width: 10,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(77),
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(77),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.location_on,
                                size: 50, // Slightly smaller pin
                                color: poi.color,
                              ),
                              Positioned(
                                top: 7,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    poi.icon,
                                    size: 18,
                                    color: poi.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Bangla Label (Visible only when toggle is ON)
                          if (_showBangla && poi.nameBn.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(230),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.withAlpha(128)),
                              ),
                              child: Text(
                                poi.nameBn,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  )),
                  // User Location Marker (Modern GPS Puck)
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Glow (imulates pulsing)
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(51),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Core Dot
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(77),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [TextSourceAttribution('© OpenStreetMap')],
              ),
            ],
          ),

          // Search Bar Overlay
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: _showBangla ? 'স্থান খুঁজুন...' : 'Search places...',
                      prefixIcon: const Icon(Icons.search, color: Colors.teal),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            })
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                // Category Filter Chips
                if (_searchQuery.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category, style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            )),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? category : 'All';
                              });
                            },
                            selectedColor: Colors.teal,
                            backgroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        );
                      },
                    ),
                  ),
                if (_searchQuery.isNotEmpty && _filteredPOIs.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredPOIs.length,
                      itemBuilder: (context, index) {
                        final poi = _filteredPOIs[index];
                        return ListTile(
                          leading: Icon(poi.icon, color: poi.color),
                          title: Text(_showBangla && poi.nameBn.isNotEmpty ? poi.nameBn : poi.name),
                          subtitle: Text(poi.category),
                          onTap: () {
                            _goToPOI(poi);
                            _showPlaceDetails(poi);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          
          // Loading indicator for route
          if (_isLoadingRoute)
            const Center(child: CircularProgressIndicator()),
          
          // Layer Switcher Button
          Positioned(
            bottom: 100,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'layers',
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal,
              onPressed: _showStylePicker,
              child: const Icon(Icons.layers),
            ),
          ),
          
          // Navigation Dashboard (displayed when route is active)
          if (_routePoints.isNotEmpty && _routeStats != null)
            Positioned(
              bottom: 20,
              left: 10,
              right: 10,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('${_routeStats!['duration']} min', 
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
                              const Text('Est. Time', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          Column(
                            children: [
                              Text('${_routeStats!['distance']} km', 
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
                              const Text('Distance', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: _clearRoute,
                          ),
                        ],
                      ),
                      const Divider(),
                      // Travel Mode Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildModeButton(Icons.directions_car, 'driving'),
                          _buildModeButton(Icons.directions_bike, 'cycling'),
                          _buildModeButton(Icons.directions_walk, 'walking'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Zoom In
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.teal,
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(_mapController.camera.center, currentZoom + 1);
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          // Zoom Out
          FloatingActionButton(
            heroTag: 'zoom_out',
            mini: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.teal,
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(_mapController.camera.center, currentZoom - 1);
            },
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 16),
          // My Location
          FloatingActionButton(
            heroTag: 'my_location',
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            onPressed: _getCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}
