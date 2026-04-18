import 'dart:convert';
import 'package:flutter/services.dart';

/// Loads location data (State → District → SubDistrict → Village)
/// from JSON asset files. Loads lazily — one state file at a time.
class LocationService {
  static final LocationService _instance = LocationService._();
  factory LocationService() => _instance;
  LocationService._();

  // Cache: stateName → districts data
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  // index: stateName → filename
  Map<String, String>? _index;

  /// Load state index (small file — always keep loaded)
  Future<Map<String, String>> _loadIndex() async {
    if (_index != null) return _index!;
    final raw = await rootBundle.loadString('assets/location/index.json');
    final map = Map<String, dynamic>.from(json.decode(raw));
    _index = map.map((k, v) => MapEntry(k, v.toString()));
    return _index!;
  }

  /// All state names (sorted)
  Future<List<String>> getStates() async {
    final index = await _loadIndex();
    final states = index.keys.toList()..sort();
    return states;
  }

  /// Load districts for a state (cached)
  Future<List<String>> getDistricts(String stateName) async {
    final data = await _loadStateData(stateName);
    return data.map((d) => d['district'] as String).toList()..sort();
  }

  /// Get sub-districts (talukas) for a district
  Future<List<String>> getSubDistricts(
    String stateName,
    String districtName,
  ) async {
    final data = await _loadStateData(stateName);
    final district = data.firstWhere(
      (d) => d['district'] == districtName,
      orElse: () => {},
    );
    if (district.isEmpty) return [];
    final subDistricts = district['subDistricts'] as List;
    return subDistricts.map((sd) => sd['subDistrict'] as String).toList()
      ..sort();
  }

  /// Get villages for a sub-district
  Future<List<String>> getVillages(
    String stateName,
    String districtName,
    String subDistrictName,
  ) async {
    final data = await _loadStateData(stateName);
    final district = data.firstWhere(
      (d) => d['district'] == districtName,
      orElse: () => {},
    );
    if (district.isEmpty) return [];
    final subDistricts = district['subDistricts'] as List;
    final subDistrict = subDistricts.firstWhere(
      (sd) => sd['subDistrict'] == subDistrictName,
      orElse: () => {},
    );
    if (subDistrict.isEmpty) return [];
    final villages = subDistrict['villages'] as List;
    return villages.map((v) => v.toString()).toList()..sort();
  }

  /// Load state JSON file (cached)
  Future<List<Map<String, dynamic>>> _loadStateData(String stateName) async {
    if (_cache.containsKey(stateName)) return _cache[stateName]!;

    final index = await _loadIndex();
    final fileName = index[stateName];
    if (fileName == null) return [];

    try {
      final raw = await rootBundle.loadString('assets/location/$fileName');
      final data = Map<String, dynamic>.from(json.decode(raw));
      final districts = List<Map<String, dynamic>>.from(
        data['districts'] ?? [],
      );
      _cache[stateName] = districts;
      return districts;
    } catch (e) {
      return [];
    }
  }
}
