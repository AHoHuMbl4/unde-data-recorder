import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../services/sensor_service.dart';
import '../services/location_recorder.dart';
import '../widgets/compass_widget.dart';
import 'map_screen.dart';
import 'preset_points_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SensorService _sensorService = SensorService();
  final LocationRecorder _locationRecorder = LocationRecorder();
  
  Map<String, dynamic> _currentSensorValues = {};
  Map<String, dynamic> _recordingStats = {};
  
  String _selectedFloor = "1";
  String? _selectedPoiType;
  String _currentConditions = '';
  List<String> _currentConditionsList = [];
  
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _yController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Типы точек интереса
  final List<String> _poiTypes = [
    'Магазин',
    'Кафе/Ресторан', 
    'Эскалатор',
    'Лифт',
    'Туалет',
    'Банкомат',
    'Информация',
    'Выход',
    'Парковка',
    'Коридор',
    'Перекресток',
    'Другое'
  ];

  @override
  void initState() {
    super.initState();
    // Обновляем показания датчиков каждые 100мс
    Stream.periodic(Duration(milliseconds: 100), (i) => i).listen((_) {
      if (mounted) {
        setState(() {
          _currentSensorValues = _sensorService.getCurrentSensorValues();
          _recordingStats = _locationRecorder.getRecordingStats();
        });
      }
    });
  }

  @override
  void dispose() {
    _sensorService.dispose();
    _locationRecorder.dispose();
    _xController.dispose();
    _yController.dispose();
    _fileNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _startRecording() {
    if (!_sensorService.isRecording) {
      _sensorService.setFloor(_selectedFloor);
      _sensorService.startRecording();
      _locationRecorder.startRecording(
        _sensorService.dataStream,
        fileName: _fileNameController.text.isNotEmpty ? _fileNameController.text : null,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Запись начата')),
      );
    }
  }

  void _stopRecording() {
    if (_sensorService.isRecording) {
      _sensorService.stopRecording();
      _locationRecorder.stopRecording();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Запись остановлена')),
      );
    }
  }

  Future<void> _saveData() async {
    try {
      final filePath = await _locationRecorder.saveToFile();
      final dataPointsCount = _recordingStats['totalPoints'] ?? 0;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Данные сохранены'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Файл сохранен в:'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  filePath,
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              SizedBox(height: 12),
              Text('Точек данных: $dataPointsCount'),
              if (_currentConditions.isNotEmpty) ...[
                SizedBox(height: 8),
                Text('Условия: $_currentConditions'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  void _markPosition() {
    final x = double.tryParse(_xController.text);
    final y = double.tryParse(_yController.text);
    
    if (x != null && y != null) {
      _sensorService.markPosition(x, y);
      _sensorService.setPoiInfo(_selectedPoiType, _descriptionController.text.isNotEmpty ? _descriptionController.text : null);
      
      String message = 'Позиция отмечена: ($x, $y)';
      if (_selectedPoiType != null) {
        message += '\nТип: $_selectedPoiType';
      }
      if (_descriptionController.text.isNotEmpty) {
        message += '\nОписание: ${_descriptionController.text}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: Duration(seconds: 3)),
      );
      
      // Очищаем поля после отметки
      _xController.clear();
      _yController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedPoiType = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Введите корректные координаты')),
      );
    }
  }

  void _resetStepCounter() {
    _sensorService.resetStepCount();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Счетчик шагов сброшен')),
    );
  }

  void _openMapScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapScreen(
          onPointSelected: (x, y) {
            setState(() {
              _xController.text = x.toInt().toString();
              _yController.text = y.toInt().toString();
            });
            _markPosition();
          },
        ),
      ),
    );
  }

  void _showConditionsDialog() {
    String? selectedTime;
    String? selectedCrowd;
    String? selectedWeather;
    String? selectedActivity;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('🌟 Условия записи'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Время суток:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Утро (6-12)', 'День (12-18)', 'Вечер (18-22)', 'Ночь (22-6)'].map((time) => 
                    FilterChip(
                      label: Text(time, style: TextStyle(fontSize: 12)),
                      selected: selectedTime == time,
                      onSelected: (selected) {
                        setState(() {
                          selectedTime = selected ? time : null;
                        });
                      },
                      selectedColor: Colors.blue[100],
                    ),
                  ).toList(),
                ),
                
                SizedBox(height: 16),
                Text('Загруженность:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Пусто (0-5)', 'Мало (5-20)', 'Средне (20-50)', 'Много (50+)'].map((crowd) => 
                    FilterChip(
                      label: Text(crowd, style: TextStyle(fontSize: 12)),
                      selected: selectedCrowd == crowd,
                      onSelected: (selected) {
                        setState(() {
                          selectedCrowd = selected ? crowd : null;
                        });
                      },
                      selectedColor: Colors.green[100],
                    ),
                  ).toList(),
                ),
                
                SizedBox(height: 16),
                Text('Погода:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Солнечно', 'Облачно', 'Дождь', 'Снег', 'Туман'].map((weather) => 
                    FilterChip(
                      label: Text(weather, style: TextStyle(fontSize: 12)),
                      selected: selectedWeather == weather,
                      onSelected: (selected) {
                        setState(() {
                          selectedWeather = selected ? weather : null;
                        });
                      },
                      selectedColor: Colors.orange[100],
                    ),
                  ).toList(),
                ),
                
                SizedBox(height: 16),
                Text('Активность:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Рабочее время', 'Обед', 'Выходной', 'Праздник', 'Распродажа'].map((activity) => 
                    FilterChip(
                      label: Text(activity, style: TextStyle(fontSize: 12)),
                      selected: selectedActivity == activity,
                      onSelected: (selected) {
                        setState(() {
                          selectedActivity = selected ? activity : null;
                        });
                      },
                      selectedColor: Colors.purple[100],
                    ),
                  ).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final conditions = <String>[];
                if (selectedTime != null) conditions.add(selectedTime!);
                if (selectedCrowd != null) conditions.add(selectedCrowd!);
                if (selectedWeather != null) conditions.add(selectedWeather!);
                if (selectedActivity != null) conditions.add(selectedActivity!);
                
                Navigator.of(context).pop();
                
                setState(() {
                  _currentConditions = conditions.join(' | ');
                  _currentConditionsList = conditions;
                });
                
                if (conditions.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Условия обновлены'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _importFloorPlan() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📐 Импорт плана здания'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Поддерживаемые форматы:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('📄 PDF - планы из AutoCAD, Visio'),
            Text('🖼️ PNG/JPG - изображения планов'),
            Text('📊 SVG - векторные планы'),
            SizedBox(height: 12),
            Text('План будет использоваться:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Для отображения в редакторе карт'),
            Text('• Как подложка при выборе координат'),
            Text('• В Navigator для навигации'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _selectFloorPlanFile();
            },
            icon: Icon(Icons.file_upload),
            label: Text('Выбрать файл'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFloorPlanFile() async {
    try {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Выберите файл плана...'),
            ],
          ),
        ),
      );

      // Симулируем выбор файла (пока без file_picker)
      await Future.delayed(Duration(seconds: 1));
      
      Navigator.of(context).pop(); // Закрываем индикатор
      
      // Показываем результат
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('📋 Инструкция по импорту'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Для импорта плана здания:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                
                Text('1️⃣ Подготовьте план:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• Сохраните план в PNG/JPG/PDF (до 500 МБ)'),
                Text('• Поддерживаются большие планы торговых центров'),
                Text('• Рекомендуемое разрешение: 300-600 DPI'),
                Text('• Масштаб: 1:100, 1:200 или 1:500'),
                SizedBox(height: 8),
                
                Text('2️⃣ Скопируйте в Downloads:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• Название: floor_plan.png (или .jpg)'),
                Text('• Путь: /Downloads/floor_plan.png'),
                SizedBox(height: 8),
                
                Text('3️⃣ Нажмите "Загрузить план":', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• План автоматически подключится'),
                Text('• Появится в редакторе карт как фон'),
                SizedBox(height: 12),
                
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💡 Совет:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Вы можете нарисовать план прямо в приложении через "Открыть карту" → инструменты рисования'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Понятно'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _loadFloorPlanFromDownloads();
              },
              icon: Icon(Icons.download),
              label: Text('Загрузить план'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
      
    } catch (e) {
      Navigator.of(context).pop(); // Закрываем индикатор если ошибка
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка выбора файла: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadFloorPlanFromDownloads() async {
    try {
      final downloadsPath = '/storage/emulated/0/Download';
      final possibleFiles = [
        'floor_plan.png',
        'floor_plan.jpg',
        'floor_plan.jpeg',
        'floor_plan.pdf',
        'plan.png',
        'plan.jpg',
        'plan.pdf',
        'building_plan.png',
        'building_plan.jpg',
        'building_plan.pdf',
        'mall_plan.png',
        'mall_plan.jpg',
        'shopping_center.png',
        'shopping_center.jpg',
      ];

      File? planFile;
      String? foundFileName;
      int fileSize = 0; // Изменили с int? на int с дефолтным значением

      // Ищем файл плана в Downloads
      for (final fileName in possibleFiles) {
        final file = File('$downloadsPath/$fileName');
        if (await file.exists()) {
          fileSize = await file.length();
          planFile = file;
          foundFileName = fileName;
          break;
        }
      }

      if (planFile != null) {
        // Проверяем размер файла (лимит 500 МБ)
        final maxSize = 500 * 1024 * 1024; // 500 МБ
        if (fileSize > maxSize) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('⚠️ Файл слишком большой'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Размер файла: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} МБ'),
                  Text('Максимум: 500 МБ'),
                  SizedBox(height: 12),
                  Text('Рекомендации:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('• Сожмите изображение в графическом редакторе'),
                  Text('• Уменьшите разрешение до 150-300 DPI'),
                  Text('• Сохраните в JPEG с качеством 80-90%'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Понятно'),
                ),
              ],
            ),
          );
          return;
        }

        // Показываем прогресс копирования для больших файлов
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Импортирую план...'),
                Text('${(fileSize / 1024 / 1024).toStringAsFixed(1)} МБ'),
              ],
            ),
          ),
        );

        // Копируем план в папку приложения
        final directory = await getApplicationDocumentsDirectory();
        final extension = foundFileName!.split('.').last;
        final appPlanFile = File('${directory.path}/imported_floor_plan.$extension');
        await planFile.copy(appPlanFile.path);

        Navigator.of(context).pop(); // Закрываем прогресс

        // Сохраняем информацию о плане
        final planInfo = {
          'imported': true,
          'fileName': foundFileName,
          'importDate': DateTime.now().millisecondsSinceEpoch,
          'filePath': appPlanFile.path,
          'fileSize': fileSize,
          'fileSizeMB': (fileSize / 1024 / 1024).toStringAsFixed(1),
        };

        final infoFile = File('${directory.path}/floor_plan_info.json');
        await infoFile.writeAsString(jsonEncode(planInfo));

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('✅ План успешно импортирован!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📁 Файл: $foundFileName'),
                Text('📊 Размер: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} МБ'),
                Text('📅 Импортирован: ${DateTime.now().toString().split('.')[0]}'),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('План доступен в:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('• Редакторе карт как фон'),
                      Text('• При выборе координат точек'),
                      Text('• В режиме навигации'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Отлично!'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openMapScreen(); // Открываем карту чтобы посмотреть план
                },
                icon: Icon(Icons.map),
                label: Text('Посмотреть на карте'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );

      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('📁 Файл плана не найден'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Не найден файл плана в Downloads.'),
                  SizedBox(height: 12),
                  Text('Ожидаемые имена файлов:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...possibleFiles.take(8).map((name) => Text('• $name')),
                  Text('• и другие варианты...'),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('💡 Поддерживаются:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('• PNG, JPG, PDF до 500 МБ'),
                        Text('• Планы торговых центров'),
                        Text('• Архитектурные чертежи'),
                        Text('• Файлы из AutoCAD, Visio'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Понятно'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _selectFloorPlanFile(); // Повторить попытку
                },
                icon: Icon(Icons.refresh),
                label: Text('Попробовать снова'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      Navigator.of(context).pop(); // Закрываем прогресс если ошибка
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки плана: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _managePresetPoints() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PresetPointsScreen(
          onPointSelected: (x, y, name, type) {
            setState(() {
              _xController.text = x.toInt().toString();
              _yController.text = y.toInt().toString();
              _selectedPoiType = type;
              _descriptionController.text = name;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Выбрана точка "$name"'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  void _startPrecisionCalibration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎯 Режим точной калибровки'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Для достижения точности < 1 метра:', 
                   style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('📱 Держите телефон в 4 ориентациях:', 
                   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              SizedBox(height: 8),
              Text('• 📱 Портрет (обычно)'),
              Text('• 📲 Альбом влево'),
              Text('• 📳 Альбом вправо'),
              Text('• 🙃 Портрет вверх ногами'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text('⏱️ По 15 секунд в каждой ориентации', 
                         style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('🧭 Держите телефон экраном на СЕВЕР'),
                    Text('📍 Стойте неподвижно в выбранной точке'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCalibrationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: Text('Настроить калибровку'),
          ),
        ],
      ),
    );
  }

  void _showCalibrationSettings() {
    String selectedTimeOfDay = _getCurrentTimeOfDay();
    String selectedCrowd = 'Средне (20-50 чел)';
    String selectedWeather = 'Обычно';
    String customComment = '';
    
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('⚙️ Настройки калибровки'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🕐 Время записи:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Утро (6-12)', 'День (12-18)', 'Вечер (18-22)', 'Ночь (22-6)'].map((time) => 
                    FilterChip(
                      label: Text(time, style: TextStyle(fontSize: 11)),
                      selected: selectedTimeOfDay == time,
                      onSelected: (selected) {
                        setState(() {
                          selectedTimeOfDay = selected ? time : selectedTimeOfDay;
                        });
                      },
                      selectedColor: Colors.blue[100],
                    ),
                  ).toList(),
                ),
                
                SizedBox(height: 16),
                Text('👥 Количество людей:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Пусто (0-5)', 'Мало (5-20)', 'Средне (20-50)', 'Много (50+)', 'Очень много (100+)'].map((crowd) => 
                    FilterChip(
                      label: Text(crowd, style: TextStyle(fontSize: 11)),
                      selected: selectedCrowd == crowd,
                      onSelected: (selected) {
                        setState(() {
                          selectedCrowd = selected ? crowd : selectedCrowd;
                        });
                      },
                      selectedColor: Colors.green[100],
                    ),
                  ).toList(),
                ),
                
                SizedBox(height: 16),
                Text('🌤️ Условия:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Обычно', 'Дождь на улице', 'Жара', 'Холодно', 'Ремонт рядом', 'Мероприятие'].map((weather) => 
                    FilterChip(
                      label: Text(weather, style: TextStyle(fontSize: 11)),
                      selected: selectedWeather == weather,
                      onSelected: (selected) {
                        setState(() {
                          selectedWeather = selected ? weather : selectedWeather;
                        });
                      },
                      selectedColor: Colors.orange[100],
                    ),
                  ).toList(),
                ),
                
                SizedBox(height: 16),
                Text('💬 Дополнительный комментарий:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'Например: "Много покупателей у касс", "Тихий час"',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    customComment = value;
                  },
                ),
                
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📋 Итоговые условия:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('• Время: $selectedTimeOfDay', style: TextStyle(fontSize: 12)),
                      Text('• Людей: $selectedCrowd', style: TextStyle(fontSize: 12)),
                      Text('• Условия: $selectedWeather', style: TextStyle(fontSize: 12)),
                      if (customComment.isNotEmpty)
                        Text('• Комментарий: $customComment', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                
                // Формируем полное описание условий
                final conditions = <String>[];
                conditions.add(selectedTimeOfDay);
                conditions.add(selectedCrowd);
                conditions.add(selectedWeather);
                if (customComment.isNotEmpty) {
                  conditions.add(customComment);
                }
                
                // Обновляем глобальные условия
                setState(() {
                  _currentConditions = conditions.join(' | ');
                  _currentConditionsList = conditions;
                });
                
                // Запускаем калибровку с выбранными условиями
                _runPrecisionCalibration();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: Text('🎯 Начать калибровку'),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'Утро (6-12)';
    if (hour >= 12 && hour < 18) return 'День (12-18)';
    if (hour >= 18 && hour < 22) return 'Вечер (18-22)';
    return 'Ночь (22-6)';
  }

  Future<void> _runPrecisionCalibration() async {
    if (_xController.text.isEmpty || _yController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Сначала укажите координаты точки'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final orientations = [
      {
        'name': 'Портрет', 
        'icon': '📱', 
        'instruction': 'Держите телефон вертикально',
        'detail': 'Экран смотрит на вас, телефон стоит как обычно'
      },
      {
        'name': 'Альбом вправо', 
        'icon': '📲', 
        'instruction': 'Поверните на 90° вправо',
        'detail': 'Кнопка домой справа, экран горизонтально'
      },
      {
        'name': 'Портрет вверх ногами', 
        'icon': '🙃', 
        'instruction': 'Поверните на 180°',
        'detail': 'Телефон перевернут, камера внизу'
      },
      {
        'name': 'Альбом влево', 
        'icon': '📳', 
        'instruction': 'Поверните на 270°',
        'detail': 'Кнопка домой слева, экран горизонтально'
      },
    ];

    for (int i = 0; i < orientations.length; i++) {
      final orientation = orientations[i];
      
      // Показываем инструкцию для каждой ориентации
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('${orientation['icon']} ${orientation['name']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    orientation['instruction']!,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    orientation['detail']!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  
                  // Компас в реальном времени
                  StreamBuilder<Map<String, dynamic>>(
                    stream: Stream.periodic(Duration(milliseconds: 200), (_) => _currentSensorValues),
                    builder: (context, snapshot) {
                      final azimuth = _currentSensorValues['azimuth'] ?? 0.0;
                      final compassDir = _currentSensorValues['compass_direction'] ?? 'Calibrating';
                      
                      return CompassWidget(
                        azimuth: azimuth,
                        compassDirection: compassDir,
                        size: 150,
                      );
                    },
                  ),
                  
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('📍 Координаты: (${_xController.text}, ${_yController.text})'),
                        Text('Ориентация ${i + 1} из ${orientations.length}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('✅ Готов к записи'),
              ),
            ],
          ),
        ),
      );

      // Обратный отсчет
      for (int countdown = 3; countdown > 0; countdown--) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⏱️ Начинаем запись через $countdown...\n${orientation['name']} - держите телефон неподвижно!',
              textAlign: TextAlign.center,
            ),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.orange,
          ),
        );
        await Future.delayed(Duration(seconds: 1));
      }

      // Начинаем запись для этой ориентации
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🔴 ЗАПИСЬ: ${orientation['name']}\n15 секунд - НЕ ДВИГАЙТЕСЬ!',
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 15),
          backgroundColor: Colors.red,
        ),
      );

      // Запускаем запись с меткой ориентации
      _startRecordingWithOrientation(orientation['name']!, i + 1, orientations.length);
      await Future.delayed(Duration(seconds: 15));
      _stopRecording();

      // Сообщение о завершении текущей ориентации
      if (i < orientations.length - 1) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${orientation['name']} завершено!\nПереходим к следующей ориентации...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(Duration(seconds: 2));
      }
    }

    // Автоматически сохраняем данные после всех ориентаций
    await Future.delayed(Duration(seconds: 1));
    await _saveData();

    // Финальное сообщение
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎉 Калибровка завершена!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Собраны данные во всех 4 ориентациях'),
            Text('📍 Точка: (${_xController.text}, ${_yController.text})'),
            Text('🕐 Время: ${DateTime.now().toString().split('.')[0]}'),
            if (_currentConditions.isNotEmpty) ...[
              SizedBox(height: 4),
              Text('📋 Условия: $_currentConditions'),
            ],
            Text('📊 Это значительно улучшит точность локализации'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Для лучшей точности повторите:',
                    style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
                  ),
                  Text('• В другое время (утром, днем, вечером)', style: TextStyle(fontSize: 12)),
                  Text('• При разной загруженности людьми', style: TextStyle(fontSize: 12)),
                  Text('• В разных условиях (дождь, ремонт, etc)', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCalibrationSettings(); // Быстрый доступ к настройкам для повтора
            },
            child: Text('🔄 Повторить с другими условиями'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Очищаем координаты для следующей точки
              _xController.clear();
              _yController.clear();
              setState(() {
                _selectedPoiType = null;
              });
              _descriptionController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('✅ Готово! К следующей точке'),
          ),
        ],
      ),
    );
  }

  void _startRecordingWithOrientation(String orientation, int current, int total) {
    // Добавляем метку ориентации к записи
    _sensorService.setOrientation('$orientation (${current}/$total)');
    
    // Устанавливаем условия записи в сенсор
    if (_currentConditionsList.isNotEmpty) {
      // Добавляем условия к описанию
      final fullDescription = _descriptionController.text.isEmpty 
          ? _currentConditions
          : '${_descriptionController.text} | $_currentConditions';
      _sensorService.setPoiInfo(_selectedPoiType, fullDescription);
    }
    
    // Запускаем обычную запись
    _startRecording();
    
    print('🎯 Начата точная калибровка: $orientation в точке (${_xController.text}, ${_yController.text})');
    print('📋 Условия: $_currentConditions');
  }

  Future<void> _showSavedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync().where((f) => f.path.endsWith('.csv')).toList();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Сохраненные файлы'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Папка:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                SelectableText(
                  directory.path,
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                SizedBox(height: 16),
                Text('Файлы CSV:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                if (files.isEmpty)
                  Text('Нет сохраненных файлов CSV')
                else
                  ...files.map((file) {
                    final fileName = file.path.split('/').last;
                    final stat = file.statSync();
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fileName, style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Размер: ${(stat.size / 1024).toStringAsFixed(1)} KB'),
                          Text('Изменен: ${DateTime.fromMillisecondsSinceEpoch(stat.modified.millisecondsSinceEpoch).toString().split('.')[0]}'),
                        ],
                      ),
                    );
                  }).toList(),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _exportAllData() async {
    try {
      // Экспорт всех CSV данных из внутренней папки
      final directory = await getApplicationDocumentsDirectory();
      final allFiles = directory.listSync();
      final csvFiles = allFiles.where((f) => f.path.endsWith('.csv')).toList();
      
      List<String> copiedFiles = [];
      
      // Копируем все CSV файлы в Downloads
      for (final csvFile in csvFiles) {
        final fileName = csvFile.path.split('/').last;
        final downloadsPath = '/storage/emulated/0/Download';
        final backupFile = File('$downloadsPath/backup_$fileName');
        await File(csvFile.path).copy(backupFile.path);
        copiedFiles.add('backup_$fileName');
      }
      
      // Экспорт карты
      final mapFile = File('${directory.path}/indoor_map.json');
      String? mapPath;
      if (await mapFile.exists()) {
        final downloadsPath = '/storage/emulated/0/Download';
        final backupMapFile = File('$downloadsPath/unde_backup_map.json');
        await mapFile.copy(backupMapFile.path);
        mapPath = backupMapFile.path;
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('🛡️ Резервная копия создана'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Данные сохранены в папке Downloads:'),
              SizedBox(height: 12),
              if (copiedFiles.isNotEmpty) ...[
                Text('📊 CSV файлы (${copiedFiles.length}):', style: TextStyle(fontWeight: FontWeight.bold)),
                ...copiedFiles.map((file) => Text('• $file', style: TextStyle(fontSize: 12))),
                SizedBox(height: 8),
              ],
              if (mapPath != null) ...[
                Text('🗺️ Карта помещения:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• unde_backup_map.json', style: TextStyle(fontSize: 12)),
                SizedBox(height: 8),
              ],
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '✅ Все ${copiedFiles.length} CSV файлов скопированы!',
                  style: TextStyle(color: Colors.green[800]),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка создания резервной копии: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importBackupData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final downloadsPath = '/storage/emulated/0/Download';
      
      // Восстанавливаем карту
      final backupMapFile = File('$downloadsPath/unde_backup_map.json');
      if (await backupMapFile.exists()) {
        final mapFile = File('${directory.path}/indoor_map.json');
        await backupMapFile.copy(mapFile.path);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Данные восстановлены из резервной копии'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка восстановления: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSensorCard(String title, String value, {Color? color}) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = _sensorService.isRecording;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('UNDE - Сбор данных'),
        backgroundColor: isRecording ? Colors.red[400] : Colors.blue[400],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Статус записи
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isRecording ? Colors.red[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isRecording ? Colors.red : Colors.grey,
                  width: 2.0,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isRecording ? '🔴 ИДЕТ ЗАПИСЬ' : '⭕ ЗАПИСЬ ОСТАНОВЛЕНА',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isRecording ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  if (isRecording && _recordingStats['totalPoints'] != null)
                    Text(
                      'Записано точек: ${_recordingStats['totalPoints']} | Время: ${(_recordingStats['durationSeconds'] ?? 0)}с',
                      style: TextStyle(fontSize: 14),
                    ),
                ],
              ),
            ),
            
            SizedBox(height: 20),

            // Текущие условия записи
            if (_currentConditions.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌟 Текущие условия записи:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _currentConditions,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 20),
            
            // Показания датчиков
            Text('Текущие показания датчиков:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            
            // Магнитометр с ориентацией + компас
            Row(
              children: [
                Expanded(
                  child: _buildSensorCard(
                    'Магнитометр (μT) + Ориентация',
                    'X: ${_currentSensorValues['magnetometer_x']?.toStringAsFixed(2) ?? '—'}\n'
                    'Y: ${_currentSensorValues['magnetometer_y']?.toStringAsFixed(2) ?? '—'}\n'
                    'Z: ${_currentSensorValues['magnetometer_z']?.toStringAsFixed(2) ?? '—'}\n'
                    'Магнитуда: ${_currentSensorValues['magnetic_magnitude']?.toStringAsFixed(2) ?? '—'} μT\n'
                    'Азимут: ${_currentSensorValues['azimuth']?.toStringAsFixed(1) ?? '—'}°\n'
                    'Компас: ${_currentSensorValues['compass_direction'] ?? '—'}\n'
                    'Ориентация: ${_currentSensorValues['device_orientation'] ?? '—'}',
                    color: Colors.purple,
                  ),
                ),
                SizedBox(width: 16),
                // Мини-компас
                CompassWidget(
                  azimuth: _currentSensorValues['azimuth'] ?? 0.0,
                  compassDirection: _currentSensorValues['compass_direction'] ?? '',
                  size: 80,
                  showText: false,
                ),
              ],
            ),
            
            // Акселерометр
            _buildSensorCard(
              'Акселерометр (m/s²)',
              'X: ${_currentSensorValues['accelerometer_x']?.toStringAsFixed(2) ?? '—'}\n'
              'Y: ${_currentSensorValues['accelerometer_y']?.toStringAsFixed(2) ?? '—'}\n'
              'Z: ${_currentSensorValues['accelerometer_z']?.toStringAsFixed(2) ?? '—'}',
              color: Colors.green,
            ),
            
            // Гироскоп
            _buildSensorCard(
              'Гироскоп (rad/s)',
              'X: ${_currentSensorValues['gyroscope_x']?.toStringAsFixed(2) ?? '—'}\n'
              'Y: ${_currentSensorValues['gyroscope_y']?.toStringAsFixed(2) ?? '—'}\n'
              'Z: ${_currentSensorValues['gyroscope_z']?.toStringAsFixed(2) ?? '—'}',
              color: Colors.orange,
            ),

            // PDR данные
            _buildSensorCard(
              'PDR (Пешеходная навигация)',
              'Шаги: ${_currentSensorValues['step_count'] ?? 0}\n'
              'Направление: ${_currentSensorValues['heading']?.toStringAsFixed(1) ?? '—'}°\n'
              'Давление: ${_currentSensorValues['pressure']?.toStringAsFixed(2) ?? '—'} hPa',
              color: Colors.blue,
            ),
            
            SizedBox(height: 20),

            // Управление проектом
            Text('Управление проектом:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _importFloorPlan,
                    icon: Icon(Icons.upload_file),
                    label: Text('ИМПОРТ ПЛАНА'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showConditionsDialog,
                    icon: Icon(Icons.tune),
                    label: Text('УСЛОВИЯ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _managePresetPoints,
              icon: Icon(Icons.location_searching),
              label: Text('ПРЕДУСТАНОВЛЕННЫЕ ТОЧКИ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _startPrecisionCalibration,
              icon: Icon(Icons.tune),
              label: Text('🎯 ТОЧНАЯ КАЛИБРОВКА'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Настройки записи
            Text('Настройки записи:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            
            // Выбор этажа и сброс шагов
            Row(
              children: [
                Text('Этаж: ', style: TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: _selectedFloor,
                  items: ['1', '2', '3', '4', '5'].map((floor) {
                    return DropdownMenuItem(value: floor, child: Text(floor));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFloor = value!;
                    });
                    _sensorService.setFloor(value!);
                  },
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: _resetStepCounter,
                  icon: Icon(Icons.refresh, size: 16),
                  label: Text('Сброс шагов'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 15),

            // Тип точки интереса
            Text('Тип точки интереса:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 5),
            DropdownButtonFormField<String>(
              value: _selectedPoiType,
              decoration: InputDecoration(
                hintText: 'Выберите тип точки (необязательно)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _poiTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPoiType = value;
                });
              },
            ),

            SizedBox(height: 10),

            // Описание точки
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Описание точки (необязательно)',
                hintText: 'Например: "Магазин Apple", "Главный вход"',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            SizedBox(height: 10),
            
            // Координаты
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _xController,
                    decoration: InputDecoration(
                      labelText: 'X координата',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _yController,
                    decoration: InputDecoration(
                      labelText: 'Y координата', 
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            // Кнопки для работы с координатами
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openMapScreen,
                    icon: Icon(Icons.map),
                    label: Text('Открыть карту'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _markPosition,
                    icon: Icon(Icons.location_on),
                    label: Text('Отметить точку'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 10),
            
            // Имя файла
            TextField(
              controller: _fileNameController,
              decoration: InputDecoration(
                labelText: 'Имя файла (необязательно)',
                border: OutlineInputBorder(),
                hintText: 'magnetic_map_floor_1',
              ),
            ),
            
            SizedBox(height: 20),
            
            // Кнопки управления записью
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isRecording ? null : _startRecording,
                    child: Text('НАЧАТЬ ЗАПИСЬ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: !isRecording ? null : _stopRecording,
                    child: Text('ОСТАНОВИТЬ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _locationRecorder.dataPointsCount > 0 ? _saveData : null,
              child: Text('СОХРАНИТЬ ДАННЫЕ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),

            SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _showSavedFiles,
              icon: Icon(Icons.folder_open),
              label: Text('ПОКАЗАТЬ ФАЙЛЫ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),

            SizedBox(height: 20),

            // Кнопки резервного копирования
            Text('Резервное копирование:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportAllData,
                    icon: Icon(Icons.backup),
                    label: Text('СОЗДАТЬ БЭКАП'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _importBackupData,
                    icon: Icon(Icons.restore),
                    label: Text('ВОССТАНОВИТЬ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
