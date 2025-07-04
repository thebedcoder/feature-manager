import 'package:feature_manager/feature.dart';
import 'package:feature_manager/feature_manager.dart';

/// Extension on `BooleanFeature` to check if the feature is enabled.
extension BooleanFeatureExt on BooleanFeature {
  /// Returns `true` if the feature is enabled, otherwise `false`.
  bool get isEnabled => FeatureManager.instance.isEnabled(this);
}

extension FeatureBooleanExt<T> on Feature<T> {
  T? get value {
    if (isBoolean) {
      return FeatureManager.instance.isEnabled(this as Feature<bool>) as T?;
    } else if (isText) {
      return FeatureManager.instance.getString(this as Feature<String>) as T?;
    } else if (isDouble) {
      return FeatureManager.instance.getDouble(this as Feature<double>) as T?;
    } else if (isInteger) {
      return FeatureManager.instance.getInt(this as Feature<int>) as T?;
    } else if (isJson) {
      return FeatureManager.instance
          .getJson(this as Feature<Map<String, dynamic>>) as T?;
    } else {
      throw Exception('Unsupported feature type');
    }
  }

  /// Returns true if this Boolean Feature
  bool get isBoolean => this is Feature<bool>;

  /// Returns true if this Text Feature
  bool get isText => this is Feature<String>;

  /// Returns true if this Double Feature
  bool get isDouble => this is Feature<double>;

  /// Returns true if this Integer Feature
  bool get isInteger => this is Feature<int>;

  /// Returns true if this Json Feature
  bool get isJson => this is Feature<Map<String, dynamic>>;
}
