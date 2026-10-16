// lib/screens/map_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPickerScreen extends StatefulWidget {
  final Function(double x, double y, String address) onLocationSelected;
  final double? initialX;
  final double? initialY;

  const MapPickerScreen({
    super.key,
    required this.onLocationSelected,
    this.initialX,
    this.initialY,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  MapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoading = false;
  bool _isGettingLocation = false;
  bool _isMapReady = false;
  String? _errorMessage;

  static const String _nominatimUrl =
      'https://nominatim.openstreetmap.org/reverse';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  void _onMapCreated(MapController controller) {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });

    if (_selectedLocation != null) {
      _mapController!.move(_selectedLocation!, 15);
    }
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);

    if (widget.initialX != null && widget.initialY != null) {
      setState(() {
        _selectedLocation = LatLng(widget.initialY!, widget.initialX!);
      });
      await _getAddressFromCoordinates(widget.initialY!, widget.initialX!);
      setState(() => _isLoading = false);
    } else {
      await _getCurrentLocation();
      setState(() => _isLoading = false);
    }
  }

  Future<LocationPermission> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('نحتاج إلى صلاحية الموقع لتحديد موقعك'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return LocationPermission.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تفعيل صلاحية الموقع من إعدادات الهاتف'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return LocationPermission.deniedForever;
    }

    return permission;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _errorMessage = null;
    });

    try {
      LocationPermission permission = await _requestLocationPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _selectedLocation = const LatLng(33.5138, 36.2765);
        });
        await _getAddressFromCoordinates(33.5138, 36.2765);

        if (_isMapReady &&
            _mapController != null &&
            _selectedLocation != null) {
          _mapController!.move(_selectedLocation!, 15);
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الرجاء تفعيل خدمة الموقع (GPS) من الإعدادات'),
              duration: Duration(seconds: 3),
            ),
          );
        }

        setState(() {
          _selectedLocation = const LatLng(33.5138, 36.2765);
        });
        await _getAddressFromCoordinates(33.5138, 36.2765);

        if (_isMapReady &&
            _mapController != null &&
            _selectedLocation != null) {
          _mapController!.move(_selectedLocation!, 15);
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      await _getAddressFromCoordinates(position.latitude, position.longitude);

      if (_isMapReady && _mapController != null && _selectedLocation != null) {
        _mapController!.move(_selectedLocation!, 15);
      }
    } catch (e) {
      print('خطأ في جلب الموقع: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في جلب الموقع: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      setState(() {
        _selectedLocation = const LatLng(33.5138, 36.2765);
      });
      await _getAddressFromCoordinates(33.5138, 36.2765);

      if (_isMapReady && _mapController != null && _selectedLocation != null) {
        _mapController!.move(_selectedLocation!, 15);
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_nominatimUrl?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
        ),
        headers: {
          'User-Agent':
              'YourAppName/1.0 (contact@yourapp.com)', // تحسين User-Agent
          'Accept-Language': 'ar,en',
        },
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          setState(() {
            _selectedAddress = data['display_name'];
          });
        }
      } else if (response.statusCode == 403) {
        print('خطأ 403 في جلب العنوان');
        setState(() {
          _selectedAddress = 'تم تحديد الموقع (خطأ في جلب العنوان)';
        });
      }
    } catch (e) {
      print('خطأ في جلب العنوان: $e');
      if (mounted) {
        setState(() {
          _selectedAddress = 'تم تحديد الموقع (فشل في جلب العنوان)';
        });
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    _getAddressFromCoordinates(point.latitude, point.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر الموقع'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () {
                widget.onLocationSelected(
                  _selectedLocation!.longitude,
                  _selectedLocation!.latitude,
                  _selectedAddress,
                );
                Navigator.pop(context);
              },
              child: const Text(
                'تأكيد',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.shade100,
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (_selectedAddress.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade100,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedAddress,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isGettingLocation) const LinearProgressIndicator(),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter:
                              _selectedLocation ??
                              const LatLng(33.5138, 36.2765),
                          initialZoom: 15,
                          onTap: _onMapTap,
                        ),
                        children: [
                          // استخدام Tile Layer مع إعدادات محسنة
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app2',
                            // إضافة إعدادات إضافية لتجنب 403
                            additionalOptions: const {
                              'user_agent': 'YourApp/1.0',
                            },
                            // إضافة retry في حالة الفشل
                            maxZoom: 19,
                            minZoom: 3,
                          ),
                          if (_selectedLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _selectedLocation!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.white,
                          onPressed: _getCurrentLocation,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
