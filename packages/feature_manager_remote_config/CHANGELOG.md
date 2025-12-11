## 4.0.0

- **Version Bump**: Major version update to 4.0.0 for compatibility with feature_manager 4.0.0
- **Dependencies**: Updated feature_manager dependency to ^4.0.0
- **Compatibility**: Updated to work with feature_manager 4.0.0 which supports the latest analyzer, build, and source_gen versions

## 3.1.3

- Bump `firebase_remote_config` version to >= 6.0.0

## 3.1.2

- **Version Bump**: Updated to version 3.1.2 for consistency with other packages in the monorepo
- **SDK**: Updated Dart SDK constraint from `^3.6.0` to `'>=3.7.0 <4.0.0'` for broader compatibility
- **Dependencies**: Removed unused `flutter_lints` dependency from dev_dependencies
- **Maintenance**: Minor version bump with no breaking changes

## 3.1.1

- Maintenance: Transitioned to Melos monorepo tooling

## 3.0.4

### Refactored Feature Type Handling

- Removed FeatureValueType and replaced it with generic type inference for Feature<T>.
- The generator now detects the correct feature type (`BooleanFeature`, `TextFeature`, etc.) based on the generic type (`Feature<bool>`, `Feature<String>,` etc.).
- Added better logging for invalid feature fields.

## 3.0.0

- Updated to the latest `FeatureManager` changes

## 2.0.0

- Updated to the latest `FeatureManager` changes
- Added documentation
- Removed specified dependencies versions

## 1.0.2

- Upgraded Dart and Flutter versions

## 1.0.1

- Updated Readme

## 1.0.0

- Initial release
