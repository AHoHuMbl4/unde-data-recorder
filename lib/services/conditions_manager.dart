import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ConditionsManager {
  static const String conditionsFile = 'recording_conditions.json';
  
  /// Предустановленные условия записи
  static const Map<String, List<String>> defaultConditions = {
    'Время суток': ['Утро (06-12)', 'День (12-18)', 'Вечер (18-22)', 'Ночь (22-06)'],
    'Загруженность': ['Пусто (0-5 чел)', 'Мало (5-20 чел)', 'Средне (20-50 чел)', 'Много (50+ чел)'],
    'Погода': ['Солнечно', 'Облачно', 'Дождь', 'Снег', 'Туман'],
    'Температура': ['Холодно (<10°C)', 'Прохладно (10-20°C)', 'Комфортно (20-25°C)', 'Тепло (>25°C)'],
    'День недели': ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'],
    'Влажность': ['Сухо (<40%)', 'Нормально (40-60%)', 'Влажно (>60%)'],
    'Активность': ['Рабочее время', 'Обеденный перерыв', 'Выходной', 'Праздник'],
    'Особенности': ['Ремонт', 'Мероприятие', 'Распродажа', 'Обычный день'],
  };

  /// Сохранить выбранные условия
  Future<void> saveConditions(RecordingConditions conditions) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$conditionsFile');
      
      final conditionsData = {
        'current': conditions.toJson(),
        'history': await _getConditionsHistory(),
      };
      
      // Добавляем в историю
      conditionsData['history'].add({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'conditions': conditions.toJson(),
      });
      
      await file.writeAsString(jsonEncode(conditionsData));
    } catch (e) {
      print('Ошибка сохранения условий: $e');
    }
  }

  /// Загрузить последние условия
  Future<RecordingConditions?> loadLastConditions() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$conditionsFile');
      
      if (!await file.exists()) {
        return null;
      }
      
      final content = await file.readAsString();
      final data = jsonDecode(content);
      
      if (data['current'] != null) {
        return RecordingConditions.fromJson(data['current']);
      }
      
      return null;
    } catch (e) {
      print('Ошибка загрузки условий: $e');
      return null;
    }
  }

  /// Получить историю условий
  Future<List<Map<String, dynamic>>> _getConditionsHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$conditionsFile');
      
      if (!await file.exists()) {
        return [];
      }
      
      final content = await file.readAsString();
      final data = jsonDecode(content);
      
      return List<Map<String, dynamic>>.from(data['history'] ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Получить статистику по условиям
  Future<Map<String, Map<String, int>>> getConditionsStats() async {
    final history = await _getConditionsHistory();
    final stats = <String, Map<String, int>>{};
    
    for (final category in defaultConditions.keys) {
      stats[category] = <String, int>{};
      for (final option in defaultConditions[category]!) {
        stats[category]![option] = 0;
      }
    }
    
    for (final record in history) {
      final conditions = record['conditions'];
      if (conditions != null) {
        for (final category in conditions.keys) {
          final value = conditions[category];
          if (value != null && stats[category] != null) {
            stats[category]![value] = (stats[category]![value] ?? 0) + 1;
          }
        }
      }
    }
    
    return stats;
  }

  /// Получить рекомендации недостающих условий
  Future<List<String>> getMissingConditions() async {
    final stats = await getConditionsStats();
    final missing = <String>[];
    
    for (final category in stats.keys) {
      final categoryStats = stats[category]!;
      final totalRecords = categoryStats.values.fold(0, (a, b) => a + b);
      
      if (totalRecords == 0) {
        missing.add('Нет записей для категории "$category"');
        continue;
      }
      
      for (final option in categoryStats.keys) {
        final count = categoryStats[option]!;
        if (count == 0) {
          missing.add('Нет записей для "$option" в категории "$category"');
        } else if (count < 3) {
          missing.add('Мало записей ($count) для "$option" в категории "$category"');
        }
      }
    }
    
    return missing;
  }
}

class RecordingConditions {
  final Map<String, String> conditions;
  final DateTime timestamp;
  final String? notes;

  RecordingConditions({
    required this.conditions,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'conditions': conditions,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  static RecordingConditions fromJson(Map<String, dynamic> json) {
    return RecordingConditions(
      conditions: Map<String, String>.from(json['conditions']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      notes: json['notes'],
    );
  }

  /// Создать строку-описание условий
  String getConditionsString() {
    final parts = <String>[];
    for (final entry in conditions.entries) {
      parts.add('${entry.key}: ${entry.value}');
    }
    if (notes?.isNotEmpty == true) {
      parts.add('Заметки: $notes');
    }
    return parts.join(' | ');
  }

  /// Создать краткое описание
  String getShortDescription() {
    final time = conditions['Время суток'] ?? '';
    final crowd = conditions['Загруженность'] ?? '';
    final weather = conditions['Погода'] ?? '';
    
    return '$time, $crowd, $weather'.replaceAll(RegExp(r'^,\s*|,\s*$'), '');
  }
}
