import 'dart:convert';

import 'package:feature_manager/src/models/feature.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureManager {
  FeatureManager._(this._sharedPreferences);

  static FeatureManager? _instance;

  final SharedPreferences _sharedPreferences;

  /// Retrieves the instance of the FeatureManager class.
  ///
  /// This method checks if the instance has already been created. If not, it initializes it by
  /// retrieving the shared preferences and creating a new instance of the FeatureManager class.
  ///
  /// Returns a `Future` that resolves to the instance of the FeatureManager class.
  static Future<FeatureManager> getInstance() async {
    if (_instance == null) {
      final sharedPreferences = await SharedPreferences.getInstance();
      _instance = FeatureManager._(sharedPreferences);
    }
    return _instance!;
  }

  /// Returns the singleton instance of [FeatureManager].
  ///
  /// Throws an [Exception] if the instance is not initialized.
  /// Ensure to call `getInstance()` before accessing this property.
  static FeatureManager get instance {
    if (_instance == null) {
      throw Exception('FeatureManager instance is not initialized. Call getInstance() first.');
    }
    return _instance!;
  }

  /// Disposes the instance of the class.
  ///
  /// This function sets the `_instance` variable to `null`, effectively disposing of the instance.
  static void dispose() {
    _instance = null;
  }

  /// Determines if the given [feature] is enabled.
  ///
  /// Retrieves the boolean value associated with the [feature]'s key from the shared preferences.
  /// If the value is not found, returns the feature's default value, or false if no default is set.
  ///
  /// Parameters:
  /// - `feature`: The [Feature<bool>] object to check.
  ///
  /// Returns:
  /// - `bool`: `true` if the feature is enabled, `false` otherwise.
  bool isEnabled(Feature<bool> feature) {
    return _sharedPreferences.getBool(feature.key) ?? feature.defaultValue ?? false;
  }

  /// Retrieves the value associated with the given [feature] from the shared preferences.
  ///
  /// Parameters:
  ///   - `feature`: The [Feature<T>] object for which the value needs to be retrieved.
  ///
  /// Returns:
  ///   - The value associated with the feature key in the shared preferences, or the feature's default value if no value is found.
  dynamic getValue(Feature<dynamic> feature) {
    return _sharedPreferences.get(feature.key) ?? feature.defaultValue;
  }

  /// Retrieves a string value from the shared preferences for the provided [Feature<String>].
  ///
  /// Parameters:
  ///   - `feature`: The [Feature<String>] for which to retrieve the value.
  ///
  /// Returns:
  ///   The string value, or `null` if not found.
  String? getString(Feature<String> feature) {
    return _sharedPreferences.getString(feature.key) ?? feature.defaultValue;
  }

  /// Retrieves an integer value from the shared preferences for the provided [Feature<int>].
  ///
  /// Parameters:
  ///   - `feature`: The [Feature<int>] for which to retrieve the value.
  ///
  /// Returns:
  ///   The integer value, or `null` if not found.
  int? getInt(Feature<int> feature) {
    return _sharedPreferences.getInt(feature.key) ?? feature.defaultValue;
  }

  /// Retrieves a double value from the shared preferences for the provided [Feature<double>].
  ///
  /// Parameters:
  ///   - `feature`: The [Feature<double>] for which to retrieve the value.
  ///
  /// Returns:
  ///   The double value, or `null` if not found.
  double? getDouble(Feature<double> feature) {
    return _sharedPreferences.getDouble(feature.key) ?? feature.defaultValue;
  }

  /// Retrieves and decodes a JSON string from the provided feature.
  ///
  /// The feature must be of type [Feature<Map<String, dynamic>>] containing a JSON string.
  ///
  /// Returns:
  ///   A `Map<String, dynamic>` containing the decoded JSON, or `null` if the string
  ///   is empty or invalid.
  Map<String, dynamic>? getJson(Feature<Map<String, dynamic>> feature) {
    final value = _sharedPreferences.getString(feature.key);
    if (value == null || value.isEmpty) {
      return feature.defaultValue;
    }
    return jsonDecode(value) as Map<String, dynamic>;
  }
}
