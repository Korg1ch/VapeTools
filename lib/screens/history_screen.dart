import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/calculation_model.dart';
import '../widgets/common_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Set<int> _selectedItems = <int>{};
  bool _isSelectionMode = false;
  bool _showOnlyFavorites = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<CalculationHistory>(
          builder: (context, history, _) {
            final items = _showOnlyFavorites ? history.favorites : history.calculations;
            return items.isEmpty
                ? _buildEmptyState(_showOnlyFavorites)
                : Column(
                    children: [
                      _buildFilterRow(),
                      Expanded(
                        child: _buildCalculationList(items, history),
                      ),
                    ],
                  );
          },
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildEmptyState(bool showingFavorites) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            showingFavorites ? Icons.star : Icons.history,
            size: 64, 
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            showingFavorites ? 'Нет избранных расчетов' : 'Нет сохраненных расчетов',
            style: const TextStyle(fontSize: 18),
          ),
          if (showingFavorites) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => setState(() => _showOnlyFavorites = false),
              icon: const Icon(Icons.list),
              label: const Text('Показать все расчеты'),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            label: Text('Все'),
            icon: Icon(Icons.list),
          ),
          ButtonSegment(
            value: true,
            label: Text('Избранные'),
            icon: Icon(Icons.star, size: 18),
          ),
        ],
        selected: {_showOnlyFavorites},
        onSelectionChanged: (values) => 
          setState(() => _showOnlyFavorites = values.first),
        style: SegmentedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
  
  Widget _buildCalculationList(List<Calculation> calculations, CalculationHistory history) {
    // Предварительно вычисляем индексы для большей производительности
    final calculationIndicesMap = <Calculation, int>{};
    for (int i = 0; i < history.calculations.length; i++) {
      calculationIndicesMap[history.calculations[i]] = i;
    }
    
    return Stack(
      children: [
        // Используем GridView.builder вместо ListView для правильного отображения карточек с фиксированной шириной
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          padding: const EdgeInsets.all(16),
          itemCount: calculations.length,
          itemBuilder: (context, index) {
            final reversedIndex = calculations.length - 1 - index;
            if (reversedIndex < 0 || reversedIndex >= calculations.length) {
              return const SizedBox.shrink();
            }
            
            final calculation = calculations[reversedIndex];
            
            // Используем предварительно вычисленные индексы для оптимизации
            final originalIndex = _showOnlyFavorites && calculationIndicesMap.containsKey(calculation)
                ? calculationIndicesMap[calculation]!
                : reversedIndex;
                
            return RepaintBoundary(
              child: CalculationCard(
                calculation: calculation,
                index: originalIndex,
                isSelected: _selectedItems.contains(originalIndex),
                selectionMode: _isSelectionMode,
                onToggleSelection: _toggleItemSelection,
                onTap: _showCalculationDetails,
                onToggleFavorite: history.toggleFavorite,
                onDelete: (index) => _confirmDelete(index, history),
                onCopy: _copyCalculationToClipboard,
              ),
            );
          },
        ),
        
        // Панель выделения
        if (_isSelectionMode) 
          Positioned(
            bottom: 0,
            left: 0,
            right: 0, 
            child: SelectionActionBar(
              selectedCount: _selectedItems.length,
              onSelectAll: () => _selectAll(history),
              onCopy: () => _copySelectedToClipboard(history),
              onAddToFavorites: () => _toggleFavoriteForSelected(history, true),
              onDelete: () => _deleteSelected(history),
              onCancel: _cancelSelection,
            ),
          ),
      ],
    );
  }

  Widget _buildFab() {
    return Consumer<CalculationHistory>(
      builder: (context, history, _) {
        if (history.calculations.isEmpty || _isSelectionMode) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton(
          onPressed: () => setState(() => _isSelectionMode = true),
          tooltip: 'Выбрать элементы',
          child: const Icon(Icons.checklist),
        );
      },
    );
  }
  
  void _toggleItemSelection(int index) {
    setState(() {
      if (_selectedItems.contains(index)) {
        _selectedItems.remove(index);
      } else {
        _selectedItems.add(index);
      }
    });
  }

  void _selectAll(CalculationHistory history) {
    setState(() {
      _selectedItems.clear();
      for (int i = 0; i < history.calculations.length; i++) {
        _selectedItems.add(i);
      }
    });
  }
  
  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }
  
  void _showCalculationDetails(Calculation calculation, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Expanded(
                  child: Text(
                    calculation.name.isNotEmpty
                      ? calculation.name
                      : 'Расчет от ${calculation.formattedDateTime}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Consumer<CalculationHistory>(
                  builder: (context, history, _) => IconButton(
                    icon: Icon(
                      calculation.isFavorite ? Icons.star : Icons.star_border,
                      color: calculation.isFavorite ? Colors.amber : null,
                    ),
                    onPressed: () => history.toggleFavorite(index),
                  ),
                ),
              ],
            ),
            
            const Divider(),
            const SizedBox(height: 8),
            
            // Параметры и результаты
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Параметры', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildDetailRow('Объем:', '${calculation.totalVolume} мл'),
                      _buildDetailRow('Крепость:', '${calculation.desiredNicotineStrength} мг/мл'),
                      _buildDetailRow('Крепость базы:', '${calculation.baseNicotineStrength} мг/мл'),
                      _buildDetailRow('База на PG:', calculation.isPgNicotineBase ? 'Да' : 'Нет'),
                      _buildDetailRow('Аромат (%):', '${(calculation.flavorPercentage * 100).toStringAsFixed(1)}%'),
                      _buildDetailRow('Аромат на PG:', calculation.isPgFlavor ? 'Да' : 'Нет'),
                      _buildDetailRow('PG/VG:', calculation.pgVgRatio),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Результаты', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildDetailRow('Никотиновая база:', '${calculation.nicotineBaseVolume.toStringAsFixed(2)} мл'),
                      _buildDetailRow('PG:', '${calculation.pgVolume.toStringAsFixed(2)} мл'),
                      _buildDetailRow('VG:', '${calculation.vgVolume.toStringAsFixed(2)} мл'),
                      _buildDetailRow('Ароматизатор:', '${calculation.flavorVolume.toStringAsFixed(2)} мл'),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editCalculationName(calculation, index),
                  icon: const Icon(Icons.edit),
                  label: const Text('Переименовать'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    _copyCalculationToClipboard(calculation);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Скопировать'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  
  void _editCalculationName(Calculation calculation, int index) {
    final nameController = TextEditingController(text: calculation.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Название расчета'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Введите название'),
          autofocus: true,
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Provider.of<CalculationHistory>(context, listen: false)
                  .setCalculationName(index, nameController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _confirmDelete(int index, CalculationHistory history) async {
    if (!mounted) return;
    
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Удалить этот расчет?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!mounted) return;
    
    if (confirm) {
      history.removeCalculation(index);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Расчет удален'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Future<void> _deleteSelected(CalculationHistory history) async {
    if (!mounted) return;
    
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Удалить ${_selectedItems.length} расчетов?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!mounted) return;
    
    if (confirm) {
      final sortedIndices = _selectedItems.toList()..sort((a, b) => b.compareTo(a));
      
      for (final index in sortedIndices) {
        history.removeCalculation(index);
      }
      
      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выбранные расчеты удалены'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _toggleFavoriteForSelected(CalculationHistory history, bool isFavorite) {
    for (final index in _selectedItems) {
      history.updateCalculation(index, isFavorite: isFavorite);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite 
            ? 'Добавлено в избранное: ${_selectedItems.length}'
            : 'Удалено из избранного: ${_selectedItems.length}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  Future<void> _copySelectedToClipboard(CalculationHistory history) async {
    final buffer = StringBuffer();
    buffer.writeln('Расчеты вейп-жидкости:');
    buffer.writeln('');
    
    final sortedIndices = _selectedItems.toList()..sort();
    
    for (final index in sortedIndices) {
      final calculation = history.calculations[index];
      buffer.writeln('--- ${calculation.name.isNotEmpty ? calculation.name : 'Расчет'} ---');
      buffer.writeln('Дата: ${calculation.formattedDateTime}');
      buffer.writeln('Объем: ${calculation.totalVolume} мл');
      buffer.writeln('Крепость: ${calculation.desiredNicotineStrength} мг/мл');
      buffer.writeln('PG/VG: ${calculation.pgVgRatio}');
      buffer.writeln('Результаты:');
      buffer.writeln('- Никотин: ${calculation.nicotineBaseVolume.toStringAsFixed(1)} мл');
      buffer.writeln('- PG: ${calculation.pgVolume.toStringAsFixed(1)} мл');
      buffer.writeln('- VG: ${calculation.vgVolume.toStringAsFixed(1)} мл');
      buffer.writeln('- Аромат: ${calculation.flavorVolume.toStringAsFixed(1)} мл');
      buffer.writeln('');
    }
    
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Скопировано в буфер обмена'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  Future<void> _copyCalculationToClipboard(Calculation calculation) async {
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
    
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
  }
}
