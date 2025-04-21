import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/calculation_model.dart';
import '../utils/calculator_utils.dart';
import '../widgets/common_widgets.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalVolumeController = TextEditingController(text: '100');
  
  // Параметры расчёта
  double _desiredNicStrength = 3.0;
  double _baseNicStrength = 20.0;
  bool _isPgNicotineBase = true;
  double _flavorPercentage = 0.1;
  bool _isPgFlavor = true;
  double _pgPercentage = 50.0;
  
  double _absoluteFlavorVolume = 10.0;
  Calculation? _calculationResult;

  // Добавьте состояния для отслеживания развернутых секций
  bool _isVolumeExpanded = false;
  bool _isNicotineExpanded = false;
  bool _isFlavorExpanded = false;
  bool _isRatioExpanded = false;

  // Добавляем контроллеры для полей никотина
  final _desiredNicStrengthController = TextEditingController();
  final _baseNicStrengthController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Инициализируем контроллеры начальными значениями
    _desiredNicStrengthController.text = _desiredNicStrength.toString();
    _baseNicStrengthController.text = _baseNicStrength.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateMixture());
  }
  
  @override
  void dispose() {
    _totalVolumeController.dispose();
    _desiredNicStrengthController.dispose();
    _baseNicStrengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Настраиваем разметку в зависимости от ориентации и размера экрана
    Widget mainContent = isLandscape && screenWidth > 600
        ? _buildLandscapeLayout(colorScheme)
        : _buildPortraitLayout(colorScheme);
    
    return Scaffold(
      body: SafeArea(
        child: mainContent,
      ),
      floatingActionButton: _calculationResult != null
          ? FloatingActionButton.extended(
              onPressed: _saveResult,
              icon: const Icon(Icons.save),
              label: const Text('Сохранить'),
            )
          : null,
    );
  }

  // Вертикальная раскладка для телефонов
  Widget _buildPortraitLayout(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Верхняя панель с параметрами
            _buildCompactParametersCard(colorScheme),
            
            const SizedBox(height: 16),
            
            // Результаты
            if (_calculationResult != null)
              _buildResultsCard(colorScheme),
            
            const SizedBox(height: 80), // Для FAB
          ],
        ),
      ),
    );
  }

  // Горизонтальная раскладка для планшетов/альбомной ориентации
  Widget _buildLandscapeLayout(ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Левая панель с параметрами
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: _buildCompactParametersCard(colorScheme),
            ),
          ),
        ),
        
        // Правая панель с результатами
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _calculationResult != null
                ? _buildResultsCard(colorScheme)
                : const Center(child: Text('Заполните параметры для расчёта')),
          ),
        ),
      ],
    );
  }

  // Компактная карточка с параметрами (убрана кнопка "Рассчитать")
  Widget _buildCompactParametersCard(ColorScheme colorScheme) {
    return Column(
      children: [
        // Секция объема
        _ExpandableSection(
          title: 'Объем жидкости',
          icon: Icons.science,
          isExpanded: _isVolumeExpanded,
          onToggle: () => setState(() => _isVolumeExpanded = !_isVolumeExpanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _totalVolumeController,
                decoration: const InputDecoration(
                  labelText: 'Объём (мл)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final volume in [10, 30, 50, 100, 120])
                    FilterChip(
                      label: Text('$volume мл'),
                      selected: _totalVolumeController.text == volume.toString(),
                      onSelected: (_) {
                        setState(() {
                          _totalVolumeController.text = volume.toString();
                          _updateVolume(volume.toDouble());
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        ),

        // Секция никотина
        _ExpandableSection(
          title: 'Никотин',
          icon: Icons.science_outlined,
          isExpanded: _isNicotineExpanded,
          onToggle: () => setState(() => _isNicotineExpanded = !_isNicotineExpanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Крепость жидкости (мг/мл)'),
              TextField(
                controller: _desiredNicStrengthController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixText: 'мг/мл',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final strength = double.tryParse(value);
                  if (strength != null) {
                    setState(() {
                      _desiredNicStrength = strength;
                      _calculateMixture();
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final strength in [3, 6, 12, 18, 20, 40, 50, 60])
                    FilterChip(
                      label: Text('$strength мг'),
                      selected: _desiredNicStrength == strength,
                      onSelected: (_) {
                        setState(() {
                          _desiredNicStrength = strength.toDouble();
                          _desiredNicStrengthController.text = strength.toString();
                          _calculateMixture();
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Крепость базы (мг/мл)'),
              TextField(
                controller: _baseNicStrengthController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixText: 'мг/мл',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final strength = double.tryParse(value);
                  if (strength != null) {
                    setState(() {
                      _baseNicStrength = strength;
                      _calculateMixture();
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final strength in [50, 100, 200])
                    FilterChip(
                      label: Text('$strength мг'),
                      selected: _baseNicStrength == strength,
                      onSelected: (_) {
                        setState(() {
                          _baseNicStrength = strength.toDouble();
                          _baseNicStrengthController.text = strength.toString();
                          _calculateMixture();
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Добавляем переключатель основы никотина
              _buildBaseTypeSelector(
                title: 'Основа никотина',
                isPG: _isPgNicotineBase,
                onChanged: (value) => setState(() {
                  _isPgNicotineBase = value;
                  _calculateMixture();
                }),
              ),
            ],
          ),
        ),

        // Секция ароматизатора
        _ExpandableSection(
          title: 'Ароматизатор',
          icon: Icons.local_drink_outlined,
          isExpanded: _isFlavorExpanded,
          onToggle: () => setState(() => _isFlavorExpanded = !_isFlavorExpanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Процент ароматизатора: ${(_flavorPercentage * 100).toStringAsFixed(1)}%'),
              Slider(
                value: _flavorPercentage,
                min: 0,
                max: 0.3,
                divisions: 30,
                label: '${(_flavorPercentage * 100).toStringAsFixed(1)}%',
                onChanged: (value) {
                  setState(() {
                    _flavorPercentage = value;
                    _absoluteFlavorVolume = _flavorPercentage * (double.tryParse(_totalVolumeController.text) ?? 100.0);
                  });
                },
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final percent in [5, 10, 15, 20])
                    FilterChip(
                      label: Text('$percent%'),
                      selected: (_flavorPercentage * 100).round() == percent,
                      onSelected: (_) => setState(() {
                        _flavorPercentage = percent / 100;
                        _absoluteFlavorVolume = _flavorPercentage * (double.tryParse(_totalVolumeController.text) ?? 100.0);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBaseTypeSelector(
                title: 'Основа аромы',
                isPG: _isPgFlavor,
                onChanged: (value) => setState(() => _isPgFlavor = value),
              ),
            ],
          ),
        ),

        // Секция PG/VG
        _ExpandableSection(
          title: 'Соотношение PG/VG',
          icon: Icons.balance_outlined,
          isExpanded: _isRatioExpanded,
          onToggle: () => setState(() => _isRatioExpanded = !_isRatioExpanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('PG/VG: ${_pgPercentage.toStringAsFixed(0)}/${(100 - _pgPercentage).toStringAsFixed(0)}'),
              Slider(
                value: _pgPercentage,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${_pgPercentage.toStringAsFixed(0)}/${(100 - _pgPercentage).toStringAsFixed(0)}',
                onChanged: (value) => setState(() => _pgPercentage = value),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ratio in ['30/70', '50/50', '70/30', '80/20'])
                    FilterChip(
                      label: Text(ratio),
                      selected: '${_pgPercentage.toStringAsFixed(0)}/${(100 - _pgPercentage).toStringAsFixed(0)}' == ratio,
                      onSelected: (_) {
                        final pg = int.parse(ratio.split('/')[0]);
                        setState(() => _pgPercentage = pg.toDouble());
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Компактный блок с параметрами, который открывает диалог при нажатии
  Widget _buildOptionsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withAlpha((0.2 * 255).round())),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  // Обновленная карточка с результатами - визуально улучшенная
  Widget _buildResultsCard(ColorScheme colorScheme) {
    if (_calculationResult == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withAlpha((0.4 * 255).round()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView( // Добавляем ScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Добавляем это свойство
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(  // Исправлено Row с запятой
                children: [
                  Icon(Icons.check_circle, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Результаты расчета',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Результаты в виде улучшенной сетки карточек
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width > 400 ? 2 : 2,
                childAspectRatio: 2.0,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildResultTile(
                    'Никотиновая база', 
                    '${_calculationResult!.nicotineBaseVolume.toStringAsFixed(1)} мл', 
                    Icons.science, 
                    colorScheme.tertiary,
                  ),
                  _buildResultTile(
                    'Ароматизатор', 
                    '${_calculationResult!.flavorVolume.toStringAsFixed(1)} мл', 
                    Icons.local_drink, 
                    colorScheme.primary,
                  ),
                  _buildResultTile(
                    'PG', 
                    '${_calculationResult!.pgVolume.toStringAsFixed(1)} мл', 
                    Icons.opacity, 
                    colorScheme.secondary,
                  ),
                  _buildResultTile(
                    'VG', 
                    '${_calculationResult!.vgVolume.toStringAsFixed(1)} мл', 
                    Icons.water_drop, 
                    colorScheme.tertiary,
                  ),
                ],
              ),
              
              // Визуальное распределение компонентов
              const SizedBox(height: 20),
              Text(
                'Распределение компонентов',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              
              // Линейная диаграмма соотношения
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildProportionBar(
                        _calculationResult!.nicotineBaseVolume / _calculationResult!.totalVolume,
                        colorScheme.tertiary,
                      ),
                      _buildProportionBar(
                        _calculationResult!.flavorVolume / _calculationResult!.totalVolume,
                        colorScheme.primary,
                      ),
                      _buildProportionBar(
                        _calculationResult!.pgVolume / _calculationResult!.totalVolume,
                        colorScheme.secondary,
                      ),
                      _buildProportionBar(
                        _calculationResult!.vgVolume / _calculationResult!.totalVolume,
                        colorScheme.tertiary.withAlpha((0.7 * 255).round()),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Легенда для диаграммы
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLegendItem('Ник. база', colorScheme.tertiary),
                  _buildLegendItem('Аромат', colorScheme.primary),
                  _buildLegendItem('PG', colorScheme.secondary),
                  _buildLegendItem('VG', colorScheme.tertiary.withAlpha((0.7 * 255).round())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Элемент полосы распределения пропорций
  Widget _buildProportionBar(double proportion, Color color) {
    return Expanded(
      flex: (proportion * 100).round(),
      child: Container(
        color: color,
      ),
    );
  }
  
  // Элемент легенды
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
  
  // Улучшенная плитка результата для грид-вью с исправлением размера
  Widget _buildResultTile(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha((0.3 * 255).round()), width: 1),
      ),
      color: color.withAlpha((0.1 * 255).round()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: IntrinsicHeight( // Используем IntrinsicHeight для адаптации высоты
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded( // Используем Expanded для гибкости
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 12, color: color.withAlpha((0.8 * 255).round())),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const Spacer(), // Spacer для распределения свободного места
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color.withAlpha((0.9 * 255).round()),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Выплывающий диалог с настройками никотина
  void _showNicotineSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Никотин', style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              const SizedBox(height: 16),
              
              // Желаемая крепость
              Text('Крепость жидкости (мг/мл)', style: Theme.of(context).textTheme.titleSmall),
              TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                controller: _desiredNicStrengthController,
                onChanged: (value) => setState(() => _desiredNicStrength = double.tryParse(value) ?? 3.0),
              ),
              const SizedBox(height: 8),
              
              // Пресеты крепости
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final strength in [3, 6, 12, 18, 20, 40, 50, 60])
                    FilterChip(
                      label: Text('$strength мг'),
                      selected: _desiredNicStrength == strength,
                      onSelected: (_) => setState(() {
                        _desiredNicStrength = strength.toDouble();
                        _desiredNicStrengthController.text = strength.toString();
                        _calculateMixture();
                      }),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              Text('Крепость базы (мг/мл)', style: Theme.of(context).textTheme.titleSmall),
              TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                controller: _baseNicStrengthController,
                onChanged: (value) => setState(() => _baseNicStrength = double.tryParse(value) ?? 100.0),
              ),
              const SizedBox(height: 8),
              
              // Пресеты базы
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final strength in [50, 100, 200])
                    FilterChip(
                      label: Text('$strength мг'),
                      selected: _baseNicStrength == strength,
                      onSelected: (_) => setState(() {
                        _baseNicStrength = strength.toDouble();
                        _baseNicStrengthController.text = strength.toString();
                        _calculateMixture();
                      }),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Тип основы через сегментированную кнопку
              _buildBaseTypeSelector(
                title: 'Основа никотина',
                isPG: _isPgNicotineBase,
                onChanged: (value) => setState(() => _isPgNicotineBase = value),
              ),
              
              _buildActionButtons(context, setState),
            ],
          ),
        ),
      ),
    );
  }

  // Выплывающий диалог с настройками ароматизатора
  void _showFlavorSettings() {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Настройки ароматизатора',
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                // Процент ароматизатора
                Text(
                  'Процент: ${(_flavorPercentage * 100).toStringAsFixed(1)}% (${(_flavorPercentage * (double.tryParse(_totalVolumeController.text) ?? 100.0)).toStringAsFixed(1)} мл)',
                  style: TextStyle(
                    color: _flavorPercentage > 0.2 ? colorScheme.error : null,
                  ),
                ),
                Slider(
                  value: _flavorPercentage,
                  min: 0,
                  max: 0.3,
                  divisions: 30,
                  label: '${(_flavorPercentage * 100).toStringAsFixed(1)}%',
                  activeColor: _flavorPercentage > 0.2 ? colorScheme.error : null,
                  onChanged: (value) {
                    setState(() {
                      _flavorPercentage = value;
                      _absoluteFlavorVolume = _flavorPercentage * (double.tryParse(_totalVolumeController.text) ?? 100.0);
                    });
                  },
                ),
                
                if (_flavorPercentage > 0.2)
                  Text(
                    'Более 20% может ухудшить вкус',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 12,
                    ),
                  ),

                // Пресеты для аромы
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('5%'),
                      selected: (_flavorPercentage * 100).round() == 5,
                      onSelected: (_) => setState(() {
                        _flavorPercentage = 0.05;
                        _absoluteFlavorVolume = _flavorPercentage * (double.tryParse(_totalVolumeController.text) ?? 100.0);
                      }),
                    ),
                    FilterChip(
                      label: const Text('10%'),
                      selected: (_flavorPercentage * 100).round() == 10,
                      onSelected: (_) => setState(() {
                        _flavorPercentage = 0.10;
                        _absoluteFlavorVolume = _flavorPercentage * (double.tryParse(_totalVolumeController.text) ?? 100.0);
                      }),
                    ),
                    FilterChip(
                      label: const Text('15%'),
                      selected: (_flavorPercentage * 100).round() == 15,
                      onSelected: (_) => setState(() {
                        _flavorPercentage = 0.15;
                        _absoluteFlavorVolume = _flavorPercentage * (double.tryParse(_totalVolumeController.text) ?? 100.0);
                      }),
                    ),
                    FilterChip(
                      label: const Text('20%'),
                      selected: (_flavorPercentage * 100).round() == 20,
                      onSelected: (_) => setState(() {
                        _flavorPercentage = 0.20;
                        _absoluteFlavorVolume = _flavorPercentage * (double.tryParse(_totalVolumeController.text) ?? 100.0);
                      }),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Тип основы аромы
                SwitchListTile(
                  title: const Text('Ароматизатор на PG'),
                  value: _isPgFlavor,
                  onChanged: (value) => setState(() => _isPgFlavor = value),
                  contentPadding: EdgeInsets.zero,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          setState(() => _calculateMixture());
                          Navigator.pop(context);
                        },
                        child: const Text('Применить'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Выплывающий диалог с настройками соотношения PG/VG
  void _showRatioSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Соотношение PG/VG',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                // Соотношение
                Center(
                  child: Text(
                    '${_pgPercentage.toStringAsFixed(0)}/${(100 - _pgPercentage).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _pgPercentage,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${_pgPercentage.toStringAsFixed(0)}/${(100 - _pgPercentage).toStringAsFixed(0)}',
                  onChanged: (value) => setState(() => _pgPercentage = value),
                ),

                // Пресеты соотношений
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('30/70'),
                      selected: _pgPercentage == 30,
                      onSelected: (_) => setState(() => _pgPercentage = 30),
                    ),
                    FilterChip(
                      label: const Text('50/50'),
                      selected: _pgPercentage == 50,
                      onSelected: (_) => setState(() => _pgPercentage == 50),
                    ),
                    FilterChip(
                      label: const Text('70/30'),
                      selected: _pgPercentage == 70,
                      onSelected: (_) => setState(() => _pgPercentage == 70),
                    ),
                    FilterChip(
                      label: const Text('80/20'),
                      selected: _pgPercentage == 80,
                      onSelected: (_) => setState(() => _pgPercentage == 80),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Пояснение
                Text(
                  'PG отвечает за вкус и "удар по горлу".\nVG даёт больше густого пара.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                  ),
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          setState(() => _calculateMixture());
                          Navigator.pop(context);
                        },
                        child: const Text('Применить'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Диалог выбора предустановленного объема
  void _showVolumePresets() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Объем жидкости',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // Поле ввода объема
            TextField(
              controller: _totalVolumeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Объём (мл)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _updateVolume(double.tryParse(value) ?? 100.0),
            ),
            const SizedBox(height: 16),
            
            // Стандартные объемы чипами
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final volume in [10, 30, 50, 100, 120])
                  FilterChip(
                    label: Text('$volume мл'),
                    selected: _totalVolumeController.text == volume.toString(),
                    onSelected: (_) {
                      _totalVolumeController.text = volume.toString();
                      _updateVolume(volume.toDouble());
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateVolume(double volume) {
    setState(() {
      _flavorPercentage = _absoluteFlavorVolume / volume;
      if (_flavorPercentage > 0.3) _flavorPercentage = 0.3;
      _calculateMixture();
    });
  }

  // Вспомогательный метод для создания пунктов меню объема
  Widget _buildVolumeOption(String label, double volume) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(
        label,
        style: const TextStyle(fontSize: 16),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.pop(context);
        _totalVolumeController.text = volume.toString();
        setState(() {
          // Обновляем процент ароматизатора с учетом нового объема
          _flavorPercentage = _absoluteFlavorVolume / volume;
          if (_flavorPercentage > 0.3) _flavorPercentage = 0.3;
          _calculateMixture();
        });
      },
    );
  }

  // Для выбора PG/VG основы
  Widget _buildBaseTypeSelector({
    required String title,
    required bool isPG,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('PG'),
              ),
              ButtonSegment(
                value: false,
                label: Text('VG'),
              ),
            ],
            selected: {isPG},
            onSelectionChanged: (Set<bool> selection) {
              if (selection.isNotEmpty) {
                onChanged(selection.first);
              }
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  // Вызываем расчет миксуты при каждом изменении данных
  void _calculateMixture() {
    try {
      // Проверяем валидность данных перед расчетом
      final totalVolumeText = _totalVolumeController.text;
      if (totalVolumeText.isEmpty) return;
      
      final totalVolume = double.tryParse(totalVolumeText);
      if (totalVolume == null || totalVolume <= 0) return;
      
      final pgVgRatio = '${_pgPercentage.toStringAsFixed(0)}/${(100 - _pgPercentage).toStringAsFixed(0)}';

      final result = VapeCalculator.calculateMixture(
        totalVolume: totalVolume,
        desiredNicotineStrength: _desiredNicStrength,
        baseNicotineStrength: _baseNicStrength,
        isPgNicotineBase: _isPgNicotineBase,
        flavorPercentage: _flavorPercentage,
        isPgFlavor: _isPgFlavor,
        pgVgRatio: pgVgRatio,
      );

      // Сохраняем абсолютное значение объема ароматизатора
      _absoluteFlavorVolume = result.flavorVolume;

      setState(() {
        _calculationResult = result;
      });
    } catch (e) {
      // Обрабатываем ошибки более мягко в лайв-режиме
      debugPrint('Ошибка расчета: $e');
    }
  }

  void _saveResult() async {
    if (_calculationResult == null) return;

    if (!mounted) return;
    
    final nameController = TextEditingController();
    bool addToFavorites = false;

    final result = await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Сохранение расчета'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название расчета',
                    hintText: 'Например: Малиновый микс',
                    prefixIcon: Icon(Icons.edit),
                  ),
                  maxLength: 30,
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Добавить в избранное'),
                  value: addToFavorites,
                  onChanged: (value) {
                    setState(() {
                      addToFavorites = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'favorite': addToFavorites,
                  });
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );

    if (!mounted) return;

    if (result == null) return;

    final name = result['name'] as String;
    final isFavorite = result['favorite'] as bool;

    if (!mounted) return;

    final calculation = _calculationResult!.copyWith(
      name: name,
      isFavorite: isFavorite,
    );

    final historyProvider = Provider.of<CalculationHistory>(context, listen: false);
    historyProvider.addCalculation(calculation);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite 
            ? 'Расчет сохранен в избранное' 
            : 'Расчет сохранен в историю',),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, StateSetter setState) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              _calculateMixture();
              Navigator.pop(context);
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  RotatedBox(
                    quarterTurns: isExpanded ? 2 : 0,
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
