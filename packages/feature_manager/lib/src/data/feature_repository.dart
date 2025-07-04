import 'dart:async';
import 'dart:convert';

import 'package:feature_manager/feature.dart';
import 'package:feature_manager/feature_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureRepository {
  FeatureRepository({
    required List<Feature<dynamic>> featuresList,
    required SharedPreferences sharedPreferences,
  })  : _featuresList = featuresList,
        _sharedPreferences = sharedPreferences;

  final List<Feature<dynamic>> _featuresList;
  final SharedPreferences _sharedPreferences;

  List<Feature<dynamic>> getFeatures() => _featuresList;

  Future<void> putValue(
    Feature<dynamic> feature,
    Object? value,
  ) async {
    if (value == null) {
      await _sharedPreferences.remove(feature.key);
      return;
    }
    if (feature.isText && value is String) {
      await _sharedPreferences.setString(feature.key, value);
    } else if (feature.isJson && value is Map<String, dynamic>) {
      await _sharedPreferences.setString(feature.key, jsonEncode(value));
    } else if (feature.isBoolean && value is bool) {
      await _sharedPreferences.setBool(feature.key, value);
    } else if (feature.isDouble && value is double) {
      await _sharedPreferences.setDouble(feature.key, value);
    } else if (feature.isInteger && value is int) {
      await _sharedPreferences.setInt(feature.key, value);
    } else {
      throw Exception('Invalid value type');
    }
  }
}
