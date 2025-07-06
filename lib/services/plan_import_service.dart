import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class PlanImportService {
  static const String plansCacheDir = 'imported_plans';
  
  /// Импорт плана здания из файла
  Future<ImportedPlan?> importFloorPlan() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'svg', 'pdf', 'dwg', 'dxf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final extension = fileName.split('.').last.toLowerCase();

        // Сохраняем файл в кеш приложения
        final savedPlan = await _savePlanToCache(file, fileName);
        
        return ImportedPlan(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fileName: fileName,
          filePath: savedPlan.path,
          fileType: extension,
          importDate: DateTime.now(),
          originalSize: await file.length(),
        );
      }
      return null;
    } catch (e) {
      print('Ошибка импорта плана: $e');
      return null;
    }
  }

  /// Импорт координат точек из CSV/JSON
  Future<List<PredefinedPoint>?> importPredefinePoints() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final extension = result.files.single.name.split('.').last.toLowerCase();

        if (extension == 'json') {
          return _parseJsonPoints(content);
        } else if (extension == 'csv') {
          return _parseCsvPoints(content);
        }
      }
      return null;
    } catch (e) {
      print('Ошибка импорта точек: $e');
      return null;
    }
  }

  /// Экспорт точек в CSV для редактирования
  Future<String?> exportPointsTemplate(List<PredefinedPoint> points) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/points_template.csv');
      
      final csvContent = StringBuffer();
      csvContent.writeln('id;name;x;y;floor;type;description;conditions');
      
      for (final point in points) {
        csvContent.writeln(
          '${point.id};${point.name};${point.x};${point.y};${point.floor};'
          '${point.type};${point.description};${point.conditions.join("|")}'
        );
      }
      
      await file.writeAsString(csvContent.toString());
      return file.path;
    } catch (e) {
      print('Ошибка экспорта шаблона: $e');
      return null;
    }
  }

  Future<File> _savePlanToCache(File sourceFile, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final plansDir = Directory('${directory.path}/$plansCacheDir');
    
    if (!await plansDir.exists()) {
      await plansDir.create(recursive: true);
    }
    
    final cachedFile = File('${plansDir.path}/$fileName');
    return await sourceFile.copy(cachedFile.path);
  }

  List<PredefinedPoint> _parseJsonPoints(String content) {
    final data = jsonDecode(content);
    final List<PredefinedPoint> points = [];
    
    if (data['points'] != null) {
      for (final pointData in data['points']) {
        points.add(PredefinedPoint.fromJson(pointData));
      }
    }
    
    return points;
  }

  List<PredefinedPoint> _parseCsvPoints(String content) {
    final lines = content.split('\n');
    final List<PredefinedPoint> points = [];
    
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      final parts = line.split(';');
      if (parts.length >= 6) {
        points.add(PredefinedPoint(
          id: parts[0],
          name: parts[1],
          x: double.tryParse(parts[2]) ?? 0.0,
          y: double.tryParse(parts[3]) ?? 0.0,
          floor: parts[4],
          type: parts[5],
          description: parts.length > 6 ? parts[6] : '',
          conditions: parts.length > 7 ? parts[7].split('|') : [],
        ));
      }
    }
    
    return points;
  }

  /// Получить все сохраненные планы
  Future<List<ImportedPlan>> getSavedPlans() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final plansDir = Directory('${directory.path}/$plansCacheDir');
      
      if (!await plansDir.exists()) {
        return [];
      }
      
      final files = plansDir.listSync();
      final List<ImportedPlan> plans = [];
      
      for (final file in files) {
        if (file is File) {
          final stat = file.statSync();
          plans.add(ImportedPlan(
            id: file.path.hashCode.toString(),
            fileName: file.path.split('/').last,
            filePath: file.path,
            fileType: file.path.split('.').last.toLowerCase(),
            importDate: stat.modified,
            originalSize: stat.size,
          ));
        }
      }
      
      return plans;
    } catch (e) {
      print('Ошибка получения планов: $e');
      return [];
    }
  }
}

class ImportedPlan {
  final String id;
  final String fileName;
  final String filePath;
  final String fileType;
  final DateTime importDate;
  final int originalSize;

  ImportedPlan({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.importDate,
    required this.originalSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType,
      'importDate': importDate.millisecondsSinceEpoch,
      'originalSize': originalSize,
    };
  }

  static ImportedPlan fromJson(Map<String, dynamic> json) {
    return ImportedPlan(
      id: json['id'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      fileType: json['fileType'],
      importDate: DateTime.fromMillisecondsSinceEpoch(json['importDate']),
      originalSize: json['originalSize'],
    );
  }
}

class PredefinedPoint {
  final String id;
  final String name;
  final double x;
  final double y;
  final String floor;
  final String type;
  final String description;
  final List<String> conditions;
  bool isCompleted;
  DateTime? lastRecorded;

  PredefinedPoint({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.floor,
    required this.type,
    required this.description,
    this.conditions = const [],
    this.isCompleted = false,
    this.lastRecorded,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'x': x,
      'y': y,
      'floor': floor,
      'type': type,
      'description': description,
      'conditions': conditions,
      'isCompleted': isCompleted,
      'lastRecorded': lastRecorded?.millisecondsSinceEpoch,
    };
  }

  static PredefinedPoint fromJson(Map<String, dynamic> json) {
    return PredefinedPoint(
      id: json['id'],
      name: json['name'],
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      floor: json['floor'],
      type: json['type'],
      description: json['description'] ?? '',
      conditions: List<String>.from(json['conditions'] ?? []),
      isCompleted: json['isCompleted'] ?? false,
      lastRecorded: json['lastRecorded'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['lastRecorded']) 
        : null,
    );
  }

  PredefinedPoint copyWith({
    bool? isCompleted,
    DateTime? lastRecorded,
  }) {
    return PredefinedPoint(
      id: id,
      name: name,
      x: x,
      y: y,
      floor: floor,
      type: type,
      description: description,
      conditions: conditions,
      isCompleted: isCompleted ?? this.isCompleted,
      lastRecorded: lastRecorded ?? this.lastRecorded,
    );
  }
}
