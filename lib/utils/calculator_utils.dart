import 'dart:math';
import '../models/calculation_model.dart';

/// Utility class for performing vape e-liquid calculations
class VapeCalculator {
  /// Calculate mixture components based on input parameters
  static Calculation calculateMixture({
    required double totalVolume,
    required double desiredNicotineStrength,
    required double baseNicotineStrength,
    required bool isPgNicotineBase,
    required double flavorPercentage,
    required bool isPgFlavor,
    required String pgVgRatio,
  }) {
    // Валидация входных данных
    if (totalVolume <= 0) {
      throw ArgumentError('Общий объем должен быть положительным');
    }
    if (desiredNicotineStrength < 0) {
      throw ArgumentError('Крепость никотина не может быть отрицательной');
    }
    if (baseNicotineStrength <= 0) {
      throw ArgumentError('Крепость базы должна быть положительной');
    }
    if (flavorPercentage < 0 || flavorPercentage > 1) {
      throw ArgumentError('Процент ароматизатора должен быть между 0 и 100%');
    }

    // Парсим соотношение PG/VG
    final pgPercent = double.parse(pgVgRatio.split('/')[0]);
    final desiredPgPercent = pgPercent / 100;
    
    // Расчет никотиновой базы
    final nicotineBaseVolume = totalVolume * desiredNicotineStrength / baseNicotineStrength;
    
    // Расчет объема ароматизатора
    final flavorVolume = totalVolume * flavorPercentage;
    
    // Расчет компонентов PG/VG на основе никотиновой базы и аромата
    double pgFromNicotine = isPgNicotineBase ? nicotineBaseVolume : 0;
    double vgFromNicotine = isPgNicotineBase ? 0 : nicotineBaseVolume;
    
    double pgFromFlavor = isPgFlavor ? flavorVolume : 0;
    double vgFromFlavor = isPgFlavor ? 0 : flavorVolume;
    
    // Расчет целевых объемов PG/VG
    double targetPgVolume = totalVolume * desiredPgPercent;
    double targetVgVolume = totalVolume - targetPgVolume;
    
    // Расчет сколько базового PG/VG нужно добавить
    double pgVolume = max(0, targetPgVolume - pgFromNicotine - pgFromFlavor);
    double vgVolume = max(0, targetVgVolume - vgFromNicotine - vgFromFlavor);
    
    // Создаем и возвращаем объект расчета
    return Calculation(
      dateTime: DateTime.now(),
      totalVolume: totalVolume,
      desiredNicotineStrength: desiredNicotineStrength,
      baseNicotineStrength: baseNicotineStrength,
      isPgNicotineBase: isPgNicotineBase,
      flavorPercentage: flavorPercentage,
      isPgFlavor: isPgFlavor,
      pgVgRatio: pgVgRatio,
      nicotineBaseVolume: nicotineBaseVolume,
      pgVolume: pgVolume,
      vgVolume: vgVolume,
      flavorVolume: flavorVolume,
    );
  }
  
  /// Форматирование даты/времени для отображения
  static String formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day.$month.$year $hour:$minute';
  }
  
  /// Генерация текстового представления расчета
  static String generateCalculationText(Calculation calculation) {
    final buffer = StringBuffer();
    buffer.writeln('Расчет вейп-жидкости от ${calculation.formattedDateTime}:');
    buffer.writeln('Объем: ${calculation.totalVolume} мл');
    buffer.writeln('Крепость: ${calculation.desiredNicotineStrength} мг/мл');
    buffer.writeln('Крепость базы: ${calculation.baseNicotineStrength} мг/мл');
    buffer.writeln('База на PG: ${calculation.isPgNicotineBase ? "Да" : "Нет"}');
    buffer.writeln('Аромат: ${(calculation.flavorPercentage * 100).toStringAsFixed(1)}%');
    buffer.writeln('Аромат на PG: ${calculation.isPgFlavor ? "Да" : "Нет"}');
    buffer.writeln('PG/VG: ${calculation.pgVgRatio}');
    buffer.writeln('');
    buffer.writeln('Результаты:');
    buffer.writeln('- Никотин: ${calculation.nicotineBaseVolume.toStringAsFixed(1)} мл');
    buffer.writeln('- PG: ${calculation.pgVolume.toStringAsFixed(1)} мл');
    buffer.writeln('- VG: ${calculation.vgVolume.toStringAsFixed(1)} мл');
    buffer.writeln('- Аромат: ${calculation.flavorVolume.toStringAsFixed(1)} мл');
    
    return buffer.toString();
  }
}

/// Константы приложения
class AppConstants {
  // Информация о приложении
  static const String appName = 'Vape Калькулятор';
  static const String appVersion = '1.0.0';
  
  // Ключи для хранения данных
  static const String prefsCalculationsKey = 'vape_calculations';
  static const String prefsThemeModeKey = 'theme_mode';
  static const String prefsAccentColorKey = 'accent_color';
  static const String prefsUseDeviceAccentKey = 'use_device_accent';
  
  // Текст "О приложении"
  static const String aboutAppText = 'Приложение для расчёта пропорций компонентов электронной жидкости. '
      'Позволяет рассчитывать составы для DIY смешивания с учётом процентного соотношения '
      'ароматизаторов, крепости никотина и соотношения PG/VG.';
}
