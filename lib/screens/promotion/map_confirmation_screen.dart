import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapConfirmationScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const MapConfirmationScreen({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  @override
  State<MapConfirmationScreen> createState() => _MapConfirmationScreenState();
}

class _MapConfirmationScreenState extends State<MapConfirmationScreen> {
  late GoogleMapController _mapController;
  late LatLng _markerPosition;
  
  @override
  void initState() {
    super.initState();
    _markerPosition = LatLng(widget.initialLatitude, widget.initialLongitude);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMarkerDragEnd(LatLng newPosition) {
    setState(() {
      _markerPosition = newPosition;
    });
  }
  
  void _confirmLocation() {
    final coordinates = {
      'latitude': _markerPosition.latitude,
      'longitude': _markerPosition.longitude,
    };
    Navigator.of(context).pop(coordinates);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirme a Localização'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _markerPosition,
              zoom: 17.0,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('event_location'),
                position: _markerPosition,
                draggable: true,
                onDragEnd: _onMarkerDragEnd,
              ),
            },
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFd74533), // Cor primária
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Confirmar Localização', style: TextStyle(color: Colors.white)),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]
              ),
              child: const Text(
                'Arraste o pino para ajustar a localização exata do seu evento.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        ],
      ),
    );
  }
}