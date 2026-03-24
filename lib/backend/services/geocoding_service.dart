import 'package:geocoding/geocoding.dart' as geo;

class GeocodingService {
  Future<List<geo.Placemark>> placemarkFromCoordinates(double latitude, double longitude) async {
    return await geo.placemarkFromCoordinates(latitude, longitude);
  }

  Future<List<geo.Location>> locationFromAddress(String address) async {
    return await geo.locationFromAddress(address);
  }
}
