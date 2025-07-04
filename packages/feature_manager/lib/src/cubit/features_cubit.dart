import 'dart:async';

import 'package:feature_manager/feature.dart';
import 'package:feature_manager/src/cubit/cubit.dart';
import 'package:feature_manager/src/data/feature_repository.dart';
import 'package:flutter/foundation.dart';

part 'features_state.dart';

class FeaturesCubit extends Cubit<FeaturesState> {
  FeaturesCubit(this.repository) : super(FeaturesInitial());

  final FeatureRepository repository;
  StreamSubscription<List<Feature<dynamic>>>? _featuresSubscription;

  void getFeatures() {
    try {
      emit(FeaturesLoading());

      final features = repository.getFeatures();

      if (features.isNotEmpty) {
        emit(FeaturesSuccess(features));
      } else {
        emit(FeaturesEmpty());
      }
    } catch (e) {
      if (kDebugMode) {
        print('FeatureManager error >> $e');
      }
      emit(FeaturesError());
    }
  }

  Future<void> changeFeature(
    Feature<dynamic> feature,
    Object? value,
  ) async {
    try {
      await repository.putValue(feature, value);
      getFeatures();
    } catch (e) {
      if (kDebugMode) {
        print('FeatureManager error >> $e');
      }
      emit(FeaturesError());
    }
  }

  @override
  Future<void> close() {
    _featuresSubscription?.cancel();
    _featuresSubscription = null;
    return super.close();
  }
}
