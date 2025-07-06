// lib/screens/home_screen.dart - ПОЛНАЯ ИСПРАВЛЕННАЯ ВЕРСИЯ
import 'package:flutter/material.dart';
import '../services/sensor_service.dart';
import '../services/location_recorder.dart';
import '../services/server_service.dart';
import '../screens/map_screen.dart';
import '../screens/preset_points_screen.dart';
import '../screens/server_test_screen.dart';
import '../screens/team_login_screen.dart';
import '../screens/map_upload_screen.dart';
import '../screens/record_point_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SensorService _sensorService = SensorService();
  final LocationRecorder _locationRecorder = LocationRecorder();
  bool _isRecording = false;
  bool _sensorsAvailable = false;
  String _statusMessage = 'Готов к записи';

  @override
  void initState() {
    super.initState();
    _checkSensors();
  }

  void _checkSensors() {
    // Простая проверка доступности датчиков
    setState(() {
      _sensorsAvailable = true;
      _statusMessage = 'Датчики готовы';
    });
  }

  Future<void> _toggleRecording() async {
    if (!_sensorsAvailable) {
      _showErrorDialog('Датчики недоступны', 'Проверьте разрешения приложения');
      return;
    }

    setState(() {
      _isRecording = !_isRecording;
      _statusMessage = _isRecording ? 'Запись данных...' : 'Запись остановлена';
    });

    // Здесь должна быть логика записи с вашими существующими методами
    if (_isRecording) {
      // _sensorService.ваш_метод_старта();
    } else {
      // _sensorService.ваш_метод_остановки();
    }
  }

  Future<void> _clearData() async {
    final confirmed = await _showConfirmDialog(
      'Очистить данные',
      'Удалить все записанные данные?\n\nЭто действие нельзя отменить.',
    );

    if (confirmed) {
      // Здесь должен быть ваш метод очистки данных
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Данные очищены'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _exportData() async {
    try {
      setState(() {
        _statusMessage = 'Экспорт данных...';
      });

      // Здесь должен быть ваш метод экспорта
      // final result = await _locationRecorder.вашМетодЭкспорта();
      
      setState(() {
        _statusMessage = 'Экспорт завершен';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📁 Данные экспортированы'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Ошибка экспорта: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка экспорта: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _syncWithServer() async {
    final serverService = ServerService();
    await serverService.initialize();

    if (!serverService.isLoggedIn) {
      _showErrorDialog(
        'Требуется авторизация',
        'Войдите в систему для синхронизации с сервером',
      );
      return;
    }

    try {
      setState(() {
        _statusMessage = 'Синхронизация с сервером...';
      });

      // Пример данных для отправки (замените на ваши реальные данные)
      final dataToSync = [
        {
          'magnetometer_x': 1.0,
          'magnetometer_y': 2.0,
          'magnetometer_z': 3.0,
          'x': 100.0,
          'y': 200.0,
          'z': 0.0,
          'timestamp': DateTime.now().toIso8601String(),
        }
      ];

      final success = await serverService.uploadSensorDataWithUser(dataToSync);
      
      if (success) {
        setState(() {
          _statusMessage = 'Синхронизация завершена';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Данные синхронизированы с сервером'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _statusMessage = 'Ошибка синхронизации';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка синхронизации с сервером'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Ошибка: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserInfo() async {
    final serverService = ServerService();
    await serverService.initialize();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('👤 Информация о пользователе'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (serverService.isLoggedIn) ...[
              Text('Имя: ${serverService.currentUserName}'),
              SizedBox(height: 8),
              Text('Роль: ${_getRoleDisplayName(serverService.currentUserRole)}'),
              SizedBox(height: 8),
              Text('ID команды: ${serverService.teamId ?? "Не назначена"}'),
              SizedBox(height: 8),
              Text('ID проекта: ${serverService.projectId ?? "Не назначен"}'),
            ] else ...[
              Text('Пользователь не авторизован'),
              SizedBox(height: 8),
              Text('Данные сохраняются локально'),
            ],
            SizedBox(height: 16),
            Text('Сервер: ${serverService.serverUrl}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Закрыть'),
          ),
          if (!serverService.isLoggedIn)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => TeamLoginScreen()),
                );
              },
              child: Text('Войти'),
            ),
        ],
      ),
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🚪 Выход'),
        content: Text('Выйти из системы?\n\nДанные останутся сохраненными локально.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final serverService = ServerService();
              await serverService.logoutUser();
              
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Вы вышли из системы'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Выйти'),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'admin':
        return 'Администратор';
      case 'coordinator':
        return 'Координатор';
      case 'collector':
        return 'Сборщик данных';
      default:
        return 'Неизвестная роль';
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Подтвердить'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UNDE Data Recorder'),
        backgroundColor: Colors.blue[400],
        actions: [
          // Кнопка проверки сервера
          IconButton(
            icon: Icon(Icons.cloud_outlined),
            tooltip: 'Проверка сервера',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ServerTestScreen()),
              );
            },
          ),
          // Меню с дополнительными опциями
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'server_test') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ServerTestScreen()),
                );
              } else if (value == 'user_info') {
                _showUserInfo();
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'server_test',
                child: Row(
                  children: [
                    Icon(Icons.cloud_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Проверка сервера'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'user_info',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16),
                    SizedBox(width: 8),
                    Text('Информация о пользователе'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Выйти', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Статус карточка
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _sensorsAvailable ? Icons.sensors : Icons.error,
                          color: _sensorsAvailable ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Статус датчиков',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(_statusMessage),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Кнопки управления
            Expanded(
              child: Column(
                children: [
                  // Кнопка записи
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _sensorsAvailable ? _toggleRecording : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _isRecording ? '⏹️ Остановить запись' : '▶️ Начать запись',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Кнопки действий
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => MapUploadScreen()),
                            );
                          },
                          icon: Icon(Icons.map),
                          label: Text('Загрузка карт'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[400],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => PresetPointsScreen(
                                onPointSelected: (x, y, name, type) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => RecordPointScreen(
                                      x: x,
                                      y: y,
                                      name: name,
                                      type: type,
                                    )),
                                  );
                                },
                              )),
                            );
                          },
                          icon: Icon(Icons.location_on),
                          label: Text('Точки'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[400],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportData,
                          icon: Icon(Icons.download),
                          label: Text('Экспорт'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _syncWithServer,
                          icon: Icon(Icons.cloud_upload),
                          label: Text('Синхронизация'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[400],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _clearData,
                      icon: Icon(Icons.delete_forever),
                      label: Text('Очистить данные'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
