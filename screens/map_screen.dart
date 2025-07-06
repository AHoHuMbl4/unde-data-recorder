import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class MapScreen extends StatefulWidget {
  final Function(double x, double y) onPointSelected;
  
  const MapScreen({Key? key, required this.onPointSelected}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<Offset> _points = [];
  final List<MapPoint> _markedPoints = [];
  Offset? _selectedPoint;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Карта помещения'),
        backgroundColor: Colors.blue[400],
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _clearMap,
            tooltip: 'Очистить карту',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveMap,
            tooltip: 'Сохранить карту',
          ),
        ],
      ),
      body: Column(
        children: [
          // Инструкция
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            color: Colors.blue[50],
            child: Text(
              '🖊️ Нарисуйте план помещения, затем нажмите в нужной точке для установки координат',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.blue[800]),
            ),
          ),
          
          // Холст для рисования
          Expanded(
            child: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _points.add(details.localPosition);
                  });
                },
                onTapDown: (details) {
                  _onMapTapped(details.localPosition);
                },
                child: CustomPaint(
                  painter: MapPainter(
                    points: _points,
                    markedPoints: _markedPoints,
                    selectedPoint: _selectedPoint,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          
          // Панель управления
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                if (_selectedPoint != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Выбрана точка: X=${_selectedPoint!.dx.toInt()}, Y=${_selectedPoint!.dy.toInt()}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _confirmPoint,
                          child: Text('Подтвердить'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _points.isNotEmpty ? _undoLastStroke : null,
                        icon: Icon(Icons.undo),
                        label: Text('Отменить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _clearMap,
                        icon: Icon(Icons.clear),
                        label: Text('Очистить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
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

  void _onMapTapped(Offset position) {
    setState(() {
      _selectedPoint = position;
    });
  }

  void _confirmPoint() {
    if (_selectedPoint != null) {
      setState(() {
        _markedPoints.add(MapPoint(_selectedPoint!, DateTime.now()));
      });
      
      // Передаем координаты обратно в главный экран
      widget.onPointSelected(_selectedPoint!.dx, _selectedPoint!.dy);
      
      // Возвращаемся на главный экран
      Navigator.of(context).pop();
    }
  }

  void _clearMap() {
    setState(() {
      _points.clear();
      _markedPoints.clear();
      _selectedPoint = null;
    });
  }

  void _undoLastStroke() {
    setState(() {
      if (_points.isNotEmpty) {
        // Удаляем последние 10 точек (примерно один штрих)
        int pointsToRemove = _points.length > 10 ? 10 : _points.length;
        _points.removeRange(_points.length - pointsToRemove, _points.length);
      }
    });
  }

  void _saveMap() {
    // TODO: Сохранение карты в файл
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Карта сохранена (функция в разработке)')),
    );
  }
}

class MapPoint {
  final Offset position;
  final DateTime timestamp;
  
  MapPoint(this.position, this.timestamp);
}

class MapPainter extends CustomPainter {
  final List<Offset> points;
  final List<MapPoint> markedPoints;
  final Offset? selectedPoint;

  MapPainter({
    required this.points,
    required this.markedPoints,
    this.selectedPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Рисуем фон
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Рисуем сетку
    _drawGrid(canvas, size);

    // Рисуем линии карты
    if (points.isNotEmpty) {
      final paint = Paint()
        ..color = Colors.blue[700]!
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    // Рисуем отмеченные точки
    for (final markedPoint in markedPoints) {
      _drawMarker(canvas, markedPoint.position, Colors.green, 8);
    }

    // Рисуем выбранную точку
    if (selectedPoint != null) {
      _drawMarker(canvas, selectedPoint!, Colors.red, 10);
      
      // Рисуем координаты
      _drawCoordinates(canvas, selectedPoint!);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    const gridSize = 20.0;

    // Вертикальные линии
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Горизонтальные линии
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawMarker(Canvas canvas, Offset position, Color color, double radius) {
    final paint = Paint()..color = color;
    canvas.drawCircle(position, radius, paint);
    
    // Белая обводка
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(position, radius, borderPaint);
  }

  void _drawCoordinates(Canvas canvas, Offset position) {
    final textStyle = ui.TextStyle(
      color: Colors.black,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
    
    final paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.left,
    );
    
    final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText('(${position.dx.toInt()}, ${position.dy.toInt()})');
    
    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: 100));
    
    // Рисуем текст рядом с точкой
    canvas.drawParagraph(
      paragraph,
      Offset(position.dx + 15, position.dy - 10),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
