library;

import 'package:build/build.dart';
import 'package:feature_manager_generator/src/factory.dart';

Builder featureManagerGenerator(BuilderOptions options) =>
    generatorFactoryBuilder(options);
