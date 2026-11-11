import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/shift_provider.dart';
import 'providers/config_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/constants.dart';

class NomiCheckApp extends StatelessWidget {
  const NomiCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkLoginStatus()),
        ChangeNotifierProvider(create: (_) => ConfigProvider()..loadConfig()),
        ChangeNotifierProvider(create: (_) => ShiftProvider()..loadShifts()),
        ChangeNotifierProvider(create: (_) => SyncProvider()..loadLastSync()),
      ],
      child: MaterialApp(
        title: 'NomiCheck',
        debugShowCheckedModeBanner: false,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: AppColors.surface,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _syncedForUser = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().addListener(_onAuthChanged);
    context.read<ShiftProvider>().onLocalChange = _pushToServer;
    _onAuthChanged();
  }

  @override
  void dispose() {
    context.read<AuthProvider>().removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _pushToServer() async {
    if (!mounted) return;
    final syncProvider = context.read<SyncProvider>();
    await syncProvider.sync();
  }

  void _onAuthChanged() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      _syncedForUser = false;
      return;
    }
    if (_syncedForUser) return;
    _syncedForUser = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final syncProvider = context.read<SyncProvider>();
      final shiftProvider = context.read<ShiftProvider>();
      final configProvider = context.read<ConfigProvider>();

      await syncProvider.sync();
      await shiftProvider.loadShifts();
      await configProvider.loadConfig();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoggedIn) {
          return const MainNavigation();
        }
        return const LoginScreen();
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    RegisterScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Consumer<ShiftProvider>(
              builder: (context, shiftProvider, child) {
                if (shiftProvider.hasOpenShift) {
                  return Badge(
                    label: const Text(''),
                    child: const Icon(Icons.play_circle_outline),
                  );
                }
                return const Icon(Icons.play_circle_outline);
              },
            ),
            selectedIcon: const Icon(Icons.play_circle),
            label: 'Registrar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                setState(() => _currentIndex = 1);
              },
              backgroundColor: AppColors.secondary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
