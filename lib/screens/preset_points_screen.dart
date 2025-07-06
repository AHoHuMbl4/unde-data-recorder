import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'map_screen.dart';

class PresetPointsScreen extends StatefulWidget {
  final Function(double x, double y, String name, String type) onPointSelected;
  
  const PresetPointsScreen({Key? key, required this.onPointSelected}) : super(key: key);

  @override
  _PresetPointsScreenState createState() => _PresetPointsScreenState();
}

class _PresetPointsScreenState extends State<PresetPointsScreen> {
  List<PresetPoint> _points = [];
  String _selectedFilter = 'Все';
  
  final List<String> _pointTypes = [
    'Все', 'Магазин', 'Кафе', 'Эскалатор', 'Лифт', 'Туалет', 
    'Банкомат', 'Информация', 'Выход', 'Парковка', 'Коридор', 'Перекресток'
  ];

  @override
  void initState() {
    super.initState();
    _loadPresetPoints();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPoints = _selectedFilter == 'Все' 
        ? _points 
        : _points.where((p) => p.type == _selectedFilter).toList();
    
    final completedCount = _points.where((p) => p.isCompleted).length;
    final totalCount = _points.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Предустановленные точки'),
        backgroundColor: Colors.indigo[400],
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addNewPoint,
            tooltip: 'Добавить точку',
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _exportPoints,
            tooltip: 'Экспорт',
          ),
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: _importPoints,
            tooltip: 'Импорт',
          ),
        ],
      ),
      body: Column(
        children: [
          // Статистика прогресса
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.indigo[50],
            child: Column(
              children: [
                Text(
                  'Прогресс сбора данных',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: totalCount > 0 ? completedCount / totalCount : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                SizedBox(height: 8),
                Text(
                  '$completedCount из $totalCount точек завершено (${totalCount > 0 ? (completedCount * 100 / totalCount).toStringAsFixed(1) : '0'}%)',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // Фильтр по типам
          Container(
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pointTypes.length,
              itemBuilder: (context, index) {
                final type = _pointTypes[index];
                final isSelected = type == _selectedFilter;
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = type;
                      });
                    },
                    selectedColor: Colors.indigo[100],
                  ),
                );
              },
            ),
          ),

          // Список точек
          Expanded(
            child: filteredPoints.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredPoints.length,
                    itemBuilder: (context, index) {
                      final point = filteredPoints[index];
                      return _buildPointCard(point);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPoint,
        backgroundColor: Colors.indigo,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Добавить новую точку',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_searching, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Нет предустановленных точек',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Добавьте точки для систематического сбора данных',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addNewPoint,
            icon: Icon(Icons.add),
            label: Text('Добавить первую точку'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointCard(PresetPoint point) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _selectPoint(point),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: point.isCompleted ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      point.isCompleted ? '✅ Завершено' : '⏳ Ожидает',
                      style: TextStyle(
                        fontSize: 12,
                        color: point.isCompleted ? Colors.green[800] : Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    point.type,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                point.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (point.description.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  point.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                  SizedBox(width: 4),
                  Text(
                    'X: ${point.x.toInt()}, Y: ${point.y.toInt()}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Spacer(),
                  if (point.lastRecorded != null) ...[
                    Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      _formatDate(point.lastRecorded!),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _selectPoint(point),
                      icon: Icon(Icons.play_arrow, size: 16),
                      label: Text('ЗАПИСАТЬ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: point.isCompleted ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _editPoint(point),
                    icon: Icon(Icons.edit, size: 20),
                    tooltip: 'Редактировать',
                  ),
                  IconButton(
                    onPressed: () => _deletePoint(point),
                    icon: Icon(Icons.delete, size: 20, color: Colors.red),
                    tooltip: 'Удалить',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectPoint(PresetPoint point) {
    widget.onPointSelected(point.x, point.y, point.name, point.type);
    
    // Отмечаем точку как завершенную
    setState(() {
      final index = _points.indexWhere((p) => p.id == point.id);
      if (index != -1) {
        _points[index] = point.copyWith(
          isCompleted: true,
          lastRecorded: DateTime.now(),
        );
      }
    });
    
    _savePresetPoints();
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Выбрана точка "${point.name}" (${point.x.toInt()}, ${point.y.toInt()})'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addNewPoint() {
    _showPointDialog();
  }

  void _editPoint(PresetPoint point) {
    _showPointDialog(point: point);
  }

  void _deletePoint(PresetPoint point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить точку?'),
        content: Text('Удалить точку "${point.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _points.removeWhere((p) => p.id == point.id);
              });
              _savePresetPoints();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Точка "${point.name}" удалена')),
              );
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _selectCoordinatesOnMap(Function(double x, double y) onCoordinatesSelected) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapScreen(
          onPointSelected: (x, y) {
            onCoordinatesSelected(x, y);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Координаты выбраны: (${x.toInt()}, ${y.toInt()})'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showPointDialog({PresetPoint? point}) {
    final isEdit = point != null;
    final nameController = TextEditingController(text: point?.name ?? '');
    final descController = TextEditingController(text: point?.description ?? '');
    final xController = TextEditingController(text: point?.x.toString() ?? '');
    final yController = TextEditingController(text: point?.y.toString() ?? '');
    String selectedType = point?.type ?? 'Магазин';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Редактировать точку' : 'Новая точка'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Название точки',
                    hintText: 'Например: "Центральный вход"',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Тип точки',
                    border: OutlineInputBorder(),
                  ),
                  items: _pointTypes.skip(1).map((type) => 
                    DropdownMenuItem(value: type, child: Text(type)),
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                SizedBox(height: 12),
                
                // Координаты с кнопкой выбора на карте
                Text('Координаты:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: xController,
                        decoration: InputDecoration(
                          labelText: 'X',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        readOnly: true,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: yController,
                        decoration: InputDecoration(
                          labelText: 'Y',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                
                // Кнопка выбора на карте
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _selectCoordinatesOnMap((x, y) {
                        setState(() {
                          xController.text = x.toInt().toString();
                          yController.text = y.toInt().toString();
                        });
                      });
                    },
                    icon: Icon(Icons.map),
                    label: Text('ВЫБРАТЬ НА КАРТЕ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                
                SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Описание (необязательно)',
                    hintText: 'Дополнительная информация о точке',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                final name = nameController.text.trim();
                final x = double.tryParse(xController.text);
                final y = double.tryParse(yController.text);
                
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Введите название точки')),
                  );
                  return;
                }
                
                if (x == null || y == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Выберите координаты на карте')),
                  );
                  return;
                }

                final newPoint = PresetPoint(
                  id: point?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  x: x,
                  y: y,
                  type: selectedType,
                  description: descController.text.trim(),
                  isCompleted: point?.isCompleted ?? false,
                  lastRecorded: point?.lastRecorded,
                );

                setState(() {
                  if (isEdit) {
                    final index = _points.indexWhere((p) => p.id == point!.id);
                    if (index != -1) {
                      _points[index] = newPoint;
                    }
                  } else {
                    _points.add(newPoint);
                  }
                });

                _savePresetPoints();
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Точка обновлена' : 'Точка добавлена'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(isEdit ? 'Обновить' : 'Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportPoints() {
    // TODO: Экспорт точек в CSV/JSON
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🚧 Экспорт - в разработке')),
    );
  }

  void _importPoints() {
    // TODO: Импорт точек из CSV/JSON
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🚧 Импорт - в разработке')),
    );
  }

  Future<void> _loadPresetPoints() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/preset_points.json');
      
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> data = jsonDecode(content);
        
        setState(() {
          _points = data.map((item) => PresetPoint.fromJson(item)).toList();
        });
      }
    } catch (e) {
      print('Ошибка загрузки точек: $e');
    }
  }

  Future<void> _savePresetPoints() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/preset_points.json');
      
      final data = _points.map((point) => point.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Ошибка сохранения точек: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class PresetPoint {
  final String id;
  final String name;
  final double x;
  final double y;
  final String type;
  final String description;
  final bool isCompleted;
  final DateTime? lastRecorded;

  PresetPoint({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.type,
    required this.description,
    this.isCompleted = false,
    this.lastRecorded,
  });

  PresetPoint copyWith({
    bool? isCompleted,
    DateTime? lastRecorded,
  }) {
    return PresetPoint(
      id: id,
      name: name,
      x: x,
      y: y,
      type: type,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
      lastRecorded: lastRecorded ?? this.lastRecorded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'x': x,
      'y': y,
      'type': type,
      'description': description,
      'isCompleted': isCompleted,
      'lastRecorded': lastRecorded?.millisecondsSinceEpoch,
    };
  }

  static PresetPoint fromJson(Map<String, dynamic> json) {
    return PresetPoint(
      id: json['id'],
      name: json['name'],
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      type: json['type'],
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      lastRecorded: json['lastRecorded'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastRecorded'])
          : null,
    );
  }
}
