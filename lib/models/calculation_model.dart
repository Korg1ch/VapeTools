import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Calculation {
  final DateTime dateTime;
  final double totalVolume;
  final double desiredNicotineStrength;
  final double baseNicotineStrength;
  final bool isPgNicotineBase;
  final double flavorPercentage;
  final bool isPgFlavor;
  final String pgVgRatio;
  final double nicotineBaseVolume;
  final double pgVolume;
  final double vgVolume;
  final double flavorVolume;
  String name;
  bool isFavorite;
  
  Calculation({
    required this.dateTime,
    required this.totalVolume,
    required this.desiredNicotineStrength,
    required this.baseNicotineStrength,
    required this.isPgNicotineBase,
    required this.flavorPercentage,
    required this.isPgFlavor,
    required this.pgVgRatio,
    required this.nicotineBaseVolume,
    required this.pgVolume,
    required this.vgVolume,
    required this.flavorVolume,
    this.name = '',
    this.isFavorite = false,
  });
  
  // Вспомогательные методы для сериализации
  Map<String, dynamic> toJson() => {
    'dateTime': dateTime.toIso8601String(),
    'totalVolume': totalVolume,
    'desiredNicotineStrength': desiredNicotineStrength,
    'baseNicotineStrength': baseNicotineStrength,
    'isPgNicotineBase': isPgNicotineBase,
    'flavorPercentage': flavorPercentage,
    'isPgFlavor': isPgFlavor,
    'pgVgRatio': pgVgRatio,
    'nicotineBaseVolume': nicotineBaseVolume,
    'pgVolume': pgVolume,
    'vgVolume': vgVolume,
    'flavorVolume': flavorVolume,
    'name': name,
    'isFavorite': isFavorite,
  };

  factory Calculation.fromJson(Map<String, dynamic> json) => Calculation(
    dateTime: DateTime.parse(json['dateTime']),
    totalVolume: json['totalVolume'],
    desiredNicotineStrength: json['desiredNicotineStrength'],
    baseNicotineStrength: json['baseNicotineStrength'],
    isPgNicotineBase: json['isPgNicotineBase'],
    flavorPercentage: json['flavorPercentage'],
    isPgFlavor: json['isPgFlavor'],
    pgVgRatio: json['pgVgRatio'],
    nicotineBaseVolume: json['nicotineBaseVolume'],
    pgVolume: json['pgVolume'],
    vgVolume: json['vgVolume'],
    flavorVolume: json['flavorVolume'],
    name: json['name'] ?? '',
    isFavorite: json['isFavorite'] ?? false,
  );

  // Добавляем геттер для форматированной даты
  String get formattedDateTime {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  Calculation copyWith({
    DateTime? dateTime,
    double? totalVolume,
    double? desiredNicotineStrength,
    double? baseNicotineStrength,
    bool? isPgNicotineBase,
    double? flavorPercentage,
    bool? isPgFlavor,
    String? pgVgRatio,
    double? nicotineBaseVolume,
    double? pgVolume,
    double? vgVolume,
    double? flavorVolume,
    String? name,
    bool? isFavorite,
  }) {
    return Calculation(
      dateTime: dateTime ?? this.dateTime,
      totalVolume: totalVolume ?? this.totalVolume,
      desiredNicotineStrength: desiredNicotineStrength ?? this.desiredNicotineStrength,
      baseNicotineStrength: baseNicotineStrength ?? this.baseNicotineStrength,
      isPgNicotineBase: isPgNicotineBase ?? this.isPgNicotineBase,
      flavorPercentage: flavorPercentage ?? this.flavorPercentage,
      isPgFlavor: isPgFlavor ?? this.isPgFlavor,
      pgVgRatio: pgVgRatio ?? this.pgVgRatio,
      nicotineBaseVolume: nicotineBaseVolume ?? this.nicotineBaseVolume,
      pgVolume: pgVolume ?? this.pgVolume,
      vgVolume: vgVolume ?? this.vgVolume,
      flavorVolume: flavorVolume ?? this.flavorVolume,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class CalculationHistory with ChangeNotifier {
  List<Calculation> _calculations = [];
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  List<Calculation>? _cachedFavorites;
  
  // Storage key
  static const String _storageKey = 'vape_calculations';
  
  List<Calculation> get calculations => List.unmodifiable(_calculations);
  List<Calculation> get favorites {
    _cachedFavorites ??= _calculations.where((calc) => calc.isFavorite).toList();
    return _cachedFavorites!;
  }
  
  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadCalculations();
    _isInitialized = true;
  }
  
  Future<void> _loadCalculations() async {
    try {
      final jsonList = _prefs.getStringList(_storageKey) ?? [];
      _calculations = jsonList
          .map((json) => Calculation.fromJson(jsonDecode(json)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load calculations: $e');
      _calculations = [];
    }
  }
  
  Future<void> _saveCalculations() async {
    try {
      _cachedFavorites = null;
      final jsonList = _calculations
          .map((calc) => jsonEncode(calc.toJson()))
          .toList();
      await _prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      debugPrint('Failed to save calculations: $e');
    }
  }
  
  void addCalculation(Calculation calculation) {
    _calculations.add(calculation);
    _saveCalculations();
    notifyListeners();
  }
  
  void removeCalculation(int index) {
    if (index >= 0 && index < _calculations.length) {
      _calculations.removeAt(index);
      _saveCalculations();
      notifyListeners();
    }
  }
  
  void toggleFavorite(int index) {
    if (index >= 0 && index < _calculations.length) {
      final calculation = _calculations[index];
      _calculations[index] = Calculation(
        dateTime: calculation.dateTime,
        totalVolume: calculation.totalVolume,
        desiredNicotineStrength: calculation.desiredNicotineStrength,
        baseNicotineStrength: calculation.baseNicotineStrength,
        isPgNicotineBase: calculation.isPgNicotineBase,
        flavorPercentage: calculation.flavorPercentage,
        isPgFlavor: calculation.isPgFlavor,
        pgVgRatio: calculation.pgVgRatio,
        nicotineBaseVolume: calculation.nicotineBaseVolume,
        pgVolume: calculation.pgVolume,
        vgVolume: calculation.vgVolume,
        flavorVolume: calculation.flavorVolume,
        name: calculation.name,
        isFavorite: !calculation.isFavorite,
      );
      _saveCalculations();
      notifyListeners();
    }
  }

  // Добавляем метод для обновления имени
  void setCalculationName(int index, String name) {
    if (index >= 0 && index < _calculations.length) {
      final calc = _calculations[index];
      _calculations[index] = Calculation(
        dateTime: calc.dateTime,
        totalVolume: calc.totalVolume,
        desiredNicotineStrength: calc.desiredNicotineStrength,
        baseNicotineStrength: calc.baseNicotineStrength,
        isPgNicotineBase: calc.isPgNicotineBase,
        flavorPercentage: calc.flavorPercentage,
        isPgFlavor: calc.isPgFlavor,
        pgVgRatio: calc.pgVgRatio,
        nicotineBaseVolume: calc.nicotineBaseVolume,
        pgVolume: calc.pgVolume,
        vgVolume: calc.vgVolume,
        flavorVolume: calc.flavorVolume,
        name: name,
        isFavorite: calc.isFavorite,
      );
      _saveCalculations();
      notifyListeners();
    }
  }

  // Добавляем метод для обновления избранного
  void updateCalculation(int index, {required bool isFavorite}) {
    if (index >= 0 && index < _calculations.length) {
      final calc = _calculations[index];
      _calculations[index] = Calculation(
        dateTime: calc.dateTime,
        totalVolume: calc.totalVolume,
        desiredNicotineStrength: calc.desiredNicotineStrength,
        baseNicotineStrength: calc.baseNicotineStrength,
        isPgNicotineBase: calc.isPgNicotineBase,
        flavorPercentage: calc.flavorPercentage,
        isPgFlavor: calc.isPgFlavor,
        pgVgRatio: calc.pgVgRatio,
        nicotineBaseVolume: calc.nicotineBaseVolume,
        pgVolume: calc.pgVolume,
        vgVolume: calc.vgVolume,
        flavorVolume: calc.flavorVolume,
        name: calc.name,
        isFavorite: isFavorite,
      );
      _saveCalculations();
      notifyListeners();
    }
  }
}
