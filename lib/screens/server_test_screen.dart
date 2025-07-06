// lib/screens/server_test_screen.dart
import 'package:flutter/material.dart';
import '../services/server_service.dart';

class ServerTestScreen extends StatefulWidget {
  @override
  _ServerTestScreenState createState() => _ServerTestScreenState();
}

class _ServerTestScreenState extends State<ServerTestScreen> {
  final ServerService _serverService = ServerService();
  bool _isLoading = true;
  bool _isConnected = false;
  List<dynamic>? _projects;
  String _statusMessage = 'Проверяем подключение...';

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Инициализация...';
    });

    try {
      // Инициализируем сервис
      await _serverService.initialize();
      
      setState(() {
        _statusMessage = 'Проверяем подключение к серверу...';
      });

      // Тестируем подключение
      final connected = await _serverService.testConnection();
      
      setState(() {
        _isConnected = connected;
        _statusMessage = connected ? 'Сервер доступен!' : 'Сервер недоступен';
      });

      if (connected) {
        setState(() {
          _statusMessage = 'Загружаем проекты...';
        });

        // Получаем проекты
        final projects = await _serverService.getProjects();
        
        setState(() {
          _projects = projects;
          _statusMessage = projects != null 
            ? 'Проекты загружены (${projects.length})' 
            : 'Ошибка загрузки проектов';
        });
      }
      
    } catch (e) {
      setState(() {
        _isConnected = false;
        _statusMessage = 'Ошибка: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Тест подключения к серверу'),
        backgroundColor: _isConnected ? Colors.green : Colors.red,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статус подключения
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.check_circle : Icons.error,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Статус подключения',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Сервер: ${_serverService.serverUrl}'),
                    SizedBox(height: 4),
                    Text(_statusMessage),
                    if (_isLoading) ...[
                      SizedBox(height: 8),
                      LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Проекты
            if (_projects != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Проекты на сервере (${_projects!.length})',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      ..._projects!.map((project) => Card(
                        color: Colors.blue[50],
                        child: ListTile(
                          title: Text(project['name'] ?? 'Без названия'),
                          subtitle: Text(project['description'] ?? 'Без описания'),
                          leading: CircleAvatar(
                            child: Text('${project['id']}'),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
            ],

            Spacer(),

            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testConnection,
                    icon: Icon(Icons.refresh),
                    label: Text('Повторить тест'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                    icon: Icon(Icons.home),
                    label: Text('Главный экран'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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
