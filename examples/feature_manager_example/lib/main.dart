import 'package:fm_example/features.dart';
import 'package:feature_manager/feature_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  final featureManager = await FeatureManager.getInstance();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(
          value: sharedPreferences,
        ),
        Provider.value(
          value: featureManager,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feature Manager Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final isEnabled = context.read<FeatureManager>().booleanFeature.isEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Manager Demo Application'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                text: 'Feature toggle ',
                children: <InlineSpan>[
                  TextSpan(
                    text: isEnabled ? 'enabled' : 'disabled',
                    style: TextStyle(
                      color: isEnabled ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Open Feature Manager'),
              onPressed: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute<void>(
                    builder: (context) => DeveloperPreferencesScreen(
                      featuresList: AppFeatures.instance().values,
                      sharedPreferences: context.read(),
                    ),
                  ),
                )
                    .then((value) {
                  setState(() {});
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
