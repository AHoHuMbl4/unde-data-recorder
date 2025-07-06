import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'orientation_service.dart';

class SensorService {
  final OrientationService _orientationService = OrientationService();
  
  // Контроллеры для потоков данных
  late StreamController<Map<String, dynamic>> _dataController;
  
  // Подписки на датчики
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  // Текущие значения
  Map<String, dynamic> _currentValues = {};
  
  // Состояние записи
  bool _isRecording = false;
  int _stepCount = 0;
  String _currentFloor = "1";
  String _currentOrientation = "Unknown";
  double? _markedX;
  double? _markedY;
  String? _poiType;
  String? _poiDescription;
  
  // Getters
  bool get isRecording => _isRecording;
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  
  SensorService() {
    _dataController = StreamController<Map<String, dynamic>>.broadcast();
    _initializeSensors();
  }

  void _initializeSensors() {
    // Магнитометр
    _magnetometerSubscription = magnetometerEvents.listen((MagnetometerEvent event) {
      final orientationData = _orientationService.getOrientationData(
        event.x, event.y, event.z,
        _currentValues['accelerometer_x'] ?? 0.0,
        _currentValues['accelerometer_y'] ?? 0.0,
        _currentValues['accelerometer_z'] ?? 0.0,
      );
      
      _currentValues.addAll({
        'magnetometer_x': event.x,
        'magnetometer_y': event.y,
        'magnetometer_z': event.z,
        'magnetic_magnitude': sqrt(event.x * event.x + event.y * event.y + event.z * event.z),
        'azimuth': orientationData['azimuth'],
        'compass_direction': orientationData['compass_direction'],
        'device_orientation': orientationData['device_orientation'],
        'bx_corrected': orientationData['bx_corrected'],
        'by_corrected': orientationData['by_corrected'],
        'bz_corrected': orientationData['bz_corrected'],
      });
      
      _updateCurrentOrientation(orientationData['device_orientation']);
      _emitData();
    });

    // Акселерометр
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _currentValues.addAll({
        'accelerometer_x': event.x,
        'accelerometer_y': event.y,
        'accelerometer_z': event.z,
      });
      
      _detectStep(event);
      _emitData();
    });

    // Гироскоп
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      _currentValues.addAll({
        'gyroscope_x': event.x,
        'gyroscope_y': event.y,
        'gyroscope_z': event.z,
      });
      
      _emitData();
    });
  }

  void _updateCurrentOrientation(String orientation) {
    _currentOrientation = orientation;
  }

  void _detectStep(AccelerometerEvent event) {
    // Простое определение шагов по пикам акселерометра
    double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    
    // TODO: Улучшить алгоритм определения шагов
    if (magnitude > 12.0) { // Порог для определения шага
      _stepCount++;
    }
  }

  void _emitData() {
    if (_isRecording) {
      final dataPoint = Map<String, dynamic>.from(_currentValues);
      
      // Добавляем метаданные
      dataPoint.addAll({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'step_count': _stepCount,
        'floor': _currentFloor,
        'recording_orientation': _currentOrientation,
        'x': _markedX,
        'y': _markedY,
        'poi_type': _poiType,
        'description': _poiDescription,
      });
      
      _dataController.add(dataPoint);
    }
  }

  void startRecording() {
    _isRecording = true;
  }

  void stopRecording() {
    _isRecording = false;
  }

  void setFloor(String floor) {
    _currentFloor = floor;
  }

  void setOrientation(String orientation) {
    _currentOrientation = orientation;
  }

  void markPosition(double x, double y) {
    _markedX = x;
    _markedY = y;
  }

  void setPoiInfo(String? poiType, String? description) {
    _poiType = poiType;
    _poiDescription = description;
  }

  void resetStepCount() {
    _stepCount = 0;
  }

  Map<String, dynamic> getCurrentSensorValues() {
    return Map<String, dynamic>.from(_currentValues)
      ..addAll({
        'step_count': _stepCount,
        'current_orientation': _currentOrientation,
      });
  }

  void dispose() {
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _dataController.close();
  }
}
