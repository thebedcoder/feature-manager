void main() {}

// import 'package:bloc_test/bloc_test.dart';
// import 'package:feature_manager/feature_manager.dart';
// import 'package:feature_manager/src/bloc/features_cubit.dart';
// import 'package:feature_manager/src/data/feature_repository.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
//
// import 'feature_cubit_test.mocks.dart';
//
// @GenerateMocks([FeatureRepository, Feature])
// void main() {
//   final FeatureRepository repository = MockFeatureRepository();
//   final Feature feature = MockFeature();
//
//   group('getFeatures', () {
//     blocTest<FeaturesCubit, FeaturesState>(
//       'FeaturesCubit emits FeaturesSuccess when feature list is not empty',
//       build: () {
//         // given
//         when(repository.getFeatures()).thenAnswer((_) async => [feature]);
//         when(repository.getFeaturesStream())
//             .thenAnswer((_) => Stream.value([feature]));
//
//         return FeaturesCubit(repository);
//       },
//       act: (cubit) => cubit.getFeatures(),
//       expect: () => [
//         isInstanceOf<FeaturesLoading>(),
//         isInstanceOf<FeaturesSuccess>(),
//         isInstanceOf<FeaturesSuccess>(),
//       ],
//     );
//
//     blocTest<FeaturesCubit, FeaturesState>(
//       'FeaturesCubit emits FeaturesEmpty when feature list is empty',
//       build: () {
//         // given
//         when(repository.getFeatures()).thenAnswer((_) async => []);
//         when(repository.getFeaturesStream())
//             .thenAnswer((_) => Stream.value([]));
//
//         return FeaturesCubit(repository);
//       },
//       act: (cubit) => cubit.getFeatures(),
//       expect: () => [
//         isInstanceOf<FeaturesLoading>(),
//         isInstanceOf<FeaturesEmpty>(),
//         isInstanceOf<FeaturesEmpty>(),
//       ],
//     );
//
//     blocTest<FeaturesCubit, FeaturesState>(
//       'FeaturesCubit emits FeaturesError when getFutures error',
//       build: () {
//         // given
//         when(repository.getFeatures()).thenThrow(Error());
//
//         return FeaturesCubit(repository);
//       },
//       act: (cubit) => cubit.getFeatures(),
//       expect: () => [
//         isInstanceOf<FeaturesLoading>(),
//         isInstanceOf<FeaturesError>(),
//       ],
//     );
//   });
//
//   group('changeFeature', () {
//     blocTest<FeaturesCubit, FeaturesState>(
//       'FeaturesCubit invokes putValue for provided feature',
//       build: () {
//         // given
//         when(repository.putValue(feature, any)).thenAnswer((_) async => {});
//
//         return FeaturesCubit(repository);
//       },
//       act: (cubit) => cubit.changeFeature(feature, true),
//       verify: (_) {
//         verify(repository.putValue(feature, true)).called(1);
//       },
//     );
//
//     blocTest<FeaturesCubit, FeaturesState>(
//       'FeaturesCubit emits FeaturesError when putValue throws error',
//       build: () {
//         // given
//         when(repository.putValue(feature, any)).thenThrow(Error());
//
//         return FeaturesCubit(repository);
//       },
//       act: (cubit) => cubit.changeFeature(feature, true),
//       verify: (_) {
//         verify(repository.putValue(feature, true)).called(1);
//       },
//       expect: () => [
//         isInstanceOf<FeaturesError>(),
//       ],
//     );
//   });
// }
