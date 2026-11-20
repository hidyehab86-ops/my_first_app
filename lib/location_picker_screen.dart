import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'app_lang.dart';
import 'main.dart'; // عشان AppColors

// مركز مدينتي تقريباً (نقطة البداية للخريطة)
const LatLng madinatyCenter = LatLng(30.10, 31.64);

// خريطة مجانية من OpenStreetMap (من غير مفتاح)
const String mapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String mapUserAgent = 'com.example.my_first_app';

String _tr(bool isAr, String ar, String en) => isAr ? ar : en;

// ======================================================================
// تحديد موقع الجهاز (GPS) مع معالجة كل حالات الفشل
// ======================================================================
enum LocationFailure { serviceOff, denied, deniedForever, error }

class LocationResult {
  const LocationResult.ok(LatLng this.point) : failure = null;
  const LocationResult.fail(LocationFailure this.failure) : point = null;

  final LatLng? point;
  final LocationFailure? failure;
}

Future<LocationResult> fetchCurrentLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult.fail(LocationFailure.serviceOff);
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationResult.fail(LocationFailure.denied);
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.fail(LocationFailure.deniedForever);
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return LocationResult.ok(LatLng(position.latitude, position.longitude));
  } catch (_) {
    return const LocationResult.fail(LocationFailure.error);
  }
}

// رسالة للمواطن + البدايل (الخريطة أو كتابة العنوان)
String locationFailureMessage(LocationFailure failure, bool isAr) {
  final alternative = _tr(
    isAr,
    ' تقدر تحدد المكان على الخريطة أو تكتب العنوان.',
    ' You can pick the spot on the map or type the address.',
  );

  switch (failure) {
    case LocationFailure.serviceOff:
      return _tr(isAr, 'خدمة الموقع (GPS) مقفولة.', 'Location service is off.') +
          alternative;
    case LocationFailure.denied:
      return _tr(isAr, 'مفيش إذن لاستخدام الموقع.',
              'Location permission was denied.') +
          alternative;
    case LocationFailure.deniedForever:
      return _tr(
            isAr,
            'إذن الموقع مرفوض، فعّله من إعدادات الموبايل.',
            'Location permission is blocked. Enable it in phone settings.',
          ) +
          alternative;
    case LocationFailure.error:
      return _tr(isAr, 'مقدرناش نحدد موقعك دلوقتي.',
              'Could not get your location right now.') +
          alternative;
  }
}

// ======================================================================
// شاشة الخريطة: المواطن بيحدد المكان، أو (readOnly) عرض مكان البلاغ بس
// ======================================================================
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initial,
    this.readOnly = false,
  });

  final LatLng? initial;
  final bool readOnly;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _controller = MapController();
  LatLng? _selected;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _useMyLocation(bool isAr) async {
    setState(() => _locating = true);
    final result = await fetchCurrentLocation();
    if (!mounted) return;
    setState(() => _locating = false);

    final point = result.point;
    if (point == null) {
      _snack(locationFailureMessage(result.failure!, isAr));
      return;
    }

    setState(() => _selected = point);
    _controller.move(point, 17);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, _) {
        final isAr = lang == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              title: Text(
                widget.readOnly
                    ? _tr(isAr, 'موقع البلاغ', 'Report location')
                    : _tr(isAr, 'حدد مكان المشكلة', 'Pick the location'),
                style: const TextStyle(fontSize: 17),
              ),
            ),
            body: Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: _selected ?? madinatyCenter,
                    initialZoom: _selected == null ? 14.5 : 17,
                    onTap: widget.readOnly
                        ? null
                        : (tapPosition, point) =>
                            setState(() => _selected = point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: mapTileUrl,
                      userAgentPackageName: mapUserAgent,
                    ),
                    if (_selected != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selected!,
                            width: 48,
                            height: 48,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFFBA1A1A),
                              size: 48,
                            ),
                          ),
                        ],
                      ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                if (!widget.readOnly)
                  PositionedDirectional(
                    top: 12,
                    start: 12,
                    end: 12,
                    child: Material(
                      color: Colors.white,
                      elevation: 3,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Text(
                          _tr(
                            isAr,
                            'اضغط على الخريطة عشان تحط الدبوس على مكان المشكلة',
                            'Tap the map to drop the pin on the problem spot',
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            floatingActionButton: widget.readOnly
                ? null
                : FloatingActionButton.extended(
                    onPressed: _locating ? null : () => _useMyLocation(isAr),
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.navy,
                    icon: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(_tr(isAr, 'موقعي الحالي', 'My location')),
                  ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: widget.readOnly
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _selected == null
                              ? null
                              : () => Navigator.pop(context, _selected),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _tr(isAr, 'تأكيد الموقع', 'Confirm location'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
