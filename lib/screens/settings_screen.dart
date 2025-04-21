import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/common_widgets.dart';
import '../main.dart'; // Импортируем для доступа к ThemeProvider

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThemeSection(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return SettingsCard(
      title: 'Персонализация',
      children: [
        const Text(
          'Режим темы',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.sunny),
                label: Text('Светлая'),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('Система'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('Темная'),
              ),
            ],
            selected: {themeProvider.themeMode},
            onSelectionChanged: (Set<ThemeMode> selection) {
              if (selection.isNotEmpty) {
                themeProvider.setThemeMode(selection.first);
              }
            },
            style: ButtonStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Акцентный цвет',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        
        // Переключатель системного акцента
        SwitchListTile(
          title: const Text('Использовать системный акцент'),
          subtitle: Text(
            'Получать цвет из настроек устройства (Material You)',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          value: themeProvider.useDeviceAccent,
          onChanged: (value) {
            themeProvider.setUseDeviceAccent(value);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        
        const SizedBox(height: 16),
        
        // Опции выбора цвета (отображаются только если не используется системный акцент)
        if (!themeProvider.useDeviceAccent) ...[
          Text(
            'Выберите цвет:',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          
          // Сетка выбора цветов
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final color in ThemeProvider.accentOptions)
                _buildColorOption(context, color),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildColorOption(BuildContext context, Color color) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isSelected = themeProvider.accentColor == color;
    
    return IconButton(
      icon: Icon(
        isSelected ? Icons.circle : Icons.circle_outlined,
        color: color,
      ),
      onPressed: () => themeProvider.setAccentColor(color),
    );
  }
}
