## 4.0.0

- **Breaking Change**: Migrated from Element2 API back to Element API for analyzer 9.0.0 compatibility
  - Updated imports from `package:analyzer/dart/element/element2.dart` to `package:analyzer/dart/element/element.dart`
  - Changed `Element2` to `Element`, `ClassElement2` to `ClassElement`, `FieldElement2` to `FieldElement`
  - Updated method calls: `name3` → `name`, `fields2` → `fields`, `type.element3` → `type.element`
  - Replaced manual metadata iteration with `TypeChecker.firstAnnotationOfExact()` for better compatibility
- **Dependencies**: Updated to latest versions for better compatibility and performance
  - analyzer: ^7.4.0 → ^9.0.0
  - build: ^3.0.0 → ^4.0.3
  - source_gen: ^3.0.0 → ^4.1.1
  - lints: ^5.1.1 → ^6.0.0

## 3.1.2

- **Breaking Change**: Migrated to analyzer 2.0 API with updated element types and method names
  - Updated imports from `package:analyzer/dart/element/element.dart` to `package:analyzer/dart/element/element2.dart`
  - Changed `Element` to `Element2`, `ClassElement` to `ClassElement2`, `FieldElement` to `FieldElement2`
  - Updated method calls: `name` → `name3`, `fields` → `fields2`, `type.element` → `type.element3`, `metadata` → `metadata2.annotations`
  - Updated `TypeChecker.fromRuntime()` to `TypeChecker.typeNamed()` for better compatibility
- **Dependencies**: Updated core dependencies for better compatibility and performance
  - analyzer: ^7.5.2 → ^7.4.0
  - build: ^2.4.2 → ^3.0.0
  - source_gen: ^2.0.0 → ^3.0.0
- **SDK**: Updated Dart SDK constraint from `^3.6.0` to `'>=3.7.0 <4.0.0'` for broader compatibility
- **Code Quality**: Improved null safety handling and code formatting throughout the generator

## 3.1.1

- Maintenance: Transitioned to Melos monorepo tooling
- Compatibility: Reverted build and lint dependencies to support Dart 3.6

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

### Refactored Feature Type Handling

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
