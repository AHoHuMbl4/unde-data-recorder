import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum DrawingTool { pen, eraser, line, rectangle }

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DrawingTool tool;
  final bool isErased;
  
  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
    this.isErased = false,
  });
  
  DrawingStroke copyWith({bool? isErased}) {
    return DrawingStroke(
      points: points,
      color: color,
      strokeWidth: strokeWidth,
      tool: tool,
      isErased: isErased ?? this.isErased,
    );
  }

  // Сериализация для сохранения
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'tool': tool.toString(),
      'isErased': isErased,
    };
  }

  // Десериализация при загрузке
  static DrawingStroke fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      points: (json['points'] as List).map((p) => Offset(p['dx'], p['dy'])).toList(),
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
      tool: DrawingTool.values.firstWhere((t) => t.toString() == json['tool']),
      isErased: json['isErased'] ?? false,
    );
  }
}

class MapScreen extends StatefulWidget {
  final Function(double x, double y) onPointSelected;
  
  const MapScreen({Key? key, required this.onPointSelected}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<DrawingStroke> _strokes = [];
  final List<MapPoint> _markedPoints = [];
  Offset? _selectedPoint;
  
  // Текущие настройки инструментов
  DrawingTool _currentTool = DrawingTool.pen;
  Color _currentColor = Colors.blue;
  double _currentStrokeWidth = 2.0;
  
  // Временные данные для рисования
  List<Offset> _currentStroke = [];
  Offset? _startPoint;

  @override
  void initState() {
    super.initState();
    _loadMap();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Редактор карты'),
        backgroundColor: Colors.blue[400],
        actions: [
          IconButton(
            icon: Icon(Icons.undo),
            onPressed: _strokes.isNotEmpty ? _undoLastStroke : null,
            tooltip: 'Отменить',
          ),
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _clearMap,
            tooltip: 'Очистить всё',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveMapManual,
            tooltip: 'Сохранить карту',
          ),
        ],
      ),
      body: Column(
        children: [
          // Инструкция
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            color: Colors.blue[50],
            child: Text(
              _currentTool == DrawingTool.eraser 
                ? '🗑️ Режим ластика: проведите по линиям чтобы стереть их'
                : '🖊️ Нарисуйте план помещения, затем нажмите в точке для установки координат',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.blue[800]),
            ),
          ),
          
          // Панель инструментов
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[100],
            child: Row(
              children: [
                // Инструменты рисования
                _buildToolButton(DrawingTool.pen, Icons.edit, 'Кисть'),
                _buildToolButton(DrawingTool.eraser, Icons.cleaning_services, 'Ластик'),
                _buildToolButton(DrawingTool.line, Icons.remove, 'Линия'),
                _buildToolButton(DrawingTool.rectangle, Icons.crop_square, 'Прямоугольник'),
                
                SizedBox(width: 8),
                VerticalDivider(width: 1),
                SizedBox(width: 8),
                
                // Цвета
                if (_currentTool != DrawingTool.eraser) ...[
                  _buildColorButton(Colors.blue),
                  _buildColorButton(Colors.red),
                  _buildColorButton(Colors.green),
                  _buildColorButton(Colors.orange),
                  _buildColorButton(Colors.purple),
                  _buildColorButton(Colors.black),
                ],
                
                Spacer(),
                
                // Информация о карте
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Штрихов: ${_strokes.length} | Точек: ${_markedPoints.length}',
                    style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                  ),
                ),
                
                SizedBox(width: 8),
                
