import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as geolocator;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final genesysMapUrl = dotenv.env['GENESYS_MAP_URL'] ?? '';
  runApp(MyApp(genesysMapUrl: genesysMapUrl));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.genesysMapUrl});
  final String genesysMapUrl;

  @override
  Widget build (BuildContext context) {
    return MaterialApp(home: Map(genesysMapUrl: genesysMapUrl));
  }
}

class Map extends StatefulWidget {
  const Map({super.key, required this.genesysMapUrl});
  final String genesysMapUrl;

  @override
  State<Map> createState() => _MapState();
}

class _MapState extends State<Map> {
  MapboxMap? mapboxMap;
  bool _isStyleLoaded = false;
  Point? _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    _initializeCameraPosition();
  }

  Future<void> _initializeCameraPosition() async {
    try {
      debugPrint('Starting location initialization');
      final position = await _determinePosition();
      debugPrint('Location obtained successfully: ${position.latitude}, ${position.longitude}');
      setState(() {
        _initialCameraPosition = Point(
          coordinates: Position(position.longitude, position.latitude),
        );
      });
    } catch (e, stackTrace) {
      debugPrint('Error getting location: $e');
      debugPrint('Stack trace: $stackTrace');
      // Fallback to a default position if location is not available
      setState(() {
        _initialCameraPosition = Point(
          coordinates: Position(72.88, 19.11),
        );
      });
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    
    try {
      mapboxMap.loadStyleURI(widget.genesysMapUrl).then((_) {
        setState(() {
          _isStyleLoaded = true;
        });
        debugPrint('Genesys map style loaded successfully');
      }).catchError((error) {
        debugPrint('Error loading Genesys map style: $error');
      });
    } catch (e) {
      debugPrint('Exception while loading Genesys map style: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
        children: [
          MapWidget(
            key: Key('map'),
            onMapCreated: _onMapCreated,
            cameraOptions: CameraOptions(
              center: _initialCameraPosition, // Default position
              zoom: 10,
            ),
          ),
          if (!_isStyleLoaded)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      );
      },
    );
  }
}

Future<geolocator.Position> _determinePosition() async {
  bool serviceEnabled;
  geolocator.LocationPermission permission;

  debugPrint('Checking if location services are enabled...');
  try {
    serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    debugPrint('Location services enabled: $serviceEnabled');
  } catch (e, stackTrace) {
    debugPrint('Error checking location services: $e');
    debugPrint('Stack trace: $stackTrace');    
    return Future.error('Failed to check location services. If using a simulator, set a simulated location.');
  }

  if (!serviceEnabled) {  
    debugPrint('Location services are disabled.');    
    return Future.error('Location services are disabled. If using a simulator, enable location services.');
  }

  debugPrint('Checking location permission...');
  try {
    permission = await geolocator.Geolocator.checkPermission();
    debugPrint('Current permission status: $permission');
  } catch (e, stackTrace) {
    debugPrint('Error checking permission: $e');
    debugPrint('Stack trace: $stackTrace');
    return Future.error('Failed to check location permission');
  }

  if (permission == geolocator.LocationPermission.denied) {
    debugPrint('Requesting location permission...');
    try {
      permission = await geolocator.Geolocator.requestPermission();
      debugPrint('Permission after request: $permission');
    } catch (e, stackTrace) {
      debugPrint('Error requesting permission: $e');
      debugPrint('Stack trace: $stackTrace');
      return Future.error('Failed to request location permission');
    }
    
    if (permission == geolocator.LocationPermission.denied) {
      debugPrint('Location permissions are denied');
      return Future.error('Location permissions are denied');
    }
  }
  
  if (permission == geolocator.LocationPermission.deniedForever) {
    debugPrint('Location permissions are permanently denied, we cannot request permissions.');
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.');
  } 

  debugPrint('Getting current position...');
  try {
    final position = await geolocator.Geolocator.getCurrentPosition();
    debugPrint('Position obtained: ${position.latitude}, ${position.longitude}');
    return position;
  } catch (e, stackTrace) {
    debugPrint('Error getting current position: $e');
    debugPrint('Stack trace: $stackTrace');
    return Future.error('Failed to get current position. If using a simulator, set a simulated location.');
  }
}