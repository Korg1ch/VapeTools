import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'screens/calculator_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'models/calculation_model.dart';
import 'utils/calculator_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  
  final calculationHistory = CalculationHistory();
  // Инициализируем тему
  final prefs = await SharedPreferences.getInstance();
  final themeModeIndex = prefs.getInt(AppConstants.prefsThemeModeKey) ?? 1;
  final themeMode = ThemeMode.values[themeModeIndex];
  
  // Загружаем сохраненный акцентный цвет
  final accentColorValue = prefs.getInt(AppConstants.prefsAccentColorKey);
  final useDeviceAccent = prefs.getBool(AppConstants.prefsUseDeviceAccentKey) ?? true;
  
  // Создаем провайдер темы с загруженными настройками
  final themeProvider = ThemeProvider(
    themeMode: themeMode,
    accentColor: accentColorValue != null ? Color(accentColorValue) : Colors.deepPurple,
    useDeviceAccent: useDeviceAccent,
  );
  
  // Инициализируем данные асинхронно
  await calculationHistory.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: calculationHistory),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const VapeApp(),
    ), // Добавляем запятую
  );
}

class VapeApp extends StatelessWidget {
  const VapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            final lightTheme = themeProvider.getLightTheme(lightDynamic);
            final darkTheme = themeProvider.getDarkTheme(darkDynamic);
            
            return MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,
              home: const HomeScreen(),
              // Оптимизируем переходы между страницами
              themeAnimationDuration: const Duration(milliseconds: 150),
              themeAnimationCurve: Curves.easeInOut,
            );
          },
        );
      },
    );
  }
}

// Расширенный провайдер темы с поддержкой динамического цвета
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode;
  Color _accentColor;
  bool _useDeviceAccent;
  
  // Список доступных акцентных цветов
  static final List<Color> accentOptions = [
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.pink,
  ];
  
  ThemeProvider({
    required ThemeMode themeMode,
    required Color accentColor,
    required bool useDeviceAccent,
  }) : 
    _themeMode = themeMode,
    _accentColor = accentColor,
    _useDeviceAccent = useDeviceAccent;
  
  // Геттеры
  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get useDeviceAccent => _useDeviceAccent;
  
  // Светлая тема с учётом динамического цвета
  ThemeData getLightTheme(ColorScheme? dynamicColor) {
    // Если включен режим использования системного акцента и доступна динамическая цветовая схема
    if (_useDeviceAccent && dynamicColor != null) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: dynamicColor,
      );
    }
    
    // В противном случае используем выбранный акцентный цвет
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: _accentColor,
    );
  }
  
  // Темная тема с учётом динамического цвета
  ThemeData getDarkTheme(ColorScheme? dynamicColor) {
    // Если включен режим использования системного акцента и доступна динамическая цветовая схема
    if (_useDeviceAccent && dynamicColor != null) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: dynamicColor,
      );
    }
    
    // В противном случае используем выбранный акцентный цвет
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: _accentColor,
    );
  }
  
  // Изменение режима темы
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    // Сохраняем настройку
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefsThemeModeKey, mode.index);
  }
  
  // Изменение акцентного цвета
  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();
    
    // Сохраняем настройку
    final prefs = await SharedPreferences.getInstance();
    // ignore: deprecated_member_use
    await prefs.setInt(AppConstants.prefsAccentColorKey, color.value);
  }
  
  // Изменение режима использования системного акцента
  Future<void> setUseDeviceAccent(bool value) async {
    _useDeviceAccent = value;
    notifyListeners();
    
    // Сохраняем настройку
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsUseDeviceAccentKey, value);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // Добавляем список labels
  static const List<String> _labels = [
    'Калькулятор', 'Сохранные', 'Настройки',
  ];

  List<Widget> get _screens => const [
    CalculatorScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_labels[_selectedIndex]),
        centerTitle: true,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Калькулятор',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Сохранные',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
