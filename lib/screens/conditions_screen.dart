import 'package:flutter/material.dart';
import '../services/conditions_manager.dart';

class ConditionsScreen extends StatefulWidget {
  final Function(RecordingConditions) onConditionsSelected;
  
  const ConditionsScreen({Key? key, required this.onConditionsSelected}) : super(key: key);

  @override
  _ConditionsScreenState createState() => _ConditionsScreenState();
}

class _ConditionsScreenState extends State<ConditionsScreen> {
  final Map<String, String> _selectedConditions = {};
  final TextEditingController _notesController = TextEditingController();
  final ConditionsManager _conditionsManager = ConditionsManager();

  @override
  void initState() {
    super.initState();
    _loadLastConditions();
  }

  Future<void> _loadLastConditions() async {
    final lastConditions = await _conditionsManager.loadLastConditions();
    if (lastConditions != null) {
      setState(() {
        _selectedConditions.addAll(lastConditions.conditions);
        _notesController.text = lastConditions.notes ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Условия записи'),
        backgroundColor: Colors.green[400],
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: _showStats,
            tooltip: 'Статистика',
          ),
          IconButton(
            icon: Icon(Icons.tips_and_updates),
            onPressed: _showRecommendations,
            tooltip: 'Рекомендации',
          ),
        ],
      ),
      body: Column(
        children: [
          // Заголовок
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.green[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌟 Выберите условия для записи данных',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Это поможет собрать данные в разных ситуациях для лучшей работы ML модели',
                  style: TextStyle(fontSize: 12, color: Colors.green[700]),
                ),
              ],
            ),
          ),
          
          // Список условий
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: ConditionsManager.defaultConditions.length + 1,
              itemBuilder: (context, index) {
                if (index == ConditionsManager.defaultConditions.length) {
                  // Поле для заметок
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'Дополнительные заметки:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          hintText: 'Например: "После дождя", "Во время распродажи", "Новые магазины"',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  );
                }
                
                final category = ConditionsManager.defaultConditions.keys.elementAt(index);
                final options = ConditionsManager.defaultConditions[category]!;
                
                return _buildConditionCategory(category, options);
              },
            ),
          ),
          
          // Кнопки действий
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Предпросмотр выбранных условий
                if (_selectedConditions.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Выбранные условия:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _getConditionsPreview(),
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                
                // Кнопки
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedConditions.isNotEmpty ? _saveAndProceed : null,
                        icon: Icon(Icons.save),
                        label: Text('СОХРАНИТЬ И ПРОДОЛЖИТЬ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _clearAll,
                      icon: Icon(Icons.clear),
                      label: Text('ОЧИСТИТЬ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionCategory(String category, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(
          category,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = _selectedConditions[category] == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedConditions[category] = option;
                  } else {
                    _selectedConditions.remove(category);
                  }
                });
              },
              selectedColor: Colors.green[100],
              checkmarkColor: Colors.green[700],
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getConditionsPreview() {
    final parts = <String>[];
    for (final entry in _selectedConditions.entries) {
      parts.add('${entry.key}: ${entry.value}');
    }
    if (_notesController.text.isNotEmpty) {
      parts.add('Заметки: ${_notesController.text}');
    }
    return parts.join('\n');
  }

  void _saveAndProceed() {
    final conditions = RecordingConditions(
      conditions: Map.from(_selectedConditions),
      timestamp: DateTime.now(),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );
    
    _conditionsManager.saveConditions(conditions);
    widget.onConditionsSelected(conditions);
    Navigator.of(context).pop();
  }

  void _clearAll() {
    setState(() {
      _selectedConditions.clear();
      _notesController.clear();
    });
  }

  Future<void> _showStats() async {
    final stats = await _conditionsManager.getConditionsStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📊 Статистика записей'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final category in stats.keys) ...[
                Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
                ...stats[category]!.entries.map((entry) => 
                  Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(entry.key, style: TextStyle(fontSize: 12))),
                        Text('${entry.value}', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                Divider(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecommendations() async {
    final missing = await _conditionsManager.getMissingConditions();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('💡 Рекомендации'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (missing.isEmpty) ...[
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 8),
                Text('🎉 Отлично! У вас есть записи для всех условий.'),
              ] else ...[
                Text('Рекомендуется собрать данные в следующих условиях:'),
                SizedBox(height: 8),
                ...missing.take(10).map((recommendation) => 
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text('• $recommendation', style: TextStyle(fontSize: 12)),
                  ),
                ),
                if (missing.length > 10)
                  Text('... и еще ${missing.length - 10} рекомендаций'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
