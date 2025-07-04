import 'package:build/build.dart';
import 'package:feature_manager_generator/src/generator.dart';
import 'package:source_gen/source_gen.dart';

Builder generatorFactoryBuilder(BuilderOptions options) => SharedPartBuilder(
      [FeatureGenerator()],
      'fm',
    );
