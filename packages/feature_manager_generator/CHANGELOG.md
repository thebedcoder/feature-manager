## 3.1.0

- Updated dependencies:
  - analyzer to ^7.5.2
  - build to ^2.5.4
  - source_gen to ^2.0.0
  - feature_manager to ^3.1.0
  - lints to ^6.0.0
- Internal maintenance and version bump.

## 3.0.5

- Update a dependency to the latest release

## 3.0.4

### Refactored Feature Type Handling:
- Removed FeatureValueType and replaced it with generic type inference for Feature<T>.
- The generator now detects the correct feature type (`BooleanFeature`, `TextFeature`, etc.) based on the generic type (`Feature<bool>`, `Feature<String>,` etc.).
- Added better logging for invalid feature fields.

## 3.0.3

- Replaced `PartBuilder` with `SharedPartBuilder` to ensure that generated code is correctly integrated into source files using part directives. This change fixes issues where generated files were not being created or included properly, enhancing compatibility and reliability in code generation workflows.

## 3.0.2

- Fixed an issue where the `remoteSourceKey` parameter specified in FeatureOptions was not included in the generated code.
- Fixed an issue where the `type` parameter in FeatureOptions, responsible for specifying the FeatureType, was not being generated.

## 3.0.1

- Fixed: Default Value Extraction Issue

## 3.0.0

- Initial version.
