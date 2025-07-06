// lib/screens/record_point_screen.dart
import 'package:flutter/material.dart';

class RecordPointScreen extends StatefulWidget {
  final double x;
  final double y;
  final String name;
  final String type;

  const RecordPointScreen({
    Key? key,
    required this.x,
    required this.y,
    required this.name,
    required this.type,
  }) : super(key: key);

  @override
  _RecordPointScreenState createState() => _RecordPointScreenState();
}

class _RecordPointScreenState extends State<RecordPointScreen> {
  bool _isRecording = false;
  String _statusMessage = 'Готов к записи';

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      _statusMessage = _isRecording 
        ? 'Запись данных в точке...' 
        : 'Запись остановлена';
    });

    if (_isRecording) {
      // Здесь будет логика записи датчиков в этой точке
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📍 Запись в точке'),
        backgroundColor: Colors.green[400],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Информация о точке',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Text('Название: ${widget.name}'),
                    Text('Тип: ${widget.type}'),
                    Text('Координаты: (${widget.x}, ${widget.y})'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статус записи',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(_statusMessage),
                    if (_isRecording) ...[
                      SizedBox(height: 8),
                      LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            Spacer(),

            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _toggleRecording,
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

            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Запись в точке "${widget.name}" завершена'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[400],
                foregroundColor: Colors.white,
              ),
              child: Text('Завершить и вернуться'),
            ),
          ],
        ),
      ),
    );
  }
}
