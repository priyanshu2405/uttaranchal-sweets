import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DetectedAddress {
  final String pincode;
  final String street;
  final String city;
  const DetectedAddress({required this.pincode, required this.street, required this.city});
}

class LocationProblem implements Exception {
  final String message;
  final bool openLocationSettings;
  final bool openAppSettings;
  const LocationProblem(this.message, {this.openLocationSettings = false, this.openAppSettings = false});

  @override
  String toString() => message;
}

/// Finds the phone's current position and turns it into pincode / street / city
/// using the phone's built-in geocoder (no API key needed).
Future<DetectedAddress> detectCurrentAddress() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationProblem('Please turn on location (GPS) and try again.', openLocationSettings: true);
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied) {
    throw const LocationProblem('Location permission was not allowed. You can type your address instead.');
  }
  if (permission == LocationPermission.deniedForever) {
    throw const LocationProblem('Location is turned off for this app. Allow it in Settings, or type your address.', openAppSettings: true);
  }

  final Position pos;
  try {
    pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
    );
  } catch (_) {
    throw const LocationProblem('We couldn’t get your location. Please try again outdoors, or type your address.');
  }

  List<Placemark> marks;
  try {
    marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
  } catch (_) {
    throw const LocationProblem('We found you, but couldn’t read the address. Please check your internet or type it in.');
  }
  if (marks.isEmpty) throw const LocationProblem('We couldn’t find an address here. Please type it in.');

  final m = marks.first;
  String clean(String? v) => (v ?? '').trim();
  final parts = <String>[];
  for (final v in [clean(m.subThoroughfare), clean(m.thoroughfare), clean(m.subLocality)]) {
    if (v.isNotEmpty && !parts.contains(v) && !RegExp(r'^\+?\w{4}\+\w{2,}').hasMatch(v)) parts.add(v);
  }
  if (parts.isEmpty && clean(m.street).isNotEmpty) parts.add(clean(m.street));
  final city = [clean(m.locality).isNotEmpty ? clean(m.locality) : clean(m.subAdministrativeArea), clean(m.administrativeArea)].where((s) => s.isNotEmpty).join(', ');

  return DetectedAddress(pincode: clean(m.postalCode), street: parts.join(', '), city: city);
}

Future<bool> openPhoneLocationSettings() => Geolocator.openLocationSettings();
Future<bool> openAppPermissionSettings() => Geolocator.openAppSettings();
