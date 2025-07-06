import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../models/magnetic_point.dart';

class LocationRecorder {
  List<MagneticPoint> _dataPoints = [];
  StreamSubscription<Map<String, dynamic>>? _dataSubscription;
  DateTime? _recordingStartTime;
  String currentFileName = '';
  
  int get dataPointsCount => _dataPoints.length;
  
  void startRecording(Stream<Map<String, dynamic>> dataStream, {String? fileName}) {
    _recordingStartTime = DateTime.now();
    
    // Генерируем имя файла если не указано
    if (fileName != null && fileName.isNotEmpty) {
      currentFileName = fileName.endsWith('.csv') ? fileName : '$fileName.csv';
    } else {
      final timestamp = _recordingStartTime!.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      currentFileName = 'magnetic_map_floor_1_$timestamp.csv';
    }
    
    // Очищаем предыдущие данные
    _dataPoints.clear();
    
    // Подписываемся на поток данных
    _dataSubscription = dataStream.listen((Map<String, dynamic> data) {
      try {
        // Преобразуем Map в MagneticPoint
        final point = MagneticPoint.fromMap(data);
        _dataPoints.add(point);
      } catch (e) {
        print('Ошибка обработки данных: $e');
      }
    });
  }
  
  void stopRecording() {
    _dataSubscription?.cancel();
    _dataSubscription = null;
  }
  
  Map<String, dynamic> getRecordingStats() {
    final now = DateTime.now();
    final duration = _recordingStartTime != null 
        ? now.difference(_recordingStartTime!).inSeconds 
        : 0;
    
    return {
      'totalPoints': _dataPoints.length,
      'durationSeconds': duration,
      'isRecording': _dataSubscription != null,
      'fileName': currentFileName,
    };
  }
  
  Future<String> saveToFile() async {
    if (_dataPoints.isEmpty) {
      throw Exception('Нет данных для сохранения');
    }

    try {
      // Сохраняем прямо в Downloads для удобства
      final downloadsPath = '/storage/emulated/0/Download';
      final file = File('$downloadsPath/$currentFileName');

      // Подготавливаем данные для CSV
      List<List<String>> csvData = [];
      
      // Добавляем заголовки
      csvData.add(MagneticPoint.csvHeaders());
      
      // Добавляем данные
      for (final point in _dataPoints) {
        csvData.add(point.toCsvRow());
      }

      // Конвертируем в CSV формат
      String csvString = const ListToCsvConverter(fieldDelimiter: ';').convert(csvData);

      // Записываем в файл
      await file.writeAsString(csvString);

      return file.path;
    } catch (e) {
      // Если не получилось в Downloads, используем стандартный путь
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$currentFileName');

      // Подготавливаем данные для CSV
      List<List<String>> csvData = [];
      
      // Добавляем заголовки
      csvData.add(MagneticPoint.csvHeaders());
      
      // Добавляем данные
      for (final point in _dataPoints) {
        csvData.add(point.toCsvRow());
      }

      // Конвертируем в CSV формат
      String csvString = const ListToCsvConverter(fieldDelimiter: ';').convert(csvData);

      // Записываем в файл
      await file.writeAsString(csvString);

      return file.path;
    }
  }
  
  void dispose() {
    _dataSubscription?.cancel();
  }
}
