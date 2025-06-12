import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    } 
    
    catch (e) {
      debugPrint('Exception while loading Genesys map style: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: Key('map'),
            onMapCreated: _onMapCreated,
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(72.89, 19.11)),
              zoom: 10,
            ),
          ),
          if (!_isStyleLoaded)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}