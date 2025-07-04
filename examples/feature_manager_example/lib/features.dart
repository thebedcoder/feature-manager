import 'package:feature_manager/annotations.dart';
import 'package:feature_manager/feature.dart';
import 'package:feature_manager/feature_manager.dart';

part 'features.g.dart';

@FeatureManagerInit()
class AppFeatures {
  AppFeatures({
    required this.textFeature,
    required this.booleanFeature,
    required this.doubleFeature,
    required this.integerFeature,
    required this.jsonFeature,
    required this.nullableTextFeature,
  });

  factory AppFeatures.instance() => _$AppFeatures();

  @FeatureOptions(
    key: 'dev-prefs-text-pref',
    remoteSourceKey: 'REMOTE-KEY-dev-prefs-text-pref',
    title: 'Text pref',
    description: 'This is text preference',
    defaultValue: 'Some default text',
  )
  final TextFeature textFeature;

  @FeatureOptions(
    key: 'dev-prefs-bool-pref',
    title: 'Toggle pref',
    description: 'This is toggle preference',
    defaultValue: false,
  )
  final BooleanFeature booleanFeature;

  @FeatureOptions(
    key: 'dev-prefs-double-pref',
    title: 'Number double pref',
    description: 'This is number double preference',
    defaultValue: 2.2,
  )
  final DoubleFeature doubleFeature;

  @FeatureOptions(
    key: 'dev-prefs-integer-pref',
    title: 'Number integer pref',
    description: 'This is number integer preference',
    defaultValue: 1,
  )
  final IntegerFeature integerFeature;

  @FeatureOptions(
    key: 'dev-prefs-json-pref',
    title: 'Json pref',
    description: 'This is json preference',
    defaultValue: {"value": "Json default value"},
  )
  final JsonFeature jsonFeature;

  @FeatureOptions(
    key: 'dev-prefs-text-pref-nullable',
    title: 'Text pref',
    description: 'This is text preference',
    defaultValue: null,
  )
  final TextFeature nullableTextFeature;
}
