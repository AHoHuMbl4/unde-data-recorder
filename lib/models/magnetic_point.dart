import 'dart:math' as math;

class MagneticPoint {
  final int timestamp;
  final double bx, by, bz; // Магнитометр
  final double ax, ay, az; // Акселерометр
  final double gx, gy, gz; // Гироскоп
  final double pressure;   // Барометр
  final double? x, y;      // Координаты
  final String floor;
  final String? poiType;
  final String? description;
  final double magneticMagnitude;
  final int stepCount;
  final double heading;
  
  // Новые поля для ориентации
  final double azimuth;
  final String compassDirection;
  final String deviceOrientation;
  final String recordingOrientation;
  final double bxCorrected;
  final double byCorrected;
  final double bzCorrected;

  MagneticPoint({
    required this.timestamp,
    required this.bx,
    required this.by,
    required this.bz,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
    required this.pressure,
    this.x,
    this.y,
    required this.floor,
    this.poiType,
    this.description,
    required this.magneticMagnitude,
    required this.stepCount,
    required this.heading,
    this.azimuth = 0.0,
    this.compassDirection = '',
    this.deviceOrientation = '',
    this.recordingOrientation = '',
    this.bxCorrected = 0.0,
    this.byCorrected = 0.0,
    this.bzCorrected = 0.0,
  });

  /// Создать MagneticPoint из Map (для работы с sensor_service)
  factory MagneticPoint.fromMap(Map<String, dynamic> data) {
    return MagneticPoint(
      timestamp: data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      bx: (data['magnetometer_x'] ?? 0.0).toDouble(),
      by: (data['magnetometer_y'] ?? 0.0).toDouble(),
      bz: (data['magnetometer_z'] ?? 0.0).toDouble(),
      ax: (data['accelerometer_x'] ?? 0.0).toDouble(),
      ay: (data['accelerometer_y'] ?? 0.0).toDouble(),
      az: (data['accelerometer_z'] ?? 0.0).toDouble(),
      gx: (data['gyroscope_x'] ?? 0.0).toDouble(),
      gy: (data['gyroscope_y'] ?? 0.0).toDouble(),
      gz: (data['gyroscope_z'] ?? 0.0).toDouble(),
      pressure: (data['pressure'] ?? 0.0).toDouble(),
      x: data['x']?.toDouble(),
      y: data['y']?.toDouble(),
      floor: data['floor']?.toString() ?? '',
      poiType: data['poi_type']?.toString(),
      description: data['description']?.toString(),
      magneticMagnitude: (data['magnetic_magnitude'] ?? 0.0).toDouble(),
      stepCount: data['step_count'] ?? 0,
      heading: (data['heading'] ?? 0.0).toDouble(),
      // Новые поля для ориентации
      azimuth: (data['azimuth'] ?? 0.0).toDouble(),
      compassDirection: data['compass_direction']?.toString() ?? '',
      deviceOrientation: data['device_orientation']?.toString() ?? '',
      recordingOrientation: data['recording_orientation']?.toString() ?? '',
      bxCorrected: (data['bx_corrected'] ?? data['magnetometer_x'] ?? 0.0).toDouble(),
      byCorrected: (data['by_corrected'] ?? data['magnetometer_y'] ?? 0.0).toDouble(),
      bzCorrected: (data['bz_corrected'] ?? data['magnetometer_z'] ?? 0.0).toDouble(),
    );
  }

  /// Создать MagneticPoint из CSV строки
  factory MagneticPoint.fromCsvRow(List<String> row) {
    return MagneticPoint(
      timestamp: int.tryParse(row[0]) ?? 0,
      bx: double.tryParse(row[1]) ?? 0.0,
      by: double.tryParse(row[2]) ?? 0.0,
      bz: double.tryParse(row[3]) ?? 0.0,
      ax: double.tryParse(row[4]) ?? 0.0,
      ay: double.tryParse(row[5]) ?? 0.0,
      az: double.tryParse(row[6]) ?? 0.0,
      gx: double.tryParse(row[7]) ?? 0.0,
      gy: double.tryParse(row[8]) ?? 0.0,
      gz: double.tryParse(row[9]) ?? 0.0,
      pressure: double.tryParse(row[10]) ?? 0.0,
      x: double.tryParse(row[11]),
      y: double.tryParse(row[12]),
      floor: row.length > 13 ? row[13] : '',
      poiType: row.length > 14 ? row[14] : null,
      description: row.length > 15 ? row[15] : null,
      magneticMagnitude: double.tryParse(row.length > 16 ? row[16] : '0') ?? 0.0,
      stepCount: int.tryParse(row.length > 17 ? row[17] : '0') ?? 0,
      heading: double.tryParse(row.length > 18 ? row[18] : '0') ?? 0.0,
      // Дополнительные поля ориентации если есть
      azimuth: double.tryParse(row.length > 19 ? row[19] : '0') ?? 0.0,
      compassDirection: row.length > 20 ? row[20] : '',
      deviceOrientation: row.length > 21 ? row[21] : '',
      recordingOrientation: row.length > 22 ? row[22] : '',
      bxCorrected: double.tryParse(row.length > 23 ? row[23] : '0') ?? 0.0,
      byCorrected: double.tryParse(row.length > 24 ? row[24] : '0') ?? 0.0,
      bzCorrected: double.tryParse(row.length > 25 ? row[25] : '0') ?? 0.0,
    );
  }

  /// Заголовки для CSV файла
  static List<String> csvHeaders() {
    return [
      'timestamp', 'bx', 'by', 'bz', 'ax', 'ay', 'az', 'gx', 'gy', 'gz',
      'pressure', 'x', 'y', 'floor', 'poi_type', 'description', 
      'magnetic_magnitude', 'step_count', 'heading',
      'azimuth', 'compass_direction', 'device_orientation', 'recording_orientation',
      'bx_corrected', 'by_corrected', 'bz_corrected'
    ];
  }

  /// Конвертировать в строку CSV
  List<String> toCsvRow() {
    return [
      timestamp.toString(),
      bx.toString(),
      by.toString(),
      bz.toString(),
      ax.toString(),
      ay.toString(),
      az.toString(),
      gx.toString(),
      gy.toString(),
      gz.toString(),
      pressure.toString(),
      x?.toString() ?? '',
      y?.toString() ?? '',
      floor,
      poiType ?? '',
      description ?? '',
      magneticMagnitude.toString(),
      stepCount.toString(),
      heading.toString(),
      azimuth.toString(),
      compassDirection,
      deviceOrientation,
      recordingOrientation,
      bxCorrected.toString(),
      byCorrected.toString(),
      bzCorrected.toString(),
    ];
  }

  /// Вычислить магнитную интенсивность
  double calculateMagnitude() {
    return math.sqrt(bx * bx + by * by + bz * bz);
  }

  /// Вычислить направление по магнитному полю
  double calculateHeading() {
    double heading = math.atan2(by, bx) * (180 / math.pi);
    if (heading < 0) heading += 360;
    return heading;
  }

  /// Проверить есть ли координаты
  bool hasCoordinates() {
    return x != null && y != null;
  }

  /// Получить краткое описание точки
  String getLocationString() {
    if (hasCoordinates()) {
      return '(${x!.toInt()}, ${y!.toInt()})';
    }
    return 'Нет координат';
  }

  /// Получить форматированное время
  String getFormattedTime() {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'MagneticPoint(${getFormattedTime()}, ${getLocationString()}, Mag: ${magneticMagnitude.toStringAsFixed(2)}μT)';
  }
}
