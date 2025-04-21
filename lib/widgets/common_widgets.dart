import 'package:flutter/material.dart';
import '../models/calculation_model.dart';

/// Dialog for displaying and editing options
class OptionDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback onSave;
  
  const OptionDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: onSave,
          child: const Text('Применить'),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
    );
  }
}

/// A calculation card widget for displaying in grid/list views
class CalculationCard extends StatelessWidget {
  final Calculation calculation;
  final int index;
  final bool isSelected;
  final bool selectionMode;
  final Function(int) onToggleSelection;
  final Function(Calculation, int) onTap;
  final Function(int) onToggleFavorite;
  final Function(int) onDelete;
  final Function(Calculation) onCopy;
  
  const CalculationCard({
    super.key,
    required this.calculation,
    required this.index,
    required this.isSelected,
    required this.selectionMode,
    required this.onToggleSelection,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = calculation.name.isNotEmpty
        ? calculation.name
        : '${calculation.totalVolume.toStringAsFixed(0)}мл ${calculation.desiredNicotineStrength}мг/мл';
    
    // Цвет карточки в зависимости от статуса
    final cardColor = selectionMode && isSelected
        ? colorScheme.primaryContainer
        : calculation.isFavorite 
            ? colorScheme.secondaryContainer.withAlpha((0.2 * 255).round())
            : null;
            
    // Используем AnimatedContainer для более плавных переходов
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuad,
      child: Card(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selectionMode && isSelected
                ? colorScheme.primary
                : calculation.isFavorite
                    ? Colors.amber.withAlpha((0.5 * 255).round())
                    : colorScheme.outlineVariant.withAlpha((0.5 * 255).round()),
            width: selectionMode && isSelected ? 2 : 1,
          ),
        ),
        // Используем TweenAnimationBuilder для плавного эффекта нажатия
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1.0, end: 1.0),
          duration: const Duration(milliseconds: 150),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: InkWell(
                onTap: selectionMode 
                    ? () => onToggleSelection(index)
                    : () => onTap(calculation, index),
                onLongPress: !selectionMode 
                    ? () => onToggleSelection(index)
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: child,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Индикатор избранного или выбора
              Row(
                children: [
                  if (calculation.isFavorite && !selectionMode)
                    const Icon(Icons.star, size: 18, color: Colors.amber),
                  const Spacer(),
                  if (selectionMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggleSelection(index),
                    ),
                ],
              ),
              
              // Название и дата
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      calculation.formattedDateTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.outline, 
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Параметры
              _buildParameterRow('Объем:', '${calculation.totalVolume.toStringAsFixed(0)} мл'),
              _buildParameterRow('Никотин:', '${calculation.desiredNicotineStrength.toStringAsFixed(1)} мг/мл'),
              _buildParameterRow('Аромат:', '${(calculation.flavorPercentage * 100).toStringAsFixed(0)}%'),
              _buildParameterRow('PG/VG:', calculation.pgVgRatio),
              
              const Spacer(),
              
              // Кнопки действий
              if (!selectionMode)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      context,
                      icon: calculation.isFavorite ? Icons.star : Icons.star_border,
                      color: calculation.isFavorite ? Colors.amber : null,
                      onPressed: () => onToggleFavorite(index),
                      tooltip: calculation.isFavorite ? 'Удалить из избранного' : 'Добавить в избранное',
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon: Icons.copy,
                      onPressed: () => onCopy(calculation),
                      tooltip: 'Копировать',
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon: Icons.delete_outline,
                      color: colorScheme.error,
                      onPressed: () => onDelete(index),
                      tooltip: 'Удалить',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildParameterRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label, 
            style: const TextStyle(fontSize: 13)
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return IconButton(
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
      ),
    );
  }
}

/// A widget for displaying a result tile in a grid
class ResultTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  
  const ResultTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha((0.3 * 255).round()), width: 1),
      ),
      color: color.withAlpha((0.1 * 255).round()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 12, color: color.withAlpha((0.8 * 255).round())),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
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
    );
  }
}

/// A widget for displaying options in a tile format
class OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  
  const OptionTile({
    super.key, 
    required this.title, 
    required this.subtitle, 
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
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
}

/// A widget for displaying a selection action bar
class SelectionActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onCopy;
  final VoidCallback onAddToFavorites;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  
  const SelectionActionBar({
    super.key,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onCopy,
    required this.onAddToFavorites,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Material(
        elevation: 3,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с количеством выбранных и кнопкой закрытия
                Row(
                  children: [
                    Text(
                      'Выбрано: $selectedCount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onCancel,
                      tooltip: 'Отменить выбор',
                    ),
                  ],
                ),
                
                // Разделитель
                const Divider(),
                
                // Анимация появления контента панели
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: 1.0,
                  curve: Curves.easeIn,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: selectedCount == 0 
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.spaceEvenly,
                      children: [
                        if (selectedCount == 0)
                          Text(
                            'Выберите элементы для действий',
                            style: TextStyle(color: colorScheme.outline),
                          )
                        else ...[
                          _buildSelectionActionButton(context, 'Выбрать всё', Icons.select_all, onSelectAll),
                          _buildSelectionActionButton(context, 'Копировать', Icons.copy, onCopy),
                          _buildSelectionActionButton(context, 'В избранное', Icons.star, onAddToFavorites),
                          _buildSelectionActionButton(context, 'Удалить', Icons.delete, onDelete, colorScheme.error),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Кнопка действия для режима выбора в стиле Material You 3
  Widget _buildSelectionActionButton(BuildContext context, String label, IconData icon, VoidCallback onPressed, [Color? color]) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonColor = color ?? colorScheme.primary;
    
    return Column(
      children: [
        FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            foregroundColor: buttonColor,
            backgroundColor: buttonColor.withAlpha((0.1 * 255).round()),
            minimumSize: const Size(56, 56),
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, color: buttonColor),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Виджет пустого состояния для экранов
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add),
                label: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Виджет для отображения настраиваемого параметра с подзаголовком
class ParameterRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  
  const ParameterRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения визуального распределения компонентов жидкости
class LiquidProportionsBar extends StatelessWidget {
  final double nicotinePercentage;
  final double flavorPercentage;
  final double pgPercentage;
  final double vgPercentage;
  
  const LiquidProportionsBar({
    super.key,
    required this.nicotinePercentage,
    required this.flavorPercentage,
    required this.pgPercentage,
    required this.vgPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Распределение компонентов',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Исправлено: используем более простую анимацию без явного value-параметра
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildProportionSegment(nicotinePercentage, colorScheme.tertiary),
                _buildProportionSegment(flavorPercentage, colorScheme.primary),
                _buildProportionSegment(pgPercentage, colorScheme.secondary),
                _buildProportionSegment(vgPercentage, colorScheme.tertiary.withAlpha((0.7 * 255).round())),
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
    );
  }
  
  // Сегмент пропорциональной полосы
  Widget _buildProportionSegment(double proportion, Color color) {
    // Защита от нулевой пропорции
    final flex = max(1, (proportion * 100).round());
    
    return Expanded(
      flex: flex,
      child: Container(color: color),
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
  
  // Вспомогательный метод для обеспечения положительного flex
  int max(int a, int b) => a > b ? a : b;
}

/// Виджет для отображения карточки настроек
class SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  
  const SettingsCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha((0.5 * 255).round()),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}