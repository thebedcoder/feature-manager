import 'dart:convert';

import 'package:feature_manager/feature.dart';
import 'package:feature_manager/feature_manager.dart';
import 'package:feature_manager/src/cubit/features_cubit.dart';
import 'package:feature_manager/src/data/feature_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'feature_item.dart';

class DeveloperPreferencesScreen extends StatefulWidget {
  const DeveloperPreferencesScreen({
    required this.sharedPreferences,
    required this.featuresList,
    super.key,
  });

  final List<Feature<dynamic>> featuresList;
  final SharedPreferences sharedPreferences;

  @override
  State<DeveloperPreferencesScreen> createState() =>
      _DeveloperPreferencesScreenState();
}

class _DeveloperPreferencesScreenState
    extends State<DeveloperPreferencesScreen> {
  late FeaturesCubit cubit;

  @override
  void initState() {
    super.initState();

    cubit = FeaturesCubit(
      FeatureRepository(
        featuresList: widget.featuresList,
        sharedPreferences: widget.sharedPreferences,
      ),
    );

    cubit.getFeatures();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Manager'),
      ),
      body: StreamBuilder<FeaturesState>(
        initialData: cubit.state,
        stream: cubit.stream,
        builder: (context, state) {
          final featuresState = state.data ?? cubit.state;
          if (featuresState is FeaturesSuccess) {
            return _Success(cubit, featuresState.features);
          } else if (featuresState is FeaturesLoading) {
            return const _Loading();
          } else if (featuresState is FeaturesEmpty) {
            return const _Empty();
          } else if (featuresState is FeaturesError) {
            return const _Error();
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success(this.cubit, this.preferences);

  final FeaturesCubit cubit;
  final List<Feature<dynamic>> preferences;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final preference = preferences[index];
        return _FeatureItem(
          preference,
          onChanged: (newValue) => cubit.changeFeature(preference, newValue),
        );
      },
      itemCount: preferences.length,
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Error while getting preferences',
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'There are no preferences',
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );
  }
}
