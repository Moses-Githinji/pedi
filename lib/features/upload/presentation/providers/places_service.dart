import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pedi/core/utils/logger.dart';

class GooglePlacesService {
  // Use the Firebase Google API Key as the default Places key
  static const String _apiKey = 'AIzaSyCfW7jMPNl7eUk7nR_CKRDMgAFgurme7wo';

  /// Fetch location predictions dynamically as the user types
  Future<List<Map<String, dynamic>>> fetchSuggestions({
    required String input,
    required String sessionToken,
  }) async {
    if (input.trim().isEmpty) return [];

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=$_apiKey'
        '&sessiontoken=$sessionToken'
        '&types=geocode|establishment', // matches geocodable regions and businesses
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List predictions = data['predictions'] ?? [];
          return predictions.map<Map<String, dynamic>>((p) {
            return {
              'description': p['description'] ?? '',
              'placeId': p['place_id'] ?? '',
              'mainText': p['structured_formatting']?['main_text'] ?? '',
              'secondaryText': p['structured_formatting']?['secondary_text'] ?? '',
            };
          }).toList();
        } else {
          logger.w('Google Places Autocomplete API warning status: ${data['status']}');
        }
      } else {
        logger.e('Failed to fetch suggestions from Google Places. Status: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Exception during fetchSuggestions: $e');
    }
    return [];
  }

  /// Retrieve coordinates (lat/lng) and exact place details for a given place ID
  Future<Map<String, double>?> fetchPlaceCoordinates({
    required String placeId,
    required String sessionToken,
  }) async {
    if (placeId.trim().isEmpty) return null;

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${Uri.encodeComponent(placeId)}'
        '&fields=geometry'
        '&key=$_apiKey'
        '&sessiontoken=$sessionToken',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']?['geometry']?['location'];
          if (location != null) {
            final double lat = (location['lat'] as num).toDouble();
            final double lng = (location['lng'] as num).toDouble();
            return {'lat': lat, 'lng': lng};
          }
        } else {
          logger.w('Google Places Details API warning status: ${data['status']}');
        }
      } else {
        logger.e('Failed to fetch place details from Google. Status: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Exception during fetchPlaceCoordinates: $e');
    }
    return null;
  }
}
