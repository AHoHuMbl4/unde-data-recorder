// lib/screens/map_upload_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/server_service.dart';

class MapUploadScreen extends StatefulWidget {
  @override
  _MapUploadScreenState createState() => _MapUploadScreenState();
}

class _MapUploadScreenState extends State<MapUploadScreen> {
  final ServerService _serverService = ServerService();
  bool _isLoading = false;
  File? _selectedFile;
  int _selectedFloorNumber = 1;
  int? _selectedProjectId;
  List<dynamic> _projects = [];
  List<dynamic> _uploadedMaps = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _serverService.initialize();
    await _loadProjects();
    await _loadUploadedMaps();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projects = await _serverService.getProjects();
      setState(() {
        _projects = projects ?? [];
        if (_projects.isNotEmpty && _selectedProjectId == null) {
          _selectedProjectId = _projects[0]['id'];
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка загрузки проектов: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadUploadedMaps() async {
    if (_selectedProjectId == null) return;

    try {
      final floors = await _serverService.getFloors(_selectedProjectId!);
      setState(() {
        _uploadedMaps = floors ?? [];
      });
    } catch (e) {
      print('Ошибка загрузки карт: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка выбора файла: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadMap() async {
    if (_selectedFile == null || _selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Выберите файл и проект'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _serverService.uploadFloorPlan(
        _selectedProjectId!,
        _selectedFloorNumber,
        _selectedFile!,
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ План этажа успешно загружен'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _selectedFile = null;
        });

        await _loadUploadedMaps();
      } else {
        throw Exception('Не удалось загрузить план');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка загрузки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildProjectSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏢 Выбор проекта',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedProjectId,
              decoration: InputDecoration(
                labelText: 'Проект',
                border: OutlineInputBorder(),
              ),
              items: _projects.map<DropdownMenuItem<int>>((project) {
                return DropdownMenuItem<int>(
                  value: project['id'],
                  child: Text(project['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProjectId = value;
                });
                _loadUploadedMaps();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📁 Выбор файла плана',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Номер этажа',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedFloorNumber.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _selectedFloorNumber = int.tryParse(value) ?? 1;
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: Icon(Icons.folder_open),
                    label: Text('Выбрать файл'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[400],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            
            if (_selectedFile != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Выбран: ${_selectedFile!.path.split('/').last}',
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _uploadMap,
                icon: _isLoading 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.cloud_upload),
                label: Text(_isLoading ? 'Загрузка...' : 'Загрузить план на сервер'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedMaps() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 Загруженные планы (${_uploadedMaps.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            
            if (_uploadedMaps.isEmpty) ...[
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Планы этажей пока не загружены',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            ] else ...[
              ...(_uploadedMaps.map((floor) => Card(
                color: Colors.blue[50],
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${floor['floor_number'] ?? '?'}'),
                    backgroundColor: Colors.blue[400],
                    foregroundColor: Colors.white,
                  ),
                  title: Text('Этаж ${floor['floor_number'] ?? 'Неизвестен'}'),
                  subtitle: Text('Загружен: ${floor['created_at']?.substring(0, 10) ?? 'Неизвестно'}'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
              )).toList()),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🗺️ Загрузка планов зданий'),
        backgroundColor: Colors.green[400],
      ),
      body: _isLoading && _projects.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProjectSelector(),
                  SizedBox(height: 16),
                  _buildFileSelector(),
                  SizedBox(height: 16),
                  _buildUploadedMaps(),
                ],
              ),
            ),
    );
  }
}
