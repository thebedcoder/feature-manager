import 'dart:convert';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:feature_manager/annotations.dart';
import 'package:feature_manager/feature.dart';
import 'package:source_gen/source_gen.dart';

class FeatureGenerator extends GeneratorForAnnotation<FeatureManagerInit> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '`@FeatureManagerInit` can only be used on classes.',
        element: element,
      );
    }

    final classElement = element;
    final buffer = StringBuffer();
    final featureFieldNames = <String>[];

    buffer.writeln('class _\$${classElement.name} implements ${classElement.name} {');
    buffer.writeln();

    buffer.writeln('''
    factory  _\$${classElement.name}() {
      return _instance;
    }''');
    buffer.writeln();

    buffer.writeln(
      ' static final _\$${classElement.name} _instance = _\$${classElement.name}._internal();',
    );
    buffer.writeln();

    // Start the constructor with initializer list
    buffer.writeln('  _\$${classElement.name}._internal()');

    final initializers = <String>[];
    final fieldDeclarations = <String>[];

    for (final field in classElement.fields) {
      final featureOptions = _getFeatureOptions(field);
      if (featureOptions == null) {
        log.warning('Field ${field.name} does not have a valid FeatureOptions annotation.');
        continue;
      }

      final featureType = _getGenericFeatureType(field);
      if (featureType == null) {
        log.warning('Field ${field.name} does not have a valid generic Feature<T> type.');
        continue;
      }

      final initializer = _generateFeatureInitializer(field.name, featureType, featureOptions);
      initializers.add(initializer);

      // Collect the feature field names
      featureFieldNames.add(field.name);

      // Generate the field declaration
      fieldDeclarations.add('  @override\n  final $featureType ${field.name};');
    }

    // Add initializers to the constructor
    if (initializers.isNotEmpty) {
      buffer.writeln('      : ${initializers.join(',\n        ')};');
    } else {
      buffer.writeln('      ;');
    }

    // Add field declarations
    fieldDeclarations.forEach(buffer.writeln);

    buffer.writeln('}');

    buffer.writeln('extension ${classElement.name}Ext on ${classElement.name} {');
    buffer.writeln('  List<Feature> get values => [');
    for (final fieldName in featureFieldNames) {
      buffer.writeln('        $fieldName,');
    }
    buffer.writeln('      ];');
    buffer.writeln('}');

    // Generate the extension
    buffer.writeln('extension FeatureManagerExt on FeatureManager {');
    for (final field in classElement.fields) {
      final featureOptions = _getFeatureOptions(field);
      if (featureOptions == null) {
        continue;
      }
      final featureType = _getGenericFeatureType(field);
      buffer.writeln(
        '  $featureType get ${field.name} => _\$${classElement.name}().${field.name};',
      );
    }
    buffer.writeln('}');

    final generatedCode = buffer.toString();
    return generatedCode;
  }

  String? _getGenericFeatureType(FieldElement field) {
    final featureInterface = field.type.element;
    if (featureInterface is ClassElement && featureInterface.name == 'Feature') {
      final typeArguments = (field.type as ParameterizedType).typeArguments;
      if (typeArguments.isEmpty) {
        return null;
      }
      final genericType = typeArguments.first;

      if (genericType.isDartCoreBool) {
        return 'BooleanFeature';
      } else if (genericType.isDartCoreString) {
        return 'TextFeature';
      } else if (genericType.isDartCoreDouble) {
        return 'DoubleFeature';
      } else if (genericType.isDartCoreInt) {
        return 'IntegerFeature';
      } else {
        return 'JsonFeature';
      }
    }
    return null;
  }

  FeatureOptions? _getFeatureOptions(FieldElement field) {
    const typeChecker = TypeChecker.fromRuntime(FeatureOptions);
    for (final metadata in field.metadata) {
      final elementValue = metadata.computeConstantValue();
      if (elementValue == null || !typeChecker.isExactlyType(elementValue.type!)) {
        continue;
      }

      final defaultValueField = elementValue.getField('defaultValue');
      final defaultValue = _getLiteralValue(defaultValueField);

      return FeatureOptions(
        key: elementValue.getField('key')?.toStringValue() ?? '',
        remoteSourceKey: elementValue.getField('remoteSourceKey')?.toStringValue() ?? '',
        title: elementValue.getField('title')?.toStringValue() ?? '',
        description: elementValue.getField('description')?.toStringValue() ?? '',
        defaultValue: defaultValue,
        type:
            FeatureType.values[elementValue.getField('type')?.getField('index')?.toIntValue() ?? 0],
      );
    }
    return null;
  }

  dynamic _getLiteralValue(DartObject? object) {
    if (object == null || object.isNull) {
      return null;
    }

    final type = object.type;
    if (type == null) {
      return null;
    }

    if (type.isDartCoreString) {
      return object.toStringValue();
    } else if (type.isDartCoreInt) {
      return object.toIntValue();
    } else if (type.isDartCoreDouble) {
      return object.toDoubleValue();
    } else if (type.isDartCoreBool) {
      return object.toBoolValue();
    } else if (type.isDartCoreMap) {
      return _dartObjectToMap(object);
    }
    return null;
  }

  String _generateFeatureInitializer(String fieldName, String featureType, FeatureOptions options) {
    return '''
        $fieldName = $featureType(
          key: '${options.key}',
          remoteSourceKey: '${options.remoteSourceKey}',
          title: '${options.title}',
          description: '${options.description}',
          defaultValue: ${_formatDefaultValue(options.defaultValue)},
          type: ${options.type},
        )''';
  }

  dynamic _formatDefaultValue(dynamic value) {
    if (value is String) {
      return "'${value.replaceAll("'", r"\'")}'";
    } else if (value is bool || value is num) {
      return value.toString();
    } else if (value is Map<String, dynamic>) {
      return jsonEncode(value);
    }
    return 'null';
  }

  Map<String, dynamic> _dartObjectToMap(DartObject object) {
    final result = <String, dynamic>{};
    final map = object.toMapValue();

    if (map != null) {
      for (final entry in map.entries) {
        final key = entry.key?.toStringValue();
        final value = _getLiteralValue(entry.value);

        if (key != null) {
          result[key] = value;
        }
      }
    }

    return result;
  }
}
