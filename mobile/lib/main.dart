import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';
import 'branding.dart';
import 'store.dart';
import 'supabase_backend.dart';
import 'ui.dart';
import 'screens.dart';
import 'motion.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    AppConfig.hasPartialSupabaseValues
        ? const ConfigurationErrorApp()
        : const MotorStockStartup(),
  );
}

Future<Supabase>? _supabaseInitialization;

Future<MotorStore> _initializeStore() async {
  SupabaseMotorRepository? remote;
  if (AppConfig.hasSupabaseValues) {
    // Keep the initialized client when a later data load needs a retry.
    try {
      final supabase = await (_supabaseInitialization ??= Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseKey,
      ));
      remote = SupabaseMotorRepository(supabase.client);
    } catch (_) {
      _supabaseInitialization = null;
      // Initialization can fail after creating its client. Clean that state
      // before allowing another attempt to restore authentication.
      try {
        await Supabase.instance.dispose();
      } catch (_) {}
      rethrow;
    }
  }
  final store = MotorStore(
    await SharedPreferences.getInstance(),
    remote: remote,
  );
  try {
    await store.initialize();
    return store;
  } catch (_) {
    store.dispose();
    rethrow;
  }
}

class MotorStockStartup extends StatefulWidget {
  final Future<MotorStore> Function()? initializeStore;
  const MotorStockStartup({super.key, this.initializeStore});

  @override
  State<MotorStockStartup> createState() => _MotorStockStartupState();
}

class _MotorStockStartupState extends State<MotorStockStartup> {
  late Future<MotorStore> _startup;

  @override
  void initState() {
    super.initState();
    _startup = _load();
  }

  Future<MotorStore> _load() async =>
      (widget.initializeStore ?? _initializeStore)();

  @override
  Widget build(BuildContext context) => FutureBuilder<MotorStore>(
    future: _startup,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData) {
        return MotorStockApp(store: snapshot.requireData);
      }
      return MaterialApp(
        title: 'MotorStock',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: MotorStockSplash(
          error:
              snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasError
              ? 'We couldn’t open your showroom. Check your connection and try again.'
              : null,
          onRetry: () => setState(() {
            _startup = _load();
          }),
        ),
      );
    },
  );
}

class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: appTheme,
    home: const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Supabase configuration is incomplete. Provide both '
              'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ),
  );
}

class MotorStockApp extends StatelessWidget {
  final MotorStore store;
  const MotorStockApp({super.key, required this.store});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => MaterialApp(
      title: 'MotorStock',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      darkTheme: darkAppTheme,
      themeMode: switch (store.appearance) {
        'Dark' => ThemeMode.dark,
        'System' => ThemeMode.system,
        _ => ThemeMode.light,
      },
      scrollBehavior: const DealerScrollBehavior(),
      home: store.signedIn
          ? HomeScreen(store: store)
          : LoginScreen(store: store),
    ),
  );
}
