## 3.1.0

- Updated dependencies:
  - lints to ^6.0.0
- Internal maintenance and version bump.


## 3.0.5

- Fixed an issue where the Developer Preferences screen did not update after a value change.
- Resolved an issue causing the `TextFeature` to appear under the `JsonFeature` flow.
- Fixed a saving issue in the `JsonFeature`.

## 3.0.4

### Breaking Changes 🔥

#### Updated Feature Model:

- `Feature<T>` now relies solely on its generic type for determining feature behavior.
- Removed FeatureValueType references in favor of type inference.

```dart
// Old
@FeatureOptions(
    key: 'dev-prefs-bool-pref',
    title: 'Toggle pref',
    description: 'This is toggle preference',
    defaultValue: false,
    valueType: FeatureValueType.toggle,
)
final Feature booleanFeature;

// New (no need for valueType)
@FeatureOptions(
    key: 'dev-prefs-bool-pref',
    title: 'Toggle pref',
    description: 'This is toggle preference',
    defaultValue: false,
  )
final Feature<bool> booleanFeature;
```

#### Compatibility with feature_manager_generator:

- Ensure your code is compatible by migrating away from FeatureValueType.

## 3.0.2

- Removed unused `value` Parameter from `FeatureOptions`:
- Added `FeatureType` Parameter to Typed Feature Classes

## 3.0.1

- Export for `src/utils/extensions.dart `to make extensions publicly accessible.

## 3.0.0

- Added a new wrapper for typed features. Instead of creating a generic Feature class, you can now use specific types: `BooleanFeature`, `TextFeature`, `IntegerFeature`, `DoubleFeature`, and `JsonFeature`.
- Introduced a new annotation for use with the `feature_manager_generator`.

## 2.0.0

- Fixed overflow issue and increased version to 2.0.0

## 1.3.0

- BREAKING CHANGE: Now you can use `FeatureManager.getInstance()` to get feature manager. Shared preferences initialization is inside now.

## 1.2.1

- Updated dependencies

## 1.2.0

- Removed `bloc` and provider `dependencies`
- Changed FeatureManager initialization. Now it's required to call `FeatureManager.initialize()` function to provide `sharePreferences` for `FeatureManager`. Otherwise it would crash.

## 1.1.2

- Upgraded Dart and Flutter versions

## 1.1.1

- Updated Readme

## 1.1.0

- BREAKING: now you need to provide SharedPreferences instance to create feature manager
- Added sync calls for FeatureManager
- Added additional getters for FeatureManger
- Added json type for Feature

## 1.0.0

- Initial release of Feature Manager
