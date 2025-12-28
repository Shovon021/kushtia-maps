import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Added for StreamSubscription
import 'package:url_launcher/url_launcher.dart';

// Define a POI (Point of Interest) class with extended details
class PointOfInterest {
  final String name;
  final String nameBn; // Bangla name
  final LatLng location;
  final IconData icon;
  final Color color;
  final String category;
  final String description;
  final String? phone;
  final String? imageUrl;
  final bool isCustom;

  const PointOfInterest({
    required this.name,
    this.nameBn = '',
    required this.location,
    required this.icon,
    required this.color,
    required this.category,
    this.description = 'A notable place in Kushtia District.',
    this.phone,
    this.imageUrl,
    this.isCustom = false,
  });

  PointOfInterest copyWith({
    String? name,
    String? nameBn,
    LatLng? location,
    IconData? icon,
    Color? color,
    String? category,
    String? description,
    String? phone,
    String? imageUrl,
    bool? isCustom,
  }) {
    return PointOfInterest(
      name: name ?? this.name,
      nameBn: nameBn ?? this.nameBn,
      location: location ?? this.location,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      category: category ?? this.category,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

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
  List<PointOfInterest> _customPOIs = [];
  List<LatLng> _routePoints = [];
  PointOfInterest? _routeDestination;
  bool _showBangla = false;
  bool _isLoadingRoute = false;
  String _selectedCategory = 'All'; // Category Filter State

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

  // List of Points of Interest in Kushtia with extended details
  final List<PointOfInterest> _allPOIs = const [
    // --- RESIDENCES ---
    PointOfInterest(
      name: "Shafin's Family Residence",
      nameBn: 'সাফিনদের বাড়ি',
      location: LatLng(23.914392, 89.117662),
      icon: Icons.home,
      color: Colors.deepPurple,
      category: 'Residence',
      description: 'The residence of Shafin and family.',
    ),

    // --- GOVERNMENT ---
    PointOfInterest(
      name: 'Deputy Commissioner Office (DC Court)',
      nameBn: 'জেলা প্রশাসকের কার্যালয়',
      location: LatLng(23.9085, 89.1225),
      icon: Icons.account_balance,
      color: Colors.brown,
      category: 'Government',
    ),
    PointOfInterest(
      name: 'Kushtia Municipality',
      nameBn: 'কুষ্টিয়া পৌরসভা',
      location: LatLng(23.9065, 89.1235),
      icon: Icons.location_city,
      color: Colors.brown,
      category: 'Government',
    ),
    PointOfInterest(
      name: 'Police Superintendent Office',
      nameBn: 'পুলিশ সুপারের কার্যালয়',
      location: LatLng(23.9095, 89.1215),
      icon: Icons.security,
      color: Colors.brown,
      category: 'Government',
    ),
    PointOfInterest(
      name: 'Circuit House',
      nameBn: 'সার্কিট হাউজ',
      location: LatLng(23.9055, 89.1265),
      icon: Icons.villa,
      color: Colors.brown,
      category: 'Government',
    ),

    // --- EDUCATION ---
    PointOfInterest(
      name: 'Islamic University',
      nameBn: 'ইসলামী বিশ্ববিদ্যালয়',
      location: LatLng(23.7245, 89.1535),
      icon: Icons.school,
      color: Colors.blue,
      category: 'Education',
      description: 'A major public research university.',
      phone: '+880-71-74560',
    ),
    PointOfInterest(
      name: 'Kushtia Govt College',
      nameBn: 'কুষ্টিয়া সরকারি কলেজ',
      location: LatLng(23.9050, 89.1245),
      icon: Icons.school,
      color: Colors.blue,
      category: 'Education',
      description: 'Premier government college.',
    ),
    PointOfInterest(
      name: 'Kushtia Zilla School',
      nameBn: 'কুষ্টিয়া জেলা স্কুল',
      location: LatLng(23.9065, 89.1180),
      icon: Icons.school,
      color: Colors.blue,
      category: 'Education',
    ),
    PointOfInterest(
      name: 'Police Lines School',
      nameBn: 'পুলিশ লাইন্স স্কুল',
      location: LatLng(23.9120, 89.1100),
      icon: Icons.school,
      color: Colors.blue,
      category: 'Education',
    ),
     PointOfInterest(
      name: 'Kushtia Medical College',
      nameBn: 'কুষ্টিয়া মেডিকেল কলেজ',
      location: LatLng(23.9000, 89.1150),
      icon: Icons.school,
      color: Colors.blue,
      category: 'Education',
    ),

    // --- HEALTH ---
    PointOfInterest(
      name: 'Kushtia General Hospital',
      nameBn: 'কুষ্টিয়া জেনারেল হাসপাতাল',
      location: LatLng(23.9100, 89.1280),
      icon: Icons.local_hospital,
      color: Colors.red,
      category: 'Hospital',
      description: '250-bed General Hospital.',
      phone: '16263',
    ),
    PointOfInterest(
      name: 'Sono Hospital',
      nameBn: 'সনো হাসপাতাল',
      location: LatLng(23.9020, 89.1300),
      icon: Icons.local_hospital,
      color: Colors.red,
      category: 'Hospital',
      description: 'Famous diagnostic center and hospital.',
    ),
    PointOfInterest(
      name: 'Ad-Din Hospital',
      nameBn: 'আদ-দ্বীন হাসপাতাল',
      location: LatLng(23.8980, 89.1250),
      icon: Icons.local_hospital,
      color: Colors.red,
      category: 'Hospital',
    ),
    PointOfInterest(
      name: 'Diabetes Hospital',
      nameBn: 'ডায়াবেটিস হাসপাতাল',
      location: LatLng(23.9210, 89.1310),
      icon: Icons.local_hospital,
      color: Colors.red,
      category: 'Hospital',
    ),

    // --- RELIGIOUS ---
    PointOfInterest(
      name: 'Lalon Shah Mazar',
      nameBn: 'লালন শাহ মাজার',
      location: LatLng(23.7765, 89.1620),
      icon: Icons.mosque,
      color: Colors.green,
      category: 'Religious',
      description: 'Shrine of Fakir Lalon Shah.',
    ),
    PointOfInterest(
      name: 'Boro Jame Masjid',
      nameBn: 'বড় জামে মসজিদ',
      location: LatLng(23.9068, 89.1195),
      icon: Icons.mosque,
      color: Colors.green,
      category: 'Religious',
      description: 'Central mosque of Kushtia town.',
    ),
    PointOfInterest(
      name: 'Thanapara Jame Masjid',
      nameBn: 'থানাপাড়া জামে মসজিদ',
      location: LatLng(23.9090, 89.1210),
      icon: Icons.mosque,
      color: Colors.green,
      category: 'Religious',
    ),

    // --- BANK & ATM ---
    PointOfInterest(
      name: 'Islami Bank Main Br.',
      nameBn: 'ইসলামী ব্যাংক',
      location: LatLng(23.9060, 89.1210),
      icon: Icons.account_balance,
      color: Colors.indigo,
      category: 'Bank',
    ),
    PointOfInterest(
      name: 'Sonali Bank Corp.',
      nameBn: 'সোনালী ব্যাংক',
      location: LatLng(23.9055, 89.1190),
      icon: Icons.account_balance,
      color: Colors.indigo,
      category: 'Bank',
    ),
    PointOfInterest(
      name: 'DBBL ATM Booth',
      nameBn: 'ডাচ-বাংলা এটিএম',
      location: LatLng(23.9085, 89.1230),
      icon: Icons.atm,
      color: Colors.indigo,
      category: 'ATM',
    ),

    // --- FOOD ---
    PointOfInterest(
      name: 'Kheya Restaurant',
      nameBn: 'খেয়া রেস্তোরাঁ',
      location: LatLng(23.9040, 89.1260),
      icon: Icons.restaurant,
      color: Colors.pink,
      category: 'Restaurant',
      description: 'Riverside dining.',
    ),
    PointOfInterest(
      name: 'Mouban Restaurant',
      nameBn: 'মৌবন রেস্তোরাঁ',
      location: LatLng(23.9075, 89.1225),
      icon: Icons.restaurant,
      color: Colors.pink,
      category: 'Restaurant',
      description: 'Sweets and snacks.',
    ),
    PointOfInterest(
      name: 'Jahangir Hotel',
      nameBn: 'জাহাঙ্গীর হোটেল',
      location: LatLng(23.9030, 89.1180),
      icon: Icons.restaurant,
      color: Colors.pink,
      category: 'Restaurant',
      description: 'Famous for local food.',
    ),
    PointOfInterest(
      name: 'KFC (Ruma)',
      nameBn: 'কেএফসি',
      location: LatLng(23.9070, 89.1240),
      icon: Icons.fastfood,
      color: Colors.pink,
      category: 'Restaurant',
    ),

    // --- HOTELS ---
    PointOfInterest(
      name: 'Hotel River View',
      nameBn: 'হোটেল রিভার ভিউ',
      location: LatLng(23.9045, 89.1270),
      icon: Icons.hotel,
      color: Colors.teal,
      category: 'Hotel',
    ),
    PointOfInterest(
      name: 'Desha Tarc',
      nameBn: 'দিশা টার্ক',
      location: LatLng(23.8800, 89.1100),
      icon: Icons.hotel,
      color: Colors.teal,
      category: 'Hotel',
      description: 'Training center and rest house.',
    ),
    PointOfInterest(
      name: 'Hotel Al-Amin',
      nameBn: 'হোটেল আল-আমিন',
      location: LatLng(23.9060, 89.1200),
      icon: Icons.hotel,
      color: Colors.teal,
      category: 'Hotel',
    ),

    // --- FUEL ---
    PointOfInterest(
      name: 'Mondol Filling Station',
      nameBn: 'মন্ডল ফিলিং স্টেশন',
      location: LatLng(23.8950, 89.1150),
      icon: Icons.local_gas_station,
      color: Colors.orange,
      category: 'Fuel',
    ),
    PointOfInterest(
      name: 'Biswas Filling Station',
      nameBn: 'বিশ্বাস ফিলিং স্টেশন',
      location: LatLng(23.9150, 89.1120),
      icon: Icons.local_gas_station,
      color: Colors.orange,
      category: 'Fuel',
    ),

     // --- MARKETS ---
    PointOfInterest(
      name: 'Kushtia Bazar',
      nameBn: 'কুষ্টিয়া বাজার',
      location: LatLng(23.9070, 89.1200),
      icon: Icons.store,
      color: Colors.purple,
      category: 'Market',
      description: 'Main market area.',
    ),
    PointOfInterest(
      name: 'NS Road Market',
      nameBn: 'এন এস রোড',
      location: LatLng(23.9060, 89.1220),
      icon: Icons.shopping_bag,
      color: Colors.purple,
      category: 'Market',
    ),

    // --- LANDMARKS ---
    PointOfInterest(
      name: 'Lalon Shah Bridge',
      nameBn: 'লালন শাহ সেতু',
      location: LatLng(24.0720, 89.0380),
      icon: Icons.architecture,
      color: Colors.brown,
      category: 'Landmark',
    ),
    PointOfInterest(
      name: 'Hardinge Bridge',
      nameBn: 'হার্ডিঞ্জ ব্রিজ',
      location: LatLng(24.0795, 89.0290),
      icon: Icons.train,
      color: Colors.brown,
      category: 'Landmark',
    ),
     PointOfInterest(
      name: 'Jagati Railway Station',
      nameBn: 'জগতি রেলওয়ে স্টেশন',
      location: LatLng(23.8880, 89.1350),
      icon: Icons.train,
      color: Colors.brown,
      category: 'Landmark',
      description: 'First railway station in East Bengal (1862).',
    ),
    PointOfInterest(
      name: 'Renwick Jajneswar',
      nameBn: 'রেনউইক যজ্ঞেশ্বর',
      location: LatLng(23.9110, 89.1320),
      icon: Icons.park,
      color: Colors.green,
      category: 'Park',
      description: 'River bank park.',
    ),
  ];

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
    _checkLocationPermission();
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
                    color: poi.color.withOpacity(0.2),
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share feature coming soon!')),
                    );
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
                });
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
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
          '?geometries=geojson&overview=full';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final routePoints = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          
          final distance = data['routes'][0]['distance'] / 1000; // km
          final duration = data['routes'][0]['duration'] / 60; // minutes
          
          setState(() {
            _routePoints = routePoints;
            _isLoadingRoute = false;
          });
          
          // Fit map to show entire route
          if (routePoints.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(routePoints);
            _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Route: ${distance.toStringAsFixed(1)} km, ~${duration.toStringAsFixed(0)} min'),
              duration: const Duration(seconds: 3),
            ),
          );
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
    });
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
                          color: isSelected ? Colors.teal.withOpacity(0.2) : Colors.grey[200],
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
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
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
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.withOpacity(0.5)),
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
                              color: Colors.blue.withOpacity(0.2),
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
                                  color: Colors.black.withOpacity(0.3),
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
          
          // Clear Route Button (when route is active)
          if (_routePoints.isNotEmpty)
            Positioned(
              bottom: 160,
              left: 16,
              child: FloatingActionButton(
                heroTag: 'clear_route',
                mini: true,
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onPressed: _clearRoute,
                child: const Icon(Icons.close),
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
