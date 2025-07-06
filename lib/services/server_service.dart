// lib/services/server_service.dart - ИСПРАВЛЕННАЯ ВЕРСИЯ
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/users.dart';

class ServerService {
  static const String baseUrl = 'http://5.129.223.192'; // ✅ Ваш сервер
  
  String? _authToken;
  String? _deviceId;
  int? _teamId;
  int? _projectId;
  Map<String, dynamic>? _currentUser;

  // Singleton pattern
  static final ServerService _instance = ServerService._internal();
  factory ServerService() => _instance;
  ServerService._internal();

  // Инициализация сервиса
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _deviceId = prefs.getString('device_id');
    _teamId = prefs.getInt('team_id');
    _projectId = prefs.getInt('project_id');
    
    // Загружаем информацию о текущем пользователе
    await loadCurrentUser();
  }

  // Получение заголовков для запросов
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ================================
  // УПРАВЛЕНИЕ ПОЛЬЗОВАТЕЛЯМИ - ИСПРАВЛЕНО
  // ================================

  // Аутентификация пользователя - ИСПРАВЛЕНО
  Future<bool> loginUser(String login, String password) async {
    final user = await UserConfig.findUser(login, password); // ✅ Добавили await
    
    if (user != null) {
      _currentUser = user; // ✅ Теперь user уже Map, не Future
      
      // Сохраняем в локальном хранилище
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_user_id', user['id']); // ✅ Работает
      await prefs.setString('current_user_name', user['name']); // ✅ Работает
      await prefs.setString('current_user_role', user['role']); // ✅ Работает
      await prefs.setInt('team_id', user['team_id']); // ✅ Работает
      
      _teamId = user['team_id']; // ✅ Работает
      
      // Генерируем device ID если его нет
      if (_deviceId == null) {
        _deviceId = await _generateDeviceId();
        await prefs.setString('device_id', _deviceId!);
      }
      
      print('✅ Пользователь авторизован: ${user['name']} (${user['role']})'); // ✅ Работает
      return true;
    }
    
    return false;
  }
  
  // Загрузка текущего пользователя при инициализации - ИСПРАВЛЕНО
  Future<void> loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('current_user_id');
    
    if (userId != null) {
      _currentUser = await UserConfig.getUserById(userId); // ✅ Добавили await
      _teamId = prefs.getInt('team_id');
    }
  }
  
  // Выход из системы
  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.remove('current_user_name');
    await prefs.remove('current_user_role');
    await prefs.remove('auth_token');
    
    _currentUser = null;
    _authToken = null;
  }

  // ================================
  // ОСНОВНЫЕ API МЕТОДЫ
  // ================================

  // Тестовое подключение к серверу
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      ).timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Ошибка подключения к серверу: $e');
      return false;
    }
  }

  // Получение проектов
  Future<List<dynamic>?> getProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/projects'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Ошибка получения проектов: ${response.body}');
      }
    } catch (e) {
      print('Ошибка получения проектов: $e');
      return null;
    }
  }

  // Создание проекта
  Future<Map<String, dynamic>?> createProject(String name, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/projects'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Ошибка создания проекта: ${response.body}');
      }
    } catch (e) {
      print('Ошибка создания проекта: $e');
      return null;
    }
  }

  // ================================
  // РАБОТА С КОМАНДАМИ
  // ================================

  // Регистрация устройства в команде
  Future<Map<String, dynamic>?> registerDevice(String deviceName, String teamCode) async {
    try {
      final deviceId = _deviceId ?? await _generateDeviceId();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register-device'),
        headers: _headers,
        body: jsonEncode({
          'deviceId': deviceId,
          'deviceName': deviceName,
          'teamCode': teamCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Сохраняем данные аутентификации
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('device_id', deviceId);
        await prefs.setInt('team_id', data['team']['id']);
        await prefs.setInt('project_id', data['team']['project_id']);
        
        _authToken = data['token'];
        _deviceId = deviceId;
        _teamId = data['team']['id'];
        _projectId = data['team']['project_id'];
        
        return data;
      } else {
        throw Exception('Ошибка регистрации: ${response.body}');
      }
    } catch (e) {
      print('Ошибка регистрации устройства: $e');
      return null;
    }
  }

  // Получение участников команды
  Future<List<dynamic>?> getTeamMembers() async {
    if (_teamId == null) return null;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/teams/$_teamId/members'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Ошибка получения команды: ${response.body}');
      }
    } catch (e) {
      print('Ошибка получения команды: $e');
      return null;
    }
  }

  // ================================
  // ОТПРАВКА ДАННЫХ ДАТЧИКОВ
  // ================================

  // Отправка данных с информацией о пользователе
  Future<bool> uploadSensorDataWithUser(List<Map<String, dynamic>> sensorData) async {
    if (_projectId == null) {
      print('⚠️ Project ID не установлен, используем ID=1');
      _projectId = 1;
    }
    
    try {
      // Добавляем информацию о пользователе к каждой точке данных
      final enrichedData = sensorData.map((point) => {
        ...point,
        'collector_id': _currentUser?['id'],
        'collector_name': _currentUser?['name'] ?? 'Неизвестный',
        'collector_role': _currentUser?['role'] ?? 'collector',
        'collected_at': DateTime.now().toIso8601String(),
      }).toList();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/sensor-data/batch'),
        headers: _headers,
        body: jsonEncode({
          'deviceId': _deviceId ?? await _generateDeviceId(),
          'projectId': _projectId,
          'floorId': 1,
          'data': enrichedData,
          'user_info': {
            'id': _currentUser?['id'],
            'name': _currentUser?['name'] ?? 'Неизвестный',
            'role': _currentUser?['role'] ?? 'collector',
          }
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('✅ Отправлено ${result['inserted']} точек данных на сервер');
        if (_currentUser != null) {
          print('👤 Сборщик: ${_currentUser!['name']}');
        }
        return true;
      } else {
        throw Exception('Ошибка отправки данных: ${response.body}');
      }
      
    } catch (e) {
      print('Ошибка отправки данных: $e');
      return false;
    }
  }

  // Стандартная отправка данных (для совместимости)
  Future<bool> uploadSensorDataBatch(List<Map<String, dynamic>> sensorData) async {
    return await uploadSensorDataWithUser(sensorData);
  }

  // ================================
  // РАБОТА С ПЛАНАМИ ЗДАНИЙ
  // ================================

  Future<List<dynamic>?> getFloors(int projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/projects/$projectId/floors'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Ошибка получения этажей: ${response.body}');
      }
    } catch (e) {
      print('Ошибка получения этажей: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> uploadFloorPlan(int projectId, int floorNumber, File planFile) async {
    try {
      print('🚀 Начинаем загрузку плана: проект=$projectId, этаж=$floorNumber');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/projects/$projectId/floors'),
      );
      
      // Добавляем заголовки без Content-Type (multipart установит сам)
      final headers = Map<String, String>.from(_headers);
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      
      request.fields['floorNumber'] = floorNumber.toString();
      request.files.add(await http.MultipartFile.fromPath('floorPlan', planFile.path));

      print('📤 Отправляем запрос на: ${request.url}');
      print('📋 Поля: ${request.fields}');
      print('📁 Файл: ${planFile.path} (${await planFile.length()} байт)');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Ответ сервера: ${response.statusCode}');
      print('📄 Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Ошибка сервера ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Ошибка загрузки плана: $e');
      return null;
    }
  }

  // ================================
  // LOCALIZATION API
  // ================================

  Future<Map<String, dynamic>?> getMagneticMap(int projectId, int floorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/localization/$projectId/$floorId/magnetic-map'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Ошибка получения магнитной карты: ${response.body}');
      }
    } catch (e) {
      print('Ошибка получения магнитной карты: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getPoiData(int projectId, int floorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/localization/$projectId/$floorId/poi-data'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Ошибка получения POI данных: ${response.body}');
      }
    } catch (e) {
      print('Ошибка получения POI данных: $e');
      return null;
    }
  }

  // ================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ================================

  Future<String> _generateDeviceId() async {
    // Генерируем уникальный ID устройства
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    final platform = Platform.isAndroid ? 'android' : 'ios';
    return 'device_${platform}_${timestamp}_$random';
  }

  // ================================
  // ГЕТТЕРЫ
  // ================================

  String? get deviceId => _deviceId;
  int? get teamId => _teamId;
  int? get projectId => _projectId;
  bool get isAuthenticated => _authToken != null;
  String get serverUrl => baseUrl;
  
  // Геттеры для пользователя
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get currentUserName => _currentUser?['name'];
  String? get currentUserRole => _currentUser?['role'];
  int? get currentUserId => _currentUser?['id'];
  bool get isLoggedIn => _currentUser != null;
  bool get isCoordinator => _currentUser?['role'] == 'coordinator';
  bool get isCollector => _currentUser?['role'] == 'collector';
}