                // Толщина линии
                if (_currentTool != DrawingTool.eraser) ...[
                  Text('Толщина:', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Container(
                    width: 60,
                    child: Slider(
                      value: _currentStrokeWidth,
                      min: 1.0,
                      max: 8.0,
                      divisions: 7,
                      onChanged: (value) {
                        setState(() {
                          _currentStrokeWidth = value;
                        });
                      },
                    ),
                  ),
                ],
              ],
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
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTapDown: _onTapDown,
                child: CustomPaint(
                  painter: MapPainter(
                    strokes: _strokes,
                    markedPoints: _markedPoints,
                    selectedPoint: _selectedPoint,
                    currentStroke: _currentStroke,
                    currentTool: _currentTool,
                    currentColor: _currentColor,
                    currentStrokeWidth: _currentStrokeWidth,
                    startPoint: _startPoint,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          
          // Панель выбора точки
          if (_selectedPoint != null)
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.all(8),
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
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedPoint = null;
                      });
                    },
                    child: Text('Отмена'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolButton(DrawingTool tool, IconData icon, String tooltip) {
    final isSelected = _currentTool == tool;
    return Container(
      margin: EdgeInsets.only(right: 4),
      child: Material(
        color: isSelected ? Colors.blue[100] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _currentTool = tool;
              _selectedPoint = null; // Сброс выбранной точки при смене инструмента
            });
          },
          child: Container(
            padding: EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.blue[700] : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _currentColor == color;
    return Container(
      margin: EdgeInsets.only(right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _currentColor = color;
            });
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected 
                ? Border.all(color: Colors.black, width: 2)
                : Border.all(color: Colors.grey[300]!, width: 1),
            ),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (_currentTool == DrawingTool.line || _currentTool == DrawingTool.rectangle) {
      _startPoint = details.localPosition;
    } else {
      _currentStroke = [details.localPosition];
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      if (_currentTool == DrawingTool.eraser) {
        _eraseAt(details.localPosition);
      } else if (_currentTool == DrawingTool.line || _currentTool == DrawingTool.rectangle) {
        // Для линии и прямоугольника обновляем только конечную точку
        _currentStroke = [_startPoint!, details.localPosition];
      } else {
        _currentStroke.add(details.localPosition);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke.isNotEmpty) {
      setState(() {
        _strokes.add(DrawingStroke(
          points: List.from(_currentStroke),
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
          tool: _currentTool,
        ));
        _currentStroke.clear();
        _startPoint = null;
      });
      
      // Автосохранение при каждом штрихе
      _saveMap();
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (_currentTool == DrawingTool.pen) {
      // Для установки точек координат
      setState(() {
        _selectedPoint = details.localPosition;
      });
    }
  }

  void _eraseAt(Offset position) {
    const double eraserRadius = 15.0;
    
    for (int i = 0; i < _strokes.length; i++) {
      if (_strokes[i].isErased) continue;
      
      for (Offset point in _strokes[i].points) {
        double distance = math.sqrt(
          math.pow(point.dx - position.dx, 2) + 
          math.pow(point.dy - position.dy, 2)
        );
        
        if (distance <= eraserRadius) {
          setState(() {
            _strokes[i] = _strokes[i].copyWith(isErased: true);
          });
          break;
        }
      }
    }
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
      
      // Сохраняем карту при добавлении новой точки
      _saveMap();
      
      // Передаем координаты обратно в главный экран
      widget.onPointSelected(_selectedPoint!.dx, _selectedPoint!.dy);
      
      // Возвращаемся на главный экран
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveMap() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mapFile = File('${directory.path}/indoor_map.json');
      
      final mapData = {
        'strokes': _strokes.map((s) => s.toJson()).toList(),
        'markedPoints': _markedPoints.map((p) => p.toJson()).toList(),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
      
      await mapFile.writeAsString(jsonEncode(mapData));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Карта сохранена: ${_strokes.length} штрихов, ${_markedPoints.length} точек'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения карты: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadMap() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mapFile = File('${directory.path}/indoor_map.json');
      
      if (await mapFile.exists()) {
        final mapContent = await mapFile.readAsString();
        final mapData = jsonDecode(mapContent);
        
        setState(() {
          _strokes.clear();
          _markedPoints.clear();
          
          // Загружаем штрихи
          for (final strokeData in mapData['strokes']) {
            _strokes.add(DrawingStroke.fromJson(strokeData));
          }
          
          // Загружаем отмеченные точки
          for (final pointData in mapData['markedPoints']) {
            _markedPoints.add(MapPoint.fromJson(pointData));
          }
        });
        
        print('Карта загружена: ${_strokes.length} штрихов, ${_markedPoints.length} точек');
      }
    } catch (e) {
      print('Ошибка загрузки карты: $e');
    }
  }

  Future<void> _clearMap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Очистить карту?'),
        content: Text('Это удалит все нарисованные элементы и отмеченные точки. Действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Очистить'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _strokes.clear();
        _markedPoints.clear();
        _selectedPoint = null;
        _currentStroke.clear();
      });
      
      // Сохраняем пустую карту
      await _saveMap();
    }
  }

  void _undoLastStroke() {
    setState(() {
      if (_strokes.isNotEmpty) {
        _strokes.removeLast();
        // Автосохранение при отмене
        _saveMap();
      }
    });
  }

  void _saveMapManual() {
    // Ручное сохранение через кнопку
    _saveMap();
  }
}

class MapPoint {
  final Offset position;
  final DateTime timestamp;
  final String? description;
  
  MapPoint(this.position, this.timestamp, {this.description});

  Map<String, dynamic> toJson() {
    return {
      'position': {'dx': position.dx, 'dy': position.dy},
      'timestamp': timestamp.millisecondsSinceEpoch,
      'description': description,
    };
  }

  static MapPoint fromJson(Map<String, dynamic> json) {
    return MapPoint(
      Offset(json['position']['dx'], json['position']['dy']),
      DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      description: json['description'],
    );
  }
}

class MapPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<MapPoint> markedPoints;
  final Offset? selectedPoint;
  final List<Offset> currentStroke;
  final DrawingTool currentTool;
  final Color currentColor;
  final double currentStrokeWidth;
  final Offset? startPoint;

  MapPainter({
    required this.strokes,
    required this.markedPoints,
    this.selectedPoint,
    required this.currentStroke,
    required this.currentTool,
    required this.currentColor,
    required this.currentStrokeWidth,
    this.startPoint,
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

    // Рисуем все штрихи
    for (final stroke in strokes) {
      if (!stroke.isErased) {
        _drawStroke(canvas, stroke);
      }
    }

    // Рисуем текущий штрих
    if (currentStroke.isNotEmpty) {
      final tempStroke = DrawingStroke(
        points: currentStroke,
        color: currentColor,
        strokeWidth: currentStrokeWidth,
        tool: currentTool,
      );
      _drawStroke(canvas, tempStroke, isPreview: true);
    }

    // Рисуем отмеченные точки
    for (final markedPoint in markedPoints) {
      _drawMarker(canvas, markedPoint.position, Colors.green, 8);
    }

    // Рисуем выбранную точку
    if (selectedPoint != null) {
      _drawMarker(canvas, selectedPoint!, Colors.red, 10);
      _drawCoordinates(canvas, selectedPoint!);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke, {bool isPreview = false}) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = isPreview ? stroke.color.withOpacity(0.7) : stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (stroke.tool) {
      case DrawingTool.pen:
      case DrawingTool.eraser:
        _drawFreehand(canvas, stroke.points, paint);
        break;
      case DrawingTool.line:
        if (stroke.points.length >= 2) {
          canvas.drawLine(stroke.points.first, stroke.points.last, paint);
        }
        break;
      case DrawingTool.rectangle:
        if (stroke.points.length >= 2) {
          final rect = Rect.fromPoints(stroke.points.first, stroke.points.last);
          canvas.drawRect(rect, paint);
        }
        break;
    }
  }

  void _drawFreehand(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      if (points.isNotEmpty) {
        canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      }
      return;
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
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
